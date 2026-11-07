# Documentation du contrôleur fil pilote

## Objet

Dossier documentaire de travail pour une carte de commande fil pilote à huit zones, avec le Waveshare ESP32-S3-POE-ETH (SKU 28771) comme candidat retenu. La documentation fabricant indique que le kit POE inclut le module PoE et que l'Ethernet est fourni par un W5500 sur SPI. Le schéma de référence fourni est `../Schematic_FilPilote_8Zones_DIN_2_2026-11-06.pdf`; le cahier initial est `../contour du projet.docx`, revu dans `../Analyse et commentaires.md`.

Cette documentation décrit l'intention et les décisions connues. Elle ne constitue ni un schéma électrique validé, ni un dossier de conformité, ni une autorisation de raccordement au secteur. Les valeurs de composants et les règles d'isolement restent à valider avant conception finale.

## Documents

- [Cahier des charges](01_Cahier-des-charges.md) : périmètre, exigences et critères de réussite.
- [Architecture et interfaces](02_Architecture-et-interfaces.md) : blocs fonctionnels, sorties candidates directes ESP32-S3 et ordres GIFAM.
- [Nomenclature prévisionnelle](03_Nomenclature.md) : quantités dérivées du concept et informations d'achat manquantes.
- [Note d'implantation PCB](04_Implantation-PCB.md) : contraintes de placement et données nécessaires à la CAO.
- [Firmware et exploitation](05_Firmware-et-exploitation.md) : comportement attendu, démarrage et gestion des défauts.
- [Plan de validation](06_Plan-de-validation.md) : contrôles documentaires, électriques, mécaniques et firmware.
- [Questions et décisions ouvertes](07_Questions-a-confirmer.md) : informations à fournir et registre de décision.
- [Revue du schéma source](08_Revue-schema-source.md) : composants repérés dans l'export EasyEDA et limites de l'inspection actuelle.
- [Commande directe des optos](09_Commande-directe-opto.md) : calcul ayant conduit au choix MOC3063M/200 Ω, piloté via un étage tampon transistor (direct-drive GPIO abandonné).
- [Projets similaires](10_Projets-similaires.md) : comparaison avec des dépôts GitHub proches (eedomus/HTTP, six ordres, triphasé, packaging DIN).
- [État du projet KiCad natif](11_Etat-KiCad.md) : schéma ERC-clean et PCB placé/DRC-clean dans `hardware/kicad/`, référence actuelle pour la topologie électrique.
- [Guide de routage PCB](12_Guide-de-routage.md) : procédure et règles à suivre dans l'éditeur graphique KiCad (classes de net, ordre de routage, clearance secteur/logique).

## Légende de statut

- **Source** : information reprise du DOCX, sans validation indépendante.
- **Proposition** : comportement ou organisation retenus comme base de travail, à confirmer.
- **À confirmer** : information absente, ambiguë ou exigeant une vérification par datasheet, mesure ou revue compétente.
- **Bloquant** : ne pas figer le schéma/PCB ni engager une fabrication avant résolution.

## État actuel

**Projet KiCad natif (référence actuelle, 2026-11-07) :** `hardware/kicad/FilPilote_8Zones.kicad_pro`. Schéma complet et vérifié ERC (0 erreur) intégrant toutes les décisions fermées (GPIO corrigés, étage tampon transistor, 4,7 kΩ + fusibles secteur, HLK-5M05, MOC3063M). PCB placé selon les principes de séparation secteur/logique et vérifié DRC (0 erreur réelle), mais **non routé** — le routage des pistes reste à faire dans l'éditeur graphique KiCad. Voir [11_État du projet KiCad](11_Etat-KiCad.md).

**Copie EasyEDA R1 (antérieure, dépassée pour la topologie) :** `FilPilote_8Zones_DIN_R1_2026-11-06`, créée à partir de l'export source par conversion. Contient encore l'ancien contrôleur WT32-S1/MCP23017/MCP1700 et les valeurs non corrigées (360 Ω, direct-drive GPIO) ; voir [08_Revue du schéma source](08_Revue-schema-source.md). À reprendre depuis le projet KiCad si cette filière EasyEDA est poursuivie, ou abandonner au profit du projet KiCad natif. Le projet source `FilPilote_8Zones_DIN_2` n'a pas été modifié.