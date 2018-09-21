// finds the relative AN/DN between 2 orbitables
// returns a Lexicon with keys "AN","DN","next","other"
//  - AN/DN: the true anomaly of the AN/DN nodes
//  - next: either "AN" or "DN" depending which is the next node
//  - other: the opposite of next
function anomaly_of_relative_nodes {
	parameter target_orbitable is TARGET, source_orbitable is SHIP.

	local src_r is source_orbitable:position - BODY:position.
	local src_v is source_orbitable:velocity:orbit.

	local tgt_r is target_orbitable:position - BODY:position.
	local tgt_v is target_orbitable:velocity:orbit.

	// angular momentum
	// h = r x v
	local src_h is VCRS(src_r,src_v).
	local tgt_h is VCRS(tgt_r,tgt_v).

	// line of nodes
	local v_nodes is VCRS(src_h, tgt_h).

	// vector normal of line of nodes and position vector
	local v_nodes_normal is VCRS(src_h, v_nodes).

	// angle between nodes normal and position tells us which half of the orbit we are in
	local ang_position is VANG(src_r, v_nodes_normal).

	// angle between current position and line of nodes is the AN
	local ang_to_an is VANG(v_nodes,src_r).
	local ang_to_dn is VANG(-v_nodes,src_r).

	local result is Lex().
	// since angle to AN/DN is relative, depending on which half of the orbit we are in
	// we need to add twice the angle difference of the next node to the other node
	// now we know which node is the next node
	if ang_position > 90 {
		set ang_to_dn to ang_to_dn + 2*ang_to_an.
		set result["next"] to "AN".
		set result["other"] to "DN".
	}
	else {
		set ang_to_an to ang_to_an + 2*ang_to_dn.
		set result["next"] to "DN".
		set result["other"] to "AN".
	}
	set result["AN"] to mod(360+source_orbitable:OBT:trueAnomaly+ang_to_an,360).
	set result["DN"] to mod(360+source_orbitable:OBT:trueAnomaly+ang_to_dn,360).

	return result.
}

// finds the relative inclination between 2 orbitables
function relativeInclination {
	parameter target_orbitable is TARGET, source_orbitable is SHIP.

	local src_r is source_orbitable:position - BODY:position.
	local src_v is source_orbitable:velocity:orbit.

	local tgt_r is target_orbitable:position - BODY:position.
	local tgt_v is target_orbitable:velocity:orbit.

	// angular momentum
	// h = r x v
	local src_h is VCRS(src_r,src_v).
	local tgt_h is VCRS(tgt_r,tgt_v).

	return VANG(src_h, tgt_h).
}

// returns a List(launchTime, launchHeading) to launch into the plane of a target orbitable
// ascent_time_mins: how long (in mins) to get into orbit - used to offset the launchTime
function getInclinedLaunchWindow {
	parameter target_orbitable, ascent_time_mins is 3.

	local deltaLng is 0.
	local launchHeading is 90.
	local currentLng is BODY:rotationAngle + SHIP:geoPosition:LNG.
	local targetAN is target_orbitable:OBT:LAN.
	local targetDN is targetAN + 180.

	// make sure AN/DN are ahead of us
	if targetAN < currentLng set targetAN to targetAN + 360.
	if targetDN < currentLng set targetDN to targetDN + 360.

	// use whichever node is closer
	if targetAN < targetDN {
		set deltaLng to targetAN - currentLng.
		set launchHeading to 90-target_orbitable:OBT:inclination.
	}
	else {
		set deltaLng to targetDN - currentLng.
		set launchHeading to 90+target_orbitable:OBT:inclination.
	}

	// take into account launch body rotation during ascent
	local launchBodyRotationRate is 360 / BODY:rotationPeriod.
	set deltaLng to deltaLng - ascent_time_mins/2 * launchBodyRotationRate.

	// how long till the launch window
	local waitTime is deltaLng / launchBodyRotationRate.

	return List(waitTime + TIME:seconds, launchHeading).
}

