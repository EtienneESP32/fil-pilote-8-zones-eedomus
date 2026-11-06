# Revue du cahier des charges

Document analyse : `contour du projet.docx`

## Avis général

L'architecture proposée est compréhensible : un WT32-ETH01 assure la liaison Ethernet, un MCP23017 fournit les commandes logiques et deux voies optotriac/diode produisent les deux polarités du fil pilote pour chacune des huit zones. Le document constitue toutefois une intention de conception, pas encore un dossier suffisant pour fabriquer ou faire vérifier une carte secteur.

Je peux accompagner la conception du schéma et du PCB, optimiser l'implantation et préparer les fichiers de fabrication. En revanche, je ne peux pas déclarer sûre ou conforme une carte 230 V sur la seule base de ce texte. Il faut d'abord confirmer le schéma par les datasheets et les exigences d'installation applicables, puis faire vérifier le prototype par une personne qualifiée avant raccordement au secteur.

## Commentaires par section

### 1. Objectif et contraintes mécaniques

- « 6 modules / 105 mm » donne la largeur nominale du boîtier rail DIN, pas son volume intérieur utile. Il faut la référence exacte du boîtier et son dessin coté : longueur, hauteur disponible, fixations, entrées de câbles, accès au RJ45 et distances aux parois.
- La dimension indicative de PCB de 105 × 85 mm n'est pas validée par le boîtier. La carte et ses connecteurs doivent rester dans l'enveloppe réelle, avec place pour le câblage et les rayons de courbure.
- « 100 % THT » doit être clarifié pour le module WT32-ETH01 : fournir la référence/révision exacte et son dessin mécanique. Vérifier l'entraxe, la rangée de broches, l'orientation du RJ45, son dépassement du boîtier et les dégagements autour de l'antenne si elle est utilisée.
- Le pas des borniers ne suffit pas à choisir leur empreinte : il faut le modèle, le nombre de pôles, le courant/tension assignés, le diamètre de fil accepté et l'encombrement réel.

### 2. Contrôle et I2C

- Les broches annoncées IO33/IO32 et leur disponibilité doivent être vérifiées sur le schéma/pinout de la révision précise du WT32-ETH01. Ne pas se fier à un brochage d'une autre carte ESP32.
- Les résistances I2C de 4,7 kΩ sont proposées sans vérifier les pull-ups déjà présentes sur le module ou une autre carte. Il faut confirmer qu'il n'y a pas de pull-ups en parallèle trop fortes et vérifier les niveaux logiques à 3,3 V.
- Prévoir le découplage local du MCP23017 (condensateur près de VDD/VSS), l'état de RESET au démarrage et un comportement matériel sûr des sorties pendant le reset, le démarrage de l'ESP32 et une perte d'alimentation.
- Les 16 sorties sont entièrement affectées. Ajouter au schéma les noms des ports, l'ordre des broches et les états de démarrage attendus pour éviter une permutation au routage ou dans le firmware.

### 3. Alimentation et commandes des optotriacs

- Le calcul de la résistance de LED doit être repris. Avec 3,3 V, une LED d'opto d'environ 1,2 V et 330 Ω, le courant nominal n'est que d'environ 6 mA : `(3,3 - 1,2) / 330`. Il faut comparer ce courant au courant de déclenchement maximal garanti de la variante exacte du MOC3041 et vérifier aussi la capacité de sortie du MCP23017. En l'état, le déclenchement n'est pas démontré.
- Ne pas corriger cette valeur au jugé : choisir le composant ou l'étage de commande après vérification des datasheets, des tolérances, de la température et du courant disponible sur le rail 3,3 V.
- Le budget 5 V/3,3 V doit inclure la WT32-ETH01, le MCP23017 et le cas où les 16 commandes sont actives. Vérifier les limites du régulateur embarqué et la dissipation, pas seulement le courant nominal annoncé par le HLK-PM01.
- Ajouter les condensateurs de découplage et préciser les protections d'entrée/sortie, le fusible et sa référence complète (courant, courbe, pouvoir de coupure, tension, porte-fusible). « Fusible 250 V préconisé » ne définit pas une protection dimensionnée.

