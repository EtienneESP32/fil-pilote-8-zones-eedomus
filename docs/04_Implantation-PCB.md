# Note d'implantation PCB

**Statut :** brief de placement. Aucun contour ni routage ne peut être considéré comme validé à ce stade.

## 1. Données mécaniques connues

- Intégration visée dans un boîtier rail DIN annoncé six modules / 105 mm de largeur.
- **Mise à jour (2026-11-07) :** le placement réel des 16 voies dans KiCad (voir [11_État du projet KiCad](11_Etat-KiCad.md)) montre qu'une carte de 105 × 85 mm est trop courte pour loger les composants traversants avec un dégagement correct.
- **Référence candidate identifiée (2026-11-07) :** gamme **CamdenBoss CNMB** (norme DIN 43880, section fixe 90 mm externe / 86,5 mm de PCB utilisable, longueur variable selon le nombre de modules), disponible chez RS Components. Carte resserrée en plusieurs passes (192→176→167→**154 mm**, 2026-11-08) pour tenir dans un **CNMB/9** (156 mm de PCB utilisable réels, datasheet officiel confirmé — marge ≈2 mm) plutôt que le CNMB/12 initialement visé. **Profondeur vérifiée (2026-11-07) :** empilement support femelle (8,5 mm) + PCB Waveshare (1,6 mm) + prise RJ45 à magnétiques intégrées (≈13,4 mm, référence `HC-RJ45` du schéma réel) ≈ 23,5 mm, contre ≈49 mm de dégagement utile dans le boîtier (58 mm externe moins parois/plots) — marge ≈2×, non limitant. Toujours indicatif : référence à commander pour confirmation finale sur pièce réelle.
- RJ45 de la carte Waveshare ESP32-S3-ETH, SKU 28771, à rendre accessible.
- **Correction d'implantation E/S (2026-11-08) :** le datasheet CNMB confirme que les découpes de câblage (accessoires guide-fils/TGRJ45) n'existent qu'aux **deux extrémités opposées de l'axe qui scale avec le nombre de modules** (la longueur de la carte), jamais sur les deux grands côtés fixes (86,5 mm, section externe constante quel que soit le modèle). Or le schéma de cotes officiel Waveshare (ESP32-S3-ETH, 72,8 × 21 mm) montre que le RJ45 et l'USB-C sont regroupés à **une seule extrémité courte du module** — extrémité qui, avec le module monté à la verticale (orientation compacte actuelle, 21 mm de large sur la carte), sort vers un grand côté FIXE de la carte, pas vers une extrémité valide. Tourner le module à 90° pour aligner son RJ45 sur une extrémité valide coûterait directement les 72,8 mm de longueur du module sur la largeur de carte — incompatible avec un CNMB/9 (et même un CNMB/12 une fois les colonnes de canaux comptées à côté). **Solution retenue :** le module Waveshare reste monté tel quel (compact) ; son port RJ45 est relié par un **court cordon Ethernet interne** à une prise RJ45 secondaire fixée derrière la découpe `TGRJ45` du bord opposé aux borniers J1-J5 — aucune piste cuivre supplémentaire, c'est une liaison par câble, pas par circuit imprimé. Le port USB-C du module reste utilisé uniquement en interne (programmation avant fermeture du boîtier). À ajouter à la nomenclature : 1 prise RJ45 panel-mount + 1 cordon Ethernet court (ou pigtail à sertir).
- RJ45 accessible depuis l'extérieur du coffret via ce cordon interne, confirmé cohérent avec le datasheet réel du coffret (2026-11-08).
- PCB embarquant une alimentation isolée secteur locale en plus de l'option PoE.
- Connecteurs envisagés : J1 secteur, J2 à J5 pour les huit fils pilotes.
- Assemblage traversant demandé.

## 2. Données mécaniques manquantes

