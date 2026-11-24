# Étape 1 — Tableau des empreintes (2026-11-24)

Sert de référence au contrôle pastille par pastille de l'étape 5. Cotes en mm. Validé par l'utilisateur le 2026-11-24.

« Officielle » : empreinte KiCad 10 utilisée telle quelle. « Modifiée » : copie de l'empreinte officielle dans la bibliothèque du projet, avec le changement indiqué. Les empreintes officielles citées ont été lues par l'API Python de KiCad.

| Repère | Pièce, boîtier | Entraxe | Broche | Perçage | Pastille | Empreinte | Source |
|---|---|---|---|---|---|---|---|
| J1 à J5 | Phoenix 1715721, 2 pôles | 5,08 | 0,9 x 0,9 (diagonale 1,27) | 1,3 | 2,0 x 3,0 ovale | Modifiée : `TerminalBlock_Phoenix_MKDS-1,5-2-5.08` (ronde 2,6 à l'origine) | Phoenix, copie Farnell 2138244 p. 1 ; copie RS A700000014777249 p. 6 et 7 |
| F0 | Schurter 0031.8201 | 22,5 | largeur 1,1 | 1,35 | 3,0 ronde | Modifiée : `Fuseholder_..._Schurter_0031_8201` (perçage 1,3 à l'origine) | Schurter OGN, copie Rapid 560678 p. 1 : 1,3 +0,1/0 |
| PS1 | IRM-05-5, 45,7 x 25,4 x 21,5 | 38,5 / 10,75 / 8 | diamètre 1,0 | 1,5 | 3,0 ronde | Officielle : `Converter_ACDC_MeanWell_IRM-05-xx_THT` | Mean Well 2025-08-08 p. 3 |
| DPWR1 | 1N5819RL, DO-41 | 10,16 | 0,71 à 0,86 | 1,1 | 2,2 | Officielle : `D_DO-41_SOD81_P10.16mm_Horizontal` | ST, copie Rapid 47-2564 p. 6 |
| D x16 | 1N4007G, DO-41 | 10,16 | 0,71 à 0,86 | 1,1 | 2,2 | Officielle : idem | Taiwan Semiconductor, série 1N400xG-K, copie Farnell 2572234, page du dessin |
| RL x16 | MRS25, corps 6,5 x 2,5 max | 10,16 | 0,6 | 0,8 | 1,6 | Officielle : `R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm` | Vishay 28724, copie RS A700000015807037, tableau des dimensions |
| RPU1, RPU2 | CFR-25JT, 6,3 x 2,4 | 10,16 | 0,55 | 0,8 | 1,6 | Officielle : idem RL | NON OUVERTE : valeur d'un extrait de recherche (fiche Yageo CFR) |
| U1 | LF33CV, TO-220 | 2,54 | 0,88 x 0,70 max (diagonale 1,12) | 1,3 | 1,9 x 2,4 | Modifiée : `TO-220-3_Vertical` (perçage 1,1 à l'origine) | ST LFxxC, copie RS 0900766b80dbdbde p. 6 (brochage) et p. 42 |
| C1, C2 | EEUFC1E470, 5 x 11 | 2,0 | 0,5 | 0,8 | 1,6 | Officielle : `CP_Radial_D5.0mm_P2.00mm` | Panasonic FC, copie Octopart, p. 1 et 6 |
| C3 + 100 nF de U1 | RDER71H104K0P1H03B, 5 x 2,5 | 2,5 | 0,5 | 0,8 | 1,6 | Officielle : `C_Disc_D5.0mm_W2.5mm_P2.50mm` | Murata, copie Akizuki p. 1 |
| OC x16 | MOC3063M sur A 06-LC-TT | 7,62 / 2,54 | 0,58 x 0,35 (support) | 1,0 | 1,6 ronde | Modifiée : `DIP-6_W7.62mm_Socket` (perçage 0,8 à l'origine) | ASSMANN ASS 0810 CO rev04 ; onsemi MOC3163M/D p. 9 |
| U2 | MCP23017-E/SP sur A 28-LC/7-T | 7,62 / 2,54 | idem | 1,0 | 1,6 ronde | Modifiée : `DIP-28_W7.62mm_Socket` | ASSMANN ASS 0810 CO ; Microchip DS20001952 p. 1 et 38 |
| U3, U4, U5 | ULN2003AN sur A 16-LC-TT | 7,62 / 2,54 | idem | 1,0 | 1,6 ronde | Modifiée : `DIP-16_W7.62mm_Socket` | ASSMANN ASS 0810 CO ; TI ULN2003A, dessin N (R-PDIP), p. 41 du PDF |
| JWS1 | ESP32-S3-ETH-M sur 2 x SSW-120-01-G-S | 2,54 / rangées 17,78 | 0,79 x 0,41 (diagonale 0,89) | 1,0 | 1,7 | À créer à partir de `PinSocket_1x20_P2.54mm_Vertical` x2 | Samtec SSW rev CA feuille 1 ; plans du wiki Waveshare |
| H1, H2 | Vis No.6 du coffret | X = 8,9 ; Y = 18,3 (bords extérieurs du coffret) | — | oblong 4,0 x 10,4 | non métallisé | Créée : `Fixation_CNMB_4.0x10.4` | X, Y : CamdenBoss 2015, copie Farnell 2144965 p. 43. Le dessin à l'échelle donne Y ≈ 11,9 : l'oblong couvre les deux. Vis : cnmb_series_d.pdf p. 393 |

## Brochages contrôlés

- PS1, vue de dessus après miroir : pastille KiCad 1 = AC/N, 2 = AC/L, 3 = -V, 4 = +V.
- U1 : 1 = entrée, 2 = masse, 3 = sortie.
- JWS1, vue côté RJ45, RJ45 en haut : 1 (GPIO20) en haut à gauche, 20 (GPIO33) en bas à gauche, 21 (GPIO43) en bas à droite, 40 (VBUS) en haut à droite. VSYS = 39, GPIO1 = 25, GPIO2 = 26, GND = 3, 8, 13, 18, 23, 28, 33, 38. Première broche à 19,87 du bord RJ45, dernière à 4,67 du bord antenne (calculé), rangées à 1,61 des longs côtés (calculé). Broches soudées côté USB-C : confirmé par l'utilisateur le 2026-11-24.

## Distances aux pastilles

- Optos : 7,62 - 1,6 = 6,02 entre pastilles. L'onsemi annonce 7 mm de cheminement et de distance dans l'air pour le composant. La distance entre lames à l'intérieur du support n'est pas cotée par ASSMANN.
- J1 à J5 : 5,08 - 2,0 = 3,08 entre les deux pastilles (2,48 avec la pastille d'origine).

## Changements de l'étape 3 (pastilles et perçages inchangés)

- DPWR et JWS renommés DPWR1 et JWS1 : KiCad exige un chiffre final.
- Contours de sécurité modifiés : DIP-6 ramené à 8,04 (support ASSMANN 7,62 ± 0,20) ; JWS1 limité aux deux supports ; H1, H2 à 7,6 x 14.
- JWS1 : zone sans cuivre ajoutée sous l'antenne (depuis 49,4 mm de la broche 1 et au-delà).
- ASSMANN ASS 0810 CO indique une tenue diélectrique de 1000 V RMS, 1 minute, pour le support. L'onsemi annonce 4170 V RMS pour l'opto seul.

## Changements de l'étape 4 (pastilles et perçages inchangés)

- Borniers Phoenix : triangle de sérigraphie retiré. ESP32 : cadre de sérigraphie rentré de 0,3. Rien d'autre.
