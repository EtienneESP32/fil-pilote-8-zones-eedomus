# Guide de routage PCB

**Statut :** procédure à suivre par l'utilisateur dans l'éditeur graphique KiCad (non pilotable depuis l'environnement CLI utilisé pour générer le schéma/placement, voir [11_État du projet KiCad](11_Etat-KiCad.md)). Le placement et le ratsnest sont prêts ; aucune piste n'est tracée.

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

## 2. Ordre de routage recommandé

1. **`GND`** : net le plus partagé. Un plan de masse (zone de cuivre) côté logique est envisageable, mais il doit s'arrêter net à la frontière des 6 mm — jamais de cuivre de plan traversant vers le secteur.
2. **`VSYS` → `3V3_OPTO`** : HLK-5M05 (`PS1`) → diode `DPWR` → `VSYS` → régulateur `U1` (AMS1117) → `3V3_OPTO`, avec les découplages `C1`/`C2` au plus près des pattes du régulateur.
3. **Bus `PHASE_PROT`** : tronc commun depuis `F0`, ramifié vers les 16 résistances secteur (`RSZxP`/`RSZxN`).
4. **Les 16 voies, zone par zone**, dans l'ordre : `GPIO (JWS) → RB → Q → RL → OC → RS/F → D → FPx`. Motif identique pour les 8 zones × 2 canaux — une fois la première voie routée, les 15 suivantes reprennent le même schéma.
5. **Sorties `FP1`-`FP8`** vers `J2`-`J5`.
6. **Connexions restantes** de l'en-tête `JWS` vers chaque zone, si pas déjà faites à l'étape 4.

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
