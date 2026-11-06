# Revue de l'export EasyEDA source

**Fichier examiné :** `../SCH_FilPilote_8Zones_DIN_2_2026-11-06.json`  
**Statut :** inventaire initial des symboles; pas une revue électrique exhaustive ni une libération de fabrication.

## 1. Constats sur le fichier

- Export EasyEDA JSON de 147 957 octets, avec une feuille de schéma.
- Le schéma est en retard sur les décisions actuelles : son symbole contrôleur est `WT32-S1`, pas le Waveshare ESP32-S3-POE-ETH SKU 28771.
- Il contient un MCP23017-E/SP, alors que la direction retenue est d'utiliser les GPIO de l'ESP32-S3 si le pinout le permet.
- Il contient un régulateur MCP1700-3302E en TO-92, alors que la préférence actuelle est d'utiliser le 3,3 V régulé de la carte Waveshare si le courant disponible suffit.
- L'inventaire des symboles inclut un HLK-PM01, 16 MOC3041M, 16 diodes 1N4007, cinq borniers deux positions (un secteur et quatre sorties), ainsi que C1/C2 et des résistances axiales.
- Les labels `PHASE_PROT`, `FP1` à `FP8`, `Z1_POS/NEG` à `Z8_POS/NEG`, `SDA`, `SCL`, `3V3` sont présents dans l'export.

Ces informations proviennent des attributs des symboles et chaînes de labels. Elles ne prouvent pas à elles seules que chaque net est connecté au bon composant ou que le routage proposé soit correct.

## 2. Écarts à traiter dans la nouvelle révision

1. Remplacer le symbole WT32-S1 par le connecteur/empreinte de montage correspondant à la carte Waveshare choisie et rendre le RJ45 accessible depuis l'extérieur du coffret.
2. **Fermé (2026-11-06) :** l'affectation provisoire utilisait GPIO33 et GPIO34, internes à la PSRAM octale de l'ESP32-S3R8 d'après le wiki fabricant — remplacés par GPIO4/GPIO5 dans [l'architecture](02_Architecture-et-interfaces.md). Les 16 GPIO retenus évitent le SPI W5500 (9-14), l'UART0 (43-44), le strapping (0/3/45/46) et l'USB natif (19/20). MCP23017/I2C supprimé.
3. Supprimer le MCP1700 seulement après validation du rail 3,3 V et de sa capacité disponible; le rail 3,3 V demeure nécessaire.
4. Conserver une alimentation secteur locale isolée pour le mode sans PoE, en plus de la possibilité PoE. Ajouter une sélection ou un power-path avec anti-retour afin de ne pas relier directement les deux sorties 5 V.
5. Vérifier si le HLK-PM01 fournit assez de puissance pour la carte, les LED d'opto (jusqu'à 16 actives) et le pire cas de commandes; choisir le module d'alimentation après bilan de puissance.
6. Vérifier la commande directe des optos : le MOC3041M du JSON peut exiger jusqu'à 15 mA garantis, alors que 330 Ω sous 3,3 V fournit environ 6 mA nominalement. Comparer un optotriac zero-cross à IFT plus faible et tension répétitive appropriée; calculer les 16 courants au pire cas. N'ajouter les drivers qu'en cas de dépassement des limites GPIO/budget global.
7. **Fermé (2026-11-06) :** les deux voies actuelles suffisent aux six ordres GIFAM; les 2 ordres temporisés sont une alternance firmware entre états statiques existants, pas un circuit nouveau (voir [01_Cahier-des-charges](01_Cahier-des-charges.md)).
8. **Fermé (2026-11-06), décision utilisateur :** phase de commande unique `PHASE_PROT` conservée pour les huit sorties.
9. **Fermé (2026-11-06) :** résistance côté secteur portée de 360 Ω à 4,7 kΩ + fusible/PTC ~100 mA par voie, calcul dans [03_Nomenclature](03_Nomenclature.md); la résistance 330 Ω côté LED reste ouverte (voir [09_Commande-directe-opto](09_Commande-directe-opto.md)).

## 3. Limites de l'inspection

L'aperçu du PDF fourni s'ouvre en page vide dans l'environnement disponible. Le JSON a été lu et ses symboles/labels inventoriés, mais les fils, points de jonction, valeurs complètes et annotations ne sont pas encore audités de bout en bout. Il faut ouvrir le JSON dans EasyEDA (ou exporter un PDF lisible/netlist/BOM) pour poursuivre la revue fonctionnelle.

Le JSON source ne contient pas de layout PCB final prêt à commander. Aucun fichier Gerber, perçage, rapport DRC/ERC, contour coté final ni BOM d'achat approuvée n'a été trouvé.

## 4. Conclusion

Le JSON est la bonne source de départ pour la reprise du schéma, mais ne doit pas servir directement à la fabrication ou à la commande des composants. La nouvelle révision doit d'abord fixer la topologie fil pilote triphasée, la table six ordres, l'alimentation double PoE/secteur, le module Waveshare et le coffret réel. Les composants répétitifs et leurs valeurs pourront ensuite être validés puis reportés aux huit zones.

## 5. Action effectuée dans EasyEDA

- Projet de travail séparé créé : `FilPilote_8Zones_DIN_R1_2026-11-06`.
- Le JSON source a été importé comme feuille de schéma dans ce projet de reprise; le projet d'origine n'a pas été édité.
- EasyEDA a généré la feuille `PCB_FilPilote_8Zones_DIN_R1_2026-11-06` par conversion du schéma et a confirmé sa sauvegarde.
- Cette conversion est un brouillon automatique de connectivité/empreintes, non une implantation optimisée. Elle contient encore les empreintes des éléments obsolètes (WT32-S1, MCP23017, MCP1700) et des valeurs source non validées.
- Le contour mécanique, le placement, le routage, les règles d'isolement et les vérifications DRC restent à réaliser dans cette révision avant tout export de fabrication.