### 4. Étage fil pilote et secteur

- Le texte ne donne pas encore un schéma électrique complet du canal : il faut figer et vérifier chaque broche des MOC3041, le sens des deux diodes, le chemin du courant, le raccordement des sorties et le comportement en circuit ouvert et en défaut.
- La résistance série 360 Ω est un point bloquant à justifier par calcul et par la spécification de l'entrée fil pilote des radiateurs. Sa puissance nominale ne peut pas être validée en l'absence du courant maximal, du cas de défaut et des conditions thermiques. Ne pas fabriquer ni raccorder cette valeur au secteur avant validation.
- Les MOC3041 sont des optotriacs à passage par zéro. Confirmer que cette variante et la topologie avec diodes donnent bien les formes d'onde et niveaux attendus pour chacun des ordres, selon la documentation des radiateurs visés.
- La séparation « ≥ 6 mm » n'est pas une règle universelle suffisante. Les distances d'isolement et de fuite dépendent notamment des tensions, catégories, pollution, matériau du PCB et conditions d'assemblage. Il faut définir ces paramètres et vérifier les exigences applicables. Prévoir des zones d'exclusion cuivre, des espacements physiques adaptés et, si nécessaire, des rainures d'isolement.
- Le secteur doit être traité comme une zone dangereuse : borniers protégés contre le contact, largeur de pistes calculée, séparation primaire/secondaire du convertisseur respectée, maintien mécanique et thermique des composants, et aucune partie accessible sous tension dans le boîtier final.
- Le HLK-PM01 est un module d'alimentation secteur, pas une validation automatique de la carte assemblée. Suivre sa datasheet et ses limites d'implantation/isolation.

### 5. Borniers et zones

- Une erreur certaine apparaît dans la table : `GPB5` / broche 6 est nommé `Z7_NEG`, mais la colonne « Zone associée » indique « Zone 6 (Hors-Gel) ». À corriger en Zone 7.
- Vérifier le nombre de pôles : quatre borniers de deux pôles offrent huit positions, une par sortie FP. Le second pôle de chaque bornier n'est pas défini dans le texte ; confirmer qu'il s'agit bien d'une sortie indépendante et non d'un retour commun.
- Le neutre des radiateurs est annoncé raccordé directement au tableau. Le câblage externe doit donc être clairement documenté pour éviter toute confusion entre neutre, phase et sorties FP.

### 6. Firmware et modes de fonctionnement

- La table d'états doit être exprimée explicitement pour chaque zone : Confort = deux voies arrêtées, Arrêt = voie positive seule, Hors-gel = voie négative seule, Éco = deux voies actives (à confirmer par la norme/protocole fil pilote retenu et les appareils utilisés).
- Définir les transitions et le comportement en cas de redémarrage, blocage du bus I2C, perte Ethernet ou commande inconnue. Le matériel ne doit pas produire un ordre indésirable pendant l'initialisation.
- Prévoir un test de continuité et d'isolement, puis une validation fonctionnelle à basse tension isolée avant tout essai secteur contrôlé.

## Corrections et informations requises avant le PCB

1. Corriger l'entrée de table GPB5/Z7_NEG.
2. Fournir le schéma actuel (EasyEDA ou PDF) et la référence exacte des radiateurs ou la spécification électrique de leurs entrées fil pilote.
3. Fournir les datasheets des composants choisis, en particulier WT32-ETH01, MOC3041 exact, MCP23017, HLK-PM01, diodes, fusible et borniers.
4. Fixer la référence du boîtier DIN, son volume intérieur et les dimensions/positions accessibles des connecteurs.
5. Valider le courant LED des optos, les résistances côté secteur, le budget d'alimentation, les protections et les distances d'isolement avec une revue électrique compétente.
6. Définir les contraintes de fabrication : fabricant PCB, épaisseur cuivre, nombre de couches, dimensions maximales, règle minimale de piste/espace, et stratégie d'assemblage/test.

