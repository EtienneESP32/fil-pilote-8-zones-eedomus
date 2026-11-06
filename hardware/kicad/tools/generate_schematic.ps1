# Générateur du schéma FilPilote_8Zones (texte .kicad_sch, format KiCad 10)
# Usage : powershell -File generate_schematic.ps1 -OutFile ..\FilPilote_8Zones.kicad_sch -ProjectName FilPilote_8Zones

param(
	[string]$OutFile = "$PSScriptRoot\..\FilPilote_8Zones.kicad_sch",
	[string]$ProjectName = "FilPilote_8Zones"
)

$script:uuidCounter = 0
function New-SeqGuid {
	# UUID déterministe (reproductible entre générations) basé sur un compteur, format valide RFC4122-like
	$script:uuidCounter++
	$h = $script:uuidCounter.ToString("x8")
	return "a0a0a0a0-$h-4a0a-8a0a-$($h)a0a0"
}

# Table des pins locales (point de connexion = valeur "at" dans la lib) par lib_id
$PinOffsets = @{
	"R2"     = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"D2"     = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"F2"     = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"CONN2"  = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"CAP2"   = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"Q3"     = @{ "1" = @(-5.08, 0);    "2" = @(0, 5.08);    "3" = @(0, -5.08) }
	"OC6"    = @{ "1" = @(-6.35, 2.54); "2" = @(-6.35, 0);   "3" = @(-6.35, -2.54); "4" = @(6.35, -2.54); "5" = @(6.35, 0); "6" = @(6.35, 2.54) }
	"REG3"   = @{ "1" = @(-5.08, 0);    "2" = @(0, -5.08);   "3" = @(5.08, 0) }
	"SW3"    = @{ "1" = @(-5.08, 0);    "2" = @(0, -5.08);   "3" = @(5.08, 0) }
	"PSU4"   = @{ "1" = @(-5.08, 2.54); "2" = @(-5.08, -2.54); "3" = @(5.08, 2.54); "4" = @(5.08, -2.54) }
}
# CONN19 : 19 pins alignées verticalement côté gauche
$PinOffsets["CONN19"] = @{}
for ($k = 1; $k -le 19; $k++) { $yoff = -($k - 1) * 2.54; $PinOffsets["CONN19"]["$k"] = @(-5.08, $yoff) }

$sb = New-Object System.Text.StringBuilder
function W([string]$s) { [void]$sb.AppendLine($s) }

# ---------- En-tête ----------
W '(kicad_sch'
W '	(version 20260306)'
W '	(generator "eeschema")'
W '	(generator_version "10.0")'
W "	(uuid `"$(New-SeqGuid)`")"
W '	(paper "A2")'
W '	(lib_symbols'

# ---------- lib_symbols : définitions des symboles personnalisés ----------
function Emit-Symbol2Pin([string]$name, [string]$refPrefix) {
	W "		(symbol `"FP:$name`""
	W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
	W "			(property `"Reference`" `"$refPrefix`" (at 0 3.81 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))"
	W "			(property `"Value`" `"$name`" (at 0 -3.81 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))"
	W "			(symbol `"$($name)_0_1`""
	W '				(rectangle (start -2.54 -1.27) (end 2.54 1.27) (stroke (width 0.254) (type default)) (fill (type none)))'
	W '			)'
	W "			(symbol `"$($name)_1_1`""
	W '				(pin passive line (at -3.81 0 0) (length 1.27) (name "1" (effects (font (size 1.27 1.27)))) (number "1" (effects (font (size 1.27 1.27)))))'
	W '				(pin passive line (at 3.81 0 180) (length 1.27) (name "2" (effects (font (size 1.27 1.27)))) (number "2" (effects (font (size 1.27 1.27)))))'
	W '			)'
	W '			(embedded_fonts no)'
	W '		)'
}
Emit-Symbol2Pin "R2" "R"
Emit-Symbol2Pin "D2" "D"
Emit-Symbol2Pin "F2" "F"
Emit-Symbol2Pin "CONN2" "J"
Emit-Symbol2Pin "CAP2" "C"

