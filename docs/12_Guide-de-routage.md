# Guide de routage PCB

**Statut (révisé 2026-11-07) :** un autorouteur A* **bicouche, en 2 passes, conscient des classes de net Secteur/Logique** (`tools/generate_pcb.ps1`, fonctions `Find-Path`/`Emit-Path`, F.Cu + B.Cu avec vias) route automatiquement **153 des 188 connexions**, 0 erreur DRC réelle — y compris la règle d'isolement 6 mm secteur/logique, désormais une vraie règle DRC vérifiée (voir § 1, et l'historique ci-dessous : elle n'existait nulle part avant ce jour). Les 35 connexions restantes (voir § 2) sont bloquées localement par la saturation des 2 couches, maintenant sous cette contrainte réelle, et restent à router à la main dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé ici).

**Important pour la suite :** le nombre de connexions auto-routées a baissé par rapport à une version intermédiaire de ce jour (172 → 153). Ce n'est pas une régression : cette version à 172 routait plus, mais sans jamais vérifier la séparation 6 mm secteur/logique (la règle n'était pas encore implémentée) — elle était électriquement non sûre, pas seulement incomplète. Voir [04_Implantation-PCB §3](04_Implantation-PCB.md) pour le détail de cette découverte et de sa correction (réorientation de l'optotriac).

## 0. Comment fonctionne l'autoroutage par script, et ses limites

Première tentative (ligne droite pure) : seules les connexions entre composants **directement voisins** (1 pas d'écart, ex. `QB_*`/`LEDA_*`) passaient sans toucher un composant intermédiaire ; tout le reste créait des courts-circuits DRC réels en ligne droite. Remplacé par un vrai **pathfinding A*** :

- **Modèle d'obstacles :** chaque broche de chaque composant (connectée ou non) est un obstacle individuel (boîte ~2,2×2,2 mm, rayon de pastille + marge de dégagement) — pas le composant entier. Un composant entier comme obstacle unique laissait une piste traverser librement les **autres** broches du même composant dès que ce composant était à une extrémité du chemin (confirmé par de vrais courts-circuits DRC sur des boîtiers à broches rapprochées comme le DIP-6 ou le TO-92, pas 1,27-2,54 mm) ; au niveau de la broche, seules les deux broches exactes visées par la piste en cours sont exclues du blocage (par coordonnée, pas par référence de composant), toutes les autres broches du même composant restent bloquantes.
- **Déplacement 4 directions uniquement** (horizontal/vertical, jamais diagonal) : un déplacement diagonal produit, une fois simplifié, un segment dont le rectangle englobant (utilisé comme obstacle pour les pistes suivantes) est disproportionné par rapport à l'encombrement réel de la piste — constaté en pratique (une fenêtre de recherche se retrouvait bloquée à 74 % dès la 2e/3e piste routée avec déplacement 8 directions).
- **Ordre de routage** : les nets les plus contraints (connexions locales à 1-2 pas, `QB_*`/`LEDA_*`/`RSF_*`, puis `LEDK_*`/`FMT2_*`/`MT1D_*`, puis `GPIO*`, puis `FP*`) sont routés **avant** les nets bus à forte connectivité (`GND`, `VSYS`, etc.). Router un bus en premier pouvait tracer une piste traversant la position exacte d'une broche qu'un net local tentait d'atteindre juste après — bug réel diagnostiqué et corrigé.
- **Recherche bicouche avec vias (ajouté 2026-11-07) :** avec une seule couche de cuivre (B.Cu), les familles `LEDK_*`/`FMT2_*`/`MT1D_*` échouaient **en bloc** (16/16 canaux), alors que `LEDA_*`/`QB_*`/`RSF_*` (routées juste avant, même longueur de trajet) réussissaient — preuve que la cause n'était pas géométrique mais une saturation de la seule couche disponible par les ~48 premières pistes. L'A* recherche maintenant sur F.Cu **et** B.Cu simultanément, avec un changement de couche (via, coût de détour équivalent à 5 mm) autorisé à toute case de la grille où l'autre couche est libre. Résultat : 90 → 157 connexions routées (31 vias posés).
- **Fenêtre de recherche locale bornée** (marge 20 mm autour du segment direct start→end, résolution de grille 1 mm) plutôt qu'une recherche sur la carte entière, pour rester rapide.
- **2e passe ciblée sur les seuls échecs (ajouté 2026-11-07) :** après la passe normale, chaque échec est retenté avec une fenêtre plus large (60 mm) et une grille plus fine (0,5 mm, pour trouver les interstices sub-millimétriques qu'une grille à 1 mm arrondissait à « bloqué »). Comme ces échecs ne sont plus en concurrence avec des nets encore à router (tout le reste est déjà fixé), élargir leur fenêtre ne dégrade rien d'autre — contrairement à un élargissement en 1ère passe (35 mm testé, résultat dégradé à 150 routées : le routeur étant glouton/séquentiel, un chemin plus généreux pour un net consomme de la place qu'un net suivant pourrait réclamer). Résultat de cette 2e passe : 157 → **172** connexions routées. Un 3e palier à 110 mm a aussi été testé sur les échecs résiduels : **0 connexion récupérée en plus**, confirmant que les 16 échecs finaux sont bloqués par la topologie/saturation locale, pas par une fenêtre trop étroite — une fenêtre plus large ne réussit jamais à débloquer une case qui est réellement occupée par un autre composant/piste/via.
- **Essais rejetés** (gardés ici pour ne pas les retenter) : trier les nets `LEDK_*`/`FMT2_*`/`MT1D_*` par canal plutôt que par famille (pour éviter que `MT1D_*`, traité en dernier alphabétiquement, ne parte toujours sur un couloir déjà saturé par les 32 autres) — `MT1D_*` s'améliorait bien, mais `PHASE_PROT`/`3V3_OPTO` se dégradaient davantage, résultat net 154 vs 157 ; coût de via réduit à 2 mm (au lieu de 5) pour favoriser le changement de couche — résultat dégradé à 148.
- **Isolement secteur/logique réellement vérifié (ajouté 2026-11-07) :** la séparation documentée de 6 mm n'était vérifiée par aucune règle DRC — seule la documentation et le placement « par construction » l'assuraient. Deux vraies classes de net (`Logique`, `Secteur`) et une règle DRC personnalisée (`hardware/kicad/FilPilote_8Zones.kicad_dru`) ont été ajoutées au projet KiCad ; chaque obstacle du pathfinder (broche, piste, via) porte maintenant la classe de son net, et `Find-Path` impose 6 mm entre classes différentes (0,3-0,55 mm sinon, selon la classe). Activer cette règle a immédiatement révélé **234 violations réelles** sur le board précédent (172 routées), dont **52 sous le minimum réglementaire IEC 60664-1 de 2 mm** (pire cas 0,78 mm) — un vrai défaut de **placement**, pas de routage : deux optotriacs (MOC3063M) de canaux/bandes voisins avaient leurs broches logique et secteur à quelques mm l'une de l'autre, parce que chaque composant de la pile est tourné à 90° pour l'empilement (voir § 1), ce qui faisait basculer la séparation logique/secteur interne de l'optotriac (normalement sur l'axe X du boîtier DIP-6) sur l'axe Y des canaux/bandes. **Corrigé en ne tournant plus l'optotriac** (seul composant concerné) — son orientation naturelle garde cette séparation sur X, indépendante de toute position Y, donc du canal/bande voisin. 0 violation de clearance réelle après correction ; le nombre auto-routé a baissé à 153 car la contrainte est maintenant réelle, pas parce que le routeur a régressé.

Chaque régénération est vérifiée par DRC systématique (`kicad-cli pcb drc`) ; les connexions qui échouent sont listées en sortie du script sous « echecs (a router a la main) » et ne sont jamais forcées.

## 1. Avant de router

1. Ouvrir `hardware/kicad/FilPilote_8Zones.kicad_pro`, éditeur PCB.
2. Vérifier que le ratsnest (fils logiques fins) relie bien toutes les pastilles.
3. Les classes de net sont **déjà définies dans le projet** (plus une étape manuelle à faire, voir § 0 et [04_Implantation-PCB](04_Implantation-PCB.md)) :

| Classe | Nets | Largeur piste | Clearance |
|---|---|---|---|
| Logique | `GPIO*`, `QB_*`, `LEDA_*`, `LEDK_*`, `GND`, `VSYS`, `3V3_OPTO`, `LOCAL_5V` | 0,3 mm | 0,2 mm (standard) |
| Secteur | `PHASE_PROT`, `MAINS_L`, `MAINS_N`, `RSF_*`, `FMT2_*`, `MT1D_*`, `FP1`…`FP8` | 0,4 mm | 0,5 mm (entre nets Secteur) |

La règle **Secteur ↔ Logique = 6 mm** n'est pas une clearance de classe (qui s'appliquerait uniformément y compris entre deux nets Secteur, rendant leur routage mutuel impossible à ce pas de carte) mais une règle DRC personnalisée conditionnelle, dans `hardware/kicad/FilPilote_8Zones.kicad_dru`, qui ne s'applique qu'à la frontière entre les deux classes. Elle reprend la valeur déjà validée dans [04_Implantation-PCB](04_Implantation-PCB.md) (dépasse le minimum IEC 60664-1 pour cette plage de tension). Le courant de défaut côté secteur est limité à ~49 mA par les résistances 4,7 kΩ (voir [03_Nomenclature](03_Nomenclature.md)) : pas besoin de cuivre épais façon piste de puissance, la largeur proposée est un confort mécanique/thermique, pas un calcul de courant fort.

4. Les optotriacs (MOC3063M, DIP-6) sont le seul pont autorisé entre logique et secteur, par construction du composant (et par l'orientation non tournée de ce composant précisément, voir § 0) — aucune piste ne doit créer un 2e pont ailleurs. Lancer le DRC (F8) confirmera toute violation de la règle des 6 mm si c'est le cas.

## 2. Ordre de routage recommandé (ce qu'il reste à faire)

**Entièrement auto-routés par le script (rien à faire, sauf vérification visuelle) :** `QB_*`, `LEDA_*`, `RSF_*`, `LEDK_*` et la quasi-totalité de `FMT2_*`/`GPIO*`/`FP*` — 153 connexions au total, vias posés pour passer sur l'autre couche dans les zones denses, tout en respectant la règle des 6 mm.

**Reste à router à la main (35 connexions, listées exactement en sortie du script à chaque régénération) — straps/cavaliers filaires recommandés plutôt que des pistes PCB classiques, voir § 3 :**

1. **`MT1D_*`** (13 des 16 canaux : `Z1P`, `Z2N/P`, `Z3N/P`, `Z4N/P`, `Z5P`, `Z6N/P`, `Z7N/P`, `Z8N/P`) : la famille la plus touchée par le durcissement de la règle 6 mm — `OC → D` passe maintenant plus loin des zones logique voisines qu'avant.
2. **`GPIO3`, `38`, `39`, `40`, `41`, `42`, `47`, `48`** (`JWS → RB` zones 5-8) : connexions longue distance vers l'en-tête Waveshare, dans la moitié de carte la plus dense en fin de routage.
3. **`FP1`, `FP2`, `FP3`, `FP4`** (`J2`/`J3 → D` du canal) : 4 des 8 sorties zone → bornier (`FP5`-`FP8` sont routées).
4. **`3V3_OPTO`** (2 segments : `RLZ3N → RLZ4P`, `RLZ3N → RLZ7N`), **`GND`** (2 segments : `QZ1P → QZ5P`, `QZ6P → PS1`) et **`LOCAL_5V`** (`DPWR → PS1`) : segments résiduels des bus d'alimentation logique.
5. **`PHASE_PROT`** (2 segments : `RSZ6P → RSZ6N`, `RSZ6P → RSZ2P`) : bus secteur, segments ponctuels.

Pour chacun, le ratsnest indique déjà la paire de pastilles à relier (le script a tenté ce trajet avec une fenêtre de recherche large ET une grille fine, sans succès — voir § 0) ; un strap filaire isolé (cavalier soudé au-dessus des composants, voir § 3) contourne la saturation locale des 2 couches sans contrainte de géométrie 2D, et reste soumis aux mêmes 6 mm de séparation que n'importe quelle piste s'il s'agit d'un net Secteur proche d'un net Logique.

## 3. Pendant le routage

- Ne jamais router une piste à moins de 6 mm d'une piste/pastille de l'autre classe (Secteur vs Logique) — ce n'est plus seulement une convention, le DRC (F8) le signale désormais explicitement par la règle `isolement_secteur_logique_6mm`.
- Pour les 35 connexions restantes, un **strap** (cavalier filaire isolé soudé au-dessus des composants, parfois appelé pont ou cavalier 0 Ω) est recommandé plutôt qu'une piste PCB classique : contrairement à une piste ou un via, il n'est pas contraint par la géométrie 2D du cuivre déjà posé — il relie directement 2 points par le dessus, ce qui correspond exactement à la situation ici (zones saturées sur les 2 couches, pas un problème de tracé impossible dans l'espace). Un strap reste soumis à la même règle de 6 mm s'il franchit la frontière secteur/logique.
- Lancer le DRC (F8) après chaque zone routée, pas seulement à la fin.

## 4. Finition

1. DRC complet, toutes règles actives, 0 erreur.
2. Si plan de masse utilisé : remplir les zones de cuivre, puis relancer le DRC (le remplissage peut révéler de nouvelles violations de clearance).
3. Vue 3D : vérifier visuellement l'absence de chevauchement composant/boîtier/voisin.
4. Sérigraphie : repères `FP1`-`FP8` et polarités (diodes, condensateur électrolytique, transistor) lisibles et correctement orientés.
5. Export Gerbers/perçage seulement après tout ce qui précède, et après revue par une personne compétente (secteur 230 V impliqué) — voir [06_Plan-de-validation](06_Plan-de-validation.md).
