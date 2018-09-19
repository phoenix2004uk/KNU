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
	local waitTime is deltaLng * launchBodyRotationRate.

	return List(TIME:seconds + waitTime, launchHeading).
}

function SetAlarm{parameter t,n.AddAlarm("Raw",t,n,"").}

set PRT to import("util/parts").
set SYS to import("system").
set MNV to import("maneuver").
set ORB to import("orbmech").
set RDV to import("rendezvous").
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).

wait until SHIP=KUNIVERSE:activeVessel.

local parkingAp is 100e3.
local minmusParkingAlt is 100e3.
local minmusParkingInc is 0.1.
local targetAp is 440e3.
local targetSMA is 500e3.
local lastStage is 0.
local launchHeading is 90.
local counter is 10.
local dv is 0.
local burnTime is 0.
set throt to 0.
lock orient to PROGRADE+R(0,0,0).
lock steer to orient.
lock burnEta to burnTime - TIME:seconds.
lock STEERING to steer.
lock THROTTLE to throt.

lock Ap to ALT:apoapsis.
lock Pe to ALT:periapsis.
lock sma to SHIP:OBT:semiMajorAxis.
lock inc to SHIP:OBT:inclination.
lock ecc to SHIP:OBT:eccentricity.

local allCallsigns is List("Deino","Enyo","Pemphredo").
local callsign is GetCallsign().
set SHIP:name to "KSAT - Minmus '"+callsign+"'".
local isFirst is callsign=allCallsigns[0].
local separation_angle is 360 / allCallsigns:length.

set steps to Lex(
0,countdown@,
1,launch@,
2,inspace@,
3,calcInsertion@,
4,insertion@,
5,calcCircularize@,
6,circularize@,
7,calcTransferInclinationBurn@,
8,transferInclinationBurn@,
9,calcMinmusTransfer@,
10,minmusTransfer@,
11,tuneTransfer@,
12,coastToMinmus@,
13,calcMinmusCapture@,
14,minmusCapture@,
15,calcParkingInclinationBurn@,
16,parkingInclinationBurn@,
17,waitForAll@,
18,calcTransfer@,
19,transfer@,
20,calcFinalBurn@,
21,finalBurn@,
22,adjustSMA@,
23,done@
).

if not isFirst {
	set first to Vessel("KSAT - Minmus '"+allCallsigns[0]+"'").
	local iter is allCallsigns:iterator.
	until not iter:next if callsign=iter:value set TARGET to Vessel("KSAT - Minmus '"+allCallsigns[iter:index-1]+"'").
}

local launchWindow is getInclinedLaunchWindow(Minmus).
lock launchCountdown to launchWindow[0] - TIME:seconds.
set launchHeading to launchWindow[1].
SetAlarm(launchWindow,"launch").

