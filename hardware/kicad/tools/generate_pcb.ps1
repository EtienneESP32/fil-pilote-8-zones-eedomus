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

# Tas binaire minimal pour A* (PowerShell 5.1 n'a pas de PriorityQueue integree).
class MinHeap {
	[System.Collections.Generic.List[object]]$items = (New-Object System.Collections.Generic.List[object])

	[void] Push([double]$priority, [object]$value) {
		$this.items.Add(@{ p = $priority; v = $value })
		$i = $this.items.Count - 1
		while ($i -gt 0) {
			$parent = [int](($i - 1) / 2)
			if ($this.items[$parent].p -le $this.items[$i].p) { break }
			$tmp = $this.items[$parent]; $this.items[$parent] = $this.items[$i]; $this.items[$i] = $tmp
			$i = $parent
		}
	}

	[object] Pop() {
		$top = $this.items[0]
		$last = $this.items.Count - 1
		$this.items[0] = $this.items[$last]
		$this.items.RemoveAt($last)
		$i = 0
		$count = $this.items.Count
		while ($true) {
			$left = 2 * $i + 1; $right = 2 * $i + 2; $smallest = $i
			if ($left -lt $count -and $this.items[$left].p -lt $this.items[$smallest].p) { $smallest = $left }
			if ($right -lt $count -and $this.items[$right].p -lt $this.items[$smallest].p) { $smallest = $right }
			if ($smallest -eq $i) { break }
			$tmp = $this.items[$i]; $this.items[$i] = $this.items[$smallest]; $this.items[$smallest] = $tmp
			$i = $smallest
		}
		return $top.v
	}

	[bool] IsEmpty() { return $this.items.Count -eq 0 }
}

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

# Transforme un offset local en offset monde pour une rotation donnee (0 ou 90 degres).
# Sens verifie empiriquement le 2026-11-07 par export SVG + rapport DRC (horaire) :
# (lx,ly) -> (ly,-lx) pour une rotation de 90 degres.
function Transform-Local([double]$lx, [double]$ly, [double]$rot) {
	if ($rot -eq 90) {
		$px = $ly
		$py = -$lx
	} else {
		$px = $lx
		$py = $ly
	}
	return @($px, $py)
}

function Get-PadPos([string]$fpType, [double]$cx, [double]$cy, [double]$rot, [string]$padNum) {
	$off = $Pads[$fpType][$padNum]
	$t = Transform-Local $off[0] $off[1] $rot
	$px = $cx + $t[0]
	$py = $cy + $t[1]
	return @($px, $py)
}

# Registre global : pour chaque net, la liste des broches (position monde + reference du
# composant proprietaire) a relier. Alimente automatiquement par Place-FP.
$script:NetPads = @{}
# Registre global des obstacles (rectangles englobants, coordonnees monde) pour le pathfinding.
$script:Obstacles = New-Object System.Collections.Generic.List[object]

