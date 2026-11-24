# Generateur du PCB FilPilote_8Zones (texte .kicad_pcb, format KiCad 10)
#
# Reprise complete (2026-11-09) : l'ancien script (autorouteur A* maison, straps a souder a la
# main) est abandonne en bloc - decision utilisateur. Le routage se fait via Freerouting (export
# DSN / reimport SES), pas de pathfinding ecrit a la main ici.
#
# Retour en arriere (2026-11-09, demande utilisateur) : la version qui suivait - 4 colonnes de 2
# zones + bus PHASE_PROT trace a la main avec detours/jogs - etait devenue un bricolage illisible
# pour gagner quelques mm, au prix de 55 straps. Cette version reprend le placement simple et
# propre (2 colonnes de 4 zones) qui avait 0 erreur de PLACEMENT, et vise un routage 100%
# automatique par Freerouting - rendu possible par l'assouplissement de la regle secteur/logique
# de 6mm a 2,5mm (decision utilisateur, 2026-11-09 : 6mm etait une marge de confort au-dela du
# minimum reglementaire IEC 60664-1 ~2mm, pas le minimum lui-meme, et s'est revele impossible a
# satisfaire entierement par autorouteur sur cette carte dense - voir FilPilote_8Zones.kicad_dru).
#
# Contrainte mecanique reelle du boitier CamdenBoss CNMB/9/1 (verifiee le 2026-11-09 en lisant le
# texte du PDF constructeur cnmb_series_d.pdf, pages 1-3) :
# - Longueur externe du boitier CNMB/9 : 159,2 mm. PCB utilisable : 86,5 x 156 mm (table page 1).
# - Modele "/1" = bornes exposees sur UN SEUL grand cote de la carte (le cote oppose au clip de
#   fixation rail DIN), disponible uniquement tailles 5, 6, 9 (page 1).
# - Fenetre reellement cablable sur ce cote : 113,8 mm, CENTREE sur la longueur externe (page 2).
# - Un accessoire RJ45 catalogue existe : CNMB/3/TGRJ45 (page 3), utilisable tailles 3/6/9/12, sur
#   ce MEME cote - pas besoin de cordon interne ni de percage sur mesure.
# Consequence : J1 (secteur), J2-J5 (FP1-8) ET le RJ45 du module Waveshare sortent tous par le
# MEME bord (Y=0 dans ce fichier), le module Waveshare conservant son montage compact.

param(
	[string]$OutFile = "$PSScriptRoot\..\FilPilote_8Zones.kicad_pcb",
	# Numero de version (demande utilisateur, 2026-11-09) : affiche dans le cartouche KiCad
	# (title_block/rev), pour distinguer les versions a l'ouverture sans avoir a comparer les
	# fichiers. Incremente a chaque jalon valide (voir hardware/kicad/versions/).
	[string]$Rev = "v1-placement-propre"
)

$script:uuidCounter = 100000
function New-SeqGuid {
	$script:uuidCounter++
	$h = $script:uuidCounter.ToString("x8")
	return "b0b0b0b0-$h-4b0b-8b0b-$($h)b0b0"
}

$sb = New-Object System.Text.StringBuilder
function W([string]$s) { [void]$sb.AppendLine($s) }

# ---------- Dimensions de carte (CNMB/9, voir note en tete de fichier) ----------
$BOARD_W = 156.0
$BOARD_H = 86.5
# Feuille A3 KiCad = 420 x 297 mm (paysage). Offset applique a tout le contour + connecteurs pour
# centrer sur la feuille.
$offX = (420.0 - $BOARD_W) / 2.0
$offY = (297.0 - $BOARD_H) / 2.0

