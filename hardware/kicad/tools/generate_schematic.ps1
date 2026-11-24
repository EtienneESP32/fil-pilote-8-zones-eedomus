# Générateur du schéma FilPilote_8Zones (texte .kicad_sch, format KiCad 10)
# Usage : powershell -File generate_schematic.ps1 -OutFile ..\FilPilote_8Zones.kicad_sch -ProjectName FilPilote_8Zones
#
# Reprise complete (2026-11-09) : architecture MCP23017 (expandeur I2C), voir docs/02_Architecture-et-interfaces.md.
# - ESP32 n'utilise plus que 2 broches (GPIO1=SDA, GPIO2=SCL) ; les 16 sorties de zone viennent du MCP23017.
# - MCP23017 + LED d'opto alimentes par un regulateur 3,3V dedie (U1, AMS1117-3,3) sur VSYS, independant
#   du 3,3V du Waveshare (ferme le risque de budget courant non documente).
# - Protection par voie (4,7 kOhm + fusible/PTC) : SUPPRIMEE, decision utilisateur explicite (2026-11-09),
#   qui accepte qu'un defaut sur une zone coupe les 8 (seul F0, fusible d'entree commun 250 mA, protege).

param(
	[string]$OutFile = "$PSScriptRoot\..\FilPilote_8Zones.kicad_sch",
	[string]$ProjectName = "FilPilote_8Zones",
	# Numero de version (demande utilisateur, 2026-11-09) : affiche dans le cartouche KiCad.
	[string]$Rev = "v1-placement-propre"
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
	"CAP2"   = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"CONN2"  = @{ "1" = @(-3.81, 0);    "2" = @(3.81, 0) }
	"OC6"    = @{ "1" = @(-6.35, 2.54); "2" = @(-6.35, 0);   "3" = @(-6.35, -2.54); "4" = @(6.35, -2.54); "5" = @(6.35, 0); "6" = @(6.35, 2.54) }
	"REG3"   = @{ "1" = @(-5.08, 0);    "2" = @(0, -5.08);   "3" = @(5.08, 0) }
	"PSU4"   = @{ "1" = @(-5.08, 2.54); "2" = @(-5.08, -2.54); "3" = @(5.08, 2.54); "4" = @(5.08, -2.54) }
}
# CONN40 : en-tete Waveshare, 2 rangees de 20 broches (format Pico), rangees espacees de 17,78 mm
$PinOffsets["CONN40"] = @{}
for ($k = 1; $k -le 20; $k++) {
	$yoff = -($k - 1) * 2.54
	$rightPin = 41 - $k
	$PinOffsets["CONN40"]["$k"] = @(-8.89, $yoff)
	$PinOffsets["CONN40"]["$rightPin"] = @(8.89, $yoff)
}
# MCP23017 : DIP-28, 14 broches par rangee, pinout reel (pin k a gauche <-> pin 29-k a droite)
$mcpNames = @{
	1="GPB0"; 2="GPB1"; 3="GPB2"; 4="GPB3"; 5="GPB4"; 6="GPB5"; 7="GPB6"; 8="GPB7"
	9="VDD"; 10="VSS"; 11="NC"; 12="SCL"; 13="SDA"; 14="NC"
	15="A0"; 16="A1"; 17="A2"; 18="RESET"; 19="INTB"; 20="INTA"
	21="GPA0"; 22="GPA1"; 23="GPA2"; 24="GPA3"; 25="GPA4"; 26="GPA5"; 27="GPA6"; 28="GPA7"
}
$PinOffsets["MCP28"] = @{}
for ($k = 1; $k -le 14; $k++) {
	$yoff = -($k - 1) * 2.54
	$rightPin = 29 - $k
	$PinOffsets["MCP28"]["$k"] = @(-8.89, $yoff)
	$PinOffsets["MCP28"]["$rightPin"] = @(8.89, $yoff)
}

$sb = New-Object System.Text.StringBuilder
function W([string]$s) { [void]$sb.AppendLine($s) }

