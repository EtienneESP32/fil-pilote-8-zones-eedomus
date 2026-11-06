# Note d'implantation PCB

**Statut :** brief de placement. Aucun contour ni routage ne peut être considéré comme validé à ce stade.

## 1. Données mécaniques connues

- Intégration visée dans un boîtier rail DIN annoncé six modules / 105 mm de largeur.
- Une carte de 105 × 85 mm est évoquée comme exemple seulement; ses dimensions ne sont pas approuvées.
- RJ45 de la carte Waveshare ESP32-S3-POE-ETH, SKU 28771, à rendre accessible.
- RJ45 accessible depuis l'extérieur du coffret, confirmé par l'utilisateur.
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

Ces principes ne remplacent pas un calcul thermique ni une revue de sécurité complète du routage final.

## 4. Stratégie de routage à définir

- Définir les classes de nets et règles de conception à partir des tensions, courants, matériaux, fabricant PCB et exigences d'isolement confirmés.
- Vérifier la largeur et l'échauffement des conducteurs selon les courants de conception documentés.
- Séparer les retours/logiques des chemins secteur; éviter que des nets secteur traversent la zone basse tension.
- Définir les plans cuivre, découpes, encoches et distances aux trous/contours après établissement des exigences d'isolement.
- Lancer les vérifications DRC/ERC dans l'outil CAO choisi et traiter les exceptions explicitement, sans masquer les violations.
- Contrôler le contour, les empreintes et les hauteurs dans une vue 3D comparée au boîtier réel.

## 5. Livrables PCB attendus après levée des blocages

- Projet CAO natif avec schéma et PCB synchronisés.
- Rapports ERC et DRC datés, avec anomalies résiduelles justifiées.
- Dessin coté de la carte et vue d'implantation.
- Gerbers ou format accepté par le fabricant, fichiers de perçage, nomenclature et fichier de placement si nécessaire.
- Instructions d'assemblage, polarités, révisions et points de contrôle.
- Rapport de revue mécanique et de séparation des domaines électriques.

## 6. Choix du coffret et approvisionnement

Le besoin retenu est un coffret rail DIN six modules, sans préférence de marque. L'exacte référence sera choisie par adéquation mécanique avec la carte Waveshare, le PCB et l'accès aux borniers/RJ45; ne pas figer le contour du PCB à partir de la seule largeur nominale 105 mm. Pour l'approvisionnement, regrouper les composants électroniques standards chez un distributeur unique autant que possible, avec achats séparés possibles pour le module Waveshare et le coffret.

L'alimentation locale sur PCB ajoute une zone primaire secteur à proximité du module ESP32/PoE. L'implantation doit réserver les distances d'isolement et les cheminements requis pour les deux sources; le sélecteur d'alimentation ne doit pas créer de liaison galvanique ou de retour entre sorties PoE et 5 V du convertisseur.