# Cahier des charges initial

**Statut :** version de travail issue du DOCX, non validée pour fabrication.

## 1. But

Définir une carte contrôleur pour huit zones de chauffage par fil pilote, commandée localement par Ethernet/eedomus et destinée à être intégrée dans un coffret rail DIN. Le candidat retenu pour l'étude est le Waveshare ESP32-S3-POE-ETH, SKU 28771, sans kit caméra. Home Assistant n'est pas requis. Il utilise un W5500 Ethernet sur SPI; la disponibilité des GPIO reste à vérifier sur le pinout.

## 2. Périmètre envisagé

- Huit sorties fil pilote indépendantes, une par zone.
- Six ordres fil pilote GIFAM par zone; la table de codage électrique et temporel reste à concevoir et valider.
- Ethernet filaire via RJ45; il faut 16 signaux de commande (2 optocoupleurs × 8 zones). L'ESP32-S3 pilotera directement les 16 drivers si 16 GPIO compatibles sont confirmés; sinon, conserver un expandeur d'E/S.
- La carte doit pouvoir être alimentée soit par PoE, soit par une alimentation secteur isolée montée sur le PCB. **Point fermé (2026-11-07) :** le schéma fabricant réel montre qu'il n'existe pas de broche « sortie PoE » externe à sélectionner (voir [02_Architecture §1](02_Architecture-et-interfaces.md)) ; l'exclusion mutuelle est un choix d'assemblage documenté, protégé par une simple diode série plutôt qu'un sélecteur.
- Pas de régulateur 3,3 V séparé souhaité : utiliser le 3,3 V généré sur la carte contrôleur si sa sortie est documentée et suffisante pour les charges logiques. Le rail logique 3,3 V reste nécessaire; cette option est à vérifier pour la variante retenue.
- Montage traversant demandé pour les composants de la carte; le module Waveshare complet est accepté même s'il comporte des composants CMS.
- Borniers secteur et sorties fil pilote en bord de carte.
- Intégration domotique eedomus; en cas de perte réseau, conserver la dernière consigne reçue.
- Installation prévue en France, réseau 230 V / 50 Hz triphasé; les radiateurs sont répartis sur L1/L2/L3 et l'utilisateur indique un neutre commun, à confirmer au niveau des protections et du câblage réel.
- Décision utilisateur : conserver une seule phase de commande `PHASE_PROT` pour les huit sorties fil pilote, y compris lorsque les radiateurs sont alimentés par d'autres phases. Cette décision fixe l'architecture souhaitée; elle ne remplace pas la vérification des entrées radiateur, du neutre et des différentiels avant mise en service.
- Le RJ45 doit être accessible depuis l'extérieur du coffret DIN 6 modules.

## 3. Exigences reprises de la source

| ID | Exigence source | Statut / commentaire |
|---|---|---|
| SYS-01 | Huit zones de fil pilote | Source; interface radiateur à documenter. |
| SYS-02 | Waveshare ESP32-S3-POE-ETH, SKU 28771, avec PoE, RJ45, Wi-Fi et Bluetooth | Candidat retenu pour l'étude; vérifier la variante effectivement commandée et les ressources GPIO du pinout. |
| SYS-03 | 16 signaux logiques au total pour commander les 16 entrées d'opto | Une affectation provisoire de 16 GPIO directs est proposée dans l'architecture; la vérifier au schéma fabricant avant retrait définitif du MCP23017. |
| SYS-04 | Aucun bus I2C requis dans l'architecture préférée | À reconsidérer seulement si le pinout ou l'architecture impose un expandeur. |
| SYS-05 | Huit sorties FP indépendantes sur quatre borniers deux positions | Confirmé par l'utilisateur; référence et encombrement du bornier à choisir. |
| SYS-06 | Alimentation PoE ou alimentation secteur locale intégrée au PCB | Les deux modes sont requis; prévoir sélection ou power-path anti-retour. Dimensionnement et protections à valider. |
| SYS-07 | Enveloppe rail DIN six modules, largeur annoncée 105 mm | Source; ce n'est pas le dessin coté du volume utile. |
| SYS-08 | Composants de la carte en THT; carte contrôleur complète acceptée même si elle contient des CMS | Confirmé par l'utilisateur; empreinte/support du Waveshare à vérifier. |
| SYS-09 | Firmware personnalisé avec intégration eedomus, sans dépendance Home Assistant | Interface réseau locale à définir; proposition HTTP/REST à valider avec le mode d'intégration eedomus retenu. |