function countdown{parameter m,p.
	if launchCountdown = 0 {
		Notify("Launch").
		set ascent to import("prg/asc")["new"](Lex("heading",launchHeading,"lastStage",lastStage,"alt",parkingAp)).
		m["next"]().
	}
	else {
		if launchCountdown - counter <= 10 Notify("T-"+counter).
		wait 1.
	}
}
function launch{parameter m,p.
	if ascent() m["next"]().
}
function inspace{parameter m,p.
	purge("prg/asc").
	PRT["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate",0).
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	lock STEERING to steer.
	lock THROTTLE to throt.
}
function calcInsertion{parameter m,p.
	set targetPe to MIN(parkingAp, Ap).
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
function calcTransferInclinationBurn{parameter m,p.
	local relNodes is anomaly_of_relative_nodes(Minmus).
	local whichNode is relNodes["next"].
	local anomalyNextNode is relNodes[whichNode].
	local altNextNode is ORB["Rt"](anomalyNextNode).
	local etaNextNode is ORB["eta"](anomalyNextNode).
	set dv to 2*MNV["VisViva"](sma, altNextNode)*SIN(relativeInclination()/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	//set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + etaNextNode - preburn.
	if whichNode="AN" lock steer to -NORMALVEC.
	else lock steer to NORMALVEC.
	SetAlarm(burnTime,"match inclination").
	m["next"].
}
function transferInclinationBurn{parameter m,p.
	if relativeInclination() < 0.01 or burnEta + fullburn <= 0 {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function calcMinmusTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](Minmus:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	local transferAnomaly to RDV["VTransferCirc"](0, Minmus).
	set burnTime to TIME:seconds + RDV["etaTransferCirc"](transferAnomaly, Minmus) - preburn.
	SetAlarm(burnTime,"transfer").
}
function minmusTransfer{parameter m,p.
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Minmus {
		set throt to 0.2.
		m["next"]().
	}
	else if Ap > Minmus:altitude + Minmus:soiRadius {
		set throt to 0.
		m["end"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function tuneTransfer{parameter m,p.
	if not SHIP:OBT:hasNextPatch m["end"]().
	else if SHIP:OBT:nextPatch:periapsis < minmusParkingAlt {
		set throt to 0.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta,"Minmus SOI").
		m["next"]().
	}
}
function coastToMinmus{parameter m,p.
	lock steer to orient.
	if BODY = Minmus {
		local rt is "ModuleRTAntenna".
		PRT["DoModuleEvent"](rt,"activate").
		PRT["SetPartModuleField"]("mediumDishAntenna",rt,"target",Kerbin).
		WAIT 30.
		m["next"]().
	}
}
function calcMinmusCapture{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"]((Pe + minmusParkingAlt)/2+Minmus:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set burnTime to TIME:seconds + ETA:periapsis-preburn.
	lock steer to RETROGRADE.
	SetAlarm(burnTime,"capture").
	m["next"]().
}
function minmusCapture{parameter m,p.
	if Ap > 0 and Ap < minmusParkingAlt {
		set throt to 0.
		m["next"]().
	}
	else if burnEta <= 0 set throt to 1.
}
function calcParkingInclinationBurn{parameter m,p.
	if inc > minmusParkingInc {
		local Ran is ORB["Rt"](ORB["Van"]()).
		local Rdn is ORB["Rt"](ORB["Vdn"]()).
		local vnode is 0.
		if Ran > Rdn {
			lock steer to -NORMALVEC.
			set burnTime to TIME:SECONDS + ORB["etaAN"]().
			set vnode to MNV["VisViva"](sma,Ran).
		}
		else {
			lock steer to NORMALVEC.
			set burnTime to TIME:SECONDS + ORB["etaDN"]().
			set vnode to MNV["VisViva"](sma,Rdn).
		}
		set dv to 2*vnode*SIN(inc/2).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set lastInc to inc.
		M["next"]().
	} else M["jump"](2).
}
function parkingInclinationBurn{parameter m,p.
	if throt > 0 {
		if inc < minmusParkingInc or round(inc - lastInc,6) > 0 {
			set throt to 0.
			M["next"]().
		}
		else if inc < maxInc*10 set throt to 0.1.
		else if inc < maxInc*2 set throt to 0.01.
	}
	else if burnEta <= 0 set throt to 1.
	set lastInc to inc.
}
function waitForAll{parameter m,p.
	LIST TARGETS in allTargets.
	local outer is allTargets:iterator.
	local allInOrbit is 0.
	until not outer:next {
		local inner is allCallsigns:iterator.
		until not inner:next {
			local name is "KSAT - Minmus '"+inner:value+"'".
			if outer:value:name = name {
				local vsl is Vessel(name).
				if vsl:OBT:BODY=Minmus and vsl:OBT:apoapsis > 0 set allInOrbit to allInOrbit + 1.
			}
		}
	}
	if allInOrbit = allCallsigns:length-1 {
		if isFirst m["next"]().
		else if TARGET:OBT:body=Minmus and TARGET:OBT:semiMajorAxis > targetSMA*0.9 {
			set targetSMA to first:OBT:semiMajorAxis.
			m["next"]().
		}
	}
	wait 10.
}
function calcTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	if isFirst set burnTime to TIME:seconds + ETA:periapsis-preburn.
	else {
		local transfer_anomaly to RDV["VTransferCirc"](separation_angle).
		set burnTime to TIME:seconds + RDV["etaTransferCirc"](transfer_anomaly)-preburn.
	}
	SetAlarm(burnTime,"transfer").
	m["next"]().
}
function transfer{parameter m,p.
	if dv=0 m["jump"](-1).
	else if Ap >= targetAp {
		set throt to 0.
		m["next"]().
	}
	else if throt=1 and Ap >= targetAp*0.95 {
		lock throt to max(0.01, min(0.1, 0.1 - (Ap-targetAp*0.95)/(targetAp*0.5))).
	}
	else if throt=0 and burnEta<=0 set throt to 1.
}
function calcFinalBurn{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](min(targetAp,Ap)).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set burnTime to TIME:seconds + ETA:apoapsis-preburn.
	SetAlarm(burnTime,"finalize").
	m["next"]().
}
function finalBurn{parameter m,p.
	if dv=0 m["jump"](-1).
	else if sma >= targetSMA {
		set throt to 0.
		m["next"]().
	}
	else if throt=1 and sma >= targetSMA*0.95 {
		lock throt to max(0.01, min(0.1, 0.1 - (sma-targetSMA*0.95)/(targetSMA*0.5))).
	}
	else if throt=0 and burnEta<=0 set throt to 1.
}
function adjustSMA{parameter m,p.
	MNV["Steer"](RETROGRADE).
	if sma > targetSMA set throt to 0.001.
	else {
		set throt to 0.
		m["next"]().
	}
}
function done{parameter m,p.
	lock steer to orient.
	m["next"]().
}