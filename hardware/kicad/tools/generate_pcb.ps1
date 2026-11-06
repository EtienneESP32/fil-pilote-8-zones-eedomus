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
# Reoriente le 2026-11-07 puis recompacte le meme jour apres etude d'une reference reelle :
# CamdenBoss CNMB (norme DIN 43880, quasi tous fabricants), section fixe 90mm externe /
# 86,5mm de PCB utilisable, longueur qui scale avec le nombre de modules. CNMB/12 (212,1mm,
# decoupe RJ45 et guide-fils 5,08mm disponibles en piece standard) convient a notre longueur.
# Carte recompactee a 192 x 85 mm (sous les 86,5mm utilisables, marge ~1,5mm) pour tenir en
# carte unique plutot qu'un empilement de 2 PCB. Toujours indicatif tant que la reference
# exacte n'est pas commandee (voir docs/04).
$BOARD_W = 192.0
$BOARD_H = 86.0

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
# En-tete Waveshare ESP32-S3-ETH : 2x20 broches format Raspberry Pi Pico verifie
# (pas 2,54 mm, rangees espacees de 17,78 mm ; broche 1 en haut a gauche, broche 40 en haut a droite).
$Pads["CONN40_PICO"] = @{}
for ($k = 1; $k -le 20; $k++) {
	$y = ($k - 1) * 2.54
	$rightPin = 41 - $k
	$Pads["CONN40_PICO"]["$k"] = @(0, $y)
	$Pads["CONN40_PICO"]["$rightPin"] = @(17.78, $y)
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
# PLACEMENT (reoriente 2026-11-07, voir note de gabarit ci-dessus)
# Colonne gauche : en-tete Waveshare + conditionnement alimentation.
# Centre : 8 zones en 4 bandes horizontales (une par index GPIO) x 2 zones cote a cote.
# Colonne droite : connectique secteur/FP en bord de carte.
# ======================================================================

# ---------- Colonne gauche : en-tete Waveshare (empreinte reelle verifiee 2026-11-07) ----------
# Format Raspberry Pi Pico : 2x20 broches, pas 2,54 mm, rangees espacees de 17,78 mm.
# GND/VSYS/VBUS/3V3/3V3_EN/RUN et les broches non utilisees (GPIO0/43/44/19/20/33-37/46) sont NC.
Place-FP "CONN40_PICO" "JWS" "Waveshare_ESP32-S3-ETH_40pin" 8 3 0 @{
	"2" = "VSYS"; "3" = "GND"
	"6" = "GPIO21"; "7" = "GPIO17"; "9" = "GPIO16"; "10" = "GPIO18"; "12" = "GPIO15"
	"14" = "GPIO3"; "15" = "GPIO2"; "16" = "GPIO1"
	"24" = "GPIO48"; "25" = "GPIO47"; "27" = "GPIO45"
	"29" = "GPIO42"; "30" = "GPIO41"; "31" = "GPIO40"; "32" = "GPIO39"; "34" = "GPIO38"
}

# ---------- Colonne gauche (suite) : conditionnement alimentation, sous l en-tete ----------
Place-FP "SW_SPDT_3" "SW1" "SPDT" 13 56 0 @{ "1" = "LOCAL_5V"; "2" = "VSYS"; "3" = "POE_5V_A_CONFIRMER" }
Place-FP "TO220_3" "U1" "AMS1117-3.3" 13 63 0 @{ "1" = "VSYS"; "2" = "GND"; "3" = "3V3_OPTO" }
Place-FP "CAP_Radial" "C1" "100uF" 13 70 0 @{ "1" = "VSYS"; "2" = "GND" }
Place-FP "CAP_Radial" "C2" "100uF" 13 77 0 @{ "1" = "3V3_OPTO"; "2" = "GND" }

# ---------- Colonne droite : connectique secteur et sorties FP (bord de carte) ----------
# J1/J2-J5 recoivent du cablage externe : rotation 90 pour que l'axe des 2 broches soit
# perpendiculaire au bord droit de la carte (sortie fil vers l'exterieur du boitier, X croissant),
# au lieu d'un axe parallele au bord comme dans la premiere implantation (signale par l'utilisateur).
# F0 et PS1 n'ont pas de cablage externe direct (fusible et module internes), orientation inchangee.
Place-FP "CONN2_508" "J1" "MAINS_IN" 187 6 90 @{ "1" = "MAINS_L"; "2" = "MAINS_N" }
Place-FP "F_Axial" "F0" "250mA_T" 182 15 0 @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place-FP "PSU4" "PS1" "HLK-5M05" 182 25 0 @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
Place-FP "CONN2_508" "J2" "FP1_FP2" 187 40 90 @{ "1" = "FP1"; "2" = "FP2" }
Place-FP "CONN2_508" "J3" "FP3_FP4" 187 50 90 @{ "1" = "FP3"; "2" = "FP4" }
Place-FP "CONN2_508" "J4" "FP5_FP6" 187 60 90 @{ "1" = "FP5"; "2" = "FP6" }
Place-FP "CONN2_508" "J5" "FP7_FP8" 187 70 90 @{ "1" = "FP7"; "2" = "FP8" }

# ---------- 8 zones : 4 bandes horizontales (une par index GPIO 0-3) x 2 zones cote a cote ----------
$zoneGpio = @{
	1 = @{ P = "GPIO1";  N = "GPIO2"  }
	2 = @{ P = "GPIO15"; N = "GPIO16" }
	3 = @{ P = "GPIO17"; N = "GPIO18" }
	4 = @{ P = "GPIO21"; N = "GPIO45" }
	5 = @{ P = "GPIO3";  N = "GPIO38" }
	6 = @{ P = "GPIO39"; N = "GPIO40" }
	7 = @{ P = "GPIO41"; N = "GPIO42" }
	8 = @{ P = "GPIO47"; N = "GPIO48" }
}

# Chaque zone (2 canaux) occupe une pile horizontale de 7 composants, pas $step, rotation 90
# (pastilles perpendiculaires au sens d empilement -> pas de collision). $chOffset separe les
# 2 canaux en Y. 4 bandes espacees de $bandPitch couvrent les 4 index GPIO (zone N et zone N+4
# partagent la meme bande, cote a cote horizontalement).
$chOffset = 11.0
$step = 9.0
$bandPitch = 21.0
$bandY0 = 6.0
$zoneLeftX0 = 35.0
$zoneRightX0 = 100.0

for ($z = 1; $z -le 8; $z++) {
	$bandIdx = ($z - 1) % 4
	$isRightZone = ($z -gt 4)
	$y0 = $bandY0 + $bandIdx * $bandPitch
	$x0 = if ($isRightZone) { $zoneRightX0 } else { $zoneLeftX0 }

	foreach ($ch in @("P", "N")) {
		$cy = $y0 + ($(if ($ch -eq "P") { 0 } else { $chOffset }))
		$gpioNet = $zoneGpio[$z][$ch]
		$suffix = "Z${z}${ch}"

		Place-FP "R_Axial" "RB$suffix" "10k" ($x0) $cy 90 @{ "1" = $gpioNet; "2" = "QB_$suffix" }
		Place-FP "TO92_3" "Q$suffix" "BC547B" ($x0 + $step) $cy 90 @{ "1" = "QB_$suffix"; "2" = "LEDK_$suffix"; "3" = "GND" }
		Place-FP "R_Axial" "RL$suffix" "200_1pct" ($x0 + 2 * $step) $cy 90 @{ "1" = "3V3_OPTO"; "2" = "LEDA_$suffix" }

		# Optotriac : transition logique (pattes LED, cote gauche de la pile) / secteur (pattes triac, cote droit)
		$ocX = $x0 + 3 * $step
		Place-FP "DIP6" "OC$suffix" "MOC3063M" $ocX $cy 90 @{ "1" = "LEDA_$suffix"; "2" = "LEDK_$suffix"; "4" = "MT1D_$suffix"; "6" = "FMT2_$suffix" }

		Place-FP "R_Axial" "RS$suffix" "4.7k" ($ocX + $step) $cy 90 @{ "1" = "PHASE_PROT"; "2" = "RSF_$suffix" }
		Place-FP "F_Axial" "F$suffix" "100mA_PTC" ($ocX + 2 * $step) $cy 90 @{ "1" = "RSF_$suffix"; "2" = "FMT2_$suffix" }

		if ($ch -eq "P") {
			Place-FP "D_Axial" "D$suffix" "1N4007" ($ocX + 3 * $step) $cy 90 @{ "1" = "MT1D_$suffix"; "2" = "FP$z" }
		} else {
			Place-FP "D_Axial" "D$suffix" "1N4007" ($ocX + 3 * $step) $cy 90 @{ "1" = "FP$z"; "2" = "MT1D_$suffix" }
		}
	}
}

# Lignes de reperage visuelles delimitant chaque bande de zones
for ($b = 0; $b -le 4; $b++) {
	Draw-IsoLine ($bandY0 + $b * $bandPitch - 3)
}

W '	(embedded_fonts no)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$resolvedDir = (Resolve-Path -Path (Split-Path $OutFile -Parent)).Path
[System.IO.File]::WriteAllText($resolvedDir + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