# Q3 : transistor NPN 3 broches (B,C,E)
W '		(symbol "FP:Q3"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "Q" (at 0 5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "Q3" (at 0 -5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "Q3_0_1"'
W '				(rectangle (start -2.54 -2.54) (end 2.54 2.54) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "Q3_1_1"'
W '				(pin passive line (at -5.08 0 0) (length 2.54) (name "B" (effects (font (size 1.27 1.27)))) (number "1" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 0 5.08 270) (length 2.54) (name "C" (effects (font (size 1.27 1.27)))) (number "2" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 0 -5.08 90) (length 2.54) (name "E" (effects (font (size 1.27 1.27)))) (number "3" (effects (font (size 1.27 1.27)))))'
W '			)'
W '			(embedded_fonts no)'
W '		)'

# OC6 : optotriac DIP-6 (1=LED A,2=LED K,3=NC,4=MT1,5=NC,6=MT2)
W '		(symbol "FP:OC6"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "OC" (at 0 5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "OC6" (at 0 -5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "OC6_0_1"'
W '				(rectangle (start -5.08 -3.81) (end 5.08 3.81) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "OC6_1_1"'
W '				(pin passive line (at -6.35 2.54 0) (length 1.27) (name "LED_A" (effects (font (size 1.27 1.27)))) (number "1" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at -6.35 0 0) (length 1.27) (name "LED_K" (effects (font (size 1.27 1.27)))) (number "2" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at -6.35 -2.54 0) (length 1.27) (name "NC" (effects (font (size 1.27 1.27)))) (number "3" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 6.35 -2.54 180) (length 1.27) (name "MT1" (effects (font (size 1.27 1.27)))) (number "4" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 6.35 0 180) (length 1.27) (name "NC" (effects (font (size 1.27 1.27)))) (number "5" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 6.35 2.54 180) (length 1.27) (name "MT2" (effects (font (size 1.27 1.27)))) (number "6" (effects (font (size 1.27 1.27)))))'
W '			)'
W '			(embedded_fonts no)'
W '		)'

# REG3 / SW3 : 3 broches génériques (régulateur IN/GND/OUT, sélecteur A/COM/B)
function Emit-Symbol3Pin([string]$name, [string]$refPrefix, [string]$n1, [string]$n2, [string]$n3) {
	W "		(symbol `"FP:$name`""
	W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
	W "			(property `"Reference`" `"$refPrefix`" (at 0 5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))"
	W "			(property `"Value`" `"$name`" (at 0 -5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))"
	W "			(symbol `"$($name)_0_1`""
	W '				(rectangle (start -2.54 -2.54) (end 2.54 2.54) (stroke (width 0.254) (type default)) (fill (type none)))'
	W '			)'
	W "			(symbol `"$($name)_1_1`""
	W "				(pin passive line (at -5.08 0 0) (length 2.54) (name `"$n1`" (effects (font (size 1.27 1.27)))) (number `"1`" (effects (font (size 1.27 1.27)))))"
	W "				(pin passive line (at 0 -5.08 90) (length 2.54) (name `"$n2`" (effects (font (size 1.27 1.27)))) (number `"2`" (effects (font (size 1.27 1.27)))))"
	W "				(pin passive line (at 5.08 0 180) (length 2.54) (name `"$n3`" (effects (font (size 1.27 1.27)))) (number `"3`" (effects (font (size 1.27 1.27)))))"
	W '			)'
	W '			(embedded_fonts no)'
	W '		)'
}
Emit-Symbol3Pin "REG3" "U" "IN" "GND" "OUT"
Emit-Symbol3Pin "SW3" "SW" "A" "COM" "B"

# PSU4 : module AC/DC 4 broches (AC_L,AC_N,DC+,DC-)
W '		(symbol "FP:PSU4"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "PS" (at 0 5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "PSU4" (at 0 -5.08 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "PSU4_0_1"'
W '				(rectangle (start -3.81 -3.81) (end 3.81 3.81) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "PSU4_1_1"'
W '				(pin passive line (at -5.08 2.54 0) (length 1.27) (name "AC_L" (effects (font (size 1.27 1.27)))) (number "1" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at -5.08 -2.54 0) (length 1.27) (name "AC_N" (effects (font (size 1.27 1.27)))) (number "2" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 5.08 2.54 180) (length 1.27) (name "DC+" (effects (font (size 1.27 1.27)))) (number "3" (effects (font (size 1.27 1.27)))))'
W '				(pin passive line (at 5.08 -2.54 180) (length 1.27) (name "DC-" (effects (font (size 1.27 1.27)))) (number "4" (effects (font (size 1.27 1.27)))))'
W '			)'
W '			(embedded_fonts no)'
W '		)'