## 4. États fonctionnels proposés

Le projet public [`epsilonrt/gifam-chip`](https://github.com/epsilonrt/gifam-chip) documente les six ordres et leur cadence. C'est une référence d'implémentation utile, mais non une publication normative GIFAM; le codage doit encore être confronté à une source fabricant/normative avant fabrication.

| Code | Ordre | Signal de travail |
|---:|---|---|
| 0 | Confort | Pas de signal fil pilote |
| 1 | Arrêt forcé | Alternance positive |
| 2 | Hors-gel | Alternance négative |
| 3 | Éco | Signal complet, alternances positive et négative |
| 4 | Confort -1 °C | Signal complet pendant 3 s, puis absence de signal pendant 4 min 57 s; cycle de 5 min |
| 5 | Confort -2 °C | Signal complet pendant 7 s, puis absence de signal pendant 4 min 53 s; cycle de 5 min |

Les codes et temporisations ci-dessus sont rapportés par l'implémentation `epsilonrt/gifam-chip`; ils sont à vérifier auprès d'une source fabricant/normative. Pour les deux ordres temporisés, le firmware peut commander les deux voies opto ensemble durant la fenêtre active puis les couper pendant le reste du cycle.

## 5. Exigences de sécurité et de conception

- La partie primaire 230 V et la logique basse tension doivent être traitées comme des domaines séparés.
- Le produit sera raccordé à une installation triphasée 230/400 V; toutes les sorties fil pilote, leur référence neutre, les phases de puissance des radiateurs et leurs protections différentielles doivent être analysées ensemble.
- **Point fermé (2026-11-06) :** la phase de commande unique `PHASE_PROT` est retenue pour les huit sorties, y compris pour des radiateurs répartis sur L1/L2/L3. Décision assumée par l'utilisateur, qui connaît son installation (neutre et protection différentielle communs). Un projet comparable décrit une architecture à phase multiple ; ce point a été signalé et tranché, il n'est plus traité comme bloquant.
- Les distances d'isolement, les protections, les pistes, les connecteurs, le boîtier et le montage doivent être déterminés selon les exigences applicables et le contexte d'utilisation, puis revus par une personne compétente.
- **Point fermé :** les 6 mm de la source dépassent le minimum IEC 60664-1 (~2 mm en isolation renforcée à 250 V, pollution degré 2) et sont conservés comme règle de conception.
- **Point fermé :** la résistance 360 Ω côté secteur est remplacée par 4,7 kΩ + un fusible/PTC ~100 mA par voie (calcul dans [la nomenclature](03_Nomenclature.md)). La résistance 330 Ω côté LED est remplacée par 200 Ω avec MOC3063M, piloté via un étage tampon transistor (voir [02_Architecture §3](02_Architecture-et-interfaces.md)).
- Le comportement au démarrage et en défaut doit éviter toute commande involontaire des zones.
- Le prototype doit être contrôlé avant tout raccordement secteur; les essais sous tension dangereuse relèvent d'un environnement et d'une personne qualifiés.

## 6. Critères d'acceptation à compléter

- Dimensions, fixations et accès connecteurs compatibles avec le boîtier sélectionné.
- Correspondance confirmée entre firmware, GPIO/voies de puissance et borniers FP1 à FP8.
- Les six ordres GIFAM sont générés et vérifiés conformément à la spécification applicable.
- Budget d'alimentation établi pour le pire cas documenté.
- Revue de schéma, vérifications CAO et contrôles de fabrication consignés.
- Essais fonctionnels et de sécurité passés selon le plan de validation, avant mise en service.