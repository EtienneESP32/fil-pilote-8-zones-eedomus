# Contrôleur fil pilote 8 zones — eedomus / ESP32-S3

Projet de carte rail DIN destinée à piloter huit zones de chauffage par fil pilote, avec intégration locale eedomus par HTTP. La carte contrôleur retenue pour l'étude est le Waveshare ESP32-S3-POE-ETH, SKU 28771, avec option d'alimentation PoE et alimentation secteur isolée locale.

> **Attention — projet en cours de conception.** Le PCB EasyEDA généré par conversion est un brouillon non placé/routé et ne doit pas être commandé ou raccordé au secteur. Le schéma source contient encore l'ancienne architecture WT32-S1/MCP23017. Les distances d'isolement, les valeurs de composants, la topologie triphasée, le codage des six ordres et les protections ne sont pas validés. Toute réalisation secteur doit être revue par une personne qualifiée.

## État

- Cahier initial, PDF et JSON EasyEDA source archivés dans le dépôt.
- Dossier de documentation technique dans [`docs/`](docs/README.md).
- Copie de travail EasyEDA R1 créée dans le compte EasyEDA de l'utilisateur, distincte du projet source.
- PCB issu de conversion présent dans cette copie R1; placement, contour, routage, DRC et export de fabrication restent à faire.
- Le projet vise 8 sorties fil pilote, 6 ordres, phase `PHASE_PROT` unique retenue par l'utilisateur, Ethernet, eedomus et options PoE/alimentation locale.
- Une recherche de projets similaires met en évidence un conflit à résoudre : un projet triphasé comparable exige une phase pilote correspondant à la phase d'alimentation du radiateur.

## Documentation

- [Index de la documentation](docs/README.md)
- [Cahier des charges](docs/01_Cahier-des-charges.md)
- [Architecture et interfaces](docs/02_Architecture-et-interfaces.md)
- [Nomenclature prévisionnelle](docs/03_Nomenclature.md)
- [Note d'implantation PCB](docs/04_Implantation-PCB.md)
- [Firmware et exploitation](docs/05_Firmware-et-exploitation.md)
- [Plan de validation](docs/06_Plan-de-validation.md)
- [Questions/décisions ouvertes](docs/07_Questions-a-confirmer.md)
- [Revue du schéma source](docs/08_Revue-schema-source.md)
- [Commande directe des optos](docs/09_Commande-directe-opto.md)
- [Projets similaires](docs/10_Projets-similaires.md)

## Contenu source

- `contour du projet.docx` : cahier initial.
- `SCH_FilPilote_8Zones_DIN_2_2026-11-06.json` : export EasyEDA source, ancienne version.
- `Schematic_FilPilote_8Zones_DIN_2_2026-11-06.pdf` : export PDF de cette source, obsolète par rapport aux choix R1.
- `Analyse et commentaires.md` : revue initiale et décisions ultérieures.

## Sauvegarde GitHub

La publication distante n'est pas encore effectuée. Recommandation : créer un dépôt **privé** au départ, vérifier les fichiers inclus et ne le rendre public qu'après revue sécurité/documentation. Voir [`GITHUB_PUBLISHING.md`](GITHUB_PUBLISHING.md).
