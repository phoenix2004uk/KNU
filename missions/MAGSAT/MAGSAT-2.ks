lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).
function loadComputer{
	purge("prg/asc").
	WAIT UNTIL HasKSCConnection().
	set partLib to import("util/parts").
	set SYS to import("system").
	set MNV to import("maneuver").
	set RDV to import("rendezvous").
	set SCI to import("science").
}
function doScience{
	SCI["run"]["dmmagBoom"]().
	SCI["run"]["rpwsAnt"]().
}

local targetAp is 100e3.
local finalMunAp is 1e6.
local finalMunPe is 50e3.
local finalMunInc is 30.
local sciAlt is 60e3.
local lastStage is 0.
local launchHeading is 90.
local counter is 10.
local throt is 0.
local burnTime is 0.
lock orient to PROGRADE+R(0,0,0).
lock steer to orient.
wait 0.
lock STEERING to steer.
lock THROTTLE to throt.
lock burnEta to burnTime - TIME:seconds.

set steps to Lex(
0,countdown@,
1,launch@,
2,inspace@,
3,insertion@,
4,calcCircularize@,
5,circularize@,
6,calcTransfer@,
7,doTransfer@,
8,tuneTransfer@,
9,coastSoi@,
10,correctInc@,
11,correctPe@,
12,calcCapture@,
13,doCapture@,
14,lowSci@,
15,hiSci@
).

function countdown{parameter m,p.
	if counter = 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",targetAp)).
		m["next"]().
	}
	else {
		Notify("T-"+counter).
		set counter to counter-1.
		wait 1.
	}
}
function launch{parameter m,p.
	if ascent() m["next"]().
}
function inspace{parameter m,p.
	loadComputer().
	partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE.
	lock STEERING to steer.
	lock THROTTLE to throt.
	set targetPe to MIN(targetAp, ALT:apoapsis).
	set dv to MNV["ChangePeDeltaV"](15000).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis-fullburn.
	AddAlarm("Raw",burnTime,"insertion","").
	m["next"]().
}
function insertion{parameter m,p.
	if ALT:periapsis >= 15000 {
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
	AddAlarm("Raw",burnTime,"circularize","").
	m["next"]().
}
function circularize{parameter m,p.
	if ALT:periapsis >= targetPe or burnEta + fullburn <= 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function calcTransfer{parameter m,p.
	set TARGET to Mun.
	partLib["DoPartModuleAction"]("longAntenna","ModuleRTAntenna","deactivate").
	set dv to MNV["ChangeApDeltaV"](Mun:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	local transferAnomaly to RDV["transferAnomalyCirc"](0, Mun).
	set burnTime to TIME:seconds + RDV["transferEtaCirc"](transferAnomaly, Mun)-preburn.
	AddAlarm("Raw",burnTime,"transfer","").
	m["next"]().
}
function doTransfer{parameter m,p.
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Mun {
		set throt to 0.2.
		m["next"]().
	}
	else if ALT:apoapsis > Mun:altitude + Mun:soiRadius {
		set throt to 0.
		m["end"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function tuneTransfer{parameter m,p.
	if not SHIP:OBT:hasNextPatch m["end"]().
	else if SHIP:OBT:nextPatch:periapsis < finalMunPe {
		set throt to 0.
		lock steer to orient.
		AddAlarm("Raw",TIME:seconds+SHIP:OBT:nextPatchEta,"Mun SOI","").
		m["next"]().
	}
}
function coastSoi{parameter m,p.
	if BODY = Mun {
		partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
		lock steer to orient.
		AddAlarm("Raw",TIME:seconds+30,"corrections","").
		wait 30.
		m["next"]().
	}
}
function correctInc{parameter m,p.
	if SHIP:OBT:inclination < finalMunInc {
		lock steer to NORMALVEC().
		if throt=0 wait 10.
		set throt to 1.
	} else {
		set throt to 0.
		lock steer to orient.
		m["next"]().
	}
}
function correctPe{parameter m,p.
	if SHIP:OBT:periapsis > finalMunPe {
		lock steer to -RADIALVEC().
		if throt=0 wait 10.
		set throt to 1.
	} else {
		set throt to 0.
		lock steer to orient.
		m["next"]().
	}
}
function calcCapture{parameter m,p.
	local vpe is MNV["VisViva"](SHIP:OBT:semiMajorAxis, ALT:periapsis).
	local vca is MNV["VisViva"]((ALT:periapsis + finalMunAp)/2+Mun:radius, ALT:periapsis).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:periapsis-preburn.
	AddAlarm("Raw",burnTime,"capture","").
	lock steer to RETROGRADE.
	m["next"]().
}
function doCapture{parameter m,p.
	if ALT:apoapsis > 0 and ALT:apoapsis < finalMunAp {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function lowSci{parameter m,p.
	if ALTITUDE < sciAlt {
		doScience().
		m["next"]().
	}
}
function hiSci{parameter m,p.
	if ALTITUDE > sciAlt {
		doScience().
		m["next"]().
	}
}