## Proposition de méthode PCB

Une fois ces points levés, l'implantation peut être optimisée en séparant physiquement la zone secteur, les huit cellules répétitives et la logique basse tension ; en plaçant les borniers au bord de carte pour un câblage direct ; en groupant les composants de chaque zone au plus près de sa sortie ; et en gardant le WT32-ETH01/RJ45 accessible sans empiéter sur l'isolation. Les règles de clearance, creepage, cuivre et routage secteur seront définies à partir des exigences applicables, puis contrôlées dans l'outil de CAO avant export des fichiers de fabrication.

**Conclusion :** oui, je peux aider à réaliser le schéma et l'implantation, puis les fichiers PCB. Avec les seuls éléments actuels, l'étape responsable est cette revue et la levée des points bloquants, pas la production d'un layout secteur présenté comme prêt à fabriquer.

## Addendum - décisions utilisateur du 2026-11-06

Le fichier CAO de travail est `SCH_FilPilote_8Zones_DIN_2_2026-11-06.json`; le PDF exporté est antérieur et n'est pas le document maître. Le JSON contient encore WT32-S1, MCP23017, MCP1700 et un réseau PHASE_PROT; il doit être repris, pas fabriqué tel quel. La carte retenue pour l'étude est Waveshare ESP32-S3-POE-ETH, SKU 28771, sans caméra. Le PCB devra aussi comporter une alimentation secteur isolée locale, en plus de l'option PoE, avec sélection empêchant tout retour entre les deux sources. Le RJ45 devra être accessible depuis l'extérieur du coffret DIN 6 modules. L'intégration visée est eedomus par HTTP, sans Home Assistant, et le comportement demandé en perte réseau est de conserver la dernière consigne.

La cible est le fil pilote GIFAM à six ordres. La table électrique et temporelle des six ordres doit être vérifiée : deux sorties POS/NEG ne représentent que quatre combinaisons statiques. Le MCP23017 et l'I2C peuvent être supprimés si le pinout de la carte retenue offre 16 GPIO compatibles; sinon, un expandeur reste une solution de repli.

Il est possible de supprimer le régulateur 3,3 V séparé si la carte Waveshare fournit une sortie 3,3 V avec une capacité disponible suffisante. Le rail 3,3 V demeure nécessaire pour la logique; ne jamais appliquer le 5 V sur la broche 3V3 ou les GPIO.

L'installation cible est en France, 230 V / 50 Hz triphasé, avec les radiateurs répartis sur L1/L2/L3. Les ordres fil pilote sont normalement des tensions entre FP et neutre; un signal L1-N peut donc être fonctionnellement détecté par une entrée conçue pour cette référence, même si le radiateur est alimenté par L2 ou L3. Cela ne suffit toutefois pas à prouver la sécurité de l'installation : les phases sont à 400 V entre elles, et la compatibilité des entrées radiateur, des neutres et des protections différentielles doit être confirmée. Ne pas diffuser PHASE_PROT vers les huit sorties avant cette revue.

## Addendum 2 - clôtures techniques du 2026-11-06

Quatre points laissés ouverts dans la revue initiale ont été traités et fermés :

