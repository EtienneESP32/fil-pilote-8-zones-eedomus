# Nomenclature prévisionnelle

Cette liste est une estimation à partir du concept du DOCX, pas une liste d'achat approuvée. Les références exactes, empreintes et caractéristiques nominales sont à confirmer par datasheets et choix de composants.

| Désignation | Référence proposée dans la source | Qté estimée | Statut / décision requise |
|---|---|---:|---|
| Carte contrôleur Ethernet | Waveshare ESP32-S3-POE-ETH, SKU 28771 | 1 | PoE inclus selon fabricant; confirmer variante commandée, brochage, alimentation autorisée, dimensions |
| Expandeur de sorties | Aucun dans l'architecture préférée | 0 | Retiré (2026-11-06) : 16 GPIO directs confirmés sur le pinout SKU 28771 |
| Convertisseur AC/DC isolé local | **Hi-Link HLK-5M05, 230 VAC → 5 V / 1 A** (remplace le HLK-PM01 600 mA de la source) | 1 | Point fermé (2026-11-06) : requis pour fonctionner sans PoE ; alimente `VSYS`. Bilan ≈620 mA pire cas (carte Waveshare + régulateur `3V3_OPTO`) sur 1 A disponible, marge ~38 % |
| Sélection/anti-retour de puissance | Sélecteur manuel SPDT entre PoE et HLK-5M05 | 1 | Point fermé (2026-11-06) : sélection manuelle, aucun retour possible entre sources, pas de power-path électronique à valider |
| Optotriac zéro-cross | **MOC3063M** (IFT max 5 mA, 600 V) | 16 | Point fermé (2026-11-06) : retenu avec étage tampon transistor, voir ligne « Transistor tampon » et [étude direct-drive](09_Commande-directe-opto.md) |
| Diode de voie | 1N4007, DO-41 | 16 | Rôle : combine les deux alternances POS/NEG sur le nœud FPx (repris du schéma source), orientation à vérifier au schéma |
| Transistor tampon GPIO→LED opto | BC547B ou équivalent NPN, THT TO-92 | 16 | Point fermé (2026-11-06) : remplace le direct-drive GPIO. Base via résistance ~10 kΩ depuis le GPIO (< 1 mA), collecteur vers la LED d'opto alimentée par `3V3_OPTO` |
| Résistance de base transistor | 10 kΩ, 1/8 W | 16 | Limite le courant GPIO à < 1 mA, hFE ≥ 110 donne une marge large pour saturer le transistor |
| Résistance LED opto | **200 Ω, 1 %** | 16 | Point fermé (2026-11-06) : calcul repris avec alimentation dédiée `3V3_OPTO` (chute transistor au lieu de VOH GPIO) ; marge IFT ≈30 %, voir [étude direct-drive](09_Commande-directe-opto.md) |
| Régulateur 3,3 V dédié LED opto | AMS1117-3,3, THT TO-220, 1 A | 1 | Point fermé (2026-11-06) : alimente `3V3_OPTO` depuis `VSYS` (5 V), dimensionné pour ~210 mA pire cas (16 voies) + marge ; découplé du 3,3 V de la carte Waveshare |
| Résistance côté secteur | **4,7 kΩ, 1/4 W** (remplace les 360 Ω de la source) | 16 | Point fermé (2026-11-06) : voir calcul plus bas. Fonction = limitation du courant de défaut, pas réglage du signal utile |
| Fusible/PTC par voie FP | Fusible rapide ou PTC ~100 mA, 250 V, 1 par voie | 16 | Point fermé (2026-11-06) : défense en profondeur en série avec chaque résistance 4,7 kΩ/opto, voir calcul plus bas |
| Réseau I2C / RESET expandeur | Non prévu | 0 | Retiré avec l'expandeur |
| Découplage logique | Céramique 100 nF par circuit intégré + électrolytique sur `VSYS`/`3V3_OPTO` | À déterminer au placement | La carte contrôleur possède son propre découplage ; ajouter le découplage local des régulateurs ajoutés |
| Entrée secteur J1 | Presse-étoupe (PG7/PG9) + raccordement fixe, pas de bornier débrochable | 1 | Point fermé (2026-11-07) : une arrivée secteur permanente est câblée en fixe (presse-étoupe), pas en connecteur enfichable — évite un débranchement accidentel d'un conducteur 230 V. Référence presse-étoupe à choisir selon diamètre de câble. |
| Bornier de sorties FP | 2 positions, pas 5,08 mm | 4 | Référence exacte à choisir (ex. gamme CTBP05xx CamdenBoss, pas 5,08 mm) ; fil accepté, encombrement et détrompage à vérifier |
| Supports de carte contrôleur | Selon format de la carte Waveshare | 1 jeu | Confirmer entraxes, nombre de broches, hauteur et méthode de montage |
| Coffret rail DIN | **CamdenBoss CNMB/12/2**, couvercle **CNMB/12/PC** (transparent) | 1 jeu | Point fermé (2026-11-07) : base avec accès bornier aux deux extrémités (`/2`), couvercle transparent choisi par l'utilisateur. Accessoires : `CNMB/3/TGRJ45` (découpe RJ45, côté Waveshare) + `CNMB/3/TG508` (guide-fils 9 pôles 5,08 mm, côté sorties FP — couvre les 8 pôles de J2-J5). |
| Fusible et porte-fusible, entrée secteur J1 | **250 mA temporisé (anti-surge), 250 V, 5x20 mm**, 1 jeu | 1 ensemble | Point fermé (2026-11-06) : dimensionné pour l'appel de courant du HLK-5M05 (~qq dizaines de mA en entrée pour 1 A/5 V en sortie) + courant cumulé des 16 voies FP (~quelques dizaines de mA) avec marge; à confirmer par mesure sur prototype avant gel définitif |
| PCB | THT, dimensions provisoires non validées | 1 | Matériau, épaisseur cuivre, nombre de couches, règles de fabrication et exigences d'isolement à définir |
| Interface eedomus | HTTP local envisagé | 1 firmware | Confirmer la méthode réellement utilisée par l'eedomus et définir commandes, retours et sécurisation réseau |

