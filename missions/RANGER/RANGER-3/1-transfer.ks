set MNV to import("maneuver").
set RDV to import("rendezvous").
set ORD to import("ordinal").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
wait until SHIP:unpacked.

local targetBody is Mun.
local capturePeriapsis is 30000.
local targetAlt is 10000.

lock orient to ORD["sun"]().
lock steer to orient.
lock STEERING to steer.
local dv is 0.
local burnTime is 0.
lock burnEta to burnTime - TIME:seconds.
lock Ap to ALT:apoapsis.
lock Pe to ALT:periapsis.
lock sma to SHIP:OBT:semiMajorAxis.
lock inc to SHIP:OBT:inclination.
lock ecc to SHIP:OBT:eccentricity.

set steps to Lex(
0,	calcTransfer@,
1,	transfer@,
2,	tuneCloseApproach@,
3,	coastSoi@,
4,	calcCapture@,
5,	capture@,
6,	calcLowerPe@,
7,	lowerPe@,
8,	calcLowerAp@,
9,	lowerAp@,
10,	done@
).

function calcTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetBody:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	local transferAnomaly is RDV["transferAnomalyCirc"](0, targetBody).
	local etaTransfer is RDV["transferEtaCirc"](transferAnomaly, targetBody).
	lock steer to PROGRADE.
	if etaTransfer - preburn > 0 {
		set TARGET to targetBody.
		set burnTime to TIME:seconds + etaTransfer - preburn.
		SetAlarm(burnTime,"transfer").
		m["next"]().
	}
}
function transfer{parameter m,p.
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = targetBody {
		set THROTTLE to 0.2.
		m["next"]().
	}
	else if Ap > targetBody:altitude + targetBody:soiRadius {
		set THROTTLE to 0.
		m["end"]().
	}
	else if burnEta <= 0 set THROTTLE to 1.
}
function tuneCloseApproach{parameter m,p.
	if not SHIP:OBT:hasNextPatch m["end"]().
	else if SHIP:OBT:nextPatch:periapsis < capturePeriapsis {
		set THROTTLE to 0.
		lock steer to orient.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta,"SOI change").
		m["next"]().
	}
}
function coastSoi{parameter m,p.
	lock steer to orient.
	if BODY = targetBody {
		wait 30.
		m["next"]().
	}
}

function calcCapture{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"](Pe+Mun:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:periapsis-preburn.
	SetAlarm(burnTime,"capture").
	lock steer to RETROGRADE.
	m["next"]().
}
function capture{parameter m,p.
	if burnEta + fullburn <= 0 and Ap > 0 {
		set THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 set THROTTLE to 1.
}
function calcLowerPe{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](targetAlt).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:apoapsis < preburn return.
	set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	SetAlarm(burnTime,"lower pe").
	lock steer to RETROGRADE.
	m["next"]().
}
function lowerPe{parameter m,p.
	if Pe <= targetAlt {
		set THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 set THROTTLE to 1.
}
function calcLowerAp{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetAlt).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:periapsis < preburn return.
	set burnTime to TIME:seconds + ETA:periapsis-preburn.
	SetAlarm(burnTime,"lower ap").
	lock steer to RETROGRADE.
	m["next"]().
}
function lowerAp{parameter m,p.
	if Ap <= targetAlt+1000 {
		set THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 set THROTTLE to 1.
}
function done{parameter m,p.
	lock steer to orient.
	m["next"]().
}