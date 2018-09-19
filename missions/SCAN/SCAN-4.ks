set SYS to import("system").
set MNV to import("maneuver").
set ORB to import("orbmech").
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).
function SetAlarm{parameter t,n.AddAlarm("Raw",t,n,"").}

local targetAp is 495e3.
local targetPe is 495e3.
local targetEcc is 0.0021.
local targetInc is 84.25.
local targetIncIsh is 0.25.
local lastStage is 0.
local launchHeading is 0.
local counter is 10.
local dv is 0.
local burnTime is 0.

set throt to 0.
lock orient to UP+R(0,0,0).
lock steer to orient.
lock burnEta to burnTime - TIME:seconds.
lock STEERING to steer.
lock THROTTLE to throt.

lock Ap to ALT:apoapsis.
lock Pe to ALT:periapsis.
lock sma to SHIP:OBT:semiMajorAxis.
lock inc to SHIP:OBT:inclination.
lock ecc to SHIP:OBT:eccentricity.

set steps to Lex(
0,countdown@,
1,launch@,
2,inspace@,
3,calcInsertion@,
4,insertion@,
5,calcCircularize@,
6,circularize@,
7,done@
).

function countdown{parameter m,p.
	if counter = 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",targetAp)).
		m["next"]().
	}
	else {
		Notify("T-"+counter).
		set counter to counter - 1.
		wait 1.
	}
}
function launch{parameter m,p.
	if ascent() m["next"]().
}
function inspace{parameter m,p.
	purge("prg/asc").
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	lock STEERING to steer.
	lock THROTTLE to throt.
}
function calcInsertion{parameter m,p.
	set targetPe to MIN(targetPe, Ap).
	set dv to MNV["ChangePeDeltaV"](15000).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis-fullburn.
	SetAlarm(burnTime,"insertion").
	m["next"]().
}
function insertion{parameter m,p.
	if dv=0 m["jump"](-1).
	else if Pe >= 15000 {
		set throt to 0.
		WAIT 1. UNTIL STAGE:NUMBER=lastStage SYS["SafeStage"]().
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function calcCircularize{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](targetPe).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	SetAlarm(burnTime,"circularize").
	m["next"]().
}
function circularize{parameter m,p.
	if dv=0 m["jump"](-1).
	else if Pe >= targetPe or burnEta + fullburn <= 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function checkInclination{parameter m,p.
	if inc < targetInc - targetIncIsh {
		set inclinationChange to 1.
		m["next"]().
	}
	else if inc > targetInc + targetIncIsh {
		set inclinationChange to -1.
		m["next"]().
	}
	else m["jump"](3).
}
function calcInclinationBurn{parameter m,p.
	local Ran is ORB["Rt"](ORB["Van"]()).
	local Rdn is ORB["Rt"](ORB["Vdn"]()).
	local vnode is 0.
	if Ran > Rdn {
		lock steer to inclinationChange*NORMALVEC.
		set burnTime to TIME:SECONDS + ORB["etaAN"]().
		set vnode to MNV["VisViva"](sma,Ran).
	}
	else {
		lock steer to inclinationChange*-NORMALVEC.
		set burnTime to TIME:SECONDS + ORB["etaDN"]().
		set vnode to MNV["VisViva"](sma,Rdn).
	}
	set dv to 2*vnode*SIN(inc/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set lastInc to inc.
	SetAlarm(burnTime,"inclination change").
	M["next"]().
}
function inclinationBurn{parameter m,p.
	if throt > 0 {
		local deltaInc is round(inc - lastInc, 6).
		local remaining is abs(inc - targetInc).
		if (inc > targetInc-targetIncIsh and inc < targetInc+targetIncIsh) or ((inclinationChange=1 and deltaInc < 0) or (inclinationChange=-1 and deltaInc > 0)) {
			set throt to 0.
			M["next"]().
		}
		else if remaining < 1 set throt to 0.1.
	}
	else if burnEta <= 0 set throt to 1.
	set lastInc to inc.
}
function calcApCorrection{parameter m,p.
	if Ap > targetAp {
		set dv to MNV["ChangeApDeltaV"](targetAp).
		set preburn to MNV["GetManeuverTime"](dv/2, 0.2).
		set burnTime to TIME:seconds + ETA:periapsis-preburn.
		set steer to RETROGRADE.
		SetAlarm(burnTime,"change Ap").
		m["next"]().
	} else m["jump"](2).
}
function apCorrection{parameter m,p.
	if Ap <= targetAp {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 0.2.
}
function calcPeCorrection{parameter m,p.
	set targetAp to Ap.
	set dv to MNV["ChangePeDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	if Pe > targetAp lock steer to RETROGRADE.
	else lock steer to PROGRADE.
	SetAlarm(burnTime,"circularize").
	m["next"]().
}
function peCorrection{parameter m,p.
	if Pe >= targetAp or burnEta + fullburn <= 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function done{parameter m,p.
	lock steer to orient.
	m["next"]().
}