# CONN19 : connecteur 19 broches (en-tête Waveshare)
W '		(symbol "FP:CONN19"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "J" (at 0 3.81 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "CONN19" (at 0 -48 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "CONN19_0_1"'
W '				(rectangle (start -3.81 1.27 ) (end 3.81 -45.72) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "CONN19_1_1"'
for ($k = 1; $k -le 19; $k++) {
	$y = -($k - 1) * 2.54
	W "				(pin passive line (at -5.08 $y 0) (length 1.27) (name `"P$k`" (effects (font (size 1.27 1.27)))) (number `"$k`" (effects (font (size 1.27 1.27)))))"
}
W '			)'
W '			(embedded_fonts no)'
W '		)'

W '	)'
# ---------- fin lib_symbols ----------

# ---------- Placement et câblage ----------
# Registre pour les no_connect (broches NC des optotriacs)
$script:ncList = New-Object System.Collections.Generic.List[object]

function Place([string]$libId, [string]$ref, [string]$value, [string]$footprint, [double]$x, [double]$y, [hashtable]$netByPin) {
	$symUuid = New-SeqGuid
	W "	(symbol (lib_id `"FP:$libId`") (at $x $y 0) (unit 1)"
	W "		(uuid `"$symUuid`")"
	W "		(property `"Reference`" `"$ref`" (at $x $($y-3.81) 0) (effects (font (size 1.27 1.27))))"
	W "		(property `"Value`" `"$value`" (at $x $($y+3.81) 0) (effects (font (size 1.27 1.27))))"
	W "		(property `"Footprint`" `"$footprint`" (at $x $y 0) (effects (font (size 1.27 1.27)) (hide yes)))"
	$offs = $PinOffsets[$libId]
	foreach ($pinNum in ($offs.Keys | Sort-Object { [int]$_ })) {
		W "		(pin `"$pinNum`" (uuid `"$(New-SeqGuid)`"))"
	}
	W '		(instances'
	W "			(project `"$ProjectName`""
	W "				(path `"/$symUuid`" (reference `"$ref`") (unit 1))"
	W '			)'
	W '		)'
	W '	)'
	# Labels globaux sur chaque broche connectée (netByPin ne liste que les broches utilisées)
	foreach ($pinNum in $netByPin.Keys) {
		$net = $netByPin[$pinNum]
		if ($null -eq $net) { continue }
		$off = $offs[$pinNum]
		$lx = $x + $off[0]
		$ly = $y - $off[1]
		W "	(global_label `"$net`" (shape bidirectional) (at $lx $ly 0)"
		W '		(effects (font (size 1.016 1.016)))'
		W "		(uuid `"$(New-SeqGuid)`")"
		W '	)'
	}
	# broches non listées dans netByPin => no_connect
	foreach ($pinNum in $offs.Keys) {
		if (-not $netByPin.ContainsKey($pinNum)) {
			$off = $offs[$pinNum]
			$lx = $x + $off[0]
			$ly = $y - $off[1]
			W "	(no_connect (at $lx $ly) (uuid `"$(New-SeqGuid)`"))"
		}
	}
}

# ---------- Section alimentation ----------
# Toutes les coordonnees sont des multiples entiers de $G (1.27 mm) pour rester sur la grille de connexion.
$G = 1.27
$px = 16 * $G; $py = 16 * $G
Place "CONN2" "J1" "MAINS_IN" "FP:TerminalBlock_2.54_2pin" $px $py @{ "1" = "MAINS_L"; "2" = "MAINS_N" }
Place "F2" "F0" "250mA_T_250V" "FP:Axial_THT" ($px + 16 * $G) $py @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place "PSU4" "PS1" "HLK-5M05" "FP:Module_PSU4" ($px + 32 * $G) $py @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
Place "SW3" "SW1" "SPDT_sel" "FP:Switch_SPDT_THT" ($px + 48 * $G) $py @{ "1" = "LOCAL_5V"; "2" = "VSYS"; "3" = "POE_5V" }
Place "REG3" "U1" "AMS1117-3.3" "FP:TO220_3pin" ($px + 64 * $G) $py @{ "1" = "VSYS"; "2" = "GND"; "3" = "3V3_OPTO" }
Place "CAP2" "C1" "100uF" "FP:CAP_THT_Radial" ($px + 64 * $G) ($py + 12 * $G) @{ "1" = "VSYS"; "2" = "GND" }
Place "CAP2" "C2" "100uF" "FP:CAP_THT_Radial" ($px + 76 * $G) ($py + 12 * $G) @{ "1" = "3V3_OPTO"; "2" = "GND" }

Place "CONN2" "J2" "FP1_FP2" "FP:TerminalBlock_5.08_2pin" ($px) ($py + 24 * $G) @{ "1" = "FP1"; "2" = "FP2" }
Place "CONN2" "J3" "FP3_FP4" "FP:TerminalBlock_5.08_2pin" ($px + 16 * $G) ($py + 24 * $G) @{ "1" = "FP3"; "2" = "FP4" }
Place "CONN2" "J4" "FP5_FP6" "FP:TerminalBlock_5.08_2pin" ($px + 32 * $G) ($py + 24 * $G) @{ "1" = "FP5"; "2" = "FP6" }
Place "CONN2" "J5" "FP7_FP8" "FP:TerminalBlock_5.08_2pin" ($px + 48 * $G) ($py + 24 * $G) @{ "1" = "FP7"; "2" = "FP8" }

# En-tête Waveshare ESP32-S3-POE-ETH : pin1=GND pin2=VSYS pin3=POE_5V pin4..19=GPIO
$gpioPinList = @("GPIO1","GPIO2","GPIO4","GPIO5","GPIO15","GPIO16","GPIO17","GPIO18","GPIO21","GPIO38","GPIO39","GPIO40","GPIO41","GPIO42","GPIO47","GPIO48")
$wsNets = @{ "1" = "GND"; "2" = "VSYS"; "3" = "POE_5V" }
for ($i = 0; $i -lt $gpioPinList.Count; $i++) { $wsNets["$($i+4)"] = $gpioPinList[$i] }
Place "CONN19" "JWS" "Waveshare_header" "FP:PinHeader_19x1_2.54" ($px + 96 * $G) ($py + 48 * $G) $wsNets

# ---------- 8 zones ----------
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

$zoneBaseX = 16 * $G
$zoneBaseY = 72 * $G
for ($z = 1; $z -le 8; $z++) {
	$col = ($z - 1) % 4
	$row = [math]::Floor(($z - 1) / 4)
	$blockX = $zoneBaseX + $col * 56 * $G
	$blockY = $zoneBaseY + $row * 56 * $G

	foreach ($ch in @("P", "N")) {
		$cx = $blockX + ($(if ($ch -eq "P") { 0 } else { 24 * $G }))
		$gpioNet = $zoneGpio[$z][$ch]
		$suffix = "Z${z}${ch}"

		Place "R2" "RB$suffix" "10k" "FP:Axial_THT" $cx ($blockY)       @{ "1" = $gpioNet; "2" = "QB_$suffix" }
		Place "Q3" "Q$suffix"  "BC547B" "FP:TO92_BEC" $cx ($blockY + 8 * $G) @{ "1" = "QB_$suffix"; "2" = "LEDK_$suffix"; "3" = "GND" }
		Place "R2" "RL$suffix" "200_1pct" "FP:Axial_THT" $cx ($blockY + 16 * $G) @{ "1" = "3V3_OPTO"; "2" = "LEDA_$suffix" }
		Place "OC6" "OC$suffix" "MOC3063M" "FP:DIP6_THT" $cx ($blockY + 25 * $G) @{ "1" = "LEDA_$suffix"; "2" = "LEDK_$suffix"; "4" = "MT1D_$suffix"; "6" = "FMT2_$suffix" }
		Place "R2" "RS$suffix" "4.7k" "FP:Axial_THT" $cx ($blockY + 35 * $G) @{ "1" = "PHASE_PROT"; "2" = "RSF_$suffix" }
		Place "F2" "F$suffix"  "100mA_PTC" "FP:Axial_THT" $cx ($blockY + 43 * $G) @{ "1" = "RSF_$suffix"; "2" = "FMT2_$suffix" }

		if ($ch -eq "P") {
			Place "D2" "D$suffix" "1N4007" "FP:DO41_THT" $cx ($blockY + 50 * $G) @{ "1" = "MT1D_$suffix"; "2" = "FP$z" }
		} else {
			Place "D2" "D$suffix" "1N4007" "FP:DO41_THT" $cx ($blockY + 50 * $G) @{ "1" = "FP$z"; "2" = "MT1D_$suffix" }
		}
	}
}

# ---------- Pied de fichier ----------
W '	(sheet_instances'
W '		(path "/" (page "1"))'
W '	)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path -Path (Split-Path $OutFile -Parent)).Path + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
