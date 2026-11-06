# Nomenclature prévisionnelle

Cette liste est une estimation à partir du concept du DOCX, pas une liste d'achat approuvée. Les références exactes, empreintes et caractéristiques nominales sont à confirmer par datasheets et choix de composants.

| Désignation | Référence proposée dans la source | Qté estimée | Statut / décision requise |
|---|---|---:|---|
| Carte contrôleur Ethernet | Waveshare ESP32-S3-POE-ETH, SKU 28771 | 1 | PoE inclus selon fabricant; confirmer variante commandée, brochage, alimentation autorisée, dimensions et courant disponible sur 3,3 V |
| Expandeur de sorties | Aucun dans l'architecture préférée | 0 | Ajouter un MCP23017 ou équivalent uniquement si le pinout ne fournit pas 16 GPIO utilisables |
| Convertisseur AC/DC isolé local | HLK-PM01, 230 VAC vers 5 V | 1 | Requis pour fonctionner sans PoE; vérifier que le budget 5 V couvre contrôleur et drivers dans le pire cas |
| Sélection/anti-retour de puissance | Sélecteur de source ou circuit power-path | 1 | Doit permettre PoE ou 5 V local sans réalimentation croisée; architecture à choisir après vérification du schéma Waveshare |
| Optotriac zéro-cross | MOC3063M, candidat de direct-drive; MOC3041M conservé uniquement comme référence source | 16 | Valider IFT maximal (candidat 5 mA), tension répétitive 600 V, comportement zero-cross et compatibilité avec les six ordres |
| Diode de voie | 1N4007, DO-41 | 16 | Valider le rôle, l'orientation et les contraintes de courant/thermiques |
| Résistance LED opto | 200 Ω, 1 %, cible de calcul provisoire pour le MOC3063M | 16 | Étude préliminaire, non gelée : vérifier Vf/VOH aux limites, courant maximal GPIO, total 16 voies et puissance du rail 3,3 V. Voir [étude direct-drive](09_Commande-directe-opto.md) |
| Résistance côté secteur | **4,7 kΩ, 1/4 W** (remplace les 360 Ω de la source) | 16 | Point fermé (2026-11-06) : voir calcul ci-dessous. Fonction = limitation du courant de défaut, pas réglage du signal utile. |
| Fusible/PTC par voie FP | Fusible rapide ou PTC ~100 mA, 250 V, 1 par voie | 16 | Point fermé (2026-11-06) : défense en profondeur en série avec chaque résistance 4,7 kΩ/opto, voir calcul ci-dessous. |
| Réseau I2C / RESET expandeur | Non prévu | 0 | À ajouter seulement si un expandeur d'E/S est retenu |
| Découplage logique | Selon carte et drivers retenus | À déterminer | Vérifier datasheets et implantation; la carte contrôleur possède son propre découplage |
| Bornier d'entrée secteur | 2 positions, pas annoncé 5/5,08 mm | 1 | Référence, tension/courant, fil accepté, protection au toucher et empreinte à choisir |
| Bornier de sorties FP | 2 positions, pas annoncé 5/5,08 mm | 4 | Référence, tension/courant, fil accepté, encombrement et détrompage à choisir |
| Supports de carte contrôleur | Selon format de la carte Waveshare | 1 jeu | Confirmer entraxes, nombre de broches, hauteur et méthode de montage |
| Drivers de sorties logiques | Aucun prévu dans l'architecture cible | 0 à 16 voies | Ajouter seulement si le direct-drive échoue au bilan de courant ou à la validation au pire cas |
| Fusible et porte-fusible, entrée secteur J1 | **250 mA temporisé (anti-surge), 250 V, 5x20 mm**, 1 jeu | 1 ensemble | Point fermé (2026-11-06) : dimensionné pour l'appel de courant du HLK-PM01 (~90 mA estimés) + courant cumulé des 16 voies FP (~quelques dizaines de mA) avec marge; à confirmer par mesure sur prototype avant gel définitif. |

### Calcul de fermeture — résistance et fusible côté secteur (2026-11-06)

Le MOC3041M est caractérisé par le fabricant à `VTM` (tension à l'état passant) pour `ITM = 100 mA` crête, avec un courant de surtension non répétitif `ITSM = 1 A` sur seulement 100 µs — ce n'est pas un courant permanent admissible. Avec la résistance source de 360 Ω, un défaut franc (FP accidentellement court-circuité au neutre, par exemple un défaut de câblage) laisserait passer `230 V / 360 Ω ≈ 640 mA` en continu : plus de 6 fois le courant de caractérisation du composant, avec une puissance instantanée dans la résistance de `360 × 0,64² ≈ 147 W`, destructrice pour un axial 1/4-1/2 W. Le courant utile normal (quelques mA, fixé par l'impédance d'entrée du récepteur fil pilote du radiateur, pas par notre résistance) n'est pas en cause ; c'est le cas de défaut qui est sous-dimensionné.

En remplaçant par **4,7 kΩ**, le même défaut franc ne produit plus que `230 / 4700 ≈ 49 mA`, sous la barre des 100 mA de caractérisation du composant, avec une marge confortable sur `ITSM`. Un **fusible rapide ou PTC ~100 mA** ajouté en série sur chaque voie coupe ce résidu de défaut en quelques millisecondes, en complément (pas en remplacement) du fusible principal d'entrée secteur qui protège le HLK-PM01 et le câblage général. Ce calcul s'appuie sur les valeurs publiées du MOC3041M ; à reconfirmer si l'optotriac change de référence (ex. MOC3063M, voir [étude direct-drive](09_Commande-directe-opto.md)).
| PCB | THT, dimensions provisoires non validées | 1 | Matériau, épaisseur cuivre, nombre de couches, règles de fabrication et exigences d'isolement à définir |
| Régulateur 3,3 V séparé | Aucun prévu à ce stade | 0 | Utiliser la sortie régulée de la carte contrôleur si sa capacité disponible est suffisante; sinon revoir le budget/architecture. Le JSON source contient un MCP1700 à supprimer ou justifier dans la nouvelle version. |
| Interface eedomus | HTTP local envisagé | 1 firmware | Confirmer la méthode réellement utilisée par l'eedomus et définir commandes, retours et sécurisation réseau |

## Règles de gel de nomenclature

- Ne pas figer les empreintes avant d'avoir choisi les références fabricant exactes et obtenu leurs dessins mécaniques.
- Ne pas figer les valeurs 330 Ω/360 Ω avant calcul et revue du circuit complet.
- Centraliser autant que possible les composants passifs, drivers, borniers et protections chez un distributeur unique; la carte Waveshare et le coffret peuvent rester des achats séparés si le même fournisseur ne les distribue pas.
- Prévoir les quantités de rechange et consommables de montage dans la commande de production, pas dans la nomenclature fonctionnelle ci-dessus.
- Joindre au dossier de fabrication les liens ou copies contrôlées des datasheets utilisées pour les décisions.