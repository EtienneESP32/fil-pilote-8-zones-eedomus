# Étape 4 — Routage (2026-11-24)

Carte : `hardware/kicad_v4/FilPilote_v4.kicad_pcb`. Cotes en mm. En attente de validation.

## Contrôles

| Contrôle | Résultat |
|---|---|
| DRC, toutes gravités, règle de 6 mm active | 0 erreur, 0 avertissement |
| Connexions manquantes | 0 |
| Parité avec le schéma | 0 écart |
| ERC | 0 erreur, 0 avertissement |
| Secteur / très basse tension, recalculé sans le DRC, faces confondues | 6,02 (pastilles d'un même opto) ; 6,15 ailleurs ; 6,31 pour la piste TBT la plus proche |

Fautes volontaires, une par essai, toutes détectées : piste GND à moins de 6 mm d'une piste de phase ; piste sans net côté secteur ; piste LED entre les rangées d'un opto ; pastille LED portée à 1,7 ; neutre à 2,9 de la phase ; piste secteur à moins de 1,2 du bord ; une liaison MT retirée ; une liaison SDA retirée. Un plan dessiné à travers la barrière recule seul à 6 mm.

## Distances de la norme (lues le 2026-11-24)

Source : IEC 60664-1 Ed3, projet CD 109/166 de 2018 (copie BEAMA), tableaux F.1, F.2, F.5, et TI SLUP419, tableaux 3 à 5. C'est un projet, pas l'édition en vigueur. La mise en colonnes du tableau F.5 a été recoupée avec TI (63, 400 et 800 V).

| Grandeur, 230 V, pollution 2 | Valeur |
|---|---|
| Tension de choc, catégorie III | 4 kV (6 kV en renforcé) |
| Distance dans l'air, 2,5 / 4 / 6 kV | 1,5 / 3,0 / 5,5 |
| Cheminement 250 V, groupe III | 2,5, soit 5,0 en renforcé |
| Cheminement 250 V, circuit imprimé verni | 1,0 (0,85 à 230 V par interpolation) |

## Distances secteur / secteur

| Entre | Retenu | Mesuré sur la carte | Justification |
|---|---|---|---|
| Neutre et tout autre secteur | 3,0 | 3,00 | 4 kV |
| Phase avant fusible et tout autre secteur | 3,0 | 3,08 | 4 kV |
| Phase protégée, MT, FP entre eux | 2,5 | 2,50 | Isolation fonctionnelle, cheminement 250 V groupe III |
| Sortie d'opto et patte de diode | 1,9 | 1,93 | Pas de 8,20 ; plus de 1,5 (2,5 kV) |
| Pastilles de deux optos voisins | — | 1,52 | Pas de 8,20 |
| Pastille d'opto et piste voisine | 1,0 | 1,07 | Cheminement circuit imprimé ; sous 1,5 (2,5 kV) |
| Broches d'un même opto | 0,9 | 0,94 | Boîtier DIP-6 au pas de 2,54 |
| Secteur et bord de carte | 1,2 | conforme au DRC | |

Les deux avant-dernières lignes ne respectent pas 1,5 dans l'air. Le boîtier l'impose entre les broches d'un opto. Elles ne séparent que du secteur du secteur, après le fusible de 250 mA : un défaut y fausse un ordre de chauffage ou fond F0, sans toucher l'isolement vers la très basse tension.

## Largeurs (cuivre 35 µm)

| Réseau | Largeur | Courant prévu | Tenue IPC-2221, +10 °C |
|---|---|---|---|
| L | 1,5 | 0,25 A (fusible) | 3,2 A |
| N (IRM seule) | 1,0 | environ 0,15 A (supposé) | 2,4 A |
| Phase protégée : bus, vers F0, vers l'IRM | 2,0 ; 1,0 ; 1,5 | 0,25 A | 2,4 A au plus étroit |
| Phase vers optos, MT | 0,8 (0,7 vers la zone 8) | quelques mA | 1,8 A |
| FP | 1,0 | quelques mA | 2,4 A |
| VSYS, 5 V, GND | 0,8 à 1,5 (0,6 sur 3 mm) | moins de 1 A | 1,6 A au plus étroit |
| Signaux | 0,4 (0,3 par endroits) | moins de 20 mA | 1,0 A |

## Choix de routage

- Phase protégée et neutre dessous. L, MT et FP dessus, sauf FP1 dessous. Aucun trou de passage côté secteur ; 4 côté très basse tension (trous 0,4).
- Pistes secteur posées à la main, TBT par Freerouting 2.5.0 (secteur + 6,01 mm interdits sur les deux faces).
- Plans de masse des deux côtés, limités à la très basse tension ; rien sous l'antenne ni autour de la vis H2.
- Tronc VSYS direct de C1 à l'ESP32.

## Changements de placement depuis l'étape 3

- J5 décalé de 5,08 vers la droite (FP8 à 41,34 et FP7 à 46,42).
- D71, D72, D81, D82 déplacées ; les autres diodes secteur décalées de 0,85 vers la gauche ou 0,67 vers la droite.
- Aucun autre composant déplacé. Pastilles et perçages inchangés.
- Sérigraphie de deux empreintes retouchée (borniers, ESP32) pour ne rien laisser hors de la carte.

## Règles DRC ajoutées

Toutes dans `FilPilote_v4.kicad_dru`. La règle de 6 mm est inchangée et reste la dernière, donc prioritaire. Une règle accepte un seul frein thermique sur les broches GND de U2 ; seule la broche 17 en a besoin, et une piste de 0,8 la relie aux broches 15 et 16.

## Reconstruire la carte

Dans l'ordre, python de KiCad : `make_pcb.py`, `route_tbt.py`, `route_mains.py`, `zones.py`, `silk.py`. Contrôle : `check_dist.py`. `make_dsn.py` ne sert qu'à refaire l'autoroutage. Sauver le `.kicad_pro` avant `make_pcb.py` et le remettre après.

## Non vérifié

- Distance entre lames dans le support d'opto, et sa tenue de 1000 V RMS (voir document 13).
- Position des fenêtres du coffret, donc la nouvelle place de J5 (relevée à l'échelle).
- Distances nominales, tolérance de fabrication non incluse.