1. **Six ordres GIFAM.** Confirmé : les deux voies POS/NEG donnent 4 états statiques (Confort, Éco, Hors-gel, Arrêt) ; Confort -1 °C et Confort -2 °C sont des alternances temporisées entre ces états, pilotées par le firmware (référence d'implémentation [`epsilonrt/gifam-chip`](https://github.com/epsilonrt/gifam-chip)). Aucune modification du circuit de puissance n'est nécessaire. Voir [01_Cahier-des-charges §4](docs/01_Cahier-des-charges.md).
2. **`PHASE_PROT` unique sur L1/L2/L3.** Fermé comme décision utilisateur assumée. Un projet comparable à phase multiple avait été signalé ; l'utilisateur a tranché en connaissance de son installation (neutre et protection différentielle communs). Voir [02_Architecture §5](docs/02_Architecture-et-interfaces.md).
3. **Pinout Waveshare ESP32-S3-POE-ETH (SKU 28771).** Vérifié contre le wiki fabricant : GPIO33-37 sont internes (PSRAM octale) et inutilisables — l'affectation initiale les utilisait pour les zones 4/5, corrigée vers GPIO4/5. Les 16 GPIO retenus évitent aussi le SPI du W5500 (9-14), l'UART0 (43-44), le strapping (0/3/45/46) et l'USB natif (19/20). Voir [02_Architecture §2](docs/02_Architecture-et-interfaces.md).
4. **Résistance côté secteur, fusible, isolement.** La valeur source de 360 Ω laissait passer environ 640 mA en défaut franc (court-circuit FP/neutre), au-delà des caractéristiques publiées du MOC3041M (courant caractérisé à 100 mA, surtension 1 A/100 µs seulement). Remplacée par 4,7 kΩ (défaut ramené à ~49 mA) plus un fusible/PTC ~100 mA par voie en complément du fusible d'entrée secteur (250 mA temporisé, 250 V). Les 6 mm d'isolement de la source dépassent le minimum IEC 60664-1 (~2 mm en isolation renforcée à 250 V) et sont conservés. Détail du calcul dans [03_Nomenclature](docs/03_Nomenclature.md).

**Reste ouvert, non traité par cet addendum :** la résistance 330 Ω côté LED d'opto et le choix MOC3041M/MOC3063M (courant de déclenchement garanti au pire cas des 16 voies), voir [09_Commande-directe-opto](docs/09_Commande-directe-opto.md). Le schéma EasyEDA lui-même (JSON/projet de reprise) n'a pas encore été modifié pour refléter ces quatre clôtures ; elles sont actées dans la documentation, à répercuter sur le schéma avant routage.

## Addendum 3 - projet KiCad natif et correction d'empreinte du 2026-11-07

Un projet KiCad natif a été créé (`hardware/kicad/`, voir [11_État du projet KiCad](docs/11_Etat-KiCad.md)) : schéma complet des 8 zones intégrant les clôtures de l'addendum 2, vérifié ERC (0 erreur), et PCB placé selon la séparation secteur/logique, vérifié DRC (0 erreur réelle). Routage non fait.

**Erreur signalée par l'utilisateur et corrigée :** la première implantation du connecteur Waveshare était un simple connecteur générique 1 rangée / 19 broches, sans rapport avec le vrai connecteur. Vérification faite contre le pinout physique réel de la carte Waveshare ESP32-S3-ETH (format Raspberry Pi Pico : 72,8 × 21 mm, 40 broches sur 2 rangées de 20, pas 2,54 mm, rangées espacées de 17,78 mm) : l'empreinte a été refaite à l'identique de la géométrie réelle, et le pinout physique exact a révélé deux erreurs supplémentaires qui seraient passées inaperçues sans cette vérification :
- GPIO4 et GPIO5 (utilisés pour les zones 4/5 depuis la clôture précédente) ne sortent en réalité que sur le connecteur carte TF, absent de l'en-tête principal câblable — remplacés par GPIO45 et GPIO3.
- GPIO21 (zone 4) est partagé avec la LED WS2812 embarquée de la carte — conservé, effet cosmétique accepté (la LED suit l'état de la zone 4).

Voir [02_Architecture §1-2](docs/02_Architecture-et-interfaces.md) pour le détail complet, y compris le point nouvellement ouvert sur l'existence réelle d'une broche « sortie PoE » exploitable (non confirmée sur l'en-tête principal).

**Gabarit de carte revu :** le placement réel des composants a montré que 105 × 85 mm ne suffit pas pour 16 voies THT avec dégagement correct. Après une première extension à 105 × 180 mm, le gabarit a été réorienté en ~11 modules DIN (192 × 108 mm) pour rester dans un format de boîtier modulaire du commerce (la hauteur d'un boîtier DIN est fixée par la gamme du fabricant, pas par le nombre de modules — point mal posé dans une réponse précédente, corrigé après question de l'utilisateur).