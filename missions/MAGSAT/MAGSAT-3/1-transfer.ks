set MNV to import("maneuver").
set ORB to import("orbmech").
set ORD to import("ordinal").
set RDV to import("rendezvous").

function munOccludesMinmusTransfers {
	local U0_mun is RDV["U0"](Mun).
	local U0_minmus is RDV["U0"](Minmus).
	local U0_delta is U0_mun - U0_minmus.
	return U0_delta >= -15 and U0_delta <= 30 .
}

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
0,	calcInclinationCorrection@,
1,	inclinationCorrection@,
2,	calcTransfer@,
3,	transfer@,
4,	tuneTransfer@,
5,	coastSoi@
).

function calcInclinationCorrection{parameter m,p.
	local relNodes is RDV["relativeNodes"](Minmus).
	local whichNode is relNodes["next"].
	local anomalyNextNode is relNodes[whichNode].
	local altNextNode is ORB["Rt"](anomalyNextNode).
	local etaNextNode is ORB["eta"](anomalyNextNode).
	set dv to 2*MNV["VisViva"](sma, altNextNode)*SIN(RDV["relativeInclination"](Minmus)/2).
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
function inclinationCorrection{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	local theta is round(RDV["relativeInclination"](Minmus),4).
	if THROTTLE > 0 {
		if theta < 0.01 {
			set THROTTLE to 0.
			m["next"]().
		}
		else if theta > lastValue {
			set THROTTLE to 0.
			m["jump"](-1).
		}
	}
	else lock THROTTLE to min(1,max(0.01,theta)).
	set lastValue to round(theta,4).
}
function calcTransfer{parameter m,p.
	set dv to MNV["ChangeApDeltaV"](Minmus:altitude).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	local transferAnomaly is RDV["transferAnomalyCirc"](0, Minmus).
	local etaTransfer is RDV["transferEtaCirc"](transferAnomaly, Minmus).
	lock STEERING to orient.
	if munOccludesMinmusTransfers() return.
	if etaTransfer < preburn + 10 return.
	set burnTime to TIME:seconds + etaTransfer - preburn.
	lock steer to PROGRADE.
	SetAlarm(burnTime,"transfer").
	m["next"]().
}
function transfer{parameter m,p.
	if dv=0 {m["jump"](-1).return.}

	if burnEta < 30 lock STEERING to steer.
	else lock STEERING to orient.
	if burnEta > 0 return.

	if THROTTLE > 0 {
		if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Minmus {
			set THROTTLE to 0.05.
			m["next"]().
		}
		else if Ap > Minmus:altitude + Minmus:soiRadius {
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
	else if SHIP:OBT:nextPatch:periapsis < 30000 {
		set THROTTLE to 0.
		SetAlarm(TIME:seconds+SHIP:OBT:nextPatchEta, Minmus:name+" SOI").
		m["next"]().
	}
}
function coastSoi{parameter m,p.
	lock steer to orient.
	if BODY = Minmus {
		WAIT 30.
		m["next"]().
	}
}