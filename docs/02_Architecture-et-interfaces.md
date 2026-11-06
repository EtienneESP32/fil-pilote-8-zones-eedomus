# Architecture et interfaces

**Statut :** architecture de principe issue du DOCX; les connexions secteur ne sont pas validées.

## 1. Blocs fonctionnels

1. **Entrée d'alimentation** : deux modes demandés : PoE via le Waveshare ESP32-S3-POE-ETH, ou alimentation secteur locale isolée sur le PCB via HLK-PM01 proposé. Prévoir un sélecteur matériel ou un power-path avec anti-retour dimensionné; le mode simultané n'est pas autorisé tant que le schéma fabricant et le circuit de partage ne le justifient pas.
2. **Contrôleur** : Waveshare ESP32-S3-POE-ETH, SKU 28771, avec module PoE inclus, RJ45, Wi-Fi et Bluetooth. L'Ethernet utilise un W5500 sur SPI; vérifier le pinout avant d'allouer les GPIO applicatifs.
3. **Sorties logiques** : le besoin est bien de 16 signaux, soit deux optocoupleurs par zone pour huit zones. La cible est la commande directe des LED d'opto par 16 GPIO, chacun avec sa résistance de limitation, si le courant garanti par opto et le budget de courant global sont compatibles avec l'ESP32-S3. Des étages drivers restent une solution de repli, pas une obligation de principe.
4. **Commandes d'isolement** : deux voies optocoupleur par zone d'après le schéma fourni. Leur aptitude à générer les six ordres, notamment les ordres temporels, reste à vérifier et peut nécessiter une modification du circuit.
5. **Connectique** : entrée secteur J1 et sorties FP1 à FP8 regroupées en J2 à J5.

## 2. Affectation logique des voies

| Zone | Voie A | Voie B | GPIO A | GPIO B |
|---:|---|---|---:|---:|
| 1 | POS | NEG | GPIO1 | GPIO2 |
| 2 | POS | NEG | GPIO15 | GPIO16 |
| 3 | POS | NEG | GPIO17 | GPIO18 |
| 4 | POS | NEG | GPIO21 | GPIO4 |
| 5 | POS | NEG | GPIO5 | GPIO38 |
| 6 | POS | NEG | GPIO39 | GPIO40 |
| 7 | POS | NEG | GPIO41 | GPIO42 |
| 8 | POS | NEG | GPIO47 | GPIO48 |

