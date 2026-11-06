# État du projet KiCad natif

**Statut (2026-11-07, révisé) :** schéma électriquement complet et vérifié ERC ; implantation PCB placée et vérifiée DRC (hors routage). Ce projet KiCad devient la référence pour la topologie électrique — il intègre toutes les clôtures du 2026-11-06 (GPIO corrigés, étage tampon transistor, 4,7 kΩ + fusibles secteur, HLK-5M05, MOC3063M) que la copie EasyEDA R1 (`FilPilote_8Zones_DIN_R1_2026-11-06`, voir [08_Revue-schema-source](08_Revue-schema-source.md)) ne contient pas encore.

**Correction importante (2026-11-07) :** l'empreinte du connecteur de la carte Waveshare, livrée dans une première version de ce document, était un connecteur générique 1 rangée / 19 broches — sans rapport avec le vrai connecteur de la carte, repérée par l'utilisateur. Voir « Correction du connecteur Waveshare » ci-dessous pour le détail et les conséquences (deux affectations GPIO supplémentaires corrigées).

## Emplacement

- `hardware/kicad/FilPilote_8Zones.kicad_pro` — projet
- `hardware/kicad/FilPilote_8Zones.kicad_sch` — schéma (généré, voir `tools/generate_schematic.ps1`)
- `hardware/kicad/FilPilote_8Zones.kicad_pcb` — PCB (généré, voir `tools/generate_pcb.ps1`)
- `hardware/kicad/*.erc.json`, `*.drc.json` — rapports de vérification bruts
- `hardware/kicad/FilPilote_8Zones_render.png` — rendu visuel du placement

## Méthode

