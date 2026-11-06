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
- [Commande directe des optos](09_Commande-directe-opto.md) : comparaison MOC3041M/330 Ω et cible de calcul pour un direct-drive GPIO.
- [Projets similaires](10_Projets-similaires.md) : analyse comparative GitHub, limites de réutilisation et point critique triphasé.

## Légende de statut

- **Source** : information reprise du DOCX, sans validation indépendante.
- **Proposition** : comportement ou organisation retenus comme base de travail, à confirmer.
- **À confirmer** : information absente, ambiguë ou exigeant une vérification par datasheet, mesure ou revue compétente.
- **Bloquant** : ne pas figer le schéma/PCB ni engager une fabrication avant résolution.

## État actuel

Le projet est au stade de reprise du schéma. Une copie de travail EasyEDA `FilPilote_8Zones_DIN_R1_2026-11-06` a été créée dans l'espace utilisateur, à partir de l'export source, et une première feuille PCB `PCB_FilPilote_8Zones_DIN_R1_2026-11-06` a été générée/sauvegardée par conversion. Le PCB est encore un brouillon automatique avec ancien contrôleur et composants à corriger; aucun placement optimisé, routage, DRC ou Gerber n'est validé. Le projet source `FilPilote_8Zones_DIN_2` n'a pas été modifié.