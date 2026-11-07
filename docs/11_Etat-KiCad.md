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

**Point fermé (2026-11-07), schéma fabricant réel consulté :** le schéma officiel ([ESP32-S3-ETH-Schematic.pdf](https://files.waveshare.com/wiki/ESP32-S3-ETH/ESP32-S3-ETH-Schematic.pdf)) montre que `POE_5V` est le même net que `VBUS` (USB-C) côté Waveshare — le module PoE s'enfiche sur un connecteur interne dédié, pas sur l'en-tête 40 broches. `VSYS` (broche 2) est la seule entrée externe accessible, déjà commutée en interne entre `VBUS`/PoE par un MOSFET (Q3, APM2307). Le sélecteur manuel `SW1` prévu initialement est donc **retiré** : il n'y a rien à sélectionner entre deux broches externes. Remplacé par une simple **diode série** (`DPWR`, 1N4007, anode HLK-5M05 / cathode `VSYS`) qui protège le HLK-5M05 d'un retour si le module PoE est malgré tout installé en parallèle. L'exclusion mutuelle PoE/local devient un choix d'assemblage à documenter dans la notice, pas un circuit électronique.

## Résultats de vérification (après correction)

- **ERC (schéma) :** 0 erreur, 0 avertissement résiduel hors bibliothèque. 248 avertissements bénins « bibliothèque FP introuvable », sans incidence électrique.
- **DRC (PCB) :** 0 erreur réelle. 124 avertissements bénins (même cause bibliothèque) + 16 avertissements cosmétiques (chevauchement de 2 repères silkscreen voisins, à ajuster visuellement en finition, sans incidence électrique ni de fabrication). **153 des 188 connexions routées automatiquement par un autorouteur A* bicouche** (F.Cu/B.Cu avec vias, 2 passes, conscient des classes de net Secteur/Logique — script, voir [12_Guide-de-routage §0](12_Guide-de-routage.md)), 35 éléments non connectés restants à router à la main dans l'éditeur graphique.
- **Correction de sécurité (2026-11-07) :** une vraie règle DRC d'isolement secteur/logique (6 mm, classes de net + fichier `.kicad_dru`) a été ajoutée — elle n'existait nulle part avant, voir [04_Implantation-PCB §3](04_Implantation-PCB.md). Son activation a révélé 234 violations réelles de placement (52 sous le minimum réglementaire IEC 60664-1), corrigées à la racine en changeant l'orientation d'un seul composant (l'optotriac, qui ne doit pas être tourné à 90° comme les autres). Le nombre de connexions auto-routées a baissé (172 → 153) non pas par régression, mais parce que le DRC vérifie désormais une contrainte réelle qu'il ignorait avant — la version précédente à 172 routées était **plus routée mais électriquement non sûre**.

## Ce que ça couvre

- Les 8 zones × 2 voies (POS/NEG), chacune : résistance de base → transistor tampon → résistance LED → MOC3063M → résistance secteur 4,7 kΩ → fusible/PTC → diode → sortie FPx, conforme aux décisions fermées du 2026-11-06.
- Section alimentation : diode anti-retour PoE/local (`DPWR`), HLK-5M05, AMS1117 dédié aux LED d'opto, découplage.
- Connectique : J1 (secteur), J2-J5 (FP1-FP8), en-tête Waveshare 40 broches réel (GND, VSYS, 16×GPIO câblés sur leurs broches physiques réelles ; les 21 autres broches — VBUS/3V3/3V3_EN/RUN/GPIO non retenus/réservés — sont non connectées).
- Implantation : colonne gauche (en-tête Waveshare + alimentation), 8 zones au centre en 4 bandes horizontales de 2 zones chacune, connectique secteur/FP en bord de carte droit.

## Révision du gabarit de carte et boîtier candidat

Le placement réel des 16 voies THT a montré que 105 × 85 mm (gabarit indicatif de la source) ne suffit pas. Une première extension à 105 × 180 mm a été reconsidérée : la hauteur d'un boîtier rail DIN modulaire est fixée par la gamme du fabricant, pas une dimension libre — seule la largeur varie avec le nombre de modules (1 module = 17,5 mm). La carte a d'abord été réorientée en 192 × 108 mm (~11 modules de large).

**Référence étudiée (2026-11-07) :** la gamme **CamdenBoss CNMB** (norme DIN 43880, quasi tous fabricants, disponible chez RS Components), datasheet officiel consulté. Section fixe **90 mm externe / 86,5 mm de PCB utilisable**, longueur qui scale avec le nombre de modules (`CNMB/12` = 212,1 mm, convient à notre longueur de 192 mm avec marge). Avantages concrets pour ce projet : **découpe RJ45 pré-percée disponible en pièce standard** (`CNMB/3/TGRJ45`, compatible tailles 3/6/9/12 — répond au point ouvert d'accès RJ45) et guide-fils/protège-bornes au pas **5,08 mm** (`CNMB/x/TG508`), qui correspond exactement au pas des borniers FP retenus dans la nomenclature.

**Carte recompactée en conséquence :** la carte 192×108 mm dépassait les 86,5 mm utilisables dans le sens de la section. Recompactée à **192 × 86 mm** (pas des bandes de zones resserré, dégagement de bord recalculé en tenant compte du rayon réel des pastilles) pour tenir en carte unique sous ce seuil, plutôt qu'un empilement de 2 PCB (également supporté par ce boîtier : « carries up to 3 PCBs horizontally »). DRC revalidé à 0 erreur réelle après compaction.

**Boîtier retenu, décision finale (2026-11-07) :** base **CNMB/12/2** (accès bornier aux deux extrémités), couvercle **CNMB/12/PC** (transparent, choisi par l'utilisateur). Accessoires : `CNMB/3/TGRJ45` côté Waveshare (découpe RJ45), `CNMB/3/TG508` côté sorties FP (guide-fils 9 pôles 5,08 mm, couvre les 8 pôles de J2-J5). L'entrée secteur J1 est câblée en fixe par presse-étoupe plutôt qu'en bornier débrochable (évite un débranchement accidentel d'un conducteur 230 V) — voir [03_Nomenclature](03_Nomenclature.md).

**Profondeur interne vérifiée (2026-11-07) :** empilement réel depuis le PCB porteur jusqu'au point le plus haut = support femelle 2,54 mm (8,5 mm, hauteur standard du commerce) + épaisseur PCB Waveshare (1,6 mm) + composant le plus haut de la carte Waveshare, la prise RJ45 à magnétiques intégrées référencée `HC-RJ45` sur le schéma réel (≈13,4 mm, valeur typique pour ce type de connecteur) ≈ **23,5 mm au total**. Côté boîtier, 58 mm de profondeur externe moins parois et plots de fixation (≈5 mm) laisse ≈49 mm de dégagement utile. **Marge ≈2× le besoin** : la profondeur n'est pas un facteur limitant, même avec des hauteurs de composants estimées prudemment (pas mesurées sur pièce réelle).

## Orientation des borniers de câblage externe (2026-11-07)

**Ce qui était faux :** `J1` (secteur) et `J2`-`J5` (sorties FP) étaient posés à plat (rotation 0°), axe des 2 broches parallèle au bord de carte — sans rapport avec le sens de sortie réel d'un câble externe, signalé par l'utilisateur.

**Correction :** rotation à 90°, axe des 2 broches perpendiculaire au bord droit de la carte (sortie fil vers l'extérieur, X croissant). Vérifié par inspection directe des coordonnées de pastilles générées (ex. `J1` : les deux broches partagent `x=187.0`, espacées en `y` de ±2,54 mm autour du centre — confirmant l'axe perpendiculaire au bord). `F0` (fusible) et `PS1` (module HLK-5M05) n'ont pas de câblage externe direct (traces PCB uniquement) : orientation inchangée. DRC revalidé à 0 erreur réelle.

**Reste non traité :** le sens exact (quelle broche est « plus proche »/« plus loin » du bord) dépend de la référence réelle du bornier, pas encore choisie ; la position le long du bord (regroupement actuel près du coin) reste à confronter aux presse-étoupes/découpes réelles du boîtier une fois celui-ci commandé.

## Ce qui n'est pas fait

- **Routage des pistes** : un autorouteur A* bicouche (F.Cu/B.Cu, vias autorisés, 2 passes, conscient des classes Secteur/Logique) par script a tracé 153 des 188 connexions (voir [12_Guide-de-routage §0](12_Guide-de-routage.md)). Les 35 restantes (surtout `MT1D_*` et `GPIO*` longue distance) sont bloquées localement par la saturation des 2 couches dans leur zone, maintenant sous la contrainte supplémentaire des 6 mm d'isolement secteur/logique réellement vérifiée. À router à la main dans l'éditeur graphique KiCad (non pilotable depuis cet environnement en ligne de commande).
- **Empreintes définitives des autres composants** : les empreintes hors connecteur Waveshare restent des gabarits génériques auto-cohérents (ex. `FP:DIP6`, `FP:TO92_3`), pas les empreintes réelles des références fabricant choisies. Elles sont correctes électriquement (mêmes numéros de broches que le schéma) mais leurs dimensions/pas exacts restent à confronter aux datasheets avant fabrication.
- **Plans de masse, classes de nets, règles de largeur de piste secteur vs logique** : non définis.
- **Table de bibliothèque locale** (`sym-lib-table`/`fp-lib-table`) : non créée ; à faire pour que KiCad propose nativement les symboles/empreintes en édition graphique (actuellement seulement en cache dans les fichiers, fonctionnel mais pas éditable comme bibliothèque séparée).
