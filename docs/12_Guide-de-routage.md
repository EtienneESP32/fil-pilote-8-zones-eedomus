# Guide de routage PCB

**Statut (révisé 2026-11-07) :** un autorouteur A* **bicouche, en 2 passes** (`tools/generate_pcb.ps1`, fonctions `Find-Path`/`Emit-Path`, F.Cu + B.Cu avec vias) route automatiquement **172 des 188 connexions**, 0 erreur DRC réelle. Les 16 connexions restantes (voir § 2) sont bloquées localement par la saturation des 2 couches dans leur zone — confirmé, pas supposé (voir § 0) — et restent à router à la main dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé ici).

## 0. Comment fonctionne l'autoroutage par script, et ses limites

Première tentative (ligne droite pure) : seules les connexions entre composants **directement voisins** (1 pas d'écart, ex. `QB_*`/`LEDA_*`) passaient sans toucher un composant intermédiaire ; tout le reste créait des courts-circuits DRC réels en ligne droite. Remplacé par un vrai **pathfinding A*** :

- **Modèle d'obstacles :** chaque broche de chaque composant (connectée ou non) est un obstacle individuel (boîte ~2,2×2,2 mm, rayon de pastille + marge de dégagement) — pas le composant entier. Un composant entier comme obstacle unique laissait une piste traverser librement les **autres** broches du même composant dès que ce composant était à une extrémité du chemin (confirmé par de vrais courts-circuits DRC sur des boîtiers à broches rapprochées comme le DIP-6 ou le TO-92, pas 1,27-2,54 mm) ; au niveau de la broche, seules les deux broches exactes visées par la piste en cours sont exclues du blocage (par coordonnée, pas par référence de composant), toutes les autres broches du même composant restent bloquantes.
- **Déplacement 4 directions uniquement** (horizontal/vertical, jamais diagonal) : un déplacement diagonal produit, une fois simplifié, un segment dont le rectangle englobant (utilisé comme obstacle pour les pistes suivantes) est disproportionné par rapport à l'encombrement réel de la piste — constaté en pratique (une fenêtre de recherche se retrouvait bloquée à 74 % dès la 2e/3e piste routée avec déplacement 8 directions).
- **Ordre de routage** : les nets les plus contraints (connexions locales à 1-2 pas, `QB_*`/`LEDA_*`/`RSF_*`, puis `LEDK_*`/`FMT2_*`/`MT1D_*`, puis `GPIO*`, puis `FP*`) sont routés **avant** les nets bus à forte connectivité (`GND`, `VSYS`, etc.). Router un bus en premier pouvait tracer une piste traversant la position exacte d'une broche qu'un net local tentait d'atteindre juste après — bug réel diagnostiqué et corrigé.
- **Recherche bicouche avec vias (ajouté 2026-11-07) :** avec une seule couche de cuivre (B.Cu), les familles `LEDK_*`/`FMT2_*`/`MT1D_*` échouaient **en bloc** (16/16 canaux), alors que `LEDA_*`/`QB_*`/`RSF_*` (routées juste avant, même longueur de trajet) réussissaient — preuve que la cause n'était pas géométrique mais une saturation de la seule couche disponible par les ~48 premières pistes. L'A* recherche maintenant sur F.Cu **et** B.Cu simultanément, avec un changement de couche (via, coût de détour équivalent à 5 mm) autorisé à toute case de la grille où l'autre couche est libre. Résultat : 90 → 157 connexions routées (31 vias posés).
- **Fenêtre de recherche locale bornée** (marge 20 mm autour du segment direct start→end, résolution de grille 1 mm) plutôt qu'une recherche sur la carte entière, pour rester rapide.
- **2e passe ciblée sur les seuls échecs (ajouté 2026-11-07) :** après la passe normale, chaque échec est retenté avec une fenêtre plus large (60 mm) et une grille plus fine (0,5 mm, pour trouver les interstices sub-millimétriques qu'une grille à 1 mm arrondissait à « bloqué »). Comme ces échecs ne sont plus en concurrence avec des nets encore à router (tout le reste est déjà fixé), élargir leur fenêtre ne dégrade rien d'autre — contrairement à un élargissement en 1ère passe (35 mm testé, résultat dégradé à 150 routées : le routeur étant glouton/séquentiel, un chemin plus généreux pour un net consomme de la place qu'un net suivant pourrait réclamer). Résultat de cette 2e passe : 157 → **172** connexions routées. Un 3e palier à 110 mm a aussi été testé sur les échecs résiduels : **0 connexion récupérée en plus**, confirmant que les 16 échecs finaux sont bloqués par la topologie/saturation locale, pas par une fenêtre trop étroite — une fenêtre plus large ne réussit jamais à débloquer une case qui est réellement occupée par un autre composant/piste/via.
- **Essais rejetés** (gardés ici pour ne pas les retenter) : trier les nets `LEDK_*`/`FMT2_*`/`MT1D_*` par canal plutôt que par famille (pour éviter que `MT1D_*`, traité en dernier alphabétiquement, ne parte toujours sur un couloir déjà saturé par les 32 autres) — `MT1D_*` s'améliorait bien, mais `PHASE_PROT`/`3V3_OPTO` se dégradaient davantage, résultat net 154 vs 157 ; coût de via réduit à 2 mm (au lieu de 5) pour favoriser le changement de couche — résultat dégradé à 148.

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

**Entièrement auto-routés par le script (rien à faire, sauf vérification visuelle) :** `QB_*`, `LEDA_*`, `RSF_*`, `LEDK_*`, `FMT2_*`, `MT1D_*` et la quasi-totalité de `GPIO*`/`FP*` — 172 connexions au total, vias posés pour passer sur l'autre couche dans les zones denses.

**Reste à router à la main (16 connexions, listées exactement en sortie du script à chaque régénération) :**

1. **`GPIO39`, `40`, `41`, `42`, `47`, `48`** (`JWS → RB` zones 6-8) : les seules connexions `GPIO*` encore bloquées, toutes vers les 3 zones les plus éloignées de l'en-tête Waveshare — la zone la plus dense de la carte en fin de routage.
2. **`FP2`, `FP3`, `FP4`** (`J2`/`J3 → D` du canal) : 3 des 8 sorties zone → bornier (`FP1`, `FP5`-`FP8` sont routées).
3. **`3V3_OPTO`** (2 segments : `RLZ3N → RLZ4P`, `RLZ3N → RLZ7N`) et **`GND`** (2 segments : `QZ1P → QZ5P`, `QZ6P → PS1`) : segments résiduels des bus d'alimentation logique, le reste de ces nets est déjà routé.
4. **`LOCAL_5V`** (`DPWR → PS1`) et **`PHASE_PROT`** (2 segments : `RSZ6P → RSZ6N`, `RSZ6P → RSZ2P`) : alimentation et bus secteur, segments ponctuels.

Pour chacun, le ratsnest indique déjà la paire de pastilles à relier (le script a tenté ce trajet avec une fenêtre de recherche large ET une grille fine, sans succès — voir § 0) ; un détour manuel même simple (1-2 coudes, éventuellement un via) suffit généralement, le routeur ayant déjà dégagé l'essentiel de la carte autour.

## 3. Pendant le routage

- Ne jamais router une piste logique à travers la bande des 6 mm. Si le ratsnest semble l'exiger, c'est un problème de placement à corriger avant de continuer, pas à contourner en routant quand même.
- Des vias seront probablement nécessaires pour les 16 connexions restantes : l'autorouteur en a déjà posé plusieurs dizaines pour contourner les zones denses, les segments qui lui résistent encore sont les plus contraints.
- Lancer le DRC (F8) après chaque zone routée, pas seulement à la fin.

## 4. Finition

1. DRC complet, toutes règles actives, 0 erreur.
2. Si plan de masse utilisé : remplir les zones de cuivre, puis relancer le DRC (le remplissage peut révéler de nouvelles violations de clearance).
3. Vue 3D : vérifier visuellement l'absence de chevauchement composant/boîtier/voisin.
4. Sérigraphie : repères `FP1`-`FP8` et polarités (diodes, condensateur électrolytique, transistor) lisibles et correctement orientés.
5. Export Gerbers/perçage seulement après tout ce qui précède, et après revue par une personne compétente (secteur 230 V impliqué) — voir [06_Plan-de-validation](06_Plan-de-validation.md).
