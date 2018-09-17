set PRT to import("util/parts").
set SYS to import("system").
set MNV to import("maneuver").
set RDV to import("rendezvous").
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).

local parkingAp is 100e3.
local targetAp is 1.4e6.
local targetSMA is 2e6.
local lastStage is 0.
local launchHeading is 90.
local counter is 10.
local throt is 0.
local burnTime is 0.
lock orient to PROGRADE+R(0,0,0).
lock steer to orient.
lock burnEta to burnTime - TIME:seconds.

local allCallsigns is List("Stilbon","Eosphorus","Hesperus","Pyroeis","Phaethon","Phaenon").
local callsign is GetCallsign().
set SHIP:name to "KSAT - LKO '"+callsign+"'".
local isFirst is callsign=allCallsigns[0].
local separation_angle is 360 / allCallsigns:length.

set steps to Lex(
0,countdown@,
1,launch@,
2,inspace@,
3,insertion@,
4,calcCircularize@,
5,circularize@,
6,waitForAll@,
7,calcTransfer@,
8,transfer@,
9,calcFinalBurn@,
10,finalBurn@,
11,adjustSMA@,
12,done@
).

if not isFirst {
	set sequence to List(0,1,2,3,4,5,6).
	local first is Vessel("KSAT - LKO '"+allCallsigns[0]+"'").
	local iter is allCallsigns:iterator.
	until not iter:next if callsign=iter:value set TARGET to Vessel("KSAT - LKO '"+allCallsigns[iter:index-1]+"'").
	set targetSMA to first:OBT:semiMajorAxis.
}

function countdown{parameter m,p.
	if counter = 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",parkingAp)).
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
	purge("prg/asc").
	PRT["DoPartModuleEvent"]("RTLongAntenna3","ModuleRTAntenna","activate",0).
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	lock STEERING to steer.
	lock THROTTLE to throt.
	set targetPe to MIN(parkingAp, ALT:apoapsis).
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
function waitForAll{parameter m,p.
	LIST TARGETS in allTargets.
	local iter is allTargets:iterator.
	until not iter:next if iter:value:name = "KSAT - LKO '"+allCallsigns[allCallsigns:length-1]+"'" m["next"](). else wait 10.
}
function calcTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	if isFirst set burnTime to TIME:seconds + ETA:periapsis-preburn.
	else {
		local transfer_anomaly to RDV["VTransferCirc"](separation_angle).
		set burnTime to TIME:seconds + RDV["etaTransferCirc"](transfer_anomaly)-preburn.
	}
	AddAlarm("Raw",burnTime,"transfer","").
	m["next"]().
}
function transfer{parameter m,p.
	if ALT:apoapsis >= targetAp {
		set throt to 0.
		m["next"]().
	}
	else if throt=1 and ALT:apoapsis >= targetAp*0.8 {
		lock throt to max(0.001, min(0.1, 0.1 - (ALT:apoapsis-targetAp*0.8)/targetAp*2)).
	}
	else if burnEta<=0 set throt to 1.
}
function calcFinalBurn{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](min(targetAp,ALT:apoapsis)).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	AddAlarm("Raw",burnTime,"finalize","").
	m["next"]().
}
function finalBurn{parameter m,p.
	if SHIP:OBT:semiMajorAxis >= targetSMA {
		set throt to 0.
		m["next"]().
	}
	else if throt=1 and SHIP:OBT:semiMajorAxis >= targetSMA*0.8 {
		lock throt to max(0.001, min(0.1, 0.1 - (SHIP:OBT:semiMajorAxis-targetSMA*0.8)/targetSMA*2)).
	}
	else if burnEta<=0 set throt to 1.
}
function adjustSMA{parameter m,p.
	MNV["Steer"](RETROGRADE).
	if SHIP:OBT:semiMajorAxis > targetSMA set throt to 0.001.
	else {
		set throt to 0.
		m["next"]().
	}
}
function done{parameter m,p.
	local m is "ModuleRTAntenna".
	PRT["DoModuleEvent"](m,"activate").
	PRT["SetPartModuleField"]("HighGainAntenna5",m,"target",Mun,0).
	PRT["SetPartModuleField"]("HighGainAntenna5",m,"target","active-vessel",1).
	PRT["SetPartModuleField"]("RTShortDish2",m,"target",Minmus).
	lock steer to orient.
	m["next"]().
}