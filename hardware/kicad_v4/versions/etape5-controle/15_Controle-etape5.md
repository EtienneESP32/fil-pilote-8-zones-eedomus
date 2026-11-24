# Étape 5 — Contrôle final (2026-11-24)

Carte contrôlée : `hardware/kicad_v4/FilPilote_v4.kicad_pcb`, identique à celle validée à l'étape 4 (SHA256 3c7ebb67…). Cotes en mm. Aucun Gerber produit.

## Contrôles électriques

| Contrôle | Résultat |
|---|---|
| DRC, toutes gravités, règle de 6 mm active, avec et sans recalcul des plans | 0 erreur, 0 avertissement |
| Connexions manquantes | 0 |
| Parité avec le schéma | 0 |
| ERC | 0 erreur, 0 avertissement |
| DRC avec 62 tests forcés en erreur, dont ceux que KiCad ignore d'origine | 0 violation, 8 remarques de nom d'empreinte (F0, H1, H2, J1 à J5), sans effet sur la carte |
| Secteur / très basse tension, recalculé sans le DRC | 6,02 (même opto), 6,15 ailleurs |
| Neutre / autre secteur ; phase avant fusible / autre secteur | 3,00 ; 3,08 |
| Secteur / centre de l'antenne | 19,7 |
| `.kicad_pro` après DRC | inchangé |

## Pastille par pastille (`tools/check_pads.py`)

309 pastilles sur 309 : position, taille, perçage, faces et net. 0 écart. Attendus écrits à la main d'après le document 13 et les brochages. Cinq fautes volontaires (perçage, sorties de l'IRM inversées, broche ESP32 décalée de 0,2, pastille de bornier, diode à l'envers) : toutes détectées.

Trous non métallisés : F0 2,7 ; H1 et H2 4,0 x 10,4. Dessins rouverts pour ce contrôle : IRM-05-5 (vue de dessous, miroir refait), Schurter OGN, ASSMANN, Phoenix 1715721, Waveshare (vue côté USB-C, miroir refait).

## Coffret (`etape5_coffret.png`)

Lu dans le catalogue CamdenBoss, p. 393 et 394 : 159,2 x 90 ; paliers 26,5 et 48 ; hauteur 58 ; carte A à 10,8 de la base ; cache 52,8 x 13,8 x 20. Le plan ne dit pas si 10,8 désigne le dessus ou le dessous du PCB, d'où les fourchettes de 1,6.

À l'échelle du dessin, donc à mesurer : le cache porte derrière une languette centrale d'environ 31,6 de long, entre 10,0 et 12,5 du bord de la carte. Elle descend d'environ 10,6 sous le dessus du cache. Il reste 3,5 à 5,1 entre elle et la carte.

**Languettes : point clos par l'utilisateur le 2026-11-24.** Elles seront coupées à la pince. F0 et U2 ne bougent pas. La feuille 1:1 ne les montre plus.

| Pièce | Constat |
|---|---|
| F0, hauteur 11,5 (12,7 avec capot), à partir de y = 10,95 (10,35 avec capot) | Touche la languette de la fenêtre 3 : recouvrement de 1,5 à 2,1 |
| Borniers, 13,8 | Jeu sous le cache de -1,2 à +1,1 (épaisseur 0,8 à 1,5 supposée) |
| Support U2, 5,1, à partir de y = 75,15 | Jeu sous la languette de -1,6 à 0 |
| J5 | Dernière position des 9 pôles de la fenêtre 1, d'après l'échelle |
| PS1 | À 0,8 de la paroi du corps haut (relevée à l'échelle) |
| Dessous | Environ 4 entre PCB et fond (échelle) : couper les pattes à 3 au plus |

Correction : l'étape 3 donnait 15,7 de hauteur libre hors du corps haut. Cette valeur ne déduisait ni le cache ni l'épaisseur du PCB, et ignorait la languette. Le RJ45 n'est pas traité ici (décision de l'utilisateur).

## Impression 1:1 (`etape5_impression_1-1.pdf`)

A4 paysage, à imprimer à 100 %. Mesuré sur le PDF, largeur de trait comprise : carte 156,0 ; règle 100,2 pour 100. La feuille porte la liste des cotes à relever.

## Reste à faire avant fabrication

1. Essai de la feuille 1:1 avec les vraies pièces et le coffret.
2. Distance entre les métaux des deux rangées du support d'opto (6 mm demandés ; tenue annoncée 1000 V RMS).
3. Accord écrit de l'utilisateur pour les Gerbers.
