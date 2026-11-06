# Architecture et interfaces

**Statut :** architecture de principe issue du DOCX; les connexions secteur ne sont pas validées.

## 1. Blocs fonctionnels

1. **Entrée d'alimentation** : deux modes : PoE via le Waveshare ESP32-S3-POE-ETH, ou alimentation secteur locale isolée sur le PCB via **Hi-Link HLK-5M05 (5 V / 1 A)**. Sélecteur manuel SPDT entre les deux sources prévu dans le schéma. **Point ouvert (découvert 2026-11-07) :** le connecteur principal 40 broches de la carte Waveshare (voir §2) n'expose aucune broche identifiée « sortie PoE » — seules `VBUS`/`VSYS`/`GND`/`3V3`/`3V3_EN`/`RUN` sont documentées côté alimentation. Le schéma câble pour l'instant l'entrée « PoE » du sélecteur sur un réseau non raccordé (`POE_5V_A_CONFIRMER`, visible comme avertissement ERC intentionnel). À vérifier sur le schéma du module PoE Waveshare lui-même avant de considérer ce sélecteur comme validé : si le module PoE alimente `VSYS` en interne sans sortie externe séparée, le principe même du sélecteur est à revoir (la mutualité PoE/local pourrait être intrinsèque au module plutôt que pilotée par un commutateur externe).
2. **Contrôleur** : Waveshare ESP32-S3-POE-ETH, SKU 28771, avec module PoE inclus, RJ45, Wi-Fi et Bluetooth. L'Ethernet utilise un W5500 sur SPI; vérifier le pinout avant d'allouer les GPIO applicatifs.
3. **Sorties logiques** : 16 signaux, deux optocoupleurs par zone pour huit zones. **Point fermé (2026-11-06) :** commande GPIO → transistor tampon → LED d'opto, voir §3. Le direct-drive GPIO→LED est abandonné au profit d'un étage tampon, pour les raisons détaillées ci-dessous.
4. **Commandes d'isolement** : deux voies optocoupleur par zone d'après le schéma fourni. Leur aptitude à générer les six ordres, notamment les ordres temporels, reste à vérifier et peut nécessiter une modification du circuit.
5. **Connectique** : entrée secteur J1 et sorties FP1 à FP8 regroupées en J2 à J5.

## 2. Affectation logique des voies

| Zone | Voie A | Voie B | GPIO A | GPIO B |
|---:|---|---|---:|---:|
| 1 | POS | NEG | GPIO1 | GPIO2 |
| 2 | POS | NEG | GPIO15 | GPIO16 |
| 3 | POS | NEG | GPIO17 | GPIO18 |
| 4 | POS | NEG | GPIO21 | GPIO45 |
| 5 | POS | NEG | GPIO3 | GPIO38 |
| 6 | POS | NEG | GPIO39 | GPIO40 |
| 7 | POS | NEG | GPIO41 | GPIO42 |
| 8 | POS | NEG | GPIO47 | GPIO48 |

