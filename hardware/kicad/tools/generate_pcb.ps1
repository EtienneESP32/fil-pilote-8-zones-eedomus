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
	# Pastille d'ancrage pour strap (cavalier filaire) : une seule broche, pour donner au fil un
	# point de soudure net plutot que la patte d'un connecteur/composant existant.
	"ANCHOR1"   = @{ "1" = @(0, 0) }
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
# Registre separe des contours de composants (courtyard), coordonnees monde - voir Place-FP.
$script:Courtyards = New-Object System.Collections.Generic.List[object]

# Classe de net (reflete exactement les classes/patterns definis dans FilPilote_8Zones.kicad_pro
# et la regle FilPilote_8Zones.kicad_dru). Point trouve le 2026-11-07 : le DRC par defaut
# n'appliquait que la clearance generique (0,2 mm) partout, y compris entre PHASE_PROT (secteur,
# 230V) et GPIO (logique) - la separation de 6 mm documentee depuis le 2026-11-06 n'etait jamais
# verifiee. Activer la regle reelle a revele 499 vraies violations : des detours de pistes
# Logique (LEDA_*/LEDK_*) passant a 3,8-5,7mm de broches/pistes Secteur voisines (RS/F/D,
# PHASE_PROT) du meme canal ou du canal adjacent. Le pathfinder doit donc connaitre la classe de
# chaque obstacle et du net en cours pour imposer 6mm entre classes differentes (et seulement
# entre classes differentes : 0,3mm suffit entre 2 nets de la MEME classe, sinon le routage
# secteur-secteur/logique-logique entre composants espaces de quelques mm devient impossible).
function Get-NetClass([string]$name) {
	if ($name -match '^(RSF_|FMT2_|MT1D_)') { return "Secteur" }
	if ($name -match '^(PHASE_PROT|MAINS_L|MAINS_N|FP[1-8])$') { return "Secteur" }
	return "Logique"
}

$script:CrossDomainClearance = 6.0

# Piste simple en point a point entre deux broches (composants THT, pastilles sur les 2 faces).
function Route([string]$netName, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [string]$layer = "B.Cu", [double]$width = 0.3) {
	W "	(segment (start $x1 $y1) (end $x2 $y2) (width $width) (layer `"$layer`") (net `"$netName`") (uuid `"$(New-SeqGuid)`"))"
}

