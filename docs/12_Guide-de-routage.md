# Guide de routage PCB

**Statut (révisé 2026-11-07) :** un autorouteur A* dédié (`tools/generate_pcb.ps1`, fonctions `Find-Path`/`Emit-Path`) route automatiquement **90 des 188 connexions**, 0 erreur DRC réelle. Les 98 connexions restantes (nets bus longue distance que la fenêtre de recherche locale ne couvre pas, ou nets dont le chemin dépasse le budget d'itérations) restent à router à la main dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé ici).

## 0. Comment fonctionne l'autoroutage par script, et ses limites

Première tentative (ligne droite pure) : seules les connexions entre composants **directement voisins** (1 pas d'écart, ex. `QB_*`/`LEDA_*`) passaient sans toucher un composant intermédiaire ; tout le reste (`LEDK_*`, `FMT2_*`, `MT1D_*`, nets bus) créait des courts-circuits DRC réels en ligne droite. Remplacé par un vrai **pathfinding A*** :

- **Modèle d'obstacles :** chaque broche de chaque composant (connectée ou non) est un obstacle individuel (boîte ~2,2×2,2 mm, rayon de pastille + marge de dégagement) — pas le composant entier. Un composant entier comme obstacle unique laissait une piste traverser librement les **autres** broches du même composant dès que ce composant était à une extrémité du chemin (confirmé par de vrais courts-circuits DRC sur des boîtiers à broches rapprochées comme le DIP-6 ou le TO-92, pas 1,27-2,54 mm) ; au niveau de la broche, seules les deux broches exactes visées par la piste en cours sont exclues du blocage (par coordonnée, pas par référence de composant), toutes les autres broches du même composant restent bloquantes.
- **Déplacement 4 directions uniquement** (horizontal/vertical, jamais diagonal) : un déplacement diagonal produit, une fois simplifié, un segment dont le rectangle englobant (utilisé comme obstacle pour les pistes suivantes) est disproportionné par rapport à l'encombrement réel de la piste — constaté en pratique (une fenêtre de recherche se retrouvait bloquée à 74 % dès la 2e/3e piste routée avec déplacement 8 directions).
- **Ordre de routage** : les nets les plus contraints (connexions locales à 1-2 pas, `QB_*`/`LEDA_*`/`RSF_*`, puis `LEDK_*`/`FMT2_*`/`MT1D_*`, puis `GPIO*`, puis `FP*`) sont routés **avant** les nets bus à forte connectivité (`GND`, `VSYS`, etc.). Router un bus en premier pouvait tracer une piste traversant la position exacte d'une broche qu'un net local tentait d'atteindre juste après — bug réel diagnostiqué et corrigé (voir historique de session).
- **Fenêtre de recherche locale bornée** (marge 20 mm autour du segment direct start→end, résolution de grille 1 mm) plutôt qu'une recherche sur la carte entière, pour rester rapide. C'est la principale cause des 98 échecs restants : un chemin existant mais plus long que la fenêtre locale n'est pas trouvé.

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

**Entièrement auto-routés par le script (rien à faire, sauf vérification visuelle) :** `QB_*`, `LEDA_*`, `RSF_*` — les 3 nets locaux à 1 pas d'écart, 16 canaux chacun.

**Entièrement à router à la main :** `LEDK_*` et `MT1D_*` (16 canaux chacun), et la quasi-totalité de `FMT2_*` — ces nets relient des composants séparés de 2-3 pas, hors de portée de la fenêtre de recherche locale de l'autorouteur (voir § 0). Tracé en L autour du composant intermédiaire, simple à faire à l'œil dans l'éditeur.

**Partiellement routés** (certains segments auto-routés, d'autres encore au ratsnest — vérifier au cas par cas dans l'éditeur, le script liste les échecs exacts sur sa sortie console à chaque régénération) :

1. **`GND`** : net le plus partagé. Un plan de masse (zone de cuivre) côté logique est envisageable pour les segments restants, mais il doit s'arrêter net à la frontière des 6 mm — jamais de cuivre de plan traversant vers le secteur.
2. **`VSYS` → `3V3_OPTO`** : HLK-5M05 (`PS1`) → diode `DPWR` → `VSYS` → régulateur `U1` (AMS1117) → `3V3_OPTO`, avec les découplages `C1`/`C2` au plus près des pattes du régulateur.
3. **Bus `PHASE_PROT`** : tronc commun depuis `F0`, ramifié vers les 16 résistances secteur (`RSZxP`/`RSZxN`).
4. **`GPIO*`** : connexions `JWS → RB` de chaque canal, longue distance à travers la carte — la plupart des hops restent à router à la main.
5. **Sorties `FP1`-`FP8`** vers `J2`-`J5`.

## 3. Pendant le routage

- Ne jamais router une piste logique à travers la bande des 6 mm. Si le ratsnest semble l'exiger, c'est un problème de placement à corriger avant de continuer, pas à contourner en routant quand même.
- Des vias seront probablement nécessaires pour sortir des zones denses (empilement RB/Q/RL/OC resserré par canal).
- Lancer le DRC (F8) après chaque zone routée, pas seulement à la fin.

## 4. Finition

1. DRC complet, toutes règles actives, 0 erreur.
2. Si plan de masse utilisé : remplir les zones de cuivre, puis relancer le DRC (le remplissage peut révéler de nouvelles violations de clearance).
3. Vue 3D : vérifier visuellement l'absence de chevauchement composant/boîtier/voisin.
4. Sérigraphie : repères `FP1`-`FP8` et polarités (diodes, condensateur électrolytique, transistor) lisibles et correctement orientés.
5. Export Gerbers/perçage seulement après tout ce qui précède, et après revue par une personne compétente (secteur 230 V impliqué) — voir [06_Plan-de-validation](06_Plan-de-validation.md).