# ---------- En-tête ----------
W '(kicad_sch'
W '	(version 20260306)'
W '	(generator "eeschema")'
W '	(generator_version "10.0")'
W "	(uuid `"$(New-SeqGuid)`")"
W '	(paper "A2")'
W "	(title_block"
W "		(title `"FilPilote 8 Zones`")"
W "		(date `"2026-11-09`")"
W "		(rev `"$Rev`")"
W '	)'
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
Emit-Symbol2Pin "CAP2" "C"
Emit-Symbol2Pin "CONN2" "J"

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

# REG3 / PSU4 : symboles 3-4 broches génériques
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

# CONN40 : en-tete Waveshare ESP32-S3-ETH, 40 broches 2 rangees, compatible Raspberry Pi Pico
# (verifie 2026-11-07 : carte 72,8 x 21 mm, pas 2,54 mm, rangees espacees de 17,78 mm, pinout reel confirme)
W '		(symbol "FP:CONN40"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "J" (at 0 3.81 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "CONN40" (at 0 -51 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "CONN40_0_1"'
W '				(rectangle (start -8.89 1.27) (end 8.89 -49.53) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "CONN40_1_1"'
for ($k = 1; $k -le 20; $k++) {
	$y = -($k - 1) * 2.54
	$rightPin = 41 - $k
	W "				(pin passive line (at -8.89 $y 0) (length 2.54) (name `"L$k`" (effects (font (size 1.27 1.27)))) (number `"$k`" (effects (font (size 1.27 1.27)))))"
	W "				(pin passive line (at 8.89 $y 180) (length 2.54) (name `"R$rightPin`" (effects (font (size 1.27 1.27)))) (number `"$rightPin`" (effects (font (size 1.27 1.27)))))"
}
W '			)'
W '			(embedded_fonts no)'
W '		)'

# MCP28 : MCP23017, DIP-28, pinout reel (voir datasheet Microchip)
W '		(symbol "FP:MCP28"'
W '			(exclude_from_sim no) (in_bom yes) (on_board yes) (in_pos_files yes) (duplicate_pin_numbers_are_jumpers no)'
W '			(property "Reference" "U" (at 0 3.81 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(property "Value" "MCP23017" (at 0 -36 0) (show_name no) (do_not_autoplace no) (effects (font (size 1.27 1.27))))'
W '			(symbol "MCP28_0_1"'
W '				(rectangle (start -8.89 1.27) (end 8.89 -34.29) (stroke (width 0.254) (type default)) (fill (type none)))'
W '			)'
W '			(symbol "MCP28_1_1"'
for ($k = 1; $k -le 14; $k++) {
	$y = -($k - 1) * 2.54
	$rightPin = 29 - $k
	$leftName = $mcpNames[$k]
	$rightName = $mcpNames[$rightPin]
	W "				(pin passive line (at -8.89 $y 0) (length 2.54) (name `"$leftName`" (effects (font (size 1.27 1.27)))) (number `"$k`" (effects (font (size 1.27 1.27)))))"
	W "				(pin passive line (at 8.89 $y 180) (length 2.54) (name `"$rightName`" (effects (font (size 1.27 1.27)))) (number `"$rightPin`" (effects (font (size 1.27 1.27)))))"
}
W '			)'
W '			(embedded_fonts no)'
W '		)'

W '	)'
# ---------- fin lib_symbols ----------

# ---------- Placement et câblage ----------
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

# ---------- Section alimentation secteur / locale ----------
# Toutes les coordonnees sont des multiples entiers de $G (1.27 mm) pour rester sur la grille de connexion.
# Feuille A2 KiCad = 594 x 420 mm (paysage). Offset applique a tout le schema pour le centrer sur la
# feuille (signale par l'utilisateur, 2026-11-09 : le schema debordait en haut a gauche sans ce decalage).
$G = 1.27
$offX = 122 * $G; $offY = 80 * $G
$px = 16 * $G + $offX; $py = 16 * $G + $offY
Place "CONN2" "J1" "MAINS_IN" "FP:TerminalBlock_2.54_2pin" $px $py @{ "1" = "MAINS_L"; "2" = "MAINS_N" }
Place "F2" "F0" "250mA_T_250V" "FP:Axial_THT" ($px + 16 * $G) $py @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place "PSU4" "PS1" "HLK-5M05" "FP:Module_PSU4" ($px + 32 * $G) $py @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
# Point ferme (2026-11-07), schema fabricant reel verifie : POE_5V est le meme net que VBUS (USB-C) sur
# la carte Waveshare, deja commute en interne par un MOSFET (Q3) entre PoE et USB vers VSYS. VSYS (broche 2
# de l'en-tete) est la seule entree externe accessible. La diode DPWR protege juste le HLK-5M05 d'un retour
# si le module PoE est aussi installe ; l'exclusion mutuelle PoE/local est un choix d'assemblage (notice).
Place "D2" "DPWR" "1N4007" "FP:DO41_THT" ($px + 48 * $G) $py @{ "1" = "LOCAL_5V"; "2" = "VSYS" }

