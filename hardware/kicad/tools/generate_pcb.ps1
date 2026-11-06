# Generateur du PCB FilPilote_8Zones (texte .kicad_pcb, format KiCad 10)
# Place les empreintes selon les principes de separation secteur/logique des docs/04.
# Ne route aucune piste : routage a faire dans l'editeur interactif (etape suivante).

param(
	[string]$OutFile = "$PSScriptRoot\..\FilPilote_8Zones.kicad_pcb"
)

$script:uuidCounter = 100000
function New-SeqGuid {
	$script:uuidCounter++
	$h = $script:uuidCounter.ToString("x8")
	return "b0b0b0b0-$h-4b0b-8b0b-$($h)b0b0"
}

$sb = New-Object System.Text.StringBuilder
function W([string]$s) { [void]$sb.AppendLine($s) }

# ---------- Dimensions de carte ----------
# Largeur fixee par le rail DIN 6 modules (105 mm). Hauteur recalculee a partir de
# l'encombrement reel des composants THT + la bande d'isolement 6 mm (voir docs/04) ;
# depasse le 85 mm indicatif de la source, qui n'etait pas valide par le boitier (point ouvert).
$BOARD_W = 105.0
$BOARD_H = 180.0

W '(kicad_pcb'
W '	(version 20260206)'
W '	(generator "pcbnew")'
W '	(generator_version "10.0")'
W '	(general'
W '		(thickness 1.6)'
W '		(legacy_teardrops no)'
W '	)'
W '	(paper "A3")'
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
W ('	(gr_rect (start 0 0) (end ' + $BOARD_W.ToString([Globalization.CultureInfo]::InvariantCulture) + ' ' + $BOARD_H.ToString([Globalization.CultureInfo]::InvariantCulture) + ')')
W '		(stroke (width 0.15) (type default)) (fill none) (layer "Edge.Cuts")'
W "		(uuid `"$(New-SeqGuid)`")"
W '	)'
# Ligne de reperage silkscreen de la bande d isolement secteur/logique (6 mm, a 2 hauteurs : limite haute et basse de la zone de recouvrement)
function Draw-IsoLine([double]$y) {
	W "	(gr_line (start 2 $y) (end $($BOARD_W-2) $y) (stroke (width 0.2) (type dash)) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`"))"
}

# ---------- Empreintes : tables de pastilles locales (mm) ----------
$Pads = @{
	"R_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"D_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"F_Axial"   = @{ "1" = @(-3.81, 0); "2" = @(3.81, 0) }
	"CAP_Radial" = @{ "1" = @(-2.54, 0); "2" = @(2.54, 0) }
	"CONN2_508" = @{ "1" = @(-2.54, 0); "2" = @(2.54, 0) }
	"TO92_3"    = @{ "1" = @(-2.54, 0); "2" = @(0, 0); "3" = @(2.54, 0) }
	"TO220_3"   = @{ "1" = @(-2.54, 0); "2" = @(0, 0); "3" = @(2.54, 0) }
	"SW_SPDT_3" = @{ "1" = @(-2.54, 0); "2" = @(0, 0); "3" = @(2.54, 0) }
	"PSU4"      = @{ "1" = @(-5, 2.5); "2" = @(-5, -2.5); "3" = @(5, 2.5); "4" = @(5, -2.5) }
	"DIP6"      = @{ "1" = @(-3.81, 2.54); "2" = @(-3.81, 0); "3" = @(-3.81, -2.54); "4" = @(3.81, -2.54); "5" = @(3.81, 0); "6" = @(3.81, 2.54) }
}
$Pads["CONN19_254"] = @{}
for ($k = 1; $k -le 19; $k++) { $Pads["CONN19_254"]["$k"] = @((($k - 1) * 2.54), 0) }

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
		$px = $off[0]; $py = $off[1]
		if ($net) {
			W "		(pad `"$padNum`" thru_hole circle (at $px $py) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (net `"$net`") (uuid `"$(New-SeqGuid)`"))"
		} else {
			W "		(pad `"$padNum`" thru_hole circle (at $px $py) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (uuid `"$(New-SeqGuid)`"))"
		}
	}
	# Courtyard simple (rectangle englobant les pastilles + marge 1mm) pour permettre au DRC de verifier les recouvrements
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
# PLACEMENT
# Bande logique (haut, Y petit) / bande d isolement 6 mm / bande secteur (bas, Y grand)
# ======================================================================

# ---------- Bande secteur basse : alimentation (sous les deux rangees de zones) ----------
Place-FP "CONN2_508" "J1" "MAINS_IN" 15 155 0 @{ "1" = "MAINS_L"; "2" = "MAINS_N" }
Place-FP "F_Axial" "F0" "250mA_T" 30 155 0 @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place-FP "PSU4" "PS1" "HLK-5M05" 50 155 0 @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
Place-FP "CONN2_508" "J2" "FP1_FP2" 15 168 0 @{ "1" = "FP1"; "2" = "FP2" }
Place-FP "CONN2_508" "J3" "FP3_FP4" 35 168 0 @{ "1" = "FP3"; "2" = "FP4" }
Place-FP "CONN2_508" "J4" "FP5_FP6" 55 168 0 @{ "1" = "FP5"; "2" = "FP6" }
Place-FP "CONN2_508" "J5" "FP7_FP8" 75 168 0 @{ "1" = "FP7"; "2" = "FP8" }