**Point fermé (2026-11-06), corrigé le 2026-11-07 :** le wiki fabricant confirme que GPIO9/10/11/12/13/14 sont pris par le W5500, que GPIO43/44 sont la console UART0, et que **GPIO33 à GPIO37 sont internes au module (PSRAM octale) et inutilisables**. Une première correction avait remplacé GPIO33/34 par GPIO4/5 (en-tête carte TF) — **erreur découverte le 2026-11-07** : GPIO4 et GPIO5 ne sortent que sur le connecteur carte TF, absent de l'en-tête principal 40 broches réellement disponible pour le câblage. Le pinout physique réel du connecteur (format Raspberry Pi Pico, 40 broches 2,54 mm sur 2 rangées, vérifié contre [espboards.dev](https://www.espboards.dev/esp32/waveshare-esp32-s3-eth/)) a été récupéré et croisé avec l'affectation :
- **GPIO4 → GPIO45** (zone 4, voie B) : GPIO4 retiré (TF card only), GPIO45 confirmé présent sur l'en-tête principal (broche physique 27, fonction Camera D1 inutilisée ici).
- **GPIO5 → GPIO3** (zone 5, voie A) : GPIO5 retiré (TF card only), GPIO3 confirmé présent (broche physique 14). GPIO3 est une broche de strapping JTAG sur ESP32-S3 : risque limité à la sélection de la source JTAG au démarrage (pas un risque de boot), accepté faute de broche libre alternative — à revalider si une broche plus neutre se libère.
- **GPIO21 conservé** (zone 4, voie A, broche physique 6) mais **partagé avec la LED WS2812 embarquée** de la carte Waveshare : effet cosmétique accepté (la LED de statut suivra l'état de la zone 4 POS), pas un risque électrique dur.
- **GPIO46 exclu** : présent sur l'en-tête (broche 26) mais **entrée seule** sur ESP32-S3 (ne peut pas piloter un transistor en sortie).

Les 13 autres GPIO (1, 2, 15, 16, 17, 18, 38, 39, 40, 41, 42, 47, 48) sont confirmés présents sur l'en-tête principal et libres de toute fonction réservée. Voir [11_État du projet KiCad](11_Etat-KiCad.md) pour le détail complet du connecteur et la correction de l'empreinte PCB (l'empreinte précédente modélisait à tort un connecteur 1 rangée/19 broches au lieu du vrai connecteur 2 rangées/40 broches).

Le MCP23017 et le bus I2C sont retirés de l'architecture. Prévoir des résistances de rappel définissant l'état inactif des drivers au démarrage et pendant reset.

## 3. Alimentation et interface du contrôleur

| Sujet | Proposition | Condition |
|---|---|---|
| Alimentation logique carte Waveshare | Régulateur embarqué de la carte, non sollicité par les LED d'opto | Le rail 3,3 V de la carte n'alimente que les GPIO en commande, pas le courant LED (voir ci-dessous). |
| Entrée de la carte | PoE ou 5 V local depuis HLK-5M05, sélecteur manuel SPDT | Un seul mode actif à la fois ; pas de retour possible entre sources, aucune électronique de bascule à valider. |
| I2C | Supprimé | MCP23017 retiré de l'architecture. |
| GPIO | 16 sorties logiques, voir §2 | Chaque GPIO attaque un transistor tampon, pas directement la LED d'opto. |

**Point fermé (2026-11-06) — abandon du direct-drive GPIO, ajout d'un étage tampon :** le calcul du pire cas (mode Éco = 16 LED actives simultanément, candidat MOC3063M/200 Ω, 5,6 à 13,1 mA par voie selon [l'étude direct-drive](09_Commande-directe-opto.md)) donne jusqu'à ~210 mA cumulés. Prélever ce courant directement sur le régulateur 3,3 V de la carte Waveshare — déjà sollicité par l'ESP32-S3, le W5500 et le module PoE — n'est pas raisonnable sans connaître sa capacité exacte, non documentée pour ce SKU. Décision : chaque GPIO pilote un petit transistor NPN (BC547B ou équivalent, THT TO-92) via une résistance de base ~10 kΩ (courant GPIO < 1 mA) ; le transistor commute la LED d'opto (MOC3063M + 200 Ω 1 %) alimentée par un rail 3,3 V dédié (`3V3_OPTO`), issu d'un régulateur séparé (AMS1117-3,3, THT TO-220, 1 A) sur le rail `VSYS` 5 V commun (PoE ou HLK-5M05). Cela déplace tout le budget de courant des 16 voies hors de la carte contrôleur et améliore aussi la marge de déclenchement (régulateur dédié non chargé, chute de saturation du transistor ~0,1-0,3 V au lieu de la chute VOH du GPIO) : marge estimée ≈30 % sur IFT min contre ≈12 % en direct-drive.

Ne jamais appliquer le 5 V sur la broche 3V3 ou les GPIO.

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