# ---------- Regulateur 3,3V dedie MCP23017 + LED opto (2026-11-09) ----------
# Ferme le risque "capacite non documentee du regulateur 3,3V embarque du Waveshare" : le MCP23017 et les
# 16 LED d'opto sont alimentes par ce rail 3V3_OPTO dedie, indépendant de la carte Waveshare.
Place "REG3" "U1" "AMS1117-3.3" "FP:TO220_THT" ($px + 64 * $G) $py @{ "1" = "VSYS"; "2" = "GND"; "3" = "3V3_OPTO" }
Place "CAP2" "C1" "10uF" "FP:Radial_THT" ($px + 56 * $G) ($py + 8 * $G) @{ "1" = "VSYS"; "2" = "GND" }
Place "CAP2" "C2" "10uF" "FP:Radial_THT" ($px + 72 * $G) ($py + 8 * $G) @{ "1" = "3V3_OPTO"; "2" = "GND" }

Place "CONN2" "J2" "FP1_FP2" "FP:TerminalBlock_5.08_2pin" ($px) ($py + 24 * $G) @{ "1" = "FP1"; "2" = "FP2" }
Place "CONN2" "J3" "FP3_FP4" "FP:TerminalBlock_5.08_2pin" ($px + 16 * $G) ($py + 24 * $G) @{ "1" = "FP3"; "2" = "FP4" }
Place "CONN2" "J4" "FP5_FP6" "FP:TerminalBlock_5.08_2pin" ($px + 32 * $G) ($py + 24 * $G) @{ "1" = "FP5"; "2" = "FP6" }
Place "CONN2" "J5" "FP7_FP8" "FP:TerminalBlock_5.08_2pin" ($px + 48 * $G) ($py + 24 * $G) @{ "1" = "FP7"; "2" = "FP8" }

# ---------- En-tête Waveshare ESP32-S3-ETH ----------
# Pinout reel verifie le 2026-11-07 (carte 72,8x21mm, 40 broches, format Raspberry Pi Pico).
# Reprise 2026-11-09 : l'ESP32 ne pilote plus les 16 zones directement. Seules 4 broches sont utilisees :
# VSYS (alimentation), GND, et 2 broches de bus I2C (GPIO1=SDA, GPIO2=SCL, aucune des deux n'a de
# particularite de demarrage - voir §1 du dossier). Toutes les autres broches sont NC (non utilisees).
$wsNets = @{
	"2" = "VSYS"; "3" = "GND"
	"15" = "SCL"; "16" = "SDA"
}
Place "CONN40" "JWS" "Waveshare_ESP32-S3-ETH_40pin" "FP:PinHeader_2x20_2.54_Pico" ($px + 96 * $G) ($py + 48 * $G) $wsNets