# ---------- Bande logique haute : conditionnement alimentation + en-tete Waveshare ----------
Place-FP "SW_SPDT_3" "SW1" "SPDT" 10 13 0 @{ "1" = "LOCAL_5V"; "2" = "VSYS"; "3" = "POE_5V" }
Place-FP "TO220_3" "U1" "AMS1117-3.3" 25 13 0 @{ "1" = "VSYS"; "2" = "GND"; "3" = "3V3_OPTO" }
Place-FP "CAP_Radial" "C1" "100uF" 36 13 0 @{ "1" = "VSYS"; "2" = "GND" }
Place-FP "CAP_Radial" "C2" "100uF" 46 13 0 @{ "1" = "3V3_OPTO"; "2" = "GND" }
Place-FP "CONN19_254" "JWS" "Waveshare_header" 10 3 0 @{
	"1" = "GND"; "2" = "VSYS"; "3" = "POE_5V"
	"4" = "GPIO1"; "5" = "GPIO2"; "6" = "GPIO4"; "7" = "GPIO5"; "8" = "GPIO15"; "9" = "GPIO16"; "10" = "GPIO17"
	"11" = "GPIO18"; "12" = "GPIO21"; "13" = "GPIO38"; "14" = "GPIO39"; "15" = "GPIO40"; "16" = "GPIO41"
	"17" = "GPIO42"; "18" = "GPIO47"; "19" = "GPIO48"
}

# ---------- 8 zones, grille 4 colonnes x 2 lignes ----------
$zoneGpio = @{
	1 = @{ P = "GPIO1";  N = "GPIO2"  }
	2 = @{ P = "GPIO15"; N = "GPIO16" }
	3 = @{ P = "GPIO17"; N = "GPIO18" }
	4 = @{ P = "GPIO21"; N = "GPIO4"  }
	5 = @{ P = "GPIO5";  N = "GPIO38" }
	6 = @{ P = "GPIO39"; N = "GPIO40" }
	7 = @{ P = "GPIO41"; N = "GPIO42" }
	8 = @{ P = "GPIO47"; N = "GPIO48" }
}

# Chaque colonne de zone (2 canaux) occupe 24 mm de large ; 4 colonnes = 96 mm (tient dans 105 mm).
# Chaque ligne de zones s etend verticalement de la bande logique (haut) a la bande secteur (bas),
# en traversant la bande d isolement avec l optotriac.
$colW = 24.0
$chOffset = 12.0  # ecart entre les deux canaux (POS/NEG) d'une meme colonne de zone
$step = 9.0       # pas vertical entre composants d'une pile de canal (aucune rotation -> faible emprise en Y)
$row1Y0 = 20.0    # ligne de zones 1-4 : debut (cote logique) de la pile verticale
$row2Y0 = 90.0    # ligne de zones 5-8 : debut, sous la ligne 1 (54 mm de pile + marge mecanique)

for ($z = 1; $z -le 8; $z++) {
	$col = ($z - 1) % 4
	$rowIsSecond = ($z -gt 4)
	$blockX = 8 + $col * $colW
	$y0 = if ($rowIsSecond) { $row2Y0 } else { $row1Y0 }

	foreach ($ch in @("P", "N")) {
		$cx = $blockX + ($(if ($ch -eq "P") { 0 } else { $chOffset }))
		$gpioNet = $zoneGpio[$z][$ch]
		$suffix = "Z${z}${ch}"

		# Aucune rotation : ces empreintes ont une faible emprise verticale a plat (pastilles alignees en X),
		# ce qui permet un pas de pile compact tout en restant a l'interieur de la colonne de 24 mm.
		Place-FP "R_Axial" "RB$suffix" "10k" $cx ($y0) 0 @{ "1" = $gpioNet; "2" = "QB_$suffix" }
		Place-FP "TO92_3" "Q$suffix" "BC547B" $cx ($y0 + $step) 0 @{ "1" = "QB_$suffix"; "2" = "LEDK_$suffix"; "3" = "GND" }
		Place-FP "R_Axial" "RL$suffix" "200_1pct" $cx ($y0 + 2 * $step) 0 @{ "1" = "3V3_OPTO"; "2" = "LEDA_$suffix" }

		# Optotriac : fait la transition entre la logique (pattes LED, cote haut/logique) et le secteur (pattes triac, cote bas/secteur)
		$ocY = $y0 + 3 * $step
		Place-FP "DIP6" "OC$suffix" "MOC3063M" $cx $ocY 0 @{ "1" = "LEDA_$suffix"; "2" = "LEDK_$suffix"; "4" = "MT1D_$suffix"; "6" = "FMT2_$suffix" }

		Place-FP "R_Axial" "RS$suffix" "4.7k" $cx ($ocY + $step) 0 @{ "1" = "PHASE_PROT"; "2" = "RSF_$suffix" }
		Place-FP "F_Axial" "F$suffix" "100mA_PTC" $cx ($ocY + 2 * $step) 0 @{ "1" = "RSF_$suffix"; "2" = "FMT2_$suffix" }

		if ($ch -eq "P") {
			Place-FP "D_Axial" "D$suffix" "1N4007" $cx ($ocY + 3 * $step) 0 @{ "1" = "MT1D_$suffix"; "2" = "FP$z" }
		} else {
			Place-FP "D_Axial" "D$suffix" "1N4007" $cx ($ocY + 3 * $step) 0 @{ "1" = "FP$z"; "2" = "MT1D_$suffix" }
		}
	}
}

# Lignes de reperage visuelles autour de la rangee d optotriacs de chaque ligne de zones
Draw-IsoLine ($row1Y0 + 3 * $step - 3)
Draw-IsoLine ($row1Y0 + 3 * $step + 3)
Draw-IsoLine ($row2Y0 + 3 * $step - 3)
Draw-IsoLine ($row2Y0 + 3 * $step + 3)

W '	(embedded_fonts no)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$resolvedDir = (Resolve-Path -Path (Split-Path $OutFile -Parent)).Path
[System.IO.File]::WriteAllText($resolvedDir + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
