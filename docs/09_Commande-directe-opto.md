# Étude préliminaire : GPIO direct vers optocoupleur

**Statut :** étude de faisabilité; valeurs de fabrication non gelées.

## Conclusion

Une GPIO ESP32-S3 peut piloter directement la LED d'un optocoupleur via une résistance de limitation. Un transistor intermédiaire n'est pas obligatoire par principe. Il faut vérifier à la fois le courant de déclenchement garanti de l'opto, la tension haute minimale de la GPIO sous charge et le courant total si les 16 voies sont actives.

Le JSON EasyEDA contient 16 MOC3041M et 16 résistances de 330 Ω côté LED. Cette paire n'est pas démontrée fiable pour une commande directe.

## Vérification de la paire actuelle

Le MOC3041M a un courant de déclenchement LED maximal `IFT` de 15 mA dans la datasheet fabricant. Avec les valeurs indicatives du projet :

- courant nominal estimé : `(3,3 V - 1,2 V) / 330 Ω = 6,4 mA`;
- courant à garantir avec 16 voies : jusqu'à `16 × 15 mA = 240 mA` si la conception doit satisfaire le `IFT` maximal du MOC3041M.

Les 6,4 mA estimés peuvent déclencher certains exemplaires dans certaines conditions, mais ne garantissent pas le déclenchement de la référence MOC3041M sur ses tolérances. Réduire simplement la résistance pour atteindre 15 mA augmenterait fortement le courant total demandé aux GPIO et au rail 3,3 V.

## Candidat de conception directe

Étudier un optotriac zero-cross à seuil LED plus faible, par exemple le **MOC3063M** (IFT maximal annoncé 5 mA, sortie 600 V à confirmer sur la variante effectivement achetée), avec une résistance dédiée en série pour chaque LED.

Exemple de calcul de départ, à confirmer par les fiches exactes :

- `RLED = 200 Ω, 1 %`;
- enveloppe de calcul illustrative : `VOH_GPIO,min = 2,64 V`, `VF_LED,max = 1,5 V`, `VDD,max = 3,6 V`;
- courant minimum estimé : `(2,64 - 1,5) / 202 = 5,6 mA`, supérieur à un IFT maximal de 5 mA;
- courant maximal conservateur estimé : `(3,6 - 1,0) / 198 = 13,1 mA` par canal;
- somme maximale si 16 voies conduisent : environ `210 mA` depuis le rail logique.

Ces chiffres sont une enveloppe préliminaire, pas une preuve de conformité : les valeurs `VOH`, `VF`, `IFT`, leur température et le courant continu cumulé doivent être confirmés dans les datasheets fabricant et le schéma de la carte. Si l'ESP32-S3 ou son régulateur embarqué ne garantit pas cette somme avec marge, réduire le courant à l'aide d'un optocoupleur mieux adapté ou ajouter des buffers externes.

## Conditions de validation avant gel

1. Vérifier les valeurs `IFT,max`, `VF,max`, `VDRM` et les conditions de température du composant exact commandé.
2. Vérifier le `VOH` garanti de la GPIO pour le courant choisi, ainsi que les limites par broche et le budget de courant total de l'ESP32-S3.
3. Vérifier que le régulateur 3,3 V du Waveshare peut fournir la consommation de la carte plus le pire cas des 16 LED; le PoE/HLK-PM01 devra être dimensionné pour ce pire cas.
4. Ajouter une résistance série par opto et définir un état inactif matériel pendant reset/boot. Éviter les GPIO de strapping ou les signaux qui togglent avant l'initialisation.
5. Tester chaque canal, puis 16 canaux actifs simultanément, à basse tension et sans raccordement au secteur avant toute validation de puissance.
6. Revalider la topologie optotriac/diodes et les six ordres fil pilote séparément; le choix d'un opto à IFT plus faible ne valide pas à lui seul la sortie secteur.

## Références fabricant à contrôler

- [onsemi MOC3041M datasheet](https://www.onsemi.com/pdf/datasheet/moc3041m-d.pdf)
- [onsemi MOC3063M datasheet](https://www.onsemi.com/pdf/datasheet/moc3063m-d.pdf)
- [Espressif ESP32-S3 datasheet](https://documentation.espressif.com/esp32-s3_datasheet_en.pdf)
