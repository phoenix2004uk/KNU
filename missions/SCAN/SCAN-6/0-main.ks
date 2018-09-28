set SYS to import("system").
set ASC to import("ascent").
set MNV to import("maneuver").
set ORB to import("orbmech").
set ORD to import("ordinal").
set RDV to import("rendezvous").
set ISH to import("util/ish").
set TLM to import("telemetry").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
function munOccludesMinmusTransfers {
	local U0_mun is RDV["U0"](Mun).
	local U0_minmus is RDV["U0"](Minmus).
	local U0_delta is U0_mun - U0_minmus.
	return U0_delta >= -15 and U0_delta <= 30 .
}

function burnStart {
parameter currentValue, targetValue, ishyness is 0, throtStart is 1.
if THROTTLE = 0 {
	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return false.

	set burnTarget to targetValue.
	set burnIsh to ishyness.
	set THROTTLE to throtStart.
	set firstValue to round(currentValue, 6).
	set lastDelta to abs(firstValue - targetValue).
}
return true.
}
function burnDiverged {
parameter currentValue.
local thisDelta is abs(round(currentValue, 6) - burnTarget).
if THROTTLE > 0 and thisDelta > lastDelta {
	set THROTTLE to 0.
	return true.
}
set lastDelta to thisDelta.
return false.
}
function burnTargetLess {
parameter currentValue.
if THROTTLE > 0 and round(currentValue, 6) < burnTarget {
	set THROTTLE to 0.
	return true.
}
return false.
}
function burnTargetEqual {
parameter currentValue.
if THROTTLE > 0 and ISH["value"](round(currentValue, 6), burnTarget, burnIsh) {
	set THROTTLE to 0.
	return true.
}
return false.
}
function burnProgress {
parameter currentValue.
return (round(currentValue, 6) - firstValue) / (burnTarget - firstValue).
}

wait until SHIP:unpacked.

local launchAlt is 100e3.
local launchHeading is 90.
local counter is 10.
local launchCountdown is counter.
local launchProfile is ASC["defaultProfile"].
local orbitStage is 0.
local insertionStage is 1.

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

local targetBody is Minmus.
local maxRelativeInclination is 0.01.
local targetOrbitAp is 250e3.
local targetOrbitApIsh is 500.
local targetOrbitMaxEcc is 0.0021.
local targetOrbitInc is 76.95.
local targetOrbitIncIsh is 0.1.

set steps to Lex(
0,prelaunch@,
10,countdown@,
20,launch@,
21,ascentWithBoosters@,
22,ascent@,
23,coastToSpace@,
24,inspace@,
25,calcInsertion@,
26,insertion@,
27,calcCircularize@,
28,circularize@,
30,calcTransferInclinationBurn@,
31,transferInclinationBurn@,
32,calcTransferBurn@,
33,transferBurn@,
34,tuneTransfer@,
35,coastSoi@,
40,calcInclinationBurn@,
41,incBurn@,
42,calcCaptureBurn@,
43,eccBurn@,
50,calcRaiseTargetApBurn@,
51,apBurn@,
52,calcLowerTargetPeBurn@,
53,peBurn@,
54,calcLowerTargetApBurn@,
55,apBurn@,
56,calcCircularizeTargetBurn@,
57,eccBurn@,
99,done@
).

