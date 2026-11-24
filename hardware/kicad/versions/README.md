# Versions du PCB FilPilote_8Zones

Chaque jalon validé (DRC/ERC vérifié) est sauvegardé ici dans son propre dossier, en plus d'être
visible dans le numéro de révision affiché par KiCad (cartouche, en bas à droite du schéma/PCB).
Pour ouvrir une ancienne version : copier son `.kicad_pro`/`.kicad_sch`/`.kicad_pcb` par-dessus les
fichiers à la racine de `hardware/kicad/`, ou ouvrir directement le `.kicad_pro` du dossier de
version dans KiCad.

| Version | Contenu | Statut |
|---|---|---|
| `v1-placement-propre` | Schéma MCP23017 (étape 2) + contour/connecteurs (étape 3) + placement 8 zones en 2 colonnes de 4 (étape 4). Aucun routage. | 0 erreur ERC/DRC réelle, vérifié le 2026-11-09. |
| `v2b-routage-81pts` | Idem v1 + routage complet (122/122 connexions, Freerouting + corrections locales vérifiées une par une). Règle secteur/logique assouplie de 6mm à 2,5mm (décision utilisateur). | 0 connexion manquante. **81 points de clearance réels restants**, plafond réel de l'automatisation sur cette carte : plusieurs stratégies testées (réglages de règle, élargissement des canaux, corrections locales multi-essais) stagnent toutes entre 80 et 105 — voir [docs/11_Etat-KiCad.md](../../../docs/11_Etat-KiCad.md). Finition manuelle dans KiCad recommandée avant fabrication. |

Les numéros de révision sont passés aux scripts `tools/generate_schematic.ps1` et
`tools/generate_pcb.ps1` via le paramètre `-Rev` (ex. `-Rev "v2-routage-complet"`), qui l'écrit
dans le cartouche KiCad (`title_block/rev`) de chaque fichier généré.