- Fabricant et référence du boîtier, dessin coté, volume utile, supports PCB et contraintes de fermeture.
- Positions des presse-étoupes/entrées de câble, sens d'insertion des conducteurs et accès aux borniers.
- Géométrie du passage RJ45 vers l'extérieur et du mécanisme de façade du coffret.
- SKU et plan coté de la carte Waveshare, dimensions exactes du RJ45, hauteur de la carte et dégagements.
- Références, nombre de pôles, empreintes et hauteurs des borniers.
- Zones de fixation, diamètre des trous, épaisseur et matériau du PCB.

## 3. Principes de placement à appliquer après validation électrique

1. Placer les borniers près des bords correspondant au chemin réel du câblage, en gardant un accès au tournevis et aux conducteurs.
2. Regrouper les composants des huit canaux selon un ordre stable, avec sérigraphie lisible des numéros FP et des fonctions.
3. Distinguer visuellement et physiquement la zone secteur de la logique basse tension; réserver les zones d'exclusion cuivre nécessaires.
4. Respecter les contraintes d'isolement du module AC/DC, des optocoupleurs, des connecteurs et du PCB selon les exigences applicables et les composants sélectionnés.
5. Garder les commandes GPIO dans la zone basse tension et éloignées des nœuds perturbés; aucune piste I2C n'est nécessaire dans l'architecture préférée.
6. Vérifier l'accès au port RJ45, au port USB/programming et aux points de test après montage dans le boîtier.
7. Ajouter des points de test basse tension et des repères de polarité/orientation utiles à l'assemblage et au diagnostic.

**Point fermé (2026-11-06) — distance d'isolement :** la table F.4 de la norme IEC 60664-1 fixe un minimum de creepage d'environ 1,0 mm en isolation basique et 2,0 mm en isolation renforcée pour une tension de travail de 250 V, degré de pollution 2, matériau de groupe I (valeurs comparables en clearance pour cette plage de tension). Les 6 mm repris de la source dépassent largement ce minimum réglementaire et sont conservés comme règle de conception du PCB, avec marge. Ce chiffre reste néanmoins à confronter à la catégorie de surtension et au matériau PCB réellement retenus avant le routage final ; il n'est plus en attente de justification de principe.

**Alerte et correction (2026-11-07) — la règle n'était vérifiée nulle part :** en poussant l'auto-routage plus loin, il est apparu que cette séparation de 6 mm n'existait que dans ce document et dans le placement supposé des composants — **aucune classe de net ni règle DRC ne la vérifiait réellement** dans le projet KiCad (le DRC appliquait uniquement la clearance générique 0,2 mm partout, y compris entre `PHASE_PROT` et `GPIO*`). En activant une vraie règle (voir §4), le DRC a révélé **234 violations réelles**, dont **52 sous le minimum réglementaire de 2 mm** (pire cas 0,78 mm) : des broches logique et secteur de deux optotriacs (MOC3063M) **voisins** (canal adjacent ou bande adjacente) se trouvaient à quelques mm les unes des autres. Cause racine identifiée : chaque composant de la pile de canal est tourné à 90° pour l'empilement (voir §3), et cette rotation faisait basculer la séparation logique/secteur interne de l'optotriac (normalement sur l'axe X de son boîtier DIP-6) sur l'axe Y — exactement l'axe d'empilement des canaux et des bandes. **Corrigé en ne tournant plus l'optotriac** (seul composant concerné, `OC*` dans `tools/generate_pcb.ps1`) : son orientation naturelle DIP-6 garde la séparation logique/secteur sur X, qui ne dépend alors d'aucune position Y — le problème disparaît par construction, sans agrandir la carte. Reste 0 violation de clearance réelle après correction (voir [11_État du projet KiCad](11_Etat-KiCad.md)). Les classes de net « Logique »/« Secteur » et la règle DRC personnalisée (6 mm entre les deux, fichier `hardware/kicad/FilPilote_8Zones.kicad_dru`) font maintenant partie du projet et sont vérifiées à chaque `kicad-cli pcb drc`, ce qui n'était pas le cas avant cette correction — ce point ne doit plus être considéré comme acquis par défaut sur un futur projet similaire tant qu'il n'est pas vérifié par un DRC qui connaît réellement la règle.