function prelaunch {parameter m,p.
	set SHIP:CONTROL:pilotMainThrottle to 0.
	set THROTTLE to 0.
	local launchWindow is RDV["inclinedLaunchWindow"](targetBody).
	if launchWindow[0] - 10 < TIME:seconds return.
	lock launchCountdown to launchWindow[0] - TIME:seconds.
	set launchHeading to launchWindow[1].
	SetAlarm(launchWindow[0],"launch").
	lock steer to HEADING(launchHeading, ASC["pitchTarget"](launchProfile)) + R(0,0,ASC["rollTarget"](launchProfile)).
	m["next"]().
}
function countdown{parameter m,p.
	if round(launchCountdown) <= 10 {
		if counter <= 0 {Notify("Launch"). m["next"]().}
		else {Notify("T-"+counter). set counter to counter - 1. wait 1.}
	}
}
function launch{parameter m,p.
	lock THROTTLE to TLM["constantTWR"](2).
	UNTIL SHIP:availableThrust > 1 SYS["SafeStage"]().
	m["next"]().
}
function ascentWithBoosters{parameter m,p.
	if STAGE:solidFuel = 0 m["next"]().
	else if SYS["Burnout"]() {
		set launchProfile["a0"] to ALTITUDE.
		SYS["SafeStage"]().
		m["next"]().
	}
}
function ascent{parameter m,p.
	SYS["Burnout"](TRUE, orbitStage).
	lock THROTTLE to THROTTLE.
	if Ap > launchAlt {
		set THROTTLE to 0.
		WAIT 1. UNTIL STAGE:NUMBER=insertionStage SYS["SafeStage"]().
		m["next"]().
	}
	else if ALTITUDE > BODY:ATM:height / 2 set THROTTLE to 1.
}
function coastToSpace{parameter m,p.
	if ALTITUDE > BODY:ATM:height m["next"]().
}
function inspace{parameter m,p.
	PANELS ON.
	LIGHTS ON.
	lock steer to PROGRADE+R(0,0,0).
	m["next"]().
}
function calcInsertion{parameter m,p.
	set dv to MNV["ChangePeDeltaV"](15000).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + ETA:apoapsis - fullburn.
	SetAlarm(burnTime,"insertion").
	m["next"]().
}
function insertion{parameter m,p.
	if Pe >= 15000 {
		set THROTTLE to 0.
		WAIT 1. UNTIL STAGE:NUMBER=orbitStage SYS["SafeStage"]().
		m["next"]().
	}
	else if burnEta<=0 set THROTTLE to 1.
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
		set THROTTLE to 0.
		m["next"]().
	}
	else if burnEta<=0 set THROTTLE to 1.
}
function calcTransferInclinationBurn{parameter m,p.
	local relNodes is RDV["relativeNodes"](targetBody).
	local whichNode is relNodes["next"].
	local anomalyNextNode is relNodes[whichNode].
	local altNextNode is ORB["Rt"](anomalyNextNode).
	local etaNextNode is ORB["eta"](anomalyNextNode).
	set dv to 2*MNV["VisViva"](sma, altNextNode)*SIN(RDV["relativeInclination"](targetBody)/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if etaNextNode > preburn + 10 {
		set burnTime to TIME:seconds + etaNextNode - preburn.
		if whichNode="AN" lock steer to -ORD["normal"]().
		else lock steer to ORD["normal"]().
		SetAlarm(burnTime,"match inclination").
		m["next"]().
	}
}
function transferInclinationBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(RDV["relativeInclination"](targetBody),4).
	if THROTTLE > 0 {
		if theta < maxRelativeInclination {
			set THROTTLE to 0.
			m["next"]().
		}
		else if theta > lastValue {
			set THROTTLE to 0.
			m["jump"](-1).
		}
	}
	else set THROTTLE to min(1,max(0.01,theta)).
	set lastValue to round(theta,4).
}
function calcTransferBurn{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](targetBody:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	local transferAnomaly is RDV["transferAnomalyCirc"](0, targetBody).
	local etaTransfer is RDV["transferEtaCirc"](transferAnomaly, targetBody).
	lock STEERING to orient.
	if munOccludesMinmusTransfers() return.
	if etaTransfer < preburn + 10 return.
	set burnTime to TIME:seconds + etaTransfer - preburn.
	lock steer to PROGRADE.
	SetAlarm(burnTime,"transfer").
	m["next"]().
}
function transferBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if THROTTLE > 0 {
		if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = targetBody {
			set THROTTLE to 0.05.
			m["next"]().
		}
		else if Ap > targetBody:altitude + targetBody:soiRadius {
			set THROTTLE to 0.
			Notify("no encounter").
			m["end"]().
		}
	}
	else set THROTTLE to 1.
}
function tuneTransfer{parameter m,p.
	if not SHIP:OBT:hasNextPatch {
		set THROTTLE to 0.
		m["end"]().
	}
	else if SHIP:OBT:nextPatch:periapsis < targetOrbitAp + targetOrbitApIsh {
		set THROTTLE to 0.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta, targetBody:name+" SOI").
		m["next"]().
	}
}
function coastSoi{parameter m,p.
	lock steer to orient.
	if BODY = targetBody {
		WAIT 30.
		m["next"]().
	}
}
function calcInclinationBurn{parameter m,p.
	local dir is SHIP:latitude / abs(SHIP:latitude).
	if inc < targetOrbitInc - targetOrbitIncIsh lock steer to -dir*ORD["normal"]().
	else if inc > targetOrbitInc + targetOrbitIncIsh lock steer to dir*ORD["normal"]().
	else {m["jump"](2). return.}
	set dv to 2*SHIP:velocity:orbit:mag*SIN(abs(inc-targetOrbitInc)/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set burnTime to TIME:seconds + max(10,fullburn).
	SetAlarm(burnTime,"inclination change").
	m["next"]().
}
function incBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}
	if burnStart(inc,targetOrbitInc,targetOrbitIncIsh) {
		local pct is burnProgress(inc).
		if burnTargetEqual(inc) m["next"]().
		else if burnDiverged(inc) m["jump"](-1).
		else if pct>0.8 lock THROTTLE to max(0.01,1-pct).
	}
}
function calcCaptureBurn{parameter m,p.
	local vpe is MNV["VisViva"](sma, Pe).
	local vca is MNV["VisViva"]((Pe + targetOrbitAp)/2+targetBody:radius, Pe).
	set dv to vpe - vca.
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:transition < ETA:periapsis or ETA:periapsis < 0 set burnTime to TIME:seconds + 10.
	else set burnTime to TIME:seconds + ETA:periapsis - preburn.
	lock steer to RETROGRADE.
	SetAlarm(burnTime,"capture").
	m["next"]().
}
function eccBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}
	if burnStart(ecc,targetOrbitMaxEcc) and Ap>0 {
		local pct is burnProgress(ecc).
		if burnTargetLess(ecc) or burnDiverged(ecc) m["next"]().
		else if pct>0.8 lock THROTTLE to max(0.01,1-pct).
	}
}
function calcRaiseTargetApBurn{parameter m,p.
	if Ap < targetOrbitAp - targetOrbitApIsh lock steer to PROGRADE.
	else {m["jump"](2). return.}
	set dv to MNV["ChangeApDeltaV"](targetOrbitAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:periapsis < preburn return.
	set burnTime to TIME:seconds + ETA:periapsis - preburn.
	SetAlarm(burnTime, "raise ap").
	m["next"]().
}
function apBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}
	if burnStart(Ap,targetOrbitAp,targetOrbitApIsh,0.1) {
		local pct is burnProgress(Ap).
		if burnTargetEqual(Ap) m["next"]().
		else if burnDiverged(Ap) m["jump"](-1).
		else if pct>0.8 lock THROTTLE to max(0.01,1-pct).
	}
}
function calcLowerTargetPeBurn{parameter m,p.
	if Pe > targetOrbitAp + targetOrbitApIsh lock steer to RETROGRADE.
	else {m["jump"](2). return.}
	set dv to MNV["ChangePeDeltaV"](targetOrbitAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:apoapsis < preburn return.
	set burnTime to TIME:seconds + ETA:apoapsis - preburn.
	SetAlarm(burnTime, "lower pe").
	m["next"]().
}
function peBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}
	if burnStart(Pe,targetOrbitAp,targetOrbitApIsh,0.1) {
		local pct is burnProgress(Pe).
		if burnTargetEqual(Pe) m["next"]().
		else if burnDiverged(Pe) m["jump"](-1).
		else if pct>0.8 lock THROTTLE to max(0.01,1-pct).
	}
}
function calcLowerTargetApBurn{parameter m,p.
	if Ap > targetOrbitAp + targetOrbitApIsh lock steer to RETROGRADE.
	else {m["jump"](2). return.}
	set dv to MNV["ChangeApDeltaV"](targetOrbitAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:periapsis < preburn return.
	set burnTime to TIME:seconds + ETA:periapsis - preburn.
	SetAlarm(burnTime, "lower ap").
	m["next"]().
}
function calcCircularizeTargetBurn{parameter m,p.
	if ecc > targetOrbitMaxEcc lock steer to PROGRADE.
	else {m["jump"](2). return.}
	set dv to MNV["ChangePeDeltaV"](targetOrbitAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if ETA:apoapsis < preburn return.
	set burnTime to TIME:seconds + ETA:apoapsis - preburn.
	SetAlarm(burnTime, "circularize").
	m["next"]().
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