W '(kicad_pcb'
W '	(version 20260206)'
W '	(generator "pcbnew")'
W '	(generator_version "10.0")'
W '	(general'
W '		(thickness 1.6)'
W '		(legacy_teardrops no)'
W '	)'
W '	(paper "A3")'
W "	(title_block"
W "		(title `"FilPilote 8 Zones`")"
W "		(date `"2026-11-09`")"
W "		(rev `"$Rev`")"
W '	)'
W '	(layers'
W '		(0 "F.Cu" signal)'
W '		(2 "B.Cu" signal)'
W '		(9 "F.Adhes" user "F.Adhesive")'
W '		(11 "B.Adhes" user "B.Adhesive")'
W '		(13 "F.Paste" user)'
W '		(15 "B.Paste" user)'
W '		(5 "F.SilkS" user "F.Silkscreen")'
W '		(7 "B.SilkS" user "B.Silkscreen")'
W '		(1 "F.Mask" user)'
W '		(3 "B.Mask" user)'
W '		(25 "Edge.Cuts" user)'
W '		(27 "Margin" user)'
W '		(31 "F.CrtYd" user "F.Courtyard")'
W '		(29 "B.CrtYd" user "B.Courtyard")'
W '		(35 "F.Fab" user)'
W '		(33 "B.Fab" user)'
W '	)'
W '	(setup'
W '		(pad_to_mask_clearance 0)'
W '	)'

# ---------- Contour de la carte (Edge.Cuts) ----------
$inv = [Globalization.CultureInfo]::InvariantCulture
$bx0 = $offX; $by0 = $offY; $bx1 = $offX + $BOARD_W; $by1 = $offY + $BOARD_H
W ('	(gr_rect (start ' + $bx0.ToString($inv) + ' ' + $by0.ToString($inv) + ') (end ' + $bx1.ToString($inv) + ' ' + $by1.ToString($inv) + ')')
W '		(stroke (width 0.15) (type default)) (fill none) (layer "Edge.Cuts")'
W "		(uuid `"$(New-SeqGuid)`")"
W '	)'
# Repere visuel (Dwgs.User, non fabrique) de la fenetre reellement cablable du boitier CNMB/9/1
# (113,8mm, centree) - aide au placement des connecteurs, pas une piece reelle.
$winX0 = $offX + 21.1; $winX1 = $offX + 134.9
W "	(gr_line (start $winX0 $by0) (end $winX0 $($by0+10)) (stroke (width 0.2) (type dash)) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`"))"
W "	(gr_line (start $winX1 $by0) (end $winX1 $($by0+10)) (stroke (width 0.2) (type dash)) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`"))"
W "	(gr_text `"Fenetre cablable CNMB/9/1 (113,8mm)`" (at $(($winX0+$winX1)/2) $($by0+12) 0) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`") (effects (font (size 1.5 1.5) (thickness 0.2))))"

# ---------- Empreintes : tables de pastilles locales (mm) ----------
$Pads = @{
	"CONN2_508" = @{ "1" = @(-2.54, 0); "2" = @(2.54, 0) }
	"GLAND2"    = @{ "1" = @(-2.54, 0); "2" = @(2.54, 0) }
	"R_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"D_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"F_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"CAP_RAD"   = @{ "1" = @(-1.5, 0);  "2" = @(1.5, 0) }
	"PSU4"      = @{ "1" = @(-5, 2.5);  "2" = @(-5, -2.5); "3" = @(5, 2.5); "4" = @(5, -2.5) }
	"REG3"      = @{ "1" = @(-2.54, 0); "2" = @(0, 0);     "3" = @(2.54, 0) }
	"DIP6"      = @{ "1" = @(-3.81, 2.54); "2" = @(-3.81, 0); "3" = @(-3.81, -2.54); "4" = @(3.81, -2.54); "5" = @(3.81, 0); "6" = @(3.81, 2.54) }
}
# En-tete Waveshare ESP32-S3-ETH : 2x20 broches format Raspberry Pi Pico verifie
# (pas 2,54 mm, rangees espacees de 17,78 mm ; broche 1 en haut a gauche, broche 40 en haut a droite).
$Pads["CONN40_PICO"] = @{}
for ($k = 1; $k -le 20; $k++) {
	$y = ($k - 1) * 2.54
	$rightPin = 41 - $k
	$Pads["CONN40_PICO"]["$k"] = @(0, $y)
	$Pads["CONN40_PICO"]["$rightPin"] = @(17.78, $y)
}
# MCP23017, DIP28 (0,6" / 15,24mm entre rangees, pas 2,54mm) : pin k a gauche <-> pin 29-k a droite,
# meme convention que le schema. Origine CENTREE (0,0 au centre du corps) : necessaire car U2 est
# tourne a 90 (une origine au coin deplace tout le corps dans une direction imprevue lors de la
# rotation au lieu de tourner autour du centre).
$Pads["DIP28"] = @{}
for ($k = 1; $k -le 14; $k++) {
	$y = ($k - 1) * 2.54 - 16.51
	$rightPin = 29 - $k
	$Pads["DIP28"]["$k"] = @(-7.62, $y)
	$Pads["DIP28"]["$rightPin"] = @(7.62, $y)
}