# Piste simple en point a point entre deux broches, sur B.Cu (composants THT sur F.Cu).
function Route([string]$netName, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [double]$width = 0.3) {
	W "	(segment (start $x1 $y1) (end $x2 $y2) (width $width) (layer `"B.Cu`") (net `"$netName`") (uuid `"$(New-SeqGuid)`"))"
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
		$t = Transform-Local $px $py $rot
		$wx = $x + $t[0]; $wy = $y + $t[1]
		if ($net) {
			W "		(pad `"$padNum`" thru_hole circle (at $px $py) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (net `"$net`") (uuid `"$(New-SeqGuid)`"))"
			if (-not $script:NetPads.ContainsKey($net)) { $script:NetPads[$net] = New-Object System.Collections.Generic.List[object] }
			$script:NetPads[$net].Add(@{ x = $wx; y = $wy; ref = $ref })
		} else {
			W "		(pad `"$padNum`" thru_hole circle (at $px $py) (size 1.6 1.6) (drill 0.9) (layers `"*.Cu`" `"*.Mask`") (uuid `"$(New-SeqGuid)`"))"
		}
		# Obstacle de pathfinding au niveau de la broche individuelle (pas du composant entier).
		# Point fermé (2026-11-07) : exclure tout le composant proprietaire d'une piste laissait
		# le chemin traverser librement les AUTRES broches de ce meme composant (confirme par
		# de vrais courts-circuits DRC sur DIP6/TO92, broches a 1,27-2,54mm les unes des autres).
		# Chaque broche est desormais son propre obstacle ; seules les 2 broches exactement
		# visees par une piste donnee sont exclues (voir Find-Path/excludePoints), le reste du
		# meme composant reste bloquant comme il se doit. Le corps du composant lui-meme n'est
		# plus modelise comme obstacle : le routage sur B.Cu sous un composant THT monte sur
		# F.Cu est electriquement normal.
		$script:Obstacles.Add(@{ x = $wx; y = $wy; minX = $wx - 1.1; minY = $wy - 1.1; maxX = $wx + 1.1; maxY = $wy + 1.1 })
	}
	# Courtyard (rectangle englobant les pastilles + marge 1mm), pour le DRC uniquement (plus utilise pour le pathfinding).
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
# SW1 (selecteur manuel) retire le 2026-11-07 : pas de broche "sortie PoE" accessible sur la
# carte Waveshare (voir generate_schematic.ps1) ; remplace par une diode serie DPWR.
Place-FP "D_Axial" "DPWR" "1N4007" 13 56 0 @{ "1" = "LOCAL_5V"; "2" = "VSYS" }
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

# ======================================================================
# ROUTAGE AUTOMATIQUE GENERIQUE PAR PATHFINDING (2026-11-07, corrige)
# Recherche de chemin (A*) sur grille, en evitant les rectangles d'encombrement de tous les
# composants (sauf ceux proprietaires des 2 broches a relier).
#
# Bug trouve et corrige : la toute premiere version autorisait les deplacements diagonaux.
# Une piste diagonale longue, une fois simplifiee, donne un seul segment dont le rectangle
# englobant (utilise comme obstacle pour les pistes suivantes) peut couvrir une tres grande
# partie de la carte alors que le cuivre reel n'est qu'un trait fin - ce qui bloquait presque
# tout le routage suivant (confirme : une fenetre de recherche de 50x29 cellules se retrouvait
# bloquee a 74% des la 2e ou 3e piste routee). Corrige en limitant les deplacements a 4
# directions (horizontal/vertical uniquement) : tout segment simplifie reste parfaitement
# aligne sur un axe, donc son rectangle englobant reste fin et exact.
# ======================================================================

function Find-Path {
	param(
		[double]$startX, [double]$startY, [double]$endX, [double]$endY,
		[object[]]$excludePoints,
		[double]$res = 1.0,
		[double]$margin = 20.0
	)
	$minX = [Math]::Min($startX, $endX) - $margin
	$maxX = [Math]::Max($startX, $endX) + $margin
	$minY = [Math]::Min($startY, $endY) - $margin
	$maxY = [Math]::Max($startY, $endY) + $margin
	if ($minX -lt 1.0) { $minX = 1.0 }
	if ($minY -lt 1.0) { $minY = 1.0 }
	$maxXLimit = $BOARD_W - 1.0
	$maxYLimit = $BOARD_H - 1.0
	if ($maxX -gt $maxXLimit) { $maxX = $maxXLimit }
	if ($maxY -gt $maxYLimit) { $maxY = $maxYLimit }

	$cols = [int][Math]::Ceiling(($maxX - $minX) / $res) + 1
	$rows = [int][Math]::Ceiling(($maxY - $minY) / $res) + 1
	if ($cols -lt 2) { $cols = 2 }
	if ($rows -lt 2) { $rows = 2 }

	$blocked = New-Object 'bool[,]' $cols, $rows

	foreach ($obs in $script:Obstacles) {
		$isExcluded = $false
		if ($excludePoints -and $obs.ContainsKey('x')) {
			foreach ($ep in $excludePoints) {
				if ([Math]::Abs($obs.x - $ep[0]) -lt 0.01 -and [Math]::Abs($obs.y - $ep[1]) -lt 0.01) { $isExcluded = $true; break }
			}
		}
		if ($isExcluded) { continue }
		$ox0 = $obs.minX - 0.3; $ox1 = $obs.maxX + 0.3
		$oy0 = $obs.minY - 0.3; $oy1 = $obs.maxY + 0.3
		if ($ox1 -lt $minX -or $ox0 -gt $maxX -or $oy1 -lt $minY -or $oy0 -gt $maxY) { continue }
		$ix0 = [Math]::Max(0, [int][Math]::Floor(($ox0 - $minX) / $res))
		$ix1 = [Math]::Min($cols - 1, [int][Math]::Ceiling(($ox1 - $minX) / $res))
		$iy0 = [Math]::Max(0, [int][Math]::Floor(($oy0 - $minY) / $res))
		$iy1 = [Math]::Min($rows - 1, [int][Math]::Ceiling(($oy1 - $minY) / $res))
		for ($ix = $ix0; $ix -le $ix1; $ix++) {
			for ($iy = $iy0; $iy -le $iy1; $iy++) { $blocked[$ix, $iy] = $true }
		}
	}

	$sx = [int][Math]::Round(($startX - $minX) / $res)
	$sy = [int][Math]::Round(($startY - $minY) / $res)
	$ex = [int][Math]::Round(($endX - $minX) / $res)
	$ey = [int][Math]::Round(($endY - $minY) / $res)
	if ($sx -lt 0) { $sx = 0 }; if ($sx -gt $cols - 1) { $sx = $cols - 1 }
	if ($sy -lt 0) { $sy = 0 }; if ($sy -gt $rows - 1) { $sy = $rows - 1 }
	if ($ex -lt 0) { $ex = 0 }; if ($ex -gt $cols - 1) { $ex = $cols - 1 }
	if ($ey -lt 0) { $ey = 0 }; if ($ey -gt $rows - 1) { $ey = $rows - 1 }
	$blocked[$sx, $sy] = $false
	$blocked[$ex, $ey] = $false

	$cameFrom = @{}
	$gScore = @{}
	$startKey = "$sx,$sy"
	$gScore[$startKey] = 0.0
	$heap = [MinHeap]::new()
	$dxs = $ex - $sx; $dys = $ey - $sy
	$hStart = [Math]::Sqrt($dxs * $dxs + $dys * $dys)
	$heap.Push($hStart, @($sx, $sy))
	$visited = @{}
	# 4 directions seulement (voir note ci-dessus) : horizontal/vertical, jamais diagonal.
	$dirs = @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))
	$found = $false
	$maxIter = 300000
	$iter = 0
	while (-not $heap.IsEmpty() -and $iter -lt $maxIter) {
		$iter++
		$cur = $heap.Pop()
		$cx = $cur[0]; $cy = $cur[1]
		$curKey = "$cx,$cy"
		if ($visited.ContainsKey($curKey)) { continue }
		$visited[$curKey] = $true
		if ($cx -eq $ex -and $cy -eq $ey) { $found = $true; break }
		foreach ($d in $dirs) {
			$nx = $cx + $d[0]; $ny = $cy + $d[1]
			if ($nx -lt 0 -or $nx -ge $cols -or $ny -lt 0 -or $ny -ge $rows) { continue }
			if ($blocked[$nx, $ny]) { continue }
			$nKey = "$nx,$ny"
			if ($visited.ContainsKey($nKey)) { continue }
			$curG = $gScore[$curKey]
			$newG = $curG + 1.0
			if (-not $gScore.ContainsKey($nKey) -or $newG -lt $gScore[$nKey]) {
				$gScore[$nKey] = $newG
				$cameFrom[$nKey] = $curKey
				$ndx = $ex - $nx; $ndy = $ey - $ny
				$h = [Math]::Abs($ndx) + [Math]::Abs($ndy)
				$prio = $newG + $h
				$heap.Push($prio, @($nx, $ny))
			}
		}
	}

	if (-not $found) { return $null }

	$path = New-Object System.Collections.Generic.List[object]
	$curKey = "$ex,$ey"
	$path.Add(@($ex, $ey))
	while ($curKey -ne $startKey) {
		$curKey = $cameFrom[$curKey]
		$parts = $curKey -split ','
		$path.Add(@([int]$parts[0], [int]$parts[1]))
	}
	$path.Reverse()

	$worldPath = New-Object System.Collections.Generic.List[object]
	foreach ($p in $path) {
		$wx = $minX + $p[0] * $res
		$wy = $minY + $p[1] * $res
		$worldPath.Add(@($wx, $wy))
	}
	$worldPath[0] = @($startX, $startY)
	$worldPath[$worldPath.Count - 1] = @($endX, $endY)
	return $worldPath
}

function Simplify-Path($path) {
	if ($path.Count -le 2) { return $path }
	$result = New-Object System.Collections.Generic.List[object]
	$result.Add($path[0])
	for ($i = 1; $i -lt $path.Count - 1; $i++) {
		$prev = $result[$result.Count - 1]
		$cur = $path[$i]
		$next = $path[$i + 1]
		$dx1 = $cur[0] - $prev[0]; $dy1 = $cur[1] - $prev[1]
		$dx2 = $next[0] - $cur[0]; $dy2 = $next[1] - $cur[1]
		$cross = $dx1 * $dy2 - $dy1 * $dx2
		if ([Math]::Abs($cross) -gt 0.001) { $result.Add($cur) }
	}
	$result.Add($path[$path.Count - 1])
	return $result
}

function Emit-Path([string]$netName, $path, [double]$width = 0.3) {
	$simplified = Simplify-Path $path
	for ($i = 0; $i -lt $simplified.Count - 1; $i++) {
		$p1 = $simplified[$i]; $p2 = $simplified[$i + 1]
		Route $netName $p1[0] $p1[1] $p2[0] $p2[1] $width
		# Les segments ne sont plus que horizontaux/verticaux (voir note ci-dessus) : le
		# rectangle englobant est donc toujours fin et exact, pas une fausse grande zone.
		$segMinX = [Math]::Min($p1[0], $p2[0]); $segMaxX = [Math]::Max($p1[0], $p2[0])
		$segMinY = [Math]::Min($p1[1], $p2[1]); $segMaxY = [Math]::Max($p1[1], $p2[1])
		$script:Obstacles.Add(@{ ref = "__track__"; minX = $segMinX; minY = $segMinY; maxX = $segMaxX; maxY = $segMaxY })
	}
}

# Ordre de traitement : du plus contraint (connexions locales courtes, peu de marge de
# manoeuvre) au plus flexible (bus partages par de nombreux points, qui peuvent se permettre
# un detour). Bug trouve : en ordre alphabetique, GND (bus) passait avant QB (local) et tracait
# une piste tout droit entre les deux transistors d'une meme zone - laquelle passait exactement
# par la broche que QB devait ensuite atteindre. Premier arrive, premier sert : les connexions
# locales doivent reserver leur chemin direct avant que les bus ne s'installent autour.
function Get-NetPriority([string]$name) {
	if ($name -match '^(QB_|LEDA_|RSF_)') { return 0 }
	if ($name -match '^(LEDK_|FMT2_|MT1D_)') { return 1 }
	if ($name -match '^GPIO') { return 2 }
	if ($name -match '^FP[0-9]') { return 3 }
	return 4
}

Write-Host "Routage automatique : $($script:NetPads.Keys.Count) nets au total"
$routedHops = 0
$failedHops = New-Object System.Collections.Generic.List[string]
$orderedNets = $script:NetPads.Keys | Sort-Object { Get-NetPriority $_ }, { $_ }
foreach ($netName in $orderedNets) {
	$pts = $script:NetPads[$netName]
	if ($pts.Count -lt 2) { continue }

	$connected = New-Object System.Collections.Generic.List[object]
	$connected.Add($pts[0])
	$remaining = New-Object System.Collections.Generic.List[object]
	for ($i = 1; $i -lt $pts.Count; $i++) { $remaining.Add($pts[$i]) }

	while ($remaining.Count -gt 0) {
		$bestDist = [double]::MaxValue
		$bestConnIdx = -1; $bestRemIdx = -1
		for ($ci = 0; $ci -lt $connected.Count; $ci++) {
			for ($ri = 0; $ri -lt $remaining.Count; $ri++) {
				$ddx = $connected[$ci].x - $remaining[$ri].x
				$ddy = $connected[$ci].y - $remaining[$ri].y
				$d = $ddx * $ddx + $ddy * $ddy
				if ($d -lt $bestDist) { $bestDist = $d; $bestConnIdx = $ci; $bestRemIdx = $ri }
			}
		}
		$a = $connected[$bestConnIdx]
		$b = $remaining[$bestRemIdx]
		$aPt = @($a.x, $a.y)
		$bPt = @($b.x, $b.y)
		$excl = @($aPt, $bPt)
		$path = Find-Path $a.x $a.y $b.x $b.y $excl
		if ($null -eq $path) {
			$failedHops.Add("$netName ($($a.ref) -> $($b.ref))")
		} else {
			Emit-Path $netName $path
			$routedHops++
		}
		$connected.Add($b)
		$remaining.RemoveAt($bestRemIdx)
	}
}
Write-Host "Connexions routees automatiquement : $routedHops ; echecs (a router a la main) : $($failedHops.Count)"
if ($failedHops.Count -gt 0) {
	Write-Host "Echecs :"
	foreach ($fh in $failedHops) { Write-Host "  - $fh" }
}

W '	(embedded_fonts no)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$resolvedDir = (Resolve-Path -Path (Split-Path $OutFile -Parent)).Path
[System.IO.File]::WriteAllText($resolvedDir + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
