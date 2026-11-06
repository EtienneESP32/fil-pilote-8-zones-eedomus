# Questions et décisions à confirmer

Les réponses doivent être rattachées à une révision du schéma/PCB et, lorsque pertinent, à une datasheet ou un dessin coté. Les éléments ci-dessous ne sont pas déductibles du DOCX avec assez de certitude.

## Questions pour lancer la conception

| ID | Question / décision restante | Pourquoi c'est nécessaire | État |
|---|---|---|---|
| Q1 | SKU Waveshare ESP32-S3-POE-ETH 28771, sans kit caméra. | Confirmé par l'utilisateur; le module PoE est inclus. | Confirmé |
| Q2 | Fermé : les 4 états statiques POS/NEG couvrent Confort/Éco/Hors-gel/Arrêt; Confort -1°C et -2°C sont des alternances temporisées (voir [`epsilonrt/gifam-chip`](https://github.com/epsilonrt/gifam-chip), table dans [01_Cahier-des-charges](01_Cahier-des-charges.md)). | Référence d'implémentation cohérente avec le principe à 2 voies; pas de modification de schéma requise. | Fermé (2026-11-06) |
| Q3 | Fermé : décision utilisateur assumée pour `PHASE_PROT` unique sur FP1 à FP8, y compris radiateurs L1/L2/L3. | L'utilisateur connaît son installation (neutre et protection différentielle communs) et tranche en connaissance de cause; un projet comparable à phase multiple a été signalé pour mémoire. | Fermé (2026-11-06), décision utilisateur |
| Q4 | Aucun modèle utilisateur à choisir : je vérifierai la spécification GIFAM et une notice fabricant représentative, puis noterai toute limite de compatibilité connue. | Le projet vise la compatibilité GIFAM générique; la revue de l'installation triphasée réelle reste requise. | Action de conception |
| Q5 | Alimentation locale intégrée en plus du PoE; sélectionner une seule source à la fois avec protection anti-retour. | La conception doit éviter de relier directement les deux sorties 5 V. | Confirmé; réalisation à ma charge |
| Q6 | API HTTP eedomus acceptée; choix de l'authentification locale à faire dans la conception firmware. | Définir les commandes/retours et éviter une commande non autorisée sur le réseau. | HTTP confirmé |
| Q7 | Coffret DIN 6 modules et RJ45 accessible depuis l'extérieur. | Il faut choisir un modèle coté compatible avec les modules, borniers et câbles. | Confirmé; référence à choisir |
| Q8 | Fermé (2026-11-07) : RS Components retenu par l'utilisateur comme distributeur principal ; Waveshare ESP32-S3-POE-ETH commandé séparément sur Amazon. | Limiter les commandes séparées. | Fermé ; vérifier à la commande HLK-5M05 et référence boîtier MOC3063M (moins typiques chez RS) |

## Réponses déjà possibles à partir du document source

- **Nombre de zones :** huit.
- **Fichier CAO source disponible :** `SCH_FilPilote_8Zones_DIN_2_2026-11-06.json`; il s'agit d'une version antérieure contenant WT32-S1, MCP23017 et MCP1700. À reprendre, pas à fabriquer telle quelle. Voir [Revue du schéma source](08_Revue-schema-source.md).
- **Contrôleur candidat :** Waveshare ESP32-S3-POE-ETH, SKU 28771, Ethernet/RJ45, Wi-Fi et Bluetooth; W5500 Ethernet sur SPI selon la documentation fabricant.
- **Expandeur :** besoin de 16 sorties logiques au total. Affectation directe en 16 GPIO fermée (2026-11-06) après vérification du wiki fabricant SKU 28771 (GPIO33-37 internes/PSRAM évités, voir [architecture](02_Architecture-et-interfaces.md)); MCP23017/I2C retiré de l'architecture.
- **Alimentation 3,3 V :** pas de régulateur distinct souhaité; le rail 3,3 V demeure et pourrait provenir du régulateur embarqué, sous réserve de capacité.
- **Connectique annoncée :** J1 deux pôles pour L/N; J2 à J5 deux pôles chacun pour FP1 à FP8.
- **Boîtier demandé :** rail DIN six modules; marque sans préférence, référence à sélectionner sur la base de l'ajustement mécanique.
- **Assemblage annoncé :** THT pour les composants de la carte; le module Waveshare complet avec CMS est accepté.
- **Fil pilote :** cible GIFAM six ordres; la table de codage électrique/temporel est à établir à partir d'une source technique fiable.
- **Interface domotique :** eedomus; pas besoin de Home Assistant; firmware demandé.
- **Comportement réseau :** conserver la dernière consigne reçue.
- **Alimentation :** PoE et alimentation secteur locale intégrée au PCB sont toutes deux requises comme options; empêcher tout retour entre sources.
- **Installation :** France, 230 V / 50 Hz, tableau triphasé; radiateurs répartis sur trois phases. Phase unique `PHASE_PROT` et protection commune : fermé, décision utilisateur assumée.
- **Mécanique :** DIN 6 modules; RJ45 accessible de l'extérieur.
- **Connectique :** huit sorties FP indépendantes, deux sorties par bornier double; confirmé par l'utilisateur.
- **Approvisionnement :** RS Components retenu comme distributeur principal (composants, borniers, coffret) ; Waveshare ESP32-S3-POE-ETH sur Amazon. Voir [03_Nomenclature](03_Nomenclature.md).
- **Incohérence certaine dans le tableau source :** GPB5/Z7_NEG est libellé Zone 6 dans la colonne de description; il doit être Zone 7 si le nom du net et l'ordre des canaux sont conservés.

## Décisions de sécurité non déductibles

- **Fermé (2026-11-06) :** distance d'isolement 6 mm (dépasse le minimum IEC 60664-1 à 250 V), résistance côté secteur (4,7 kΩ + fusible/PTC ~100 mA par voie), fusible d'entrée secteur (250 mA temporisé 250 V). Détail et calcul dans [03_Nomenclature](03_Nomenclature.md).
- **Fermé (2026-11-06) :** MOC3063M + 200 Ω retenus côté LED, pilotés par un étage tampon transistor (et non plus en direct-drive GPIO) — voir [02_Architecture §3](02_Architecture-et-interfaces.md) et [09_Commande-directe-opto](09_Commande-directe-opto.md). Les largeurs de piste secteur et la conformité d'ensemble restent à vérifier une fois le placement PCB réalisé.