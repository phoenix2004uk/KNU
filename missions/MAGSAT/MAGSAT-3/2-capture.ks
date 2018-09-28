set ORD to import("ordinal").
set MNV to import("maneuver").

function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
wait until SHIP:unpacked.

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
0,	calcInclinationChange@,
1,	inclinationChange@,
2,	calcCapture@,
3,	capture@,
4,	calclowerPeBurn@,
5,	lowerPe@,
6,	done@
).

function calcInclinationChange{parameter m,p.
	local dir is SHIP:latitude / abs(SHIP:latitude).
	if inc < 45 lock steer to -dir*ORD["normal"]().
	else {m["jump"](2). return.}
	set dv to 2*SHIP:velocity:orbit:mag*SIN(abs(inc-45)/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + max(10,fullburn).
	SetAlarm(burnTime,"inclination change").
	m["next"]().
}
function inclinationChange{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if inc > 45 {
		set THROTTLE to 0.
		m["next"]().
	}
	else set THROTTLE to 1.
}

function calcCapture{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"]((Pe + 500000)/2+Minmus:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:transition < ETA:periapsis or ETA:periapsis < 0 set burnTime to TIME:seconds + 10.
	else set burnTime to TIME:seconds + ETA:periapsis - preburn.
	lock steer to RETROGRADE.
	SetAlarm(burnTime,"capture").
	m["next"]().
}
function capture{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if Ap > 0 and Ap < 500000 {
		set THROTTLE to 0.
		m["next"]().
	}
	else set THROTTLE to 1.
}

function calclowerPeBurn{parameter m,p.
	if Pe > 10000 and Pe < 30000 {
		m["jump"](2).
		return.
	}
	set dv to MNV["ChangePeDeltaV"](20000).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:apoapsis < preburn return.
	set burnTime to TIME:seconds + ETA:apoapsis - preburn.
	if Pe > 30000 lock steer to RETROGRADE.
	else lock steer to PROGRADE.
	SetAlarm(burnTime,"lower pe").
	m["next"]().
}
function lowerPe{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if Pe < 30000 and Pe > 10000 {
		set THROTTLE to 0.
		m["next"]().
	}
	else set THROTTLE to 1.
}

function done{parameter m,p.
	lock steer to orient.
	m["next"]().
}