Le schéma et le PCB sont produits par deux scripts PowerShell (`tools/generate_schematic.ps1`, `tools/generate_pcb.ps1`) qui écrivent directement les fichiers texte `.kicad_sch`/`.kicad_pcb` au format KiCad 10, plutôt que d'utiliser l'éditeur graphique (non disponible dans cet environnement). Les symboles et empreintes sont des définitions minimales propres au projet (bibliothèque `FP`, non enregistrée dans une table de bibliothèque — d'où les avertissements bénins « bibliothèque FP introuvable » dans les rapports, sans impact électrique), à l'exception du connecteur Waveshare dont la géométrie a été vérifiée contre le vrai composant (voir ci-dessous). Chaque script a été validé empiriquement avec `kicad-cli` (erreurs de format corrigées par itération : inversion d'axe Y des broches de symbole, pas de grille, calcul d'offset, opérateur PowerShell qui répétait un tableau au lieu de multiplier une valeur).

## Correction du connecteur Waveshare (2026-11-07)

**Ce qui était faux :** le connecteur `JWS` modélisait une rangée unique de 19 broches arbitraires, sans rapport avec la géométrie réelle de la carte Waveshare ESP32-S3-ETH.

**Vérification faite :** le pinout physique réel a été récupéré ([espboards.dev](https://www.espboards.dev/esp32/waveshare-esp32-s3-eth/), recoupé avec le wiki fabricant). La carte fait 72,8 × 21 mm et porte un **en-tête 40 broches compatible Raspberry Pi Pico** : 2 rangées de 20 broches, pas 2,54 mm, rangées espacées de 17,78 mm. Le connecteur `FP:CONN40_PICO` a été refait à l'identique de cette géométrie (vérifié par inspection directe des coordonnées de pastilles générées : deux colonnes à 10,00 mm et 27,78 mm d'écart exact).

**Deux erreurs d'affectation GPIO découvertes en croisant le pinout physique réel** (en plus de la correction GPIO33/34 déjà actée le 2026-11-06) :

| Zone/voie | GPIO précédent | Problème | GPIO corrigé |
|---|---:|---|---:|
| Zone 4, voie B | GPIO4 | Ne sort que sur le connecteur carte TF, absent de l'en-tête principal câblable | **GPIO45** |
| Zone 5, voie A | GPIO5 | Idem (carte TF uniquement) | **GPIO3** (broche de strapping JTAG ESP32-S3 ; risque limité à la sélection de source JTAG au démarrage, pas un risque de boot ; accepté faute d'alternative libre) |
| Zone 4, voie A | GPIO21 | Partagé avec la LED WS2812 embarquée de la carte | **Conservé** ; effet cosmétique accepté (la LED de statut suivra l'état de la zone 4 POS) |
| — | — | GPIO46 présent sur l'en-tête mais **entrée seule** sur ESP32-S3 | Exclu des candidats |

Table complète et à jour dans [02_Architecture-et-interfaces §2](02_Architecture-et-interfaces.md).

**Point nouvellement ouvert :** l'en-tête 40 broches ne documente aucune broche « sortie PoE » exploitable (seules `VBUS`/`VSYS`/`GND`/`3V3`/`3V3_EN`/`RUN` apparaissent côté alimentation). Le sélecteur `SW1` prévu entre alimentation locale et PoE a son entrée « PoE » câblée sur un réseau non raccordé (`POE_5V_A_CONFIRMER`, visible comme avertissement ERC volontaire). Il faut le schéma du module PoE Waveshare lui-même pour confirmer si une sortie externe existe ou si le PoE alimente `VSYS` en interne (auquel cas le principe du sélecteur externe serait à revoir).

## Résultats de vérification (après correction)

- **ERC (schéma) :** 0 erreur. 1 avertissement intentionnel (`POE_5V_A_CONFIRMER` non raccordé, voir ci-dessus). 248 avertissements bénins « bibliothèque FP introuvable », sans incidence électrique.
- **DRC (PCB) :** 0 erreur réelle. 124 avertissements bénins (même cause bibliothèque). ~188 éléments non connectés — **attendu : aucune piste n'est routée**, le DRC ne vérifie ici que le placement, les chevauchements de courtyard et les règles de dégagement.

## Ce que ça couvre

- Les 8 zones × 2 voies (POS/NEG), chacune : résistance de base → transistor tampon → résistance LED → MOC3063M → résistance secteur 4,7 kΩ → fusible/PTC → diode → sortie FPx, conforme aux décisions fermées du 2026-11-06.
- Section alimentation : sélecteur PoE/local (entrée PoE non raccordée, voir point ouvert ci-dessus), HLK-5M05, AMS1117 dédié aux LED d'opto, découplage.
- Connectique : J1 (secteur), J2-J5 (FP1-FP8), en-tête Waveshare 40 broches réel (GND, VSYS, 16×GPIO câblés sur leurs broches physiques réelles ; les 21 autres broches — VBUS/3V3/3V3_EN/RUN/GPIO non retenus/réservés — sont non connectées).
- Implantation : colonne gauche (en-tête Waveshare + alimentation), 8 zones au centre en 4 bandes horizontales de 2 zones chacune, connectique secteur/FP en bord de carte droit.

## Révision du gabarit de carte

Le placement réel des 16 voies THT a montré que 105 × 85 mm (gabarit indicatif de la source) ne suffit pas. Une première extension à 105 × 180 mm a ensuite été reconsidérée après une question de l'utilisateur : **la hauteur d'un boîtier rail DIN modulaire est fixée par la gamme du fabricant (environ 80-130 mm usuel), ce n'est pas une dimension libre — seule la largeur varie avec le nombre de modules (1 module = 17,5 mm)**. La carte a donc été réorientée en **192 × 108 mm, soit ~11 modules de large**, pour rester dans un gabarit de boîtier modulaire courant du commerce (ex. boîtiers RS PRO d'une largeur proche dans la même famille). Toujours indicatif : à confronter à la référence réelle du boîtier une fois choisie (point déjà listé comme ouvert dans [04_Implantation-PCB](04_Implantation-PCB.md)).

## Ce qui n'est pas fait

- **Routage des pistes** : aucune piste cuivre n'est tracée (seulement le placement et le ratsnest). C'est l'étape suivante, qui nécessite l'éditeur interactif KiCad (non pilotable depuis cet environnement en ligne de commande) — à faire dans l'interface graphique KiCad installée sur cette machine.
- **Sortie PoE côté Waveshare** : non confirmée, voir point ouvert ci-dessus — à lever avant de considérer le sélecteur d'alimentation comme validé.
- **Empreintes définitives des autres composants** : les empreintes hors connecteur Waveshare restent des gabarits génériques auto-cohérents (ex. `FP:DIP6`, `FP:TO92_3`), pas les empreintes réelles des références fabricant choisies. Elles sont correctes électriquement (mêmes numéros de broches que le schéma) mais leurs dimensions/pas exacts restent à confronter aux datasheets avant fabrication.
- **Plans de masse, classes de nets, règles de largeur de piste secteur vs logique** : non définis.
- **Table de bibliothèque locale** (`sym-lib-table`/`fp-lib-table`) : non créée ; à faire pour que KiCad propose nativement les symboles/empreintes en édition graphique (actuellement seulement en cache dans les fichiers, fonctionnel mais pas éditable comme bibliothèque séparée).