# ---------- Expandeur I2C MCP23017 ----------
# Adresse I2C fixe 0x20 (A0/A1/A2 a la masse, un seul expandeur sur le bus). RESET tire au 3V3_OPTO
# (jamais actif). INTA/INTB non utilises (NC). VDD/VSS sur le rail dedie 3V3_OPTO/GND.
Place "MCP28" "U2" "MCP23017" "FP:DIP28_THT" ($px + 96 * $G) ($py - 16 * $G) @{
	"9" = "3V3_OPTO"; "10" = "GND"; "12" = "SCL"; "13" = "SDA"
	"15" = "GND"; "16" = "GND"; "17" = "GND"; "18" = "3V3_OPTO"
	"21" = "DRV_Z1A"; "22" = "DRV_Z1B"; "23" = "DRV_Z2A"; "24" = "DRV_Z2B"
	"25" = "DRV_Z3A"; "26" = "DRV_Z3B"; "27" = "DRV_Z4A"; "28" = "DRV_Z4B"
	"1" = "DRV_Z5A"; "2" = "DRV_Z5B"; "3" = "DRV_Z6A"; "4" = "DRV_Z6B"
	"5" = "DRV_Z7A"; "6" = "DRV_Z7B"; "7" = "DRV_Z8A"; "8" = "DRV_Z8B"
}
Place "CAP2" "C3" "100nF" "FP:Radial_THT" ($px + 112 * $G) ($py - 16 * $G) @{ "1" = "3V3_OPTO"; "2" = "GND" }
Place "R2" "RPU1" "4.7k" "FP:Axial_THT" ($px + 80 * $G) ($py + 36 * $G) @{ "1" = "SDA"; "2" = "3V3_OPTO" }
Place "R2" "RPU2" "4.7k" "FP:Axial_THT" ($px + 80 * $G) ($py + 40 * $G) @{ "1" = "SCL"; "2" = "3V3_OPTO" }

# ---------- 8 zones ----------
# Sorties MCP23017 -> zones : GPA0-7 = zones 1-4, GPB0-7 = zones 5-8 (affectation arbitraire, aucune
# contrainte materielle sur ces broches, contrairement a l'ancien schema GPIO direct).
$zoneDrv = @{
	1 = @{ P = "DRV_Z1A"; N = "DRV_Z1B" }
	2 = @{ P = "DRV_Z2A"; N = "DRV_Z2B" }
	3 = @{ P = "DRV_Z3A"; N = "DRV_Z3B" }
	4 = @{ P = "DRV_Z4A"; N = "DRV_Z4B" }
	5 = @{ P = "DRV_Z5A"; N = "DRV_Z5B" }
	6 = @{ P = "DRV_Z6A"; N = "DRV_Z6B" }
	7 = @{ P = "DRV_Z7A"; N = "DRV_Z7B" }
	8 = @{ P = "DRV_Z8A"; N = "DRV_Z8B" }
}

$zoneBaseX = 16 * $G + $offX
$zoneBaseY = 96 * $G + $offY
for ($z = 1; $z -le 8; $z++) {
	$col = ($z - 1) % 4
	$row = [math]::Floor(($z - 1) / 4)
	$blockX = $zoneBaseX + $col * 56 * $G
	$blockY = $zoneBaseY + $row * 56 * $G

	foreach ($ch in @("P", "N")) {
		$cx = $blockX + ($(if ($ch -eq "P") { 0 } else { 24 * $G }))
		$drvNet = $zoneDrv[$z][$ch]
		$suffix = "Z${z}${ch}"

		# MCP23017 -> RL (limitation LED, 200 ohms 1%) -> LED du MOC3063M.
		Place "R2" "RL$suffix" "200_1pct" "FP:Axial_THT" $cx ($blockY) @{ "1" = $drvNet; "2" = "LEDA_$suffix" }
		# Protection par voie (4,7k + fusible/PTC) SUPPRIMEE (decision utilisateur explicite, 2026-11-09) :
		# MT2 revient directement sur PHASE_PROT. Seul F0 (fusible d'entree commun, 250 mA) protege ce
		# noeud desormais ; un defaut sur une zone coupe les 8, courant de defaut non plafonne a 49 mA
		# avant reaction de F0. Risque accepte sciemment, voir docs/03_Nomenclature.md pour le calcul
		# d'origine et le niveau de protection perdu.
		Place "OC6" "OC$suffix" "MOC3063M" "FP:DIP6_THT" $cx ($blockY + 9 * $G) @{ "1" = "LEDA_$suffix"; "2" = "GND"; "4" = "MT1D_$suffix"; "6" = "PHASE_PROT" }

		if ($ch -eq "P") {
			Place "D2" "D$suffix" "1N4007" "FP:DO41_THT" $cx ($blockY + 18 * $G) @{ "1" = "MT1D_$suffix"; "2" = "FP$z" }
		} else {
			Place "D2" "D$suffix" "1N4007" "FP:DO41_THT" $cx ($blockY + 18 * $G) @{ "1" = "FP$z"; "2" = "MT1D_$suffix" }
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
