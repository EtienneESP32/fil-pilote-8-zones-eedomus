# Guide de routage PCB

**Statut (révisé 2026-11-07) :** un routage automatisé partiel a été tenté par script (même méthode que le placement : génération en texte + vérification DRC). 48 connexions locales sont tracées (3 nets sûrs × 16 canaux, voir § 0). Le reste — l'essentiel du routage — reste à faire par l'utilisateur dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé ici).

## 0. Ce qui est déjà routé automatiquement, et pourquoi pas plus

Tentative de router par script les 6 connexions internes à chaque canal (`QB_*`, `LEDK_*`, `LEDA_*`, `RSF_*`, `FMT2_*`, `MT1D_*`). Résultat après vérification DRC systématique :

- **Routées avec succès (48 segments, 0 erreur DRC) :** `QB_*` et `LEDA_*` (+ `RSF_*`) — ces connexions relient deux composants **directement voisins** dans la pile du canal (1 pas d'écart), une piste droite ne croise rien.
- **Abandonnées après test (`LEDK_*`, `FMT2_*`, `MT1D_*`) :** ces connexions relient des composants séparés de 2 ou 3 pas. Une piste droite entre les deux frôle ou traverse le(s) composant(s) intermédiaire(s) — confirmé par des courts-circuits DRC réels lors du premier essai (ex. `LEDK_Z1P` touchait une broche non connectée de l'optotriac `OCZ1P`). Une piste correcte demande un détour (tracé en L, visible et ajustable seulement avec un retour visuel) que le script ne peut pas calculer en aveugle — **à router à la main**, voir § 2.

Cet épisode illustre directement la limite du « routage par script » évoquée précédemment : sans retour visuel, impossible de détecter un chevauchement avant qu'il soit signalé — d'où la vérification systématique par DRC après chaque tentative, et l'abandon net des 3 connexions à risque plutôt que de les forcer.

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

1. **`GND`** : net le plus partagé. Un plan de masse (zone de cuivre) côté logique est envisageable, mais il doit s'arrêter net à la frontière des 6 mm — jamais de cuivre de plan traversant vers le secteur.
2. **`VSYS` → `3V3_OPTO`** : HLK-5M05 (`PS1`) → diode `DPWR` → `VSYS` → régulateur `U1` (AMS1117) → `3V3_OPTO`, avec les découplages `C1`/`C2` au plus près des pattes du régulateur.
3. **Bus `PHASE_PROT`** : tronc commun depuis `F0`, ramifié vers les 16 résistances secteur (`RSZxP`/`RSZxN`).
4. **`LEDK_*`, `FMT2_*`, `MT1D_*`** (16 canaux chacun) : déjà au ratsnest, nécessitent un détour autour d'un composant voisin (voir § 0) — tracé en L plutôt qu'en ligne droite, simple à faire à l'œil dans l'éditeur.
5. **`GPIO*`** : connexions `JWS → RB` de chaque canal, longue distance à travers la carte.
6. **Sorties `FP1`-`FP8`** vers `J2`-`J5`.

`QB_*`, `LEDA_*` et `RSF_*` sont déjà routées (voir § 0) — rien à faire sur ces 48 connexions, sauf vérification visuelle rapide.

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
