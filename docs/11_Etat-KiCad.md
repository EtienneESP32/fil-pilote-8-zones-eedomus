# État du projet KiCad natif

**Statut (2026-11-07) :** schéma électriquement complet et vérifié ERC ; implantation PCB placée et vérifiée DRC (hors routage). Ce projet KiCad devient la référence pour la topologie électrique — il intègre toutes les clôtures du 2026-11-06 (GPIO corrigés, étage tampon transistor, 4,7 kΩ + fusibles secteur, HLK-5M05, MOC3063M) que la copie EasyEDA R1 (`FilPilote_8Zones_DIN_R1_2026-11-06`, voir [08_Revue-schema-source](08_Revue-schema-source.md)) ne contient pas encore.

## Emplacement

- `hardware/kicad/FilPilote_8Zones.kicad_pro` — projet
- `hardware/kicad/FilPilote_8Zones.kicad_sch` — schéma (généré, voir `tools/generate_schematic.ps1`)
- `hardware/kicad/FilPilote_8Zones.kicad_pcb` — PCB (généré, voir `tools/generate_pcb.ps1`)
- `hardware/kicad/*.erc.json`, `*.drc.json` — rapports de vérification bruts
- `hardware/kicad/FilPilote_8Zones_render.png` — rendu visuel du placement

## Méthode

Le schéma et le PCB sont produits par deux scripts PowerShell (`tools/generate_schematic.ps1`, `tools/generate_pcb.ps1`) qui écrivent directement les fichiers texte `.kicad_sch`/`.kicad_pcb` au format KiCad 10, plutôt que d'utiliser l'éditeur graphique (non disponible dans cet environnement). Les symboles et empreintes sont des définitions minimales propres au projet (bibliothèque `FP`, non enregistrée dans une table de bibliothèque — d'où les avertissements bénins « bibliothèque FP introuvable » dans les rapports, sans impact électrique). Chaque script a été validé empiriquement avec `kicad-cli` (erreurs de format corrigées par itération : inversion d'axe Y des broches de symbole, pas de grille, calcul d'offset).

## Résultats de vérification

- **ERC (schéma) :** 0 erreur, 0 avertissement réel. 248 avertissements bénins « bibliothèque FP introuvable » (248 = 124 composants × 2, symbole + empreinte), sans incidence électrique.
- **DRC (PCB) :** 0 erreur réelle. 124 avertissements bénins (même cause). 189 éléments non connectés — **attendu : aucune piste n'est routée**, le DRC ne vérifie ici que le placement, les chevauchements de courtyard et les règles de dégagement.

## Ce que ça couvre

- Les 8 zones × 2 voies (POS/NEG), chacune : résistance de base → transistor tampon → résistance LED → MOC3063M → résistance secteur 4,7 kΩ → fusible/PTC → diode → sortie FPx, conforme aux décisions fermées du 2026-11-06.
- Section alimentation : sélecteur PoE/local, HLK-5M05, AMS1117 dédié aux LED d'opto, découplage.
- Connectique : J1 (secteur), J2-J5 (FP1-FP8), en-tête Waveshare 19 broches (GND, VSYS, POE_5V, 16×GPIO).
- Implantation : bande logique en haut de chaque rangée, bande secteur en bas, optotriacs à la jonction (pattes LED vers la logique, pattes triac vers le secteur) — conforme au principe de séparation des domaines de [04_Implantation-PCB](04_Implantation-PCB.md).

## Révision du gabarit de carte

La carte occupe **105 × 180 mm**, pas 105 × 85 mm. La largeur de 105 mm (rail DIN 6 modules) est conservée car c'est la seule contrainte mécanique réelle confirmée ; la hauteur de 85 mm de la source n'avait jamais été validée (voir [04_Implantation-PCB](04_Implantation-PCB.md)) et s'est révélée insuffisante dès qu'on place réellement 16 voies de composants traversants avec un dégagement correct. Une carte rail DIN peut légitimement être plus longue que large (le nombre de modules fixe seulement la largeur) ; reste à vérifier que 180 mm de hauteur entre dans le boîtier réel une fois celui-ci choisi — point déjà listé comme ouvert.

## Ce qui n'est pas fait

- **Routage des pistes** : aucune piste cuivre n'est tracée (seulement le placement et le ratsnest). C'est l'étape suivante, qui nécessite l'éditeur interactif KiCad (non pilotable depuis cet environnement en ligne de commande) — à faire dans l'interface graphique KiCad installée sur cette machine.
- **Empreintes définitives** : toutes les empreintes sont des gabarits génériques auto-cohérents (ex. `FP:DIP6`, `FP:TO92_3`), pas les empreintes réelles des références fabricant choisies. Elles sont correctes électriquement (mêmes numéros de broches que le schéma) mais leurs dimensions/pas exacts restent à confronter aux datasheets avant fabrication.
- **Plans de masse, classes de nets, règles de largeur de piste secteur vs logique** : non définis.
- **Table de bibliothèque locale** (`sym-lib-table`/`fp-lib-table`) : non créée ; à faire pour que KiCad propose nativement les symboles/empreintes en édition graphique (actuellement seulement en cache dans les fichiers, fonctionnel mais pas éditable comme bibliothèque séparée).