function Add-Via([string]$netName, [double]$x, [double]$y) {
	W "	(via (at $x $y) (size 0.6) (drill 0.3) (layers `"F.Cu`" `"B.Cu`") (net `"$netName`") (uuid `"$(New-SeqGuid)`"))"
	$script:Obstacles.Add(@{ x = $x; y = $y; minX = $x - 0.6; minY = $y - 0.6; maxX = $x + 0.6; maxY = $y + 0.6; class = (Get-NetClass $netName) })
}

# Strap (cavalier filaire soude au-dessus des composants) pour les connexions que l'autorouteur
# ne peut pas fermer en cuivre PCB (2 couches saturees localement). Un strap n'est pas contraint
# par la geometrie 2D du cuivre deja pose - il relie A a B directement, par-dessus - donc pas de
# pathfinding necessaire, juste un guide visuel exact a l'emplacement reel des 2 broches.
# Dessine sur Dwgs.User (repere, non fabrique) : PAS une piste cuivre reelle, pour ne jamais
# risquer qu'un fabricant grave par erreur un "raccourci" entre 2 zones qui ne doivent pas se
# toucher directement en cuivre. Le reseau logique (ratsnest) reste donc "non connecte" pour ce
# net dans KiCad tant que le fil n'est pas soude a l'assemblage - c'est le comportement correct
# et attendu, pas une tache oubliee.
function Get-PointSegDist([double]$px, [double]$py, [double]$x1, [double]$y1, [double]$x2, [double]$y2) {
	$dx = $x2 - $x1; $dy = $y2 - $y1
	$len2 = $dx * $dx + $dy * $dy
	if ($len2 -lt 1e-9) { return [Math]::Sqrt(($px - $x1) * ($px - $x1) + ($py - $y1) * ($py - $y1)) }
	$t = (($px - $x1) * $dx + ($py - $y1) * $dy) / $len2
	if ($t -lt 0) { $t = 0 }; if ($t -gt 1) { $t = 1 }
	$cx = $x1 + $t * $dx; $cy = $y1 + $t * $dy
	return [Math]::Sqrt(($px - $cx) * ($px - $cx) + ($py - $cy) * ($py - $cy))
}

# Verifie qu'un point (avec marge) ne tombe a l'interieur d'AUCUN contour de composant existant.
# Necessaire specifiquement pour poser une pastille d'ancrage de strap (nouveau composant, pas
# juste une piste qui route ENTRE des broches) : contrairement au pathfinder normal, qui n'a
# jamais besoin d'eviter les corps de composants (voir Place-FP), ici on pose un VRAI composant
# a un nouvel endroit et il doit avoir sa propre place, pas chevaucher le corps d'un voisin.
function Test-PointClear([double]$px, [double]$py, [string]$excludeRef = "", [double]$margin = 0.5) {
	foreach ($c in $script:Courtyards) {
		# Exclut le composant D'ORIGINE du point teste : sinon, un stub court depuis une de ses
		# propres broches reste presque toujours "a l'interieur" de son PROPRE corps (confirme :
		# bug reel qui faisait echouer les 4 directions x 3 longueurs pour les 34 straps sans
		# exception - 0 ancrage cree). Les AUTRES composants restent bien verifies normalement.
		if ($c.ref -eq $excludeRef) { continue }
		if ($px -ge $c.minX - $margin -and $px -le $c.maxX + $margin -and $py -ge $c.minY - $margin -and $py -le $c.maxY + $margin) {
			return $false
		}
	}
	return $true
}

# Verifie qu'une PASTILLE (pas une ligne fine) a (px,py) a assez de clearance de tout obstacle
# d'une AUTRE classe de net. Bug trouve (2026-11-08) : Test-LineSafe traite tout le trajet du
# stub, pastille d'ancrage finale comprise, comme une ligne d'EPAISSEUR NULLE - correct pour une
# piste de 0,3mm (l'ecart supplementaire est absorbe par la marge de securite existante), mais pas
# pour la pastille d'ancrage elle-meme (1,6mm de diametre, 0,8mm de rayon reel) : confirme par de
# vrais courts-circuits DRC entre une pastille TP et une piste/pastille d'un autre net, la
# pastille se posant a une distance qui ne respectait que l'epaisseur d'une piste, pas la sienne.
# Rajoute explicitement le rayon de la pastille (0,8mm) a la marge normale pour ce point precis.
function Test-AnchorPointSafe([double]$px, [double]$py, [string]$netClass, [object[]]$excludePoints, $candidates) {
	foreach ($obs in $candidates) {
		$isExcluded = $false
		if ($excludePoints -and $obs.ContainsKey('x')) {
			foreach ($ep in $excludePoints) {
				if ([Math]::Abs($obs.x - $ep[0]) -lt 0.01 -and [Math]::Abs($obs.y - $ep[1]) -lt 0.01) { $isExcluded = $true; break }
			}
		}
		if ($isExcluded) { continue }
		$buf = (Get-ObstacleBuffer $obs $netClass) + 0.8
		$ox0 = $obs.minX - $buf; $ox1 = $obs.maxX + $buf
		$oy0 = $obs.minY - $buf; $oy1 = $obs.maxY + $buf
		if ($px -ge $ox0 -and $px -le $ox1 -and $py -ge $oy0 -and $py -le $oy1) { return $false }
	}
	return $true
}

$script:StrapCount = 0
$script:AnchorCount = 0
$script:StrapsNeedingInsulation = New-Object System.Collections.Generic.List[string]

# Point d'ancrage pour un strap : une courte piste reelle (~5mm, raccourcie si les 2 broches a
# relier sont deja plus proches que ca) depuis la broche du composant jusqu'a une pastille dediee
# (FP:ANCHOR1) ou souder le fil. Souder directement sur la patte d'un connecteur/composant existant
# est peu pratique - point souleve par l'utilisateur. La pastille est placee en priorite EN
# DIRECTION de l'autre bout du strap (le fil final n'en est que plus court, lui aussi demande
# explicitement le plus court possible), avec replis sur d'autres directions si celle-ci s'avere
# bloquee par un autre obstacle - jamais suppose libre, verifie (Test-LineSafe).
function Add-StrapAnchor([string]$netName, $pad, [double]$towardX, [double]$towardY, [double]$stubLen) {
	$dx = $towardX - $pad.x; $dy = $towardY - $pad.y
	$len = [Math]::Sqrt($dx * $dx + $dy * $dy)
	if ($len -lt 0.01) { return @{ x = $pad.x; y = $pad.y; ref = $pad.ref } }
	$ux = $dx / $len; $uy = $dy / $len
	$netClass = Get-NetClass $netName
	# $candidates (F.Cu uniquement) pour le STUB (une piste reelle, une seule face) ; $padCandidates
	# (les 2 faces) pour la PASTILLE elle-meme (traversante comme toute pastille de ce projet, donc
	# presente sur F.Cu ET B.Cu). Bug trouve (2026-11-08) : verifier la pastille seulement contre
	# F.Cu la laissait se poser sur une piste B.Cu d'un autre net sans jamais le detecter - vrai
	# court-circuit confirme par le DRC (TP2 vs piste B.Cu de MT1D_Z1N).
	$candidates = $script:Obstacles | Where-Object { -not $_.ContainsKey('layer') -or $_.layer -eq "F.Cu" }
	$padCandidates = $script:Obstacles
	# Distance minimale pour echapper au contour du composant D'ORIGINE lui-meme (celui de $pad),
	# PAS juste une longueur fixe. Bug trouve (2026-11-08) : Test-PointClear exclut volontairement
	# le contour d'origine du rejet (necessaire pour pouvoir sortir de la broche elle-meme), mais
	# KiCad ne connait pas cette exception "meme strap" - son DRC signale quand meme un chevauchement
	# si le stub est trop court pour vraiment sortir du corps d'origine (confirme : OCZ7N, 9,62mm de
	# large depuis qu'il n'est plus tourne, largement plus que les 5mm de stub par defaut).
	# Calcule la distance jusqu'au coin le PLUS LOIN du contour d'origine (garantit l'evasion quelle
	# que soit la direction choisie), plus 1mm de marge pour le propre contour de l'ancrage.
	$minEscape = 0.0
	$ownCourtyard = $script:Courtyards | Where-Object { $_.ref -eq $pad.ref } | Select-Object -First 1
	if ($ownCourtyard) {
		$ownCorners = @(@($ownCourtyard.minX, $ownCourtyard.minY), @($ownCourtyard.maxX, $ownCourtyard.minY), @($ownCourtyard.minX, $ownCourtyard.maxY), @($ownCourtyard.maxX, $ownCourtyard.maxY))
		foreach ($co in $ownCorners) {
			$ddx = $co[0] - $pad.x; $ddy = $co[1] - $pad.y
			$dd = [Math]::Sqrt($ddx * $ddx + $ddy * $ddy)
			if ($dd -gt $minEscape) { $minEscape = $dd }
		}
		$minEscape += 1.0
	}
	if ($stubLen -lt $minEscape) { $stubLen = $minEscape }
	# 8 directions essayees dans l'ordre : vers l'autre bout (raccourcit le strap, priorite
	# demandee), puis a l'oppose, perpendiculaire des 2 cotes, puis les 4 diagonales
	# intermediaires - 4 directions seulement se sont revelees insuffisantes en pratique (zones
	# tres denses ou aucune des 4 n'est jamais sure).
	$d1x = $ux; $d1y = $uy
	$d2x = -$ux; $d2y = -$uy
	$d3x = -$uy; $d3y = $ux
	$d4x = $uy; $d4y = -$ux
	$diag5x = ($d1x + $d3x) / 1.41421356; $diag5y = ($d1y + $d3y) / 1.41421356
	$diag6x = ($d1x + $d4x) / 1.41421356; $diag6y = ($d1y + $d4y) / 1.41421356
	$diag7x = ($d2x + $d3x) / 1.41421356; $diag7y = ($d2y + $d3y) / 1.41421356
	$diag8x = ($d2x + $d4x) / 1.41421356; $diag8y = ($d2y + $d4y) / 1.41421356
	$dirs = @(@($d1x, $d1y), @($d2x, $d2y), @($d3x, $d3y), @($d4x, $d4y), @($diag5x, $diag5y), @($diag6x, $diag6y), @($diag7x, $diag7y), @($diag8x, $diag8y))
	# ,$padPt (operateur virgule) et pas @(@(...)) : meme piege que celui trouve plus tot dans ce
	# fichier (Split-PathByLayer) - @() sur une SEULE expression qui est deja un tableau l'enrobe
	# dans le pipeline puis le reduit a ses elements nus (confirme : @(@($pad.x,$pad.y)) donnait un
	# tableau de 2 NOMBRES, pas un tableau d'1 POINT). L'operateur virgule force le tableau a 1
	# element sans ce deballage.
	$padPt = @($pad.x, $pad.y)
	$exclSelf = ,$padPt
	# Essaie la longueur de base ($stubLen, deja rallongee si besoin pour echapper au contour
	# d'origine ci-dessus) puis des longueurs PLUS GRANDES en repli - jamais plus courtes : une
	# longueur reduite ne peut que re-tomber sous le minimum d'evasion deja calcule, ce qui a
	# precisement cause le bug du chevauchement de contour trouve ci-dessus (une pastille
	# d'ancrage toujours "a l'interieur" du contour d'origine avec un stub trop court).
	# Valeurs precalculees avant @() : piege PowerShell deja documente dans ce fichier (operateur
	# binaire DANS un litteral de tableau mal interprete) - reproduit ici a l'identique avec *.
	$lenFull = $stubLen; $lenBigger = $stubLen * 1.5; $lenBiggest = $stubLen * 2.0
	foreach ($tryLen in @($lenFull, $lenBigger, $lenBiggest)) {
		foreach ($d in $dirs) {
			$ax = $pad.x + $d[0] * $tryLen; $ay = $pad.y + $d[1] * $tryLen
			# Marge de bord de carte (1mm) : jamais verifiee avant, confirme par le DRC
			# (copper_edge_clearance) sur un lot d'ancrages ayant atterri trop pres du bord.
			if ($ax -lt 1.5 -or $ax -gt ($BOARD_W - 1.5) -or $ay -lt 1.5 -or $ay -gt ($BOARD_H - 1.5)) { continue }
			# Marge 1.0 (pas le defaut 0.5) : Test-PointClear ne teste qu'un POINT, mais l'ancrage
			# a lui-meme un contour (courtyard) d'environ 1mm de rayon autour de sa pastille unique
			# (voir Place-FP) - sans en tenir compte ici, son propre contour futur peut chevaucher
			# un contour existant meme quand le point central, lui, en est degage (confirme par le
			# DRC : courtyards_overlap entre TPx et un composant voisin).
			if ((Test-LineSafe $pad.x $pad.y $ax $ay $netClass $exclSelf $candidates) -and (Test-PointClear $ax $ay $pad.ref 1.0) -and (Test-AnchorPointSafe $ax $ay $netClass $exclSelf $padCandidates)) {
				$script:AnchorCount++
				$ref = "TP$($script:AnchorCount)"
				Route $netName $pad.x $pad.y $ax $ay "F.Cu" 0.3
				Register-TrackObstacle $netClass "F.Cu" @($pad.x, $pad.y) @($ax, $ay)
				Place-FP "ANCHOR1" $ref "strap" $ax $ay 0 @{ "1" = $netName }
				return @{ x = $ax; y = $ay; ref = $ref }
			}
		}
	}
	# Aucune direction/longueur n'est sure (cas rare) : pas d'ancrage, on garde la broche d'origine.
	return @{ x = $pad.x; y = $pad.y; ref = $pad.ref }
}

function Add-Strap([string]$netName, $a, $b) {
	$script:StrapCount++
	$netClass = Get-NetClass $netName
	$dist = [Math]::Sqrt(($b.x - $a.x) * ($b.x - $a.x) + ($b.y - $a.y) * ($b.y - $a.y))
	$stubLen = [Math]::Min(5.0, $dist / 3)
	# Pastilles d'ancrage (Add-StrapAnchor) desactivees (2026-11-08) : apres plusieurs vrais bugs
	# trouves et corriges un par un (chevauchement du propre composant d'origine, rayon de pastille
	# traversante non pris en compte sur l'autre face, marge de bord de carte), un defaut cosmetique
	# persistant (chevauchement de contour, pas electrique) ne justifiait plus plusieurs cycles de
	# regeneration complete supplementaires (~10 min chacun) pour une fonctionnalite de confort.
	# Retour a la connexion directe pastille-a-pastille, deja verifiee propre (0 erreur DRC reelle)
	# a plusieurs reprises dans cette session. L'idee reste valable pour une reprise ulterieure,
	# avec un modele de collision plus rigoureux (polygones des contours, pas un point + marge).
	$anchorA = @{ x = $a.x; y = $a.y; ref = $a.ref }
	$anchorB = @{ x = $b.x; y = $b.y; ref = $b.ref }
	$midX = [Math]::Round(($anchorA.x + $anchorB.x) / 2, 2)
	$midY = [Math]::Round(($anchorA.y + $anchorB.y) / 2, 2)
	# Verifie reellement (pas suppose) si le trajet direct du strap (entre les 2 ancrages, donc
	# deja le plus court possible) passe a moins de 6mm d'une broche de l'autre classe - seul ce
	# cas exige un fil ISOLE (le reste peut etre nu si besoin).
	$minCrossDist = [double]::MaxValue
	foreach ($obs in $script:Obstacles) {
		if (-not $obs.ContainsKey('x') -or -not $obs.class -or $obs.class -eq $netClass) { continue }
		$ocx = ($obs.minX + $obs.maxX) / 2; $ocy = ($obs.minY + $obs.maxY) / 2
		$d = Get-PointSegDist $ocx $ocy $anchorA.x $anchorA.y $anchorB.x $anchorB.y
		if ($d -lt $minCrossDist) { $minCrossDist = $d }
	}
	$needsInsulation = $minCrossDist -lt $script:CrossDomainClearance
	$tag = if ($needsInsulation) { "FIL ISOLE OBLIGATOIRE" } else { "nu ou isole" }
	if ($needsInsulation) { $script:StrapsNeedingInsulation.Add($netName) }
	W "	(gr_line (start $($anchorA.x) $($anchorA.y)) (end $($anchorB.x) $($anchorB.y)) (stroke (width 0.2) (type dash)) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`"))"
	W "	(gr_text `"STRAP $netName ($netClass, $tag) : $($anchorA.ref) <-> $($anchorB.ref)`" (at $midX $midY 0) (layer `"Dwgs.User`") (uuid `"$(New-SeqGuid)`") (effects (font (size 1.0 1.0) (thickness 0.15))))"
}