function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}

set PRT to import("util/parts").
set SYS to import("system").
set MNV to import("maneuver").
set ORB to import("orbmech").
set RDV to import("rendezvous").

lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).

wait until SHIP=KUNIVERSE:activeVessel.
wait until SHIP:unpacked.

lock orient to LOOKDIRUP(V(0,1,0),SUN:position).
local launchAlt is 100e3.
local lastStage is 0.
local insertionStage is 1.
local launchHeading is 90.
local counter is 10.

function munOccludesMinmusTransfers {
	local U0_mun is RDV["U0"](Mun).
	local U0_minmus is RDV["U0"](Minmus).
	local U0_delta is U0_mun - U0_minmus.
	return U0_delta >= -15 and U0_delta <= 30 .
}

local targetBody is Minmus.
local maxRelativeInclination is 0.01.
local targetParkingAlt is 100e3.
local targetParkingEcc is 0.001.
local targetParkingInc is 0.1.
local targetOrbitAp is 440e3.
local targetOrbitSMA is 500e3.

local allCallsigns is List("Deino","Enyo","Pemphredo").
local callsign is GetCallsign().
local separation_angle is 360 / allCallsigns:length.
local satID is 0.
until satID = allCallsigns:length if callsign = allCallsigns[satID] break. else set satID to satID + 1.
set targetID to satID - 1.
set TARGET to targetBody.
function satExists {
	parameter callsign.
	list TARGETS in allTargets.
	local iter is allTargets:iterator.
	until not iter:next {
		if iter:value:name = "KSAT - Minmus '"+callsign+"'" return TRUE.
	}
	return FALSE.
}
function getSatellite {
	parameter index.
	return Vessel("KSAT - Minmus '"+allCallsigns[index]+"'").
}

local dv is 0.
local burnTime is 0.
set throt to 0.
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
0,init@,
1,countdown@,
2,launch@,
3,inspace@,
4,calcInsertion@,
5,insertion@,
6,calcCircularize@,
7,circularize@,
8,calcTransferInclinationBurn@,
9,transferInclinationBurn@,
10,calcMinmusTransfer@,
11,minmusTransfer@,
12,tuneTransfer@,
13,coastToMinmus@,
14,calcMinmusCapture@,
15,minmusCapture@,
16,calcParkingInclinationBurn@,
17,parkingInclinationBurn@,
18,waitForAll@,
19,calcTransfer@,
20,transfer@,
21,calcFinalBurn@,
22,finalBurn@,
23,prepareFinalAdjustment@,
24,adjustSMA@,
25,done@
).