Ces principes ne remplacent pas un calcul thermique ni une revue de sécurité complète du routage final.

## 4. Stratégie de routage à définir

- Définir les classes de nets et règles de conception à partir des tensions, courants, matériaux, fabricant PCB et exigences d'isolement confirmés.
- Vérifier la largeur et l'échauffement des conducteurs selon les courants de conception documentés.
- Séparer les retours/logiques des chemins secteur; éviter que des nets secteur traversent la zone basse tension.
- Définir les plans cuivre, découpes, encoches et distances aux trous/contours après établissement des exigences d'isolement.
- Lancer les vérifications DRC/ERC dans l'outil CAO choisi et traiter les exceptions explicitement, sans masquer les violations.
- Contrôler le contour, les empreintes et les hauteurs dans une vue 3D comparée au boîtier réel.

## 5. Livrables PCB attendus après levée des blocages

- Projet CAO natif avec schéma et PCB synchronisés. **Fait (2026-11-07)** pour le schéma et le placement, voir [11_État du projet KiCad](11_Etat-KiCad.md) ; routage restant à faire.
- Rapports ERC et DRC datés, avec anomalies résiduelles justifiées. **Fait pour l'état actuel** (0 erreur réelle ERC/DRC, avertissements bénins documentés) ; à refaire après routage et empreintes définitives.
- Dessin coté de la carte et vue d'implantation.
- Gerbers ou format accepté par le fabricant, fichiers de perçage, nomenclature et fichier de placement si nécessaire.
- Instructions d'assemblage, polarités, révisions et points de contrôle.
- Rapport de revue mécanique et de séparation des domaines électriques.

## 6. Choix du coffret et approvisionnement

**Fournisseur retenu (2026-11-07) :** RS Components (ex-RadioSpares) pour les composants électroniques standards, borniers et le coffret — distributeur unique couvrant la majorité de la nomenclature avec fiches techniques tracées. Deux références à vérifier spécifiquement à la commande car moins typiques chez RS : le module **HLK-5M05** (plus courant chez LCSC/Mouser/Reichelt) et la référence exacte boîtier du **MOC3063M**. La carte **Waveshare ESP32-S3-POE-ETH** sera commandée séparément sur Amazon (vendeur Waveshare direct disponible).

**Coffret retenu, mis à jour (2026-11-08) :** base **CamdenBoss CNMB/9/2** (9 modules, 156 mm de PCB utilisable, accès bornier aux deux extrémités opposées), couvercle **CNMB/9/PC** transparent (choix utilisateur), disponible chez RS Components — remplace le CNMB/12 initialement visé, devenu surdimensionné une fois la carte resserrée à 154 mm (voir §1). Accessoires guide-fils/découpe aux deux extrémités : `CNMB/3/TGRJ45` × 3 côté RJ45 (prise secondaire + cordon interne, voir §1) et `CNMB/3/TG508` × 3 côté J1-J5 (guide-fils 5,08 mm), chaque référence étant un segment modulaire de 52,8 mm ("taille 3") — un CNMB/9 nécessite 3 segments par extrémité pour couvrir la largeur du boîtier (confirmé par le datasheet officiel, 2026-11-08). L'entrée secteur J1 est câblée en fixe par presse-étoupe plutôt qu'en bornier débrochable. Profondeur interne vérifiée avec marge ≈2× (voir §1). Quantités et références exactes à reconfirmer auprès du fabricant avant commande.

L'alimentation locale sur PCB ajoute une zone primaire secteur à proximité du module ESP32/PoE. L'implantation doit réserver les distances d'isolement et les cheminements requis pour les deux sources; le sélecteur d'alimentation ne doit pas créer de liaison galvanique ou de retour entre sorties PoE et 5 V du convertisseur.