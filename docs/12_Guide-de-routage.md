# Guide de routage PCB

**Statut (révisé 2026-11-07) :** un autorouteur A* **bicouche** (`tools/generate_pcb.ps1`, fonctions `Find-Path`/`Emit-Path`, F.Cu + B.Cu avec vias) route automatiquement **157 des 188 connexions**, 0 erreur DRC réelle. Les 31 connexions restantes (voir § 2) restent à router à la main dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé ici).

## 0. Comment fonctionne l'autoroutage par script, et ses limites

Première tentative (ligne droite pure) : seules les connexions entre composants **directement voisins** (1 pas d'écart, ex. `QB_*`/`LEDA_*`) passaient sans toucher un composant intermédiaire ; tout le reste créait des courts-circuits DRC réels en ligne droite. Remplacé par un vrai **pathfinding A*** :

- **Modèle d'obstacles :** chaque broche de chaque composant (connectée ou non) est un obstacle individuel (boîte ~2,2×2,2 mm, rayon de pastille + marge de dégagement) — pas le composant entier. Un composant entier comme obstacle unique laissait une piste traverser librement les **autres** broches du même composant dès que ce composant était à une extrémité du chemin (confirmé par de vrais courts-circuits DRC sur des boîtiers à broches rapprochées comme le DIP-6 ou le TO-92, pas 1,27-2,54 mm) ; au niveau de la broche, seules les deux broches exactes visées par la piste en cours sont exclues du blocage (par coordonnée, pas par référence de composant), toutes les autres broches du même composant restent bloquantes.
- **Déplacement 4 directions uniquement** (horizontal/vertical, jamais diagonal) : un déplacement diagonal produit, une fois simplifié, un segment dont le rectangle englobant (utilisé comme obstacle pour les pistes suivantes) est disproportionné par rapport à l'encombrement réel de la piste — constaté en pratique (une fenêtre de recherche se retrouvait bloquée à 74 % dès la 2e/3e piste routée avec déplacement 8 directions).
- **Ordre de routage** : les nets les plus contraints (connexions locales à 1-2 pas, `QB_*`/`LEDA_*`/`RSF_*`, puis `LEDK_*`/`FMT2_*`/`MT1D_*`, puis `GPIO*`, puis `FP*`) sont routés **avant** les nets bus à forte connectivité (`GND`, `VSYS`, etc.). Router un bus en premier pouvait tracer une piste traversant la position exacte d'une broche qu'un net local tentait d'atteindre juste après — bug réel diagnostiqué et corrigé.
- **Recherche bicouche avec vias (ajouté 2026-11-07) :** avec une seule couche de cuivre (B.Cu), les familles `LEDK_*`/`FMT2_*`/`MT1D_*` échouaient **en bloc** (16/16 canaux), alors que `LEDA_*`/`QB_*`/`RSF_*` (routées juste avant, même longueur de trajet) réussissaient — preuve que la cause n'était pas géométrique mais une saturation de la seule couche disponible par les ~48 premières pistes. L'A* recherche maintenant sur F.Cu **et** B.Cu simultanément, avec un changement de couche (via, coût de détour équivalent à 5 mm) autorisé à toute case de la grille où l'autre couche est libre. Résultat : 90 → 157 connexions routées (31 vias posés). Tourner la marge de fenêtre à la hausse (35 mm) ou baisser le coût du via (2 mm) ont tous deux été essayés et ont **dégradé** le résultat (150 et 148 routées respectivement) : le routeur reste glouton et séquentiel (plus proche voisin, un net à la fois), donc un chemin plus long ou plus libre pour un net peut consommer de la place dont un net suivant avait besoin — les valeurs actuelles (marge 20 mm, coût via 5) sont un optimum local trouvé empiriquement, pas une valeur théorique.
- **Fenêtre de recherche locale bornée** (marge 20 mm autour du segment direct start→end, résolution de grille 1 mm) plutôt qu'une recherche sur la carte entière, pour rester rapide.

Chaque régénération est vérifiée par DRC systématique (`kicad-cli pcb drc`) ; les connexions qui échouent sont listées en sortie du script sous « echecs (a router a la main) » et ne sont jamais forcées.

## 1. Avant de router

1. Ouvrir `hardware/kicad/FilPilote_8Zones.kicad_pro`, éditeur PCB.
2. Vérifier que le ratsnest (fils logiques fins) relie bien toutes les pastilles.
3. Définir les classes de net (`Fichier > Paramètres de la carte > Classes de net`) **avant** de commencer à router :

| Classe | Nets | Largeur piste | Clearance |
|---|---|---|---|
| Logique | `GPIO*`, `QB_*`, `LEDA_*`, `LEDK_*`, `GND`, `VSYS`, `3V3_OPTO` | 0,25–0,3 mm | 0,2 mm (standard) |
| Secteur | `PHASE_PROT`, `MAINS_L`, `MAINS_N`, `RSF_*`, `FMT2_*`, `MT1D_*`, `FP1`…`FP8` | 0,4–0,5 mm | **≥ 6 mm vis-à-vis de la classe Logique** |

La clearance de 6 mm reprend la valeur déjà validée dans [04_Implantation-PCB](04_Implantation-PCB.md) (dépasse le minimum IEC 60664-1 pour cette plage de tension). Le courant de défaut côté secteur est limité à ~49 mA par les résistances 4,7 kΩ (voir [03_Nomenclature](03_Nomenclature.md)) : pas besoin de cuivre épais façon piste de puissance, la largeur proposée est un confort mécanique/thermique, pas un calcul de courant fort.

4. Repérer les lignes en pointillés sur la couche `Dwgs.User` (autour de chaque rangée d'optotriacs) : elles marquent la bande de 6 mm qui doit rester vierge de cuivre. Les optotriacs (MOC3063M, DIP-6) sont le seul pont autorisé entre logique et secteur, par construction du composant — aucune piste ne doit la traverser ailleurs.

## 2. Ordre de routage recommandé (ce qu'il reste à faire)

**Entièrement auto-routés par le script (rien à faire, sauf vérification visuelle) :** `QB_*`, `LEDA_*`, `RSF_*`, `LEDK_*`, `FMT2_*` et la quasi-totalité de `MT1D_*` — 157 connexions au total, 31 vias posés pour passer sur l'autre couche dans les zones denses.

**Reste à router à la main (31 connexions, listées exactement en sortie du script à chaque régénération) :**

1. **`MT1D_Z2P`, `Z3P`, `Z4P`, `Z6P`, `Z7P`, `Z8P`** (`OCZxP → DZxP`) : 6 des 16 canaux `MT1D_*`, mêmes composants et même distance que les 10 autres canaux routés automatiquement — échec par manque de place locale (pas un problème de géométrie).
2. **`GPIO15`, `17`, `2`, `21`, `3`, `38`-`42`, `47`, `48`** (`JWS → RB` du canal correspondant) : 12 connexions longue distance de l'en-tête Waveshare vers les zones, dans une zone de la carte déjà dense une fois les 157 premières pistes posées.
3. **`FP1`-`FP4`** (`J2`/`J3 → D` du canal) : 4 des 8 sorties zone → bornier (`FP5`-`FP8` sont routées).
4. **`3V3_OPTO`** (2 segments : `RLZ3N → RLZ4P`, `RLZ3N → RLZ7N`) et **`GND`** (3 segments : `JWS → QZ1P`, `QZ1P → QZ5P`, `QZ6P → PS1`) : segments résiduels des bus d'alimentation logique, le reste de ces nets est déjà routé.
5. **`LOCAL_5V`** (`DPWR → PS1`), **`VSYS`** (`JWS → DPWR`) et **`PHASE_PROT`** (2 segments : `RSZ6P → RSZ6N`, `RSZ6P → RSZ2P`) : alimentation et bus secteur, segments ponctuels.

Pour chacun, le ratsnest indique déjà la paire de pastilles à relier (le script a tenté exactement ce trajet et échoué) ; un détour manuel même simple (1-2 coudes, éventuellement un via) suffit généralement, le routeur ayant déjà dégagé l'essentiel de la carte autour.

## 3. Pendant le routage

- Ne jamais router une piste logique à travers la bande des 6 mm. Si le ratsnest semble l'exiger, c'est un problème de placement à corriger avant de continuer, pas à contourner en routant quand même.
- Des vias seront probablement nécessaires pour les 31 connexions restantes : l'autorouteur en a déjà posé 31 pour contourner les zones denses, les segments qui lui résistent encore sont les plus contraints.
- Lancer le DRC (F8) après chaque zone routée, pas seulement à la fin.

## 4. Finition

1. DRC complet, toutes règles actives, 0 erreur.
2. Si plan de masse utilisé : remplir les zones de cuivre, puis relancer le DRC (le remplissage peut révéler de nouvelles violations de clearance).
3. Vue 3D : vérifier visuellement l'absence de chevauchement composant/boîtier/voisin.
4. Sérigraphie : repères `FP1`-`FP8` et polarités (diodes, condensateur électrolytique, transistor) lisibles et correctement orientés.
5. Export Gerbers/perçage seulement après tout ce qui précède, et après revue par une personne compétente (secteur 230 V impliqué) — voir [06_Plan-de-validation](06_Plan-de-validation.md).
