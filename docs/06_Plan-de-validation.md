# Plan de validation

Ce plan est une trame documentaire. Les contrôles secteur et les mesures de sécurité doivent être définis et réalisés par une personne compétente, avec l'équipement adapté. Aucune valeur de test de tenue diélectrique n'est spécifiée ici faute de contexte normatif et de conception finale.

## 1. Revue documentaire avant schéma final

- [ ] SKU/révision exacte de la carte Waveshare ESP32-S3 ETH identifiée; brochage et broches réservées confirmés.
- [ ] Datasheets contrôlées pour la carte Waveshare, l'alimentation retenue, les optocoupleurs, diodes, drivers, résistances, fusible et borniers.
- [ ] Spécifications d'entrée fil pilote des radiateurs obtenues.
- [ ] Calculs de courant LED, dissipation, alimentation et protections documentés.
- [ ] Exigences d'isolement et contexte d'installation déterminés et revus.
- [ ] Boîtier, connecteurs et enveloppe mécanique identifiés.
- [ ] `PHASE_PROT` unique sur L1/L2/L3 : architecture validée par décision utilisateur (fermé) ; câblage neutre/différentiel commun documenté à la mise en service, sans remise en cause de l'architecture.
- [ ] Sélecteur manuel PoE/HLK-5M05 testé (un seul mode actif, aucun retour croisé); modes d'alimentation clairement repérés sur la carte.

## 2. Vérifications schématiques et logiques

- [ ] ERC exécuté et anomalies justifiées.
- [ ] Broches GPIO, réseaux, drivers et états de démarrage vérifiés avec le schéma fabricant.
- [ ] Mapping Z1 à Z8 contrôlé de bout en bout entre GPIO, optocoupleurs, borniers et firmware.
- [ ] Erreur source GPB5/Z7_NEG corrigée dans le schéma et toute documentation dérivée.
- [ ] Polarités et orientations de tous les composants polarisés vérifiées.
- [ ] États au démarrage et comportement en défaut définis.

## 3. Vérifications PCB et fabrication

- [ ] DRC exécuté avec les règles établies pour le fabricant et les exigences confirmées.
- [ ] Séparation entre domaines électriques contrôlée et revue.
- [ ] Empreintes confrontées aux dessins mécaniques des composants réels.
- [ ] Carte vérifiée dans le boîtier avec accès borniers, RJ45, fixations et dégagements.
- [ ] Sérigraphie des zones, polarités, entrées et avertissements relue.
- [ ] Fichiers de fabrication ouverts dans un visualiseur Gerber avant commande.
- [ ] Nomenclature comparée aux références et empreintes de la révision de PCB.

## 4. Contrôles du prototype hors secteur

- [ ] Inspection visuelle et contrôle de polarité avant alimentation.
- [ ] Vérification de continuité et d'absence de court-circuit sur les rails basse tension.
- [ ] Mise sous tension initiale selon une procédure de laboratoire adaptée, sans raccorder les entrées/sorties au secteur.
- [ ] Vérification des tensions logiques et du courant consommé par la partie basse tension.
- [ ] Vérification de chacune des 16 sorties logiques et de ses drivers avec charge de test adaptée; si expandeur retenu, valider aussi I2C.
- [ ] Test des 8 zones et des six ordres GIFAM sur un montage de test approprié, sans connexion à une installation de chauffage.
- [ ] Test de redémarrage, perte Ethernet, absence du MCP et récupération après défaut.

## 5. Essais fonctionnels sur le système fil pilote

Les essais avec tension secteur ne sont entrepris qu'après validation du schéma, du PCB, du boîtier, des protections et de la procédure par une personne qualifiée. Les charges et instruments doivent convenir aux formes d'onde fil pilote.

- [ ] Confirmer chaque ordre sur une charge/testeur approprié avant raccordement aux radiateurs.
- [ ] Vérifier absence de couplage involontaire entre zones.
- [ ] Vérifier états de démarrage et transitions de modes.
- [ ] Consigner instrument, montage, conditions, résultats, anomalies et décision de mise en service.

## 6. Dossier de preuve

Archiver par révision : schéma, PCB, rapports ERC/DRC, nomenclature, datasheets, procédures et résultats de test, photos du prototype et liste des dérogations. Toute modification matérielle doit entraîner une revue d'impact et une nouvelle validation des contrôles concernés.