function Place-FP([string]$fpType, [string]$ref, [string]$value, [double]$x, [double]$y, [double]$rot, [hashtable]$netByPad) {
	$pads = $Pads[$fpType]
	$fpUuid = New-SeqGuid
	W "	(footprint `"FP:$fpType`""
	W '		(layer "F.Cu")'
	W "		(uuid `"$fpUuid`")"
	W "		(at $x $y $rot)"
	W "		(property `"Reference`" `"$ref`" (at 0 -4 0) (layer `"F.SilkS`") (uuid `"$(New-SeqGuid)`") (effects (font (size 0.8 0.8) (thickness 0.12))))"
	W "		(property `"Value`" `"$value`" (at 0 4 0) (layer `"F.Fab`") (uuid `"$(New-SeqGuid)`") (effects (font (size 0.8 0.8) (thickness 0.12))))"
	W '		(attr through_hole)'
	foreach ($padNum in ($pads.Keys | Sort-Object { [int]$_ })) {
		$off = $pads[$padNum]
		$net = $netByPad[$padNum]
		if ($net) {
			W "		(pad `"$padNum`" thru_hole circle (at $($off[0]) $($off[1])) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (net `"$net`") (uuid `"$(New-SeqGuid)`"))"
		} else {
			W "		(pad `"$padNum`" thru_hole circle (at $($off[0]) $($off[1])) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (uuid `"$(New-SeqGuid)`"))"
		}
	}
	$xs = $pads.Values | ForEach-Object { $_[0] }
	$ys = $pads.Values | ForEach-Object { $_[1] }
	$minX = ($xs | Measure-Object -Minimum).Minimum - 1.0
	$maxX = ($xs | Measure-Object -Maximum).Maximum + 1.0
	$minY = ($ys | Measure-Object -Minimum).Minimum - 1.0
	$maxY = ($ys | Measure-Object -Maximum).Maximum + 1.0
	W "		(fp_rect (start $minX $minY) (end $maxX $maxY) (stroke (width 0.05) (type default)) (fill none) (layer `"F.CrtYd`") (uuid `"$(New-SeqGuid)`"))"
	W '	)'
}

# ======================================================================
# Contour + connecteurs (J1, JWS, J2-J5), tous rot=0, alignes sur le meme bord (Y=5).
# ======================================================================
Place-FP "GLAND2" "J1" "MAINS_IN" ($offX + 10) ($offY + 5) 0 @{ "1" = "MAINS_L"; "2" = "MAINS_N" }

Place-FP "CONN40_PICO" "JWS" "Waveshare_ESP32-S3-ETH_40pin" ($offX + 24) ($offY + 5) 0 @{
	"2" = "VSYS"; "3" = "GND"
	"15" = "SCL"; "16" = "SDA"
}