### Calcul de fermeture — résistance et fusible côté secteur (2026-11-06)

Le MOC3041M est caractérisé par le fabricant à `VTM` (tension à l'état passant) pour `ITM = 100 mA` crête, avec un courant de surtension non répétitif `ITSM = 1 A` sur seulement 100 µs — ce n'est pas un courant permanent admissible. Avec la résistance source de 360 Ω, un défaut franc (FP accidentellement court-circuité au neutre, par exemple un défaut de câblage) laisserait passer `230 V / 360 Ω ≈ 640 mA` en continu : plus de 6 fois le courant de caractérisation du composant, avec une puissance instantanée dans la résistance de `360 × 0,64² ≈ 147 W`, destructrice pour un axial 1/4-1/2 W. Le courant utile normal (quelques mA, fixé par l'impédance d'entrée du récepteur fil pilote du radiateur, pas par notre résistance) n'est pas en cause ; c'est le cas de défaut qui est sous-dimensionné.

En remplaçant par **4,7 kΩ**, le même défaut franc ne produit plus que `230 / 4700 ≈ 49 mA`, sous la barre des 100 mA de caractérisation du composant, avec une marge confortable sur `ITSM`. Un **fusible rapide ou PTC ~100 mA** ajouté en série sur chaque voie coupe ce résidu de défaut en quelques millisecondes, en complément (pas en remplacement) du fusible principal d'entrée secteur qui protège le HLK-PM01 et le câblage général. Ce calcul s'appuie sur les valeurs publiées du MOC3041M ; il reste valable pour le MOC3063M retenu côté LED (même famille, même boîtier/triac).

## Règles de gel de nomenclature

- Ne pas figer les empreintes avant d'avoir choisi les références fabricant exactes et obtenu leurs dessins mécaniques.
- **Fournisseur retenu (2026-11-07) :** RS Components pour les composants passifs, drivers, borniers, protections et le coffret CamdenBoss CNMB. Vérifier spécifiquement à la commande : HLK-5M05 (plus courant chez LCSC/Mouser/Reichelt) et la référence boîtier exacte du MOC3063M. Carte Waveshare ESP32-S3-POE-ETH commandée séparément sur Amazon (vendeur Waveshare direct).
- Prévoir les quantités de rechange et consommables de montage dans la commande de production, pas dans la nomenclature fonctionnelle ci-dessus.
- Joindre au dossier de fabrication les liens ou copies contrôlées des datasheets utilisées pour les décisions.