**Point fermé (2026-11-06) :** le wiki fabricant (docs.waveshare.com/ESP32-S3-ETH) confirme que GPIO9/10/11/12/13/14 sont pris par le W5500 (RST/INT/MOSI/MISO/SCLK/CS), que GPIO43/44 sont la console UART0, et surtout que **GPIO33 à GPIO37 sont internes au module (PSRAM octale de l'ESP32-S3R8) et inutilisables**. L'affectation initiale plaçait GPIO33 (zone 4, voie B) et GPIO34 (zone 5, voie A) dans cette plage : ces deux lignes sont remplacées ci-dessus par GPIO4 et GPIO5 (en-tête carte TF, libres sur la variante sans lecteur de carte). Les 14 autres GPIO (1, 2, 15, 16, 17, 18, 21, 38, 39, 40, 41, 42, 47, 48) ne recoupent ni le SPI Ethernet, ni l'UART0, ni la PSRAM, ni les broches de strapping (0, 3, 45, 46), ni l'USB natif (19, 20) : affectation validée pour le schéma. La position physique exacte des broches sur le connecteur reste à relever sur le dessin du footprint au moment du placement, mais ne remet plus en cause le choix des GPIO.

Le MCP23017 et le bus I2C sont retirés de l'architecture. Prévoir des résistances de rappel définissant l'état inactif des drivers au démarrage et pendant reset.

## 3. Alimentation et interface du contrôleur

| Sujet | Proposition | Condition |
|---|---|---|
| Alimentation logique | Pas de régulateur 3,3 V séparé; utiliser le régulateur embarqué de la carte | Confirmer capacité disponible sur la broche 3V3. Le rail 3,3 V reste nécessaire. |
| Entrée de la carte | PoE ou 5 V local depuis HLK-PM01 | Les deux modes doivent être disponibles; sélection avec anti-retour à concevoir. |
| I2C | Non utilisé dans l'architecture directe ESP32 | MCP23017/I2C possible en repli si nécessaire. |
| GPIO | 16 sorties logiques demandées | Établir le tableau pin-à-net après contrôle du schéma fabricant. |

La commande directe GPIO -> résistance -> LED d'opto est électriquement possible. Elle devra être démontrée par calcul sur le courant de déclenchement maximal garanti de l'opto, la tension de sortie GPIO minimale sous charge, la tolérance de résistance et le pire cas où 16 voies sont actives. Exemple à ne pas reprendre tel quel : avec 3,3 V, une LED supposée à 1,2 V et 330 Ω, le courant est d'environ 6,4 mA; le MOC3041M peut demander jusqu'à 15 mA pour un déclenchement garanti. Un optotriac à courant de déclenchement plus faible (par exemple une variante MOC3063M à vérifier, tension répétitive et compatibilité comprises) peut permettre la commande directe avec un dimensionnement adapté. Si le courant cumulé dépasse le budget GPIO/alimentation, ajouter des drivers.

Ne jamais appliquer le 5 V sur la broche 3V3 ou les GPIO. Pour la commande directe, raccorder chaque LED d'opto via une résistance de limitation calculée; ajouter un driver actif seulement si le courant d'entrée garanti ou le budget global des 16 voies l'exige.

## 4. Connectique proposée

| Référence | Fonction | Affectation envisagée |
|---|---|---|
| J1 | Entrée secteur, 2 positions | L et N; modèles et protection à choisir |
| J2 | Sorties fil pilote, 2 positions | FP1, FP2 |
| J3 | Sorties fil pilote, 2 positions | FP3, FP4 |
| J4 | Sorties fil pilote, 2 positions | FP5, FP6 |
| J5 | Sorties fil pilote, 2 positions | FP7, FP8 |

Chaque position de sortie est supposée être une sortie FP indépendante. Le neutre des radiateurs est annoncé comme raccordé directement au tableau. Cette convention de câblage doit être confirmée et étiquetée clairement sur la carte et dans la notice.

## 5. Contexte triphasé et référence des sorties

**Point fermé (2026-11-06), décision utilisateur :** une phase de commande `PHASE_PROT` unique alimente les huit sorties fil pilote, y compris pour des radiateurs répartis sur L1/L2/L3. L'utilisateur connaît son installation (neutre et protection différentielle communs confirmés) et assume ce choix d'architecture. Le réseau `PHASE_PROT` du JSON source est conservé comme principe, le circuit sera néanmoins redessiné (et non recopié tel quel).

Pour mémoire au dossier : une référence externe ([`Dackara/Fil_Pilote`](https://github.com/Dackara/Fil_Pilote)) décrit une architecture à phase multiple plutôt qu'unique. Ce point a été signalé à l'utilisateur, qui a tranché pour `PHASE_PROT` unique en connaissance de cause ; il n'est plus traité comme bloquant dans ce dossier.

## 6. Interface fonctionnelle firmware/carte

**Point fermé (2026-11-06) :** les deux voies par zone (POS/NEG) suffisent matériellement aux six ordres GIFAM. Confort, Éco, Hors-gel et Arrêt sont les 4 combinaisons statiques (POS/NEG à 0 ou 1). Confort -1 °C et Confort -2 °C sont obtenus par alternance temporelle entre deux de ces états, pilotée uniquement par le firmware (ex. bascule périodique Confort/Éco à un rapport cyclique donné) : aucune voie ni composant supplémentaire n'est nécessaire côté schéma. Le firmware devra fixer la période et le rapport cyclique exacts à partir de la spécification GIFAM retenue, synchronisés au passage par zéro pour rester cohérent avec les optotriacs zero-cross.
- Une zone est commandée par deux voies; leur séquencement produit les six ordres GIFAM selon le principe ci-dessus.
- À la mise sous tension et pendant l'initialisation, les sorties doivent rester dans l'état matériel prévu et documenté.
- En cas de perte réseau, conserver la dernière consigne reçue.
- Le comportement au redémarrage doit restaurer la dernière consigne persistée et éviter les transitoires de sortie.
- Le comportement en cas de défaut GPIO/driver doit être déterministe et signalé.
- L'interface domotique cible est eedomus; un API HTTP local est une proposition à confirmer lors de la définition du firmware.