# J2-J5 (FP1-FP8) : accoles pour ne former qu'un seul bloc continu, comme les segments
# CNMB/3/TG508 reels qui se posent bout a bout. Pas de 10,16mm = largeur exacte d'un bloc 2 poles
# a 5,08mm.
$fpPitch = 10.16
$fpStart = 55
Place-FP "CONN2_508" "J2" "FP1_FP2" ($offX + $fpStart) ($offY + 5) 0 @{ "1" = "FP1"; "2" = "FP2" }
Place-FP "CONN2_508" "J3" "FP3_FP4" ($offX + $fpStart + $fpPitch) ($offY + 5) 0 @{ "1" = "FP3"; "2" = "FP4" }
Place-FP "CONN2_508" "J4" "FP5_FP6" ($offX + $fpStart + 2 * $fpPitch) ($offY + 5) 0 @{ "1" = "FP5"; "2" = "FP6" }
Place-FP "CONN2_508" "J5" "FP7_FP8" ($offX + $fpStart + 3 * $fpPitch) ($offY + 5) 0 @{ "1" = "FP7"; "2" = "FP8" }

# ======================================================================
# Alimentation (F0/PS1/DPWR/U1/C1/C2) : colonne gauche, sous J1.
# ======================================================================
Place-FP "F_Axial" "F0" "250mA_T_250V" ($offX + 10) ($offY + 20) 0 @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place-FP "PSU4" "PS1" "HLK-5M05" ($offX + 10) ($offY + 35) 0 @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
Place-FP "D_Axial" "DPWR" "1N4007" ($offX + 10) ($offY + 50) 0 @{ "1" = "LOCAL_5V"; "2" = "VSYS" }
# Regulateur dedie 3,3V (U1) + decouplage (C1 entree/VSYS, C2 sortie/3V3_OPTO) - ferme le risque
# "capacite non documentee du regulateur Waveshare", voir docs/02 §3.
Place-FP "REG3" "U1" "AMS1117-3.3" ($offX + 10) ($offY + 63) 0 @{ "1" = "VSYS"; "2" = "GND"; "3" = "3V3_OPTO" }
Place-FP "CAP_RAD" "C1" "10uF" ($offX + 10) ($offY + 71) 0 @{ "1" = "VSYS"; "2" = "GND" }
Place-FP "CAP_RAD" "C2" "10uF" ($offX + 10) ($offY + 78) 0 @{ "1" = "3V3_OPTO"; "2" = "GND" }

# ---------- Expandeur I2C MCP23017 (U2), decale de l'axe du module Waveshare ----------
# Deplace 34->55 (demande utilisateur, 2026-11-09) : a X=34, U2 restait exactement dans l'axe de
# JWS (qui s'etend de X=24 a ~44) - pas de probleme electrique (U2 est sous JWS, Y different), mais
# gene visuellement. A X=55, clairement a droite de JWS, avant la colonne de zones (X=96).
Place-FP "DIP28" "U2" "MCP23017" ($offX + 55) ($offY + 65) 90 @{
	"9" = "3V3_OPTO"; "10" = "GND"; "12" = "SCL"; "13" = "SDA"
	"15" = "GND"; "16" = "GND"; "17" = "GND"; "18" = "3V3_OPTO"
	"21" = "DRV_Z1A"; "22" = "DRV_Z1B"; "23" = "DRV_Z2A"; "24" = "DRV_Z2B"
	"25" = "DRV_Z3A"; "26" = "DRV_Z3B"; "27" = "DRV_Z4A"; "28" = "DRV_Z4B"
	"1" = "DRV_Z5A"; "2" = "DRV_Z5B"; "3" = "DRV_Z6A"; "4" = "DRV_Z6B"
	"5" = "DRV_Z7A"; "6" = "DRV_Z7B"; "7" = "DRV_Z8A"; "8" = "DRV_Z8B"
}
Place-FP "CAP_RAD" "C3" "100nF" ($offX + 55) ($offY + 78) 0 @{ "1" = "3V3_OPTO"; "2" = "GND" }
Place-FP "R_Axial" "RPU1" "4.7k" ($offX + 46) ($offY + 30) 90 @{ "1" = "SDA"; "2" = "3V3_OPTO" }
Place-FP "R_Axial" "RPU2" "4.7k" ($offX + 46) ($offY + 40) 90 @{ "1" = "SCL"; "2" = "3V3_OPTO" }

