# Publication et sauvegarde GitHub

## État actuel

- Le dossier n'est pas encore un dépôt Git local (`git status` renvoie « not a git repository »).
- GitHub CLI (`gh`) n'est pas installé.
- Les pages de recherche GitHub consultées ne montrent pas de session connectée; aucune action de publication distante n'a été effectuée.
- `README.md` et `.gitignore` sont prêts dans ce dossier.
- Le projet contient un contrôleur de chauffage secteur encore en étude et des détails d'installation résidentielle. Recommandation initiale : dépôt GitHub **privé** pour la sauvegarde.

## Nom proposé

`fil-pilote-8-zones-eedomus`

## Contenu prévu dans la sauvegarde

- Cahier initial DOCX et exports PDF/JSON EasyEDA, conservés comme sources historiques.
- Dossier `docs/` avec exigences, architecture, nomenclature, validation, revue des erreurs et comparatif des projets.
- README racine et ce guide de publication.
- Plus tard : export R1 EasyEDA, schéma corrigé, PCB natif, rapports ERC/DRC, BOM figée, Gerbers et instructions d'assemblage après revue.

## Avant toute publication publique

- Vérifier le contenu du DOCX et retirer toute information personnelle ou locale qui ne doit pas être diffusée.
- Vérifier qu'aucune donnée Wi-Fi, clé/API token, mot de passe, adresse IP publique ou information privée du réseau ne se trouve dans les futurs fichiers firmware.
- Ne pas inclure un PCB/Gerber présenté comme prêt à fabriquer avant validation du triphasé, des protections, des distances d'isolement et des six ordres.
- Choisir une licence propre au projet. Ne pas copier le matériel ou le firmware de dépôts tiers sans respecter leur licence. En particulier, le matériel de `tducret/programmateur-fil-pilote-wifi` est annoncé CC BY-NC-SA 4.0.
- Faire relire le dossier secteur par une personne qualifiée avant de le présenter comme réalisation validée.

## Étapes une fois la visibilité confirmée

1. Créer sur GitHub un dépôt vide nommé `fil-pilote-8-zones-eedomus`, de préférence privé pour la sauvegarde initiale. Ne pas demander à GitHub de créer un second README si celui du dossier est conservé.
2. Initialiser Git dans ce dossier, définir `main` comme branche principale et ajouter les fichiers destinés à la sauvegarde.
3. Vérifier la liste des fichiers indexés et le diff avant le premier commit.
4. Effectuer un premier commit local, puis relier le dépôt distant GitHub et pousser la branche principale.
5. Vérifier sur GitHub que le dépôt est privé, que les sources attendues sont présentes et qu'aucun secret ou export dangereux n'a été publié.

Aucun dépôt distant, commit ou push n'a été créé par cette préparation. La visibilité publique/privée doit être décidée avant l'étape 1.