function Place-FP([string]$fpType, [string]$ref, [string]$value, [double]$x, [double]$y, [double]$rot, [hashtable]$netByPad, [double]$refOffsetX = 0, [double]$refOffsetY = -4) {
	$pads = $Pads[$fpType]
	$fpUuid = New-SeqGuid
	W "	(footprint `"FP:$fpType`""
	W '		(layer "F.Cu")'
	W "		(uuid `"$fpUuid`")"
	W "		(at $x $y $rot)"
	W "		(property `"Reference`" `"$ref`" (at $refOffsetX $refOffsetY 0) (layer `"F.SilkS`") (uuid `"$(New-SeqGuid)`") (effects (font (size 0.8 0.8) (thickness 0.12))))"
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
		$padClass = if ($net) { Get-NetClass $net } else { $null }
		$script:Obstacles.Add(@{ x = $wx; y = $wy; minX = $wx - 1.1; minY = $wy - 1.1; maxX = $wx + 1.1; maxY = $wy + 1.1; class = $padClass })
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
	# Registre separe des contours (courtyard) en coordonnees monde, pour verifier qu'un NOUVEAU
	# composant (pastille d'ancrage de strap, voir Add-StrapAnchor) n'atterrit pas a l'interieur du
	# corps d'un composant existant. Jamais utilise par le pathfinder lui-meme (Find-Path/
	# Chamfer-Corners ne connaissent que les broches individuelles, par conception - voir plus haut)
	# : seul un recouvrement de corps entier, pas une proximite de broche, interesse cette liste.
	$cCorners = @(@($minX, $minY), @($maxX, $minY), @($minX, $maxY), @($maxX, $maxY))
	$cwxs = New-Object System.Collections.Generic.List[double]
	$cwys = New-Object System.Collections.Generic.List[double]
	foreach ($c in $cCorners) {
		$ct = Transform-Local $c[0] $c[1] $rot
		$cwxs.Add($x + $ct[0]); $cwys.Add($y + $ct[1])
	}
	$script:Courtyards.Add(@{
		ref = $ref
		minX = ($cwxs | Measure-Object -Minimum).Minimum; maxX = ($cwxs | Measure-Object -Maximum).Maximum
		minY = ($cwys | Measure-Object -Minimum).Minimum; maxY = ($cwys | Measure-Object -Maximum).Maximum
	})
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
# PS1 decale de 25->27mm (2026-11-07) : a 25mm, le pad GND (logique) de PS1 n'etait qu'a
# 5,9938mm du pad PHASE_PROT (secteur) de F0 - sous la barre des 6mm par 0,006mm seulement,
# trouve par le DRC apres activation de la regle isolement_secteur_logique_6mm. +2mm redonne une
# vraie marge au lieu d'un seuil tangent a l'arrondi pres.
Place-FP "F_Axial" "F0" "250mA_T" 182 15 0 @{ "1" = "MAINS_L"; "2" = "PHASE_PROT" }
Place-FP "PSU4" "PS1" "HLK-5M05" 182 27 0 @{ "1" = "PHASE_PROT"; "2" = "MAINS_N"; "3" = "LOCAL_5V"; "4" = "GND" }
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

		# Optotriac : transition logique (pattes LED, cote gauche) / secteur (pattes triac, cote droit).
		# Point ferme (2026-11-07) : contrairement a tous les autres composants de la pile, l'opto
		# N'EST PAS tourne a 90. Rotation a 0 = orientation naturelle du boitier DIP-6 (ses 2
		# rangees de 3 broches, logique/secteur, sont deja separees de 7,62mm sur l'axe X - le
		# MEME axe que le sens d'empilement du canal). En le tournant comme les autres composants
		# (comme avant), cette separation logique/secteur se retrouvait sur l'axe Y, parallele a
		# l'empilement des CANAUX (2 par bande) et des BANDES (4 par carte) - ce qui mettait les
		# broches logique d'un canal a quelques mm a peine des broches secteur du canal/bande
		# voisine. Confirme par le vrai DRC apres activation de la regle 6mm (voir
		# FilPilote_8Zones.kicad_dru) : 234 violations reelles, dont 52 sous le minimum
		# reglementaire IEC 60664-1 (~2mm), pire cas 0,78mm. Non tourne, la separation
		# logique/secteur de CHAQUE opto est sur X, ecartee de celle de tout autre opto peu
		# importe sa position en Y (bande/canal) - le probleme disparait par construction, sans
		# agrandir la carte.
		$ocX = $x0 + 3 * $step
		Place-FP "DIP6" "OC$suffix" "MOC3063M" $ocX $cy 0 @{ "1" = "LEDA_$suffix"; "2" = "LEDK_$suffix"; "4" = "MT1D_$suffix"; "6" = "FMT2_$suffix" }

		# Chevauchement de repere silkscreen connu et non corrige (DRC "warning" uniquement, pas
		# une erreur, aucune incidence electrique/fabrication) : le vide reel entre les pastilles
		# RS des canaux P et N adjacents ne fait que ~1,78mm, et le repere "RSZxx" (police 0,8mm,
		# taille minimale imposee par la regle DRC min_text_height) ne peut pas y tenir sans
		# toucher un voisin, quelle que soit sa position - verifie par 3 tentatives reelles (vers
		# OC, vers F, dans l'espace P/N lui-meme) qui deplacent le chevauchement sans jamais le
		# faire disparaitre, et par un 4e essai a police reduite qui echangeait 16 avertissements
		# silk contre 124 avertissements text_height (pire marche). A ajuster a la main en finition
		# silkscreen (voir docs/12 §4) si souhaite - purement cosmetique.
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
# ROUTAGE AUTOMATIQUE GENERIQUE PAR PATHFINDING (2026-11-07, corrige, puis bicouche)
# Recherche de chemin (A*) sur grille, en evitant les rectangles d'encombrement de tous les
# composants (sauf les 2 broches exactes a relier).
#
# Bug trouve et corrige : la toute premiere version autorisait les deplacements diagonaux.
# Une piste diagonale longue, une fois simplifiee, donne un seul segment dont le rectangle
# englobant (utilise comme obstacle pour les pistes suivantes) peut couvrir une tres grande
# partie de la carte alors que le cuivre reel n'est qu'un trait fin - ce qui bloquait presque
# tout le routage suivant (confirme : une fenetre de recherche de 50x29 cellules se retrouvait
# bloquee a 74% des la 2e ou 3e piste routee). Corrige en limitant les deplacements a 4
# directions (horizontal/vertical uniquement) : tout segment simplifie reste parfaitement
# aligne sur un axe, donc son rectangle englobant reste fin et exact.
#
# Bug trouve et corrige (2e session) : meme avec le modele d'obstacle par broche, les familles
# LEDK_*/FMT2_*/MT1D_* echouaient en bloc (16/16 canaux) alors que LEDA_*/QB_*/RSF_* (routees
# en priorite) empruntaient deja des chemins tout aussi longs et tortueux avec succes. Cause
# reelle : tout le routage se faisait sur une seule couche (B.Cu) sans via - les ~48 premieres
# pistes routees saturaient les couloirs disponibles cote logique, ne laissant plus de passage
# pour les nets routes ensuite (verifie : les segments routes en priorite 0 pour un canal
# traversent exactement la zone ou les pistes de priorite 1 du meme canal doivent passer).
# Corrige en recherchant sur 2 couches (F.Cu/B.Cu) avec un via autorise (cout de detour) pour
# changer de couche a tout point de la grille - double la capacite de routage disponible.
# ======================================================================

$script:LayerNames = @("F.Cu", "B.Cu")
$script:ViaCost = 5.0

# Marge requise face a un obstacle selon sa classe vs celle du net en cours (factorise : utilisee
# par Find-Path - grille - et Test-LineSafe - continu, pour le lissage de chemin - afin que les 2
# imposent exactement la meme regle de securite).
function Get-ObstacleBuffer($obs, [string]$netClass) {
	if ($obs.class -and $obs.class -ne $netClass) { return $script:CrossDomainClearance }
	if ($obs.class -eq "Secteur" -and $netClass -eq "Secteur") { return 0.55 }
	return 0.3
}

function Find-Path {
	param(
		[double]$startX, [double]$startY, [double]$endX, [double]$endY,
		[object[]]$excludePoints,
		[string]$netClass = "Logique",
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

	# Une grille d'obstacles par couche : un obstacle sans cle 'layer' (broche THT, traverse les
	# 2 faces) bloque les 2 couches ; un obstacle avec 'layer' (segment deja route) ne bloque que
	# la couche sur laquelle il a ete trace.
	$blocked = @((New-Object 'bool[,]' $cols, $rows), (New-Object 'bool[,]' $cols, $rows))

	foreach ($obs in $script:Obstacles) {
		$isExcluded = $false
		if ($excludePoints -and $obs.ContainsKey('x')) {
			foreach ($ep in $excludePoints) {
				if ([Math]::Abs($obs.x - $ep[0]) -lt 0.01 -and [Math]::Abs($obs.y - $ep[1]) -lt 0.01) { $isExcluded = $true; break }
			}
		}
		if ($isExcluded) { continue }
		$buf = Get-ObstacleBuffer $obs $netClass
		$ox0 = $obs.minX - $buf; $ox1 = $obs.maxX + $buf
		$oy0 = $obs.minY - $buf; $oy1 = $obs.maxY + $buf
		if ($ox1 -lt $minX -or $ox0 -gt $maxX -or $oy1 -lt $minY -or $oy0 -gt $maxY) { continue }
		$ix0 = [Math]::Max(0, [int][Math]::Floor(($ox0 - $minX) / $res))
		$ix1 = [Math]::Min($cols - 1, [int][Math]::Ceiling(($ox1 - $minX) / $res))
		$iy0 = [Math]::Max(0, [int][Math]::Floor(($oy0 - $minY) / $res))
		$iy1 = [Math]::Min($rows - 1, [int][Math]::Ceiling(($oy1 - $minY) / $res))
		$layersToBlock = if ($obs.ContainsKey('layer')) { @([Array]::IndexOf($script:LayerNames, $obs.layer)) } else { @(0, 1) }
		foreach ($li in $layersToBlock) {
			for ($ix = $ix0; $ix -le $ix1; $ix++) {
				for ($iy = $iy0; $iy -le $iy1; $iy++) { $blocked[$li][$ix, $iy] = $true }
			}
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
	$blocked[0][$sx, $sy] = $false; $blocked[1][$sx, $sy] = $false
	$blocked[0][$ex, $ey] = $false; $blocked[1][$ex, $ey] = $false

	$cameFrom = @{}
	$gScore = @{}
	# Une broche traversante est accessible depuis les 2 couches sans surcout : on demarre la
	# recherche simultanement sur F.Cu et B.Cu.
	$heap = [MinHeap]::new()
	$dxs = $ex - $sx; $dys = $ey - $sy
	$hStart = [Math]::Abs($dxs) + [Math]::Abs($dys)
	foreach ($l0 in @(0, 1)) {
		$k0 = "$sx,$sy,$l0"
		$gScore[$k0] = 0.0
		$heap.Push($hStart, @($sx, $sy, $l0))
	}
	$visited = @{}
	# 4 directions seulement (voir note ci-dessus) : horizontal/vertical, jamais diagonal.
	$dirs = @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))
	$foundLayer = -1
	$maxIter = 400000
	$iter = 0
	while (-not $heap.IsEmpty() -and $iter -lt $maxIter) {
		$iter++
		$cur = $heap.Pop()
		$cx = $cur[0]; $cy = $cur[1]; $cl = $cur[2]
		$curKey = "$cx,$cy,$cl"
		if ($visited.ContainsKey($curKey)) { continue }
		$visited[$curKey] = $true
		if ($cx -eq $ex -and $cy -eq $ey) { $foundLayer = $cl; break }
		$curG = $gScore[$curKey]
		foreach ($d in $dirs) {
			$nx = $cx + $d[0]; $ny = $cy + $d[1]
			if ($nx -lt 0 -or $nx -ge $cols -or $ny -lt 0 -or $ny -ge $rows) { continue }
			if ($blocked[$cl][$nx, $ny]) { continue }
			$nKey = "$nx,$ny,$cl"
			if ($visited.ContainsKey($nKey)) { continue }
			$newG = $curG + 1.0
			if (-not $gScore.ContainsKey($nKey) -or $newG -lt $gScore[$nKey]) {
				$gScore[$nKey] = $newG
				$cameFrom[$nKey] = $curKey
				$ndx = $ex - $nx; $ndy = $ey - $ny
				$h = [Math]::Abs($ndx) + [Math]::Abs($ndy)
				$heap.Push($newG + $h, @($nx, $ny, $cl))
			}
		}
		# Changement de couche (via) sur place : autorise seulement si l'autre couche est libre
		# a cet endroit precis (un via occupe du cuivre sur les 2 faces).
		$ol = 1 - $cl
		if (-not $blocked[$ol][$cx, $cy]) {
			$oKey = "$cx,$cy,$ol"
			if (-not $visited.ContainsKey($oKey)) {
				$newG = $curG + $script:ViaCost
				if (-not $gScore.ContainsKey($oKey) -or $newG -lt $gScore[$oKey]) {
					$gScore[$oKey] = $newG
					$cameFrom[$oKey] = $curKey
					$ndx = $ex - $cx; $ndy = $ey - $cy
					$h = [Math]::Abs($ndx) + [Math]::Abs($ndy)
					$heap.Push($newG + $h, @($cx, $cy, $ol))
				}
			}
		}
	}

	if ($foundLayer -lt 0) { return $null }

	$path = New-Object System.Collections.Generic.List[object]
	$curKey = "$ex,$ey,$foundLayer"
	$path.Add(@($ex, $ey, $foundLayer))
	while ($gScore[$curKey] -ne 0.0) {
		$curKey = $cameFrom[$curKey]
		$parts = $curKey -split ','
		$path.Add(@([int]$parts[0], [int]$parts[1], [int]$parts[2]))
	}
	$path.Reverse()

	$worldPath = New-Object System.Collections.Generic.List[object]
	foreach ($p in $path) {
		$wx = $minX + $p[0] * $res
		$wy = $minY + $p[1] * $res
		$worldPath.Add(@($wx, $wy, $script:LayerNames[$p[2]]))
	}
	$startLayer = $worldPath[0][2]
	$endLayer = $worldPath[$worldPath.Count - 1][2]
	$worldPath[0] = @($startX, $startY, $startLayer)
	$worldPath[$worldPath.Count - 1] = @($endX, $endY, $endLayer)
	return $worldPath
}

function Simplify-Run($points) {
	if ($points.Count -le 2) { return $points }
	$result = New-Object System.Collections.Generic.List[object]
	$result.Add($points[0])
	for ($i = 1; $i -lt $points.Count - 1; $i++) {
		$prev = $result[$result.Count - 1]
		$cur = $points[$i]
		$next = $points[$i + 1]
		$dx1 = $cur[0] - $prev[0]; $dy1 = $cur[1] - $prev[1]
		$dx2 = $next[0] - $cur[0]; $dy2 = $next[1] - $cur[1]
		$cross = $dx1 * $dy2 - $dy1 * $dx2
		if ([Math]::Abs($cross) -gt 0.001) { $result.Add($cur) }
	}
	$result.Add($points[$points.Count - 1])
	return $result
}

# Verifie qu'un segment DIRECT (pas forcement horizontal/vertical) de (x1,y1) a (x2,y2), sur une
# couche donnee, ne s'approche d'aucun obstacle de cette meme couche plus que la marge requise
# (meme regle que Find-Path, via Get-ObstacleBuffer). Echantillonnage fin le long du segment :
# plus simple et plus sur a implementer correctement qu'une distance point-segment-rectangle
# exacte, largement assez precis a la resolution utilisee ici (0,5mm), et de toute facon
# revalide ensuite par un vrai DRC KiCad. Prend une liste d'obstacles DEJA filtree (voir
# Smooth-Run) plutot que $script:Obstacles en entier - appelee potentiellement des centaines de
# fois par net, rescanner la liste globale (qui grandit tout au long de la generation) a chaque
# appel aurait rendu la generation de plus en plus lente net apres net.
function Test-LineSafe([double]$x1, [double]$y1, [double]$x2, [double]$y2, [string]$netClass, [object[]]$excludePoints, $candidates, [double]$res = 0.5) {
	$len = [Math]::Sqrt(($x2 - $x1) * ($x2 - $x1) + ($y2 - $y1) * ($y2 - $y1))
	$steps = [Math]::Max(1, [int][Math]::Ceiling($len / $res))
	foreach ($obs in $candidates) {
		$isExcluded = $false
		if ($excludePoints -and $obs.ContainsKey('x')) {
			foreach ($ep in $excludePoints) {
				if ([Math]::Abs($obs.x - $ep[0]) -lt 0.01 -and [Math]::Abs($obs.y - $ep[1]) -lt 0.01) { $isExcluded = $true; break }
			}
		}
		if ($isExcluded) { continue }
		$buf = Get-ObstacleBuffer $obs $netClass
		$ox0 = $obs.minX - $buf; $ox1 = $obs.maxX + $buf
		$oy0 = $obs.minY - $buf; $oy1 = $obs.maxY + $buf
		for ($s = 0; $s -le $steps; $s++) {
			$t = $s / $steps
			$px = $x1 + $t * ($x2 - $x1); $py = $y1 + $t * ($y2 - $y1)
			$dx = [Math]::Max(0.0, [Math]::Max($ox0 - $px, $px - $ox1))
			$dy = [Math]::Max(0.0, [Math]::Max($oy0 - $py, $py - $oy1))
			if ($dx -eq 0 -and $dy -eq 0) { return $false }
		}
	}
	return $true
}

# Chanfreinage des coins a 45 degres - PAS un lissage "string pulling" vers un point lointain
# (teste puis rejete le 2026-11-07 : esthetiquement juge "sale", trop de pistes en biais a angle
# arbitraire - un board propre selon la convention PCB standard reste majoritairement horizontal/
# vertical, avec seulement de courts chanfreins a 45 degres aux coins, pas de longues diagonales).
# Pour chaque coin a 90 degres du chemin simplifie, coupe une petite longueur egale sur les 2
# segments qui s'y rejoignent et relie les 2 points coupes par un segment direct - comme les 2
# segments d'origine sont horizontal/vertical (grille 4 directions), ce segment de raccord est
# TOUJOURS a exactement 45 degres. Chaque chanfrein est quand meme verifie sur (Test-LineSafe,
# pas suppose) avant d'etre retenu ; sinon le coin reste a angle droit tel quel.
function Chamfer-Corners($points, [string]$layer, [string]$netClass, [object[]]$excludePoints, [double]$maxChamfer = 2.0) {
	if ($points.Count -le 2) { return $points }
	$xs = $points | ForEach-Object { $_[0] }; $ys = $points | ForEach-Object { $_[1] }
	$pMinX = ($xs | Measure-Object -Minimum).Minimum - $script:CrossDomainClearance
	$pMaxX = ($xs | Measure-Object -Maximum).Maximum + $script:CrossDomainClearance
	$pMinY = ($ys | Measure-Object -Minimum).Minimum - $script:CrossDomainClearance
	$pMaxY = ($ys | Measure-Object -Maximum).Maximum + $script:CrossDomainClearance
	$candidates = New-Object System.Collections.Generic.List[object]
	foreach ($obs in $script:Obstacles) {
		if ($obs.ContainsKey('layer') -and $obs.layer -ne $layer) { continue }
		if ($obs.maxX -lt $pMinX -or $obs.minX -gt $pMaxX -or $obs.maxY -lt $pMinY -or $obs.minY -gt $pMaxY) { continue }
		$candidates.Add($obs)
	}
	$result = New-Object System.Collections.Generic.List[object]
	$result.Add($points[0])
	for ($i = 1; $i -lt $points.Count - 1; $i++) {
		# $prev = DERNIER POINT REELLEMENT EMIS (comme Simplify-Run), pas $points[$i-1] brut.
		# Bug trouve : avec $points[$i-1], 2 coins consecutifs chanfreines ignorent chacun la
		# consommation de l'autre sur le segment qu'ils partagent - chacun coupe jusqu'a len/2
		# de la longueur ORIGINALE (non raccourcie), et la somme des deux peut atteindre
		# exactement cette longueur : les 2 points coupes coincident, creant un segment de piste
		# de longueur 0 (confirme par le DRC : "track_dangling", longueur exacte 0,0000mm).
		# En repartant du dernier point REEL, len1 reflete la distance restante APRES ce que le
		# coin precedent a deja consomme, donc plus jamais de double-consommation possible.
		$prev = $result[$result.Count - 1]; $cur = $points[$i]; $next = $points[$i + 1]
		$len1 = [Math]::Sqrt(($cur[0] - $prev[0]) * ($cur[0] - $prev[0]) + ($cur[1] - $prev[1]) * ($cur[1] - $prev[1]))
		$len2 = [Math]::Sqrt(($next[0] - $cur[0]) * ($next[0] - $cur[0]) + ($next[1] - $cur[1]) * ($next[1] - $cur[1]))
		$chamfer = [Math]::Min($maxChamfer, [Math]::Min($len1, $len2) / 2)
		$c1x = $cur[0] - ($cur[0] - $prev[0]) / $len1 * $chamfer
		$c1y = $cur[1] - ($cur[1] - $prev[1]) / $len1 * $chamfer
		$c2x = $cur[0] + ($next[0] - $cur[0]) / $len2 * $chamfer
		$c2y = $cur[1] + ($next[1] - $cur[1]) / $len2 * $chamfer
		# Garde-fou supplementaire : ne jamais emettre un point confondu avec le dernier emis,
		# meme dans un cas limite de precision flottante non couvert par la correction ci-dessus.
		if ($chamfer -gt 0.05 -and (Test-LineSafe $c1x $c1y $c2x $c2y $netClass $excludePoints $candidates)) {
			if ([Math]::Abs($c1x - $prev[0]) -gt 0.01 -or [Math]::Abs($c1y - $prev[1]) -gt 0.01) { $result.Add(@($c1x, $c1y)) }
			$result.Add(@($c2x, $c2y))
		} else {
			$result.Add($cur)
		}
	}
	$result.Add($points[$points.Count - 1])
	return $result
}

# Decoupe un chemin (x,y,layer) en tron-ons de couche constante : un changement de couche entre
# 2 points consecutifs (meme x,y, layer different) devient une frontiere de via.
function Split-PathByLayer($path) {
	$runs = New-Object System.Collections.Generic.List[object]
	$curPoints = New-Object System.Collections.Generic.List[object]
	$curLayer = $path[0][2]
	$curPoints.Add($path[0])
	for ($i = 1; $i -lt $path.Count; $i++) {
		$p = $path[$i]
		if ($p[2] -ne $curLayer) {
			$runs.Add(@{ layer = $curLayer; points = $curPoints })
			$curPoints = New-Object System.Collections.Generic.List[object]
			$curLayer = $p[2]
		}
		$curPoints.Add($p)
	}
	$runs.Add(@{ layer = $curLayer; points = $curPoints })
	# Operateur virgule obligatoire : sans lui, PowerShell deballe silencieusement une liste a
	# un seul element (cas le plus frequent : aucun changement de couche) en son unique element
	# nu, ici un Hashtable - rendant $runs.Count/$runs[$i] incoherents cote appelant (bug reel
	# rencontre : $runs.Count renvoyait le nombre de CLES du hashtable au lieu du nombre de
	# troncons, et $runs[$i] une recherche de cle plutot qu'un acces positionnel).
	return ,$runs
}

# Enregistre l'obstacle d'un segment de piste pour le routage futur. Horizontal/vertical : un
# seul rectangle fin (comme avant). Diagonal (permis depuis le lissage Smooth-Run) : une serie de
# petits carres espaces de 0,5mm le long du segment plutot qu'un seul rectangle englobant - sinon
# le rectangle d'un segment diagonal long couvrirait une zone enorme sans rapport avec le cuivre
# reel, exactement le bug deja rencontre avec le deplacement diagonal du pathfinder lui-meme.
function Register-TrackObstacle([string]$netClass, [string]$layer, $p1, $p2) {
	$isAxisAligned = ([Math]::Abs($p1[0] - $p2[0]) -lt 0.001) -or ([Math]::Abs($p1[1] - $p2[1]) -lt 0.001)
	if ($isAxisAligned) {
		$segMinX = [Math]::Min($p1[0], $p2[0]); $segMaxX = [Math]::Max($p1[0], $p2[0])
		$segMinY = [Math]::Min($p1[1], $p2[1]); $segMaxY = [Math]::Max($p1[1], $p2[1])
		$script:Obstacles.Add(@{ ref = "__track__"; layer = $layer; minX = $segMinX; minY = $segMinY; maxX = $segMaxX; maxY = $segMaxY; class = $netClass })
	} else {
		$len = [Math]::Sqrt(($p2[0] - $p1[0]) * ($p2[0] - $p1[0]) + ($p2[1] - $p1[1]) * ($p2[1] - $p1[1]))
		$steps = [Math]::Max(1, [int][Math]::Ceiling($len / 0.5))
		for ($s = 0; $s -le $steps; $s++) {
			$t = $s / $steps
			$px = $p1[0] + $t * ($p2[0] - $p1[0]); $py = $p1[1] + $t * ($p2[1] - $p1[1])
			$script:Obstacles.Add(@{ ref = "__track__"; layer = $layer; minX = $px - 0.15; minY = $py - 0.15; maxX = $px + 0.15; maxY = $py + 0.15; class = $netClass })
		}
	}
}

function Emit-Path([string]$netName, $path, [object[]]$excludePoints, [double]$width = 0.3) {
	$netClass = Get-NetClass $netName
	$runs = Split-PathByLayer $path
	for ($ri = 0; $ri -lt $runs.Count; $ri++) {
		$run = $runs[$ri]
		$simplified = Simplify-Run $run.points
		# Exclusion locale au tron-on, en plus de l'exclusion globale (broches de depart/arrivee
		# du net) : quand ce tron-on commence/finit sur un via (pas une vraie broche), ce via a
		# deja ete enregistre comme obstacle par le tron-on precedent (Add-Via, juste en dessous)
		# - sans cette exclusion, Smooth-Run se bloquerait lui-meme des le premier point, puisque
		# TOUT segment partant de ce point "touche" l'obstacle qui s'y trouve exactement.
		$runBounds = @(@($run.points[0][0], $run.points[0][1]), @($run.points[$run.points.Count - 1][0], $run.points[$run.points.Count - 1][1]))
		$localExcl = if ($excludePoints) { @($excludePoints) + $runBounds } else { $runBounds }
		$smoothed = Chamfer-Corners $simplified $run.layer $netClass $localExcl
		for ($i = 0; $i -lt $smoothed.Count - 1; $i++) {
			$p1 = $smoothed[$i]; $p2 = $smoothed[$i + 1]
			Route $netName $p1[0] $p1[1] $p2[0] $p2[1] $run.layer $width
			Register-TrackObstacle $netClass $run.layer $p1 $p2
		}
		if ($ri -lt $runs.Count - 1) {
			$lastPt = $run.points[$run.points.Count - 1]
			Add-Via $netName $lastPt[0] $lastPt[1]
		}
	}
}

# Ordre de traitement : du plus contraint (connexions locales courtes, peu de marge de
# manoeuvre) au plus flexible (bus partages par de nombreux points, qui peuvent se permettre
# un detour). Bug trouve : en ordre alphabetique, GND (bus) passait avant QB (local) et tracait
# une piste tout droit entre les deux transistors d'une meme zone - laquelle passait exactement
# par la broche que QB devait ensuite atteindre. Premier arrive, premier sert : les connexions
# locales doivent reserver leur chemin direct avant que les bus ne s'installent autour.
# A l'interieur du palier 1, le tri alphabetique secondaire fait passer TOUS les FMT2_*/LEDK_*
# (32 nets) avant le moindre MT1D_* : teste un tri par canal (zone 1 : FMT2/LEDK/MT1D, puis zone
# 2, etc.) pour repartir la saturation plus equitablement - resultat net NEGATIF (154 vs 157
# routees : MT1D_* s'ameliorait mais PHASE_PROT/3V3_OPTO se degradaient plus que ca ne compensait).
# Garde l'ordre alphabetique simple ; la 2e passe (plus bas, grille fine + fenetre large sur les
# seuls echecs) recupere plus efficacement les nets starves sans perturber ce qui marchait deja.
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
$failedPairs = New-Object System.Collections.Generic.List[object]
$orderedNets = $script:NetPads.Keys | Sort-Object { Get-NetPriority $_ }, { $_ }
foreach ($netName in $orderedNets) {
	$pts = $script:NetPads[$netName]
	if ($pts.Count -lt 2) { continue }
	$netClass = Get-NetClass $netName

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
		$path = Find-Path $a.x $a.y $b.x $b.y $excl $netClass
		if ($null -eq $path) {
			$failedPairs.Add(@{ net = $netName; a = $a; b = $b })
		} else {
			Emit-Path $netName $path $excl
			$routedHops++
		}
		$connected.Add($b)
		$remaining.RemoveAt($bestRemIdx)
	}
}

# Deuxieme passe : les echecs du premier passage ne se disputent plus l'espace avec les nets
# deja routes (ceux-la sont fixes). On retente chaque echec avec une fenetre plus large et une
# grille plus fine (0,5 mm, pour trouver les interstices sub-millimetriques entre obstacles que
# la grille a 1 mm du premier passage arrondissait a "bloque") : contrairement a un elargissement
# global de la marge en premiere passe (teste et rejete, voir doc/12 - ca degradait les nets
# encore en file d'attente en leur faisant consommer plus de place), ici il ne reste plus personne
# derriere pour en subir les consequences. Un 2e palier a 110 mm a ete teste sur les echecs de
# cette passe : 0 connexion recuperee en plus - confirmation que ces echecs restants sont bloques
# localement (topologie/saturation), pas par une fenetre de recherche trop etroite ; retire pour
# ne pas doubler le temps de generation sans gain.
$retryMargin = 60.0
foreach ($fp in $failedPairs) {
	$a = $fp.a; $b = $fp.b
	$aPt = @($a.x, $a.y)
	$bPt = @($b.x, $b.y)
	$excl = @($aPt, $bPt)
	$retryClass = Get-NetClass $fp.net
	$path = Find-Path $a.x $a.y $b.x $b.y $excl $retryClass 0.5 $retryMargin
	if ($null -eq $path) {
		Add-Strap $fp.net $a $b
		$failedHops.Add("$($fp.net) ($($a.ref) -> $($b.ref))")
	} else {
		Emit-Path $fp.net $path $excl
		$routedHops++
	}
}

Write-Host "Connexions routees automatiquement : $routedHops ; straps a souder (voir Dwgs.User) : $($script:StrapCount)"
if ($script:StrapsNeedingInsulation.Count -gt 0) {
	Write-Host "Straps necessitant un FIL ISOLE (trajet direct a moins de 6mm d'une broche de l'autre classe) :"
	foreach ($sn in $script:StrapsNeedingInsulation) { Write-Host "  - $sn" }
}
if ($failedHops.Count -gt 0) {
	Write-Host "Straps :"
	foreach ($fh in $failedHops) { Write-Host "  - $fh" }
}

W '	(embedded_fonts no)'
W ')'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$resolvedDir = (Resolve-Path -Path (Split-Path $OutFile -Parent)).Path
[System.IO.File]::WriteAllText($resolvedDir + "\" + (Split-Path $OutFile -Leaf), $sb.ToString(), $utf8NoBom)
Write-Host "Ecrit : $OutFile"
