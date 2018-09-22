function loadLibs {
	set SYS to import("system").
	set MNV to import("maneuver").
	set ORB to import("orbmech").
	set RDV to import("rendezvous").
}
if STATUS<>"PRELAUNCH" loadLibs().
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}

local parkingAp is 100e3.
local finalAp is 235e3.
local finalPe is 234e3.
local finalAltIsh is 500.
local finalEcc is 0.002.
local finalInc is 87.1.
local finalIncIsh is 0.25.
local lastStage is 0.
local launchHeading is 90.
local counter is 10.
local dv is 0.
local burnTime is 0.

set throt to 0.
lock orient to LOOKDIRUP(V(0,1,0),SUN:position).
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
7,calcMunTransfer@,
8,munTransfer@,
9,finishMunTransfer@,
10,coastSoi@,
11,calcInclinationBurn@,
12,inclinationBurn@,
13,calcCaptureBurn@,
14,captureBurn@,
15,calcFinalApBurn@,
16,finalApBurn@,
17,calcFinalEccBurn@,
18,finalEccBurn@,
19,done@
).

function countdown{parameter m,p.
	if counter = 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",parkingAp)).
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
	loadLibs().
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	lock STEERING to steer.
	lock THROTTLE to throt.
	m["next"]().
}
function calcInsertion{parameter m,p.
	set targetPe to MIN(parkingAp, Ap).
	set dv to MNV["ChangePeDeltaV"](15000).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis - fullburn.
	SetAlarm(burnTime,"insertion").
	m["next"]().
}
function insertion{parameter m,p.
	if Pe >= 15000 {
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
	if ETA:apoapsis + preburn > 0 and ETA:apoapsis < ETA:periapsis
		set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	else set burnTime to TIME:seconds + 5.
	SetAlarm(burnTime,"circularize").
	set startAp to Ap.
	m["next"]().
}
function circularize{parameter m,p.
	if Pe >= targetPe or (Ap >= startAp+1e3 and Pe > BODY:ATM:height) {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function calcMunTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](Mun:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	local transferAnomaly is RDV["transferAnomalyCirc"](0, Mun).
	local etaTransfer is RDV["transferEtaCirc"](transferAnomaly, Mun).
	if etaTransfer - preburn > 0 {
		set TARGET to Mun.
		set burnTime to TIME:seconds + etaTransfer - preburn.
		SetAlarm(burnTime,"transfer").
		m["next"]().
	}
}
function munTransfer{parameter m,p.
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Mun {
		set throt to 0.2.
		m["next"]().
	}
	else if Ap > Mun:altitude + Mun:soiRadius {
		set throt to 0.
		m["end"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function finishMunTransfer{parameter m,p.
	if not SHIP:OBT:hasNextPatch m["end"]().
	else if SHIP:OBT:nextPatch:periapsis < finalAp {
		set throt to 0.
		lock steer to orient.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta,"Mun SOI").
		m["next"]().
	}
}
function coastSoi{parameter m,p.
	lock steer to orient.
	if BODY = Mun {
		SetAlarm(TIME:seconds+30,"corrections").
		wait 30.
		m["next"]().
	}
}
function calcInclinationBurn{parameter m,p.
	if inc < finalInc+finalIncIsh {
		set dv to 2*MNV["VisViva"](sma, ALTITUDE)*SIN((finalInc-inc)/2).
		if SHIP:latitude > 0
			lock steer to NORMALVEC.
		else
			lock steer to -NORMALVEC.
		set preburn to MNV["GetManeuverTime"](dv/2).
		set burnTime to TIME:seconds + 10 + preburn.
		SetAlarm(burnTime,"inclination change").
		m["next"]().
	} else {
		lock steer to orient.
		m["jump"](2).
	}
}
function inclinationBurn{parameter m,p.
	if inc >= finalInc {
		set throt to 0.
		m["next"]().
	}
	else if throt > 0 and inc >= finalInc-1 set throt to 0.2.
	else if burnEta <= 0 set throt to 1.
}
function calcCaptureBurn{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"]((Pe + finalAp)/2+Mun:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:periapsis-preburn.
	SetAlarm(burnTime,"capture").
	lock steer to RETROGRADE.
	m["next"]().
}
function captureBurn{parameter m,p.
	if burnEta + fullburn <= 0 and Ap > 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function calcFinalApBurn{parameter m,p.
	local highAp is Ap > (finalAp + finalAltIsh).
	local lowAp is Ap < (finalAp - finalAltIsh).
	if highAp or lowAp {
		set dv to MNV["ChangeApDeltaV"](finalAp).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		if highAp lock steer to RETROGRADE.
		else lock steer to PROGRADE.
		if ETA:periapsis - preburn > 0 {
			set burnTime to TIME:seconds + ETA:periapsis - preburn.
			SetAlarm(burnTime,"adjust Ap").
			m["next"]().
		}
	} else m["jump"](2).
}
function finalApBurn{parameter m,p.
	if Ap > finalAp-finalAltIsh and Ap < finalAp+finalAltIsh {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function calcFinalEccBurn{parameter m,p.
	local highEcc is ecc > finalEcc.
	local lowPe is Pe < (finalPe - finalAltIsh).
	if highEcc or lowPe {
		set dv to MNV["ChangePeDeltaV"](finalPe).
		set preburn to MNV["GetManeuverTime"](dv/2, 0.2).
		set fullburn to MNV["GetManeuverTime"](dv, 0.2).
		if highEcc lock steer to RETROGRADE.
		else lock steer to PROGRADE.
		if ETA:apoapsis - preburn > 0 {
			set burnTime to TIME:seconds + ETA:apoapsis - preburn.
			SetAlarm(burnTime,"adjust Pe").
			m["next"]().
		}
	} else m["jump"](2).
}
function finalEccBurn{parameter m,p.
	if Pe > finalPe-finalAltIsh and ecc < finalEcc {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 0.2.
}
function done{parameter m,p.
	lock steer to orient.
	local scanner is SHIP:PartsNamed("SCANsat.Scanner24")[0].
	local scannerModule is scanner:GetModule("SCANsat").
	Notify("Deploying "+scanner:TITLE).
	scannerModule:DoEvent("start scan: multispectral").
	WAIT 10.
	Notify("SCANsat Altitude: " + scannerModule:GetField("scansat altitude")).
	m["next"]().
}