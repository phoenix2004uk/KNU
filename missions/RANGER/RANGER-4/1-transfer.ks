set MNV to import("maneuver").
set RDV to import("rendezvous").
set ORD to import("ordinal").
set ORB to import("orbmech").
set TLM to import("telemetry").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
function munOccludesMinmusTransfers {
	local U0_mun is RDV["U0"](Mun).
	local U0_minmus is RDV["U0"](Minmus).
	local U0_delta is U0_mun - U0_minmus.
	return U0_delta >= -15 and U0_delta <= 30 .
}
wait until SHIP:unpacked.

local targetBody is Minmus.
local capturePeriapsis is List(10000,30000).
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
0,	calcTransferInclination@,
1,	transferInclination@,
2,	calcTransfer@,
3,	transfer@,
4,	tuneCloseApproach@,
5,	coastSoi@,
6,	calcCapture@,
7,	capture@,
8,	calcInclinationBurn@,
9,	inclinationBurn@,
10,	calcLowerPe@,
11,	lowerPe@,
12,	calcLowerAp@,
13,	lowerAp@,
14,	done@
).

function calcTransferInclination{parameter m,p.
	local relNodes is RDV["relativeNodes"](targetBody).
	local whichNode is relNodes["next"].
	local anomalyNextNode is relNodes[whichNode].
	local altNextNode is ORB["Rt"](anomalyNextNode).
	local etaNextNode is ORB["eta"](anomalyNextNode).
	set dv to 2*MNV["VisViva"](sma, altNextNode)*SIN(RDV["relativeInclination"](targetBody)/2).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	if etaNextNode < preburn + 10 return.
	set burnTime to TIME:seconds + etaNextNode - preburn.
	if whichNode="AN" lock steer to -ORD["normal"]().
	else lock steer to ORD["normal"]().
	SetAlarm(burnTime,"match inclination").
	m["next"]().
}
function transferInclination{parameter m,p.
	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(RDV["relativeInclination"](targetBody),4).
	if THROTTLE > 0 {
		if theta < 0.01 {
			lock THROTTLE to 0.
			m["next"]().
		}
		else if theta > lastValue {
			lock THROTTLE to 0.
			m["jump"](-1).
		}
	}
	else lock THROTTLE to min(1,max(0.01,theta)).
	set lastValue to round(theta,4).
}
function calcTransfer{parameter m,p.
	if munOccludesMinmusTransfers() return.
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
	if THROTTLE > 0 {
		if Ap > targetBody:altitude - 2*targetBody:soiRadius {
			lock THROTTLE to TLM["constantTWR"](0.1).
		}
		if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = targetBody {
			lock THROTTLE to TLM["constantTWR"](0.01).
			m["next"]().
		}
		else if Ap > targetBody:altitude + targetBody:soiRadius {
			lock THROTTLE to 0.
			m["end"]().
		}
	}
	else if burnEta <= 0 lock THROTTLE to 1.
}
function tuneCloseApproach{parameter m,p.
	if not SHIP:OBT:hasNextPatch {
		lock THROTTLE to 0.
		m["end"]().
	}
	else if SHIP:OBT:nextPatch:periapsis > capturePeriapsis[0] and SHIP:OBT:nextPatch:periapsis < capturePeriapsis[1] {
		lock THROTTLE to 0.
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
	local vca is MNV["VisViva"](Pe+targetBody:radius, Pe).
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
		lock THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 lock THROTTLE to 1.
}
function calcInclinationBurn{parameter m,p.
	if inc > 0.05 {
		local Ran is ORB["Rt"](ORB["Van"]()).
		local Rdn is ORB["Rt"](ORB["Vdn"]()).
		local vnode is 0.
		local whichNode is "".
		if Ran > Rdn {
			lock steer to -ORD["normal"]().
			set whichNode to "AN".
			set vnode to MNV["VisViva"](sma,Ran).
		}
		else {
			lock steer to ORD["normal"]().
			set whichNode to "DN".
			set vnode to MNV["VisViva"](sma,Rdn).
		}
		set dv to 2*vnode*SIN(inc/2).
		set preburn to MNV["GetManeuverTime"](dv/2,0.1).
		set fullburn to MNV["GetManeuverTime"](dv,0.1).
		local etaNode is ORB["eta" + whichNode]().
		if etaNode > preburn + 10 {
			set burnTime to TIME:SECONDS + etaNode - preburn.
			SetAlarm(burnTime,"inclination change").
			M["next"]().
		}
	} else M["jump"](2).
}
function inclinationBurn{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(inc,4).
	if THROTTLE > 0 {
		if theta < 0.05 {
			lock THROTTLE to 0.
			m["next"]().
		}
		else if theta > lastValue {
			lock THROTTLE to 0.
			m["jump"](-1).
		}
	}
	else lock THROTTLE to 0.1.
	set lastValue to round(theta,4).
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
		lock THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 lock THROTTLE to 1.
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
		lock THROTTLE to 0.
		m["next"]().
	}
	else if burnEta <= 0 lock THROTTLE to 1.
}
function done{parameter m,p.
	lock steer to orient.
	m["next"]().
}