# ======================================================================
# 8 zones : 2 colonnes de 4 zones (gauche = zones 1-4 / GPA, droite = zones 5-8 / GPB).
# Chaque canal = 3 composants en pile horizontale (RL -> OC -> D), rotation 90, SAUF l'optotriac
# (DIP6, jamais tourne - isolement secteur/logique sur son axe X naturel). Plus de RS/F par voie
# (retires, decision utilisateur).
# Colonnes a 96/122 (apres le bloc J2-J5, qui finit a 90,56) : distance X seule (>40mm) suffit
# largement a respecter l'isolement secteur/logique quelle que soit la distance en Y.
# ======================================================================
# gapThin/gapOC elargis 7/8 -> 10/10 puis REVENU a 7/8 (2026-11-09) : l'elargissement a en realite
# AGGRAVE le resultat (86 -> 100-103 violations, verifie sur 2 executions Freerouting) - Freerouting
# etant un algorithme glouton/heuristique, plus de place ne garantit pas un meilleur resultat global,
# juste un chemin different (confirme empiriquement, pas suppose). 7/8 retenu comme meilleure valeur
# trouvee a ce jour.
$gapThin = 7.0; $gapOC = 8.0
$offRL = 0.0; $offOC = $offRL + $gapOC; $offD = $offOC + $gapThin
# rowPitch : RL/D tournes a 90 ont leurs 2 pastilles alignees sur Y (+-3,81mm du centre), donc un
# rectangle d'encombrement (marge courtyard +1mm) de +-4,81mm en Y - 2 rangees consecutives ont
# besoin d'au moins 9,62mm d'ecart centre-a-centre pour ne pas se chevaucher ; 9,8mm retenu.
$rowPitch = 9.8
$bandY0 = 12.0
$zoneLeftX0 = 96.0; $zoneRightX0 = 122.0

$zoneDrv = @{
	1 = @{ P = "DRV_Z1A"; N = "DRV_Z1B" }; 2 = @{ P = "DRV_Z2A"; N = "DRV_Z2B" }
	3 = @{ P = "DRV_Z3A"; N = "DRV_Z3B" }; 4 = @{ P = "DRV_Z4A"; N = "DRV_Z4B" }
	5 = @{ P = "DRV_Z5A"; N = "DRV_Z5B" }; 6 = @{ P = "DRV_Z6A"; N = "DRV_Z6B" }
	7 = @{ P = "DRV_Z7A"; N = "DRV_Z7B" }; 8 = @{ P = "DRV_Z8A"; N = "DRV_Z8B" }
}

for ($z = 1; $z -le 8; $z++) {
	$bandIdx = ($z - 1) % 4
	$isRightZone = ($z -gt 4)
	$x0 = $offX + $(if ($isRightZone) { $zoneRightX0 } else { $zoneLeftX0 })

	foreach ($ch in @("P", "N")) {
		$rowIdx = $bandIdx * 2 + $(if ($ch -eq "P") { 0 } else { 1 })
		$cy = $offY + $bandY0 + $rowIdx * $rowPitch
		$drvNet = $zoneDrv[$z][$ch]
		$suffix = "Z${z}${ch}"

		Place-FP "R_Axial" "RL$suffix" "200_1pct" ($x0 + $offRL) $cy 90 @{ "1" = $drvNet; "2" = "LEDA_$suffix" }
		Place-FP "DIP6" "OC$suffix" "MOC3063M" ($x0 + $offOC) $cy 0 @{ "1" = "LEDA_$suffix"; "2" = "GND"; "4" = "MT1D_$suffix"; "6" = "PHASE_PROT" }
		if ($ch -eq "P") {
			Place-FP "D_Axial" "D$suffix" "1N4007" ($x0 + $offD) $cy 90 @{ "1" = "MT1D_$suffix"; "2" = "FP$z" }
		} else {
			Place-FP "D_Axial" "D$suffix" "1N4007" ($x0 + $offD) $cy 90 @{ "1" = "FP$z"; "2" = "MT1D_$suffix" }
		}
	}
}

W '	(embedded_fonts no)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path -Path (Split-Path $OutFile -Parent)).Path + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