function init{parameter m,p.
	clearscreen.
	set SHIP:name to "KSAT - Minmus '"+callsign+"'".
	if satID = allCallsigns:length {
		Notify("unknown callsign: " + callsign).
		m["end"]().
		return.
	}
	local launchWindow is getInclinedLaunchWindow(targetBody).
	if launchWindow[0] - counter > TIME:seconds {
		lock launchCountdown to launchWindow[0] - TIME:seconds.
		set launchHeading to launchWindow[1].
		SetAlarm(launchWindow[0],"launch").
		m["next"]().
	}
}
function countdown{parameter m,p.
	if ceiling(launchCountdown) <= 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",launchAlt)).
		m["next"]().
	}
	else {
		if ceiling(launchCountdown) <= counter Notify("T-"+ceiling(launchCountdown)).
		wait 1.
	}
}
function launch{parameter m,p.
	if ascent() {
		WAIT 1. UNTIL STAGE:NUMBER=insertionStage SYS["SafeStage"]().
		m["next"]().
	}
}
function inspace{parameter m,p.
	purge("prg/asc").
	PRT["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate",0).
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	lock STEERING to steer.
	lock THROTTLE to throt.
	m["next"]().
}
function calcInsertion{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](15000).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis-fullburn.
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
	set dv to MNV["ChangePeDeltaV"](Ap).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:apoapsis > preburn and ETA:apoapsis < ETA:periapsis
		set burnTime to TIME:seconds + ETA:apoapsis - preburn.
	else set burnTime to TIME:seconds + 5.
	SetAlarm(burnTime,"circularize").
	m["next"]().
}
function circularize{parameter m,p.
	if Pe > BODY:ATM:height and burnEta + fullburn <= 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta<=0 set throt to 1.
}
function calcTransferInclinationBurn{parameter m,p.
	local relNodes is anomaly_of_relative_nodes(targetBody).
	local whichNode is relNodes["next"].
	local anomalyNextNode is relNodes[whichNode].
	local altNextNode is ORB["Rt"](anomalyNextNode).
	local etaNextNode is ORB["eta"](anomalyNextNode).
	set dv to 2*MNV["VisViva"](sma, altNextNode)*SIN(relativeInclination(targetBody)/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if etaNextNode > preburn + 10 {
		set burnTime to TIME:seconds + etaNextNode - preburn.
		if whichNode="AN" lock steer to -NORMALVEC.
		else lock steer to NORMALVEC.
		SetAlarm(burnTime,"match inclination").
		m["next"]().
	}
}
function transferInclinationBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(relativeInclination(targetBody),4).
	if throt > 0 {
		if theta < maxRelativeInclination {
			set throt to 0.
			m["next"]().
		}
		else if theta > lastValue {
			set throt to 0.
			m["jump"](-1).
		}
	}
	else set throt to min(1,max(0.01,theta)).
	set lastValue to round(theta,4).
}
function calcMinmusTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetBody:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	local transferAnomaly is RDV["VTransferCirc"](0, targetBody).
	local etaTransfer is RDV["etaTransferCirc"](transferAnomaly, targetBody).
	lock STEERING to orient.
	if munOccludesMinmusTransfers() return.
	if etaTransfer < preburn + 10 return.
	set burnTime to TIME:seconds + etaTransfer - preburn.
	lock steer to PROGRADE.
	SetAlarm(burnTime,"transfer").
	m["next"]().
}
function minmusTransfer{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if throt > 0 {
		if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = targetBody {
			set throt to 0.05.
			m["next"]().
		}
		else if Ap > targetBody:altitude + targetBody:soiRadius {
			set throt to 0.
			Notify("no encounter").
			m["end"]().
		}
	}
	else set throt to 1.
}
function tuneTransfer{parameter m,p.
	if not SHIP:OBT:hasNextPatch {
		set throt to 0.
		m["end"]().
	}
	else if SHIP:OBT:nextPatch:periapsis < targetParkingAlt {
		set throt to 0.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta, targetBody:name+" SOI").
		m["next"]().
	}
}
function coastToMinmus{parameter m,p.
	lock steer to orient.
	if BODY = targetBody {
		WAIT 30.
		m["next"]().
	}
}
function calcMinmusCapture{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"]((Pe + targetParkingAlt)/2+targetBody:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:transition < ETA:periapsis or ETA:periapsis < 0
		set burnTime to TIME:seconds + 10.
	else
		set burnTime to TIME:seconds + ETA:periapsis - preburn.
	lock steer to RETROGRADE.
	SetAlarm(burnTime,"capture").
	m["next"]().
}
function minmusCapture{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local x is round(ecc,6).
	if throt > 0 {
		if Ap > targetBody:radius and (x < targetParkingEcc or x > lastValue) {
			set throt to 0.
			m["next"]().
		}
	} else set throt to 1.
	set lastValue to round(ecc,6).
}
function calcParkingInclinationBurn{parameter m,p.
	if inc > targetParkingInc {
		local Ran is ORB["Rt"](ORB["Van"]()).
		local Rdn is ORB["Rt"](ORB["Vdn"]()).
		local vnode is 0.
		local whichNode is "".
		if Ran > Rdn {
			lock steer to -NORMALVEC.
			set whichNode to "AN".
			set vnode to MNV["VisViva"](sma,Ran).
		}
		else {
			lock steer to NORMALVEC.
			set whichNode to "DN".
			set vnode to MNV["VisViva"](sma,Rdn).
		}
		set dv to 2*vnode*SIN(inc/2).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		local etaNode is ORB["eta" + whichNode]().
		if etaNode > preburn + 10 {
			set burnTime to TIME:SECONDS + etaNode - preburn.
			SetAlarm(burnTime,"inclination change").
			M["next"]().
		}
	} else M["jump"](2).
}
function parkingInclinationBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(inc,4).
	if throt > 0 {
		if theta < targetParkingInc {
			set throt to 0.
			m["next"]().
		}
		else if theta > lastValue {
			set throt to 0.
			m["jump"](-1).
		}
	}
	else set throt to min(1,max(0.01,theta)).
	set lastValue to round(theta,4).
}
function waitForAll{parameter m,p.

	lock steer to orient.
	wait 60.

	local iter is allCallsigns:iterator.
	until not iter:next {
		if iter:value <> callsign {
			if not satExists(iter:value) return.
			local sat is getSatellite(iter:index).
			if sat:body <> targetBody return.
			if sat:OBT:apoapsis < 0 return.
		}
	}

	if satID>0 {
		local targetSat is getSatellite(targetID).
		if targetSat:OBT:semiMajorAxis < targetOrbitSMA*0.9 return.

		set targetOrbitSMA to getSatellite(0):OBT:semiMajorAxis.
		set TARGET to targetSat.
	}

	m["next"]().
}
function calcTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetOrbitAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).

	local etaTransfer is ETA:periapsis.
	if satID>0 {
		local transfer_anomaly is RDV["VTransferCirc"](separation_angle).
		set etaTransfer to RDV["etaTransferCirc"](transfer_anomaly).
	}
	if etaTransfer > preburn + 10 {
		set burnTime to tIME:seconds + etaTransfer - preburn.
		lock steer to PROGRADE.
		SetAlarm(burnTime,"transfer").
		m["next"]().
	}
}
function transfer{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if throt > 0 {
		if Ap >= targetOrbitAp {
			set throt to 0.
			m["next"]().
		}
		else if throt=1 and Ap >= targetOrbitAp*0.95 {
			lock throt to max(0.01, min(0.1, 0.1 - (Ap-targetOrbitAp*0.95)/(targetOrbitAp*0.5))).
		}
	}
	else if burnEta <= 0 set throt to 1.
}
function calcFinalBurn{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](min(targetOrbitAp,Ap)).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis - preburn.
	lock steer to PROGRADE.
	SetAlarm(burnTime,"finalize").
	m["next"]().
}
function finalBurn{parameter m,p.
	if dv=0 {m["end"](). Notify("failed to reach orbit"). return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if throt > 0 {
		if sma >= targetOrbitSMA {
			set throt to 0.
			m["next"]().
		}
		else if throt=1 and sma >= targetOrbitSMA*0.95 {
			lock throt to max(0.01, min(0.1, 0.1 - (sma-targetOrbitSMA*0.95)/(targetOrbitSMA*0.5))).
		}
	}
	else if burnEta <= 0 set throt to 1.
}
function prepareFinalAdjustment{parameter m,p.
	MNV["Steer"](RETROGRADE).
	wait 10.
	m["next"]().
}
function adjustSMA{parameter m,p.
	if sma > targetOrbitSMA set throt to 0.001.
	else {
		set throt to 0.
		m["next"]().
	}
}
function done{parameter m,p.
	lock STEERING to orient.
	local rt is "ModuleRTAntenna".
	PRT["DoModuleEvent"](rt,"activate").
	PRT["SetPartModuleField"]("mediumDishAntenna",rt,"target",Kerbin).
	m["next"]().
}