# Projets open source similaires

**Recherche effectuée :** 6 novembre 2026.  
**Portée :** dépôts GitHub trouvés par recherche de `fil-pilote`, `fil pilote ESPHome` et `eedomus fil pilote`. Les descriptions ci-dessous résument les README publics consultés; elles ne constituent pas une revue indépendante de leur sécurité.

## Comparaison

| Projet | Proximité avec notre cible | Éléments réutilisables comme idées | Différences / réserves |
|---|---|---|---|
| [tducret/programmateur-fil-pilote-wifi](https://github.com/tducret/programmateur-fil-pilote-wifi) | Très proche pour l'intégration HTTP et le multi-zone : le README annonce 7 zones et 4 ordres commandés par requêtes HTTP. | Le modèle « requête HTTP depuis une box domotique vers un contrôleur local » correspond à la direction eedomus. Le dépôt contient des dossiers matériel et logiciel ainsi qu'un schéma de principe. | Projet ancien (dernière mise à jour affichée en 2018), limité à 4 ordres et 7 zones selon son README. Licence annoncée : code MIT, autres éléments CC BY-NC-SA 4.0; ne pas reprendre le matériel sans vérifier les conditions de licence et les différences électriques. |
| [Dackara/Fil_Pilote](https://github.com/Dackara/Fil_Pilote) | Très proche pour les 6 ordres et le triphasé. Le README annonce jusqu'à 4 zones par carte et un assemblage de plusieurs cartes. | Prévoit plusieurs entrées de phase; sa documentation est particulièrement pertinente pour analyser l'architecture triphasée et l'organisation des zones. | Son README indique explicitement que le 230 V appliqué au fil pilote doit venir de la même phase que l'alimentation du chauffage piloté. Cela contredit notre choix d'une phase unique pour des radiateurs L1/L2/L3 : point critique à faire confirmer par notices fabricant et électricien, avant gel du schéma secteur. Architecture décrite autour d'ESPHome et d'un expandeur I2C/connexion de cartes, contrairement à notre préférence de GPIO directs. |
| [epsilonrt/gifam-chip](https://github.com/epsilonrt/gifam-chip) | Référence logicielle utile pour le codage des 6 ordres GIFAM et l'usage d'un signal de passage par zéro. | README : codes 0 à 5; Confort -1 °C = signal complet 3 s puis silence 4 min 57 s; Confort -2 °C = signal complet 7 s puis silence 4 min 53 s. Décrit aussi un contrôleur I2C esclave basé sur ATtiny45. | Dépôt ancien (2013-2016 selon son README) et son propre circuit I2C n'est pas nécessairement adapté à notre ESP32. Ces informations sont une implémentation communautaire à corroborer par documentation fabricant/normative avant fabrication. Licence CeCILL v2.1 indiquée par le projet. |
| [zefr0g/maxpilot](https://github.com/zefr0g/maxpilot) | Proche pour le concept carte fil pilote compacte, traversante, alimentation HLK-PM01 et dossier de fabrication complet. | Le dépôt annonce schéma/PCB KiCad, Gerbers, BOM, firmware et boîtier imprimable; son organisation documentaire peut servir de modèle. | ESP8266/Wemos D1 Mini, ESPHome/Home Assistant et 4 ordres dans le README. Il ne couvre pas notre cible ESP32-S3/eedomus à huit zones et n'établit pas à lui seul la compatibilité triphasée. |
| [Plokkke/sauter-marapi-esphome](https://github.com/Plokkke/sauter-marapi-esphome) | Proche pour le traitement des 6 ordres et l'emploi de deux optotriacs plus diodes. | Son README détaille une conception autour d'un appareil précis et décrit une voie de repli Éco par relais. Peut aider à repérer les questions de formes d'onde et de compatibilité appareil. | Dédié au sèche-serviettes Sauter Marapi; le README précise que son électronique complémentaire et son firmware ne sont pas encore fabriqués/testés. Ne pas généraliser sa topologie à toutes les zones/radiateurs. |
| [Floche/domodin](https://github.com/Floche/domodin) | Proche seulement pour le format rail DIN et le fil pilote. | Extension rail DIN basée sur Raspberry Pi; comparaison de packaging et d'intégration mécanique. | Ancien projet Eagle/Raspberry Pi, pas une base pour le contrôleur ESP32-S3/6 ordres/eedomus. |

## Conclusions pour notre conception

1. L'API HTTP locale pour eedomus est une direction crédible : le dépôt tducret démontre ce modèle de contrôle HTTP à plusieurs zones, même si sa capacité documentée est de 7 zones et 4 ordres.
2. Le tableau de six ordres doit inclure les séquences répétitives confort -1/-2. La table de `epsilonrt/gifam-chip` est une bonne base de vérification, pas une preuve normative suffisante.
3. Le sujet triphasé est maintenant le principal point de sécurité ouvert : Dackara prescrit une phase pilote correspondant à la phase d'alimentation du radiateur. Il faut vérifier si cette prescription s'applique aux appareils et au câblage de notre installation avant de conserver une seule `PHASE_PROT`.
4. Aucun des projets examinés n'est une preuve de conformité ni un substitut à la revue du schéma, aux calculs d'isolement/courant et à la validation par une personne qualifiée.
5. Ne pas copier le matériel ou le firmware de ces dépôts sans vérifier les licences fichier par fichier et sans revue technique. En particulier, les éléments matériels du dépôt tducret sont annoncés CC BY-NC-SA 4.0.

## Liens consultés

- https://github.com/tducret/programmateur-fil-pilote-wifi
- https://github.com/Dackara/Fil_Pilote
- https://github.com/epsilonrt/gifam-chip
- https://github.com/zefr0g/maxpilot
- https://github.com/Plokkke/sauter-marapi-esphome
- https://github.com/Floche/domodin
