set SYS to import("system").
set MNV to import("maneuver").
set ASC to import("ascent").
set ORD to import("ordinal").
set RDV to import("rendezvous").
set TLM to import("telemetry").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
wait until SHIP:unpacked.

local targetBody is Minmus.
local launchAlt is 100e3.
local launchHeading is 90.
local counter is 10.
local launchCountdown is counter.
local launchProfile is ASC["defaultProfile"].
local orbitStage is 1.
local insertionStage is 2.

lock orient to ORD["sun"]().
lock steer to orient.
lock STEERING to steer.
set throt to 0.
lock THROTTLE to throt.
local dv is 0.
local burnTime is 0.
lock burnEta to burnTime - TIME:seconds.
lock Ap to ALT:apoapsis.
lock Pe to ALT:periapsis.
lock sma to SHIP:OBT:semiMajorAxis.
lock inc to SHIP:OBT:inclination.
lock ecc to SHIP:OBT:eccentricity.

set steps to Lex(
0,prelaunch@,
1,countdown@,
2,launch@,
2.1,ascentWithBoosters@,
2.2,ascent@,
2.3,coastToSpace@,
2.4,inspace@,
2.5,calcInsertion@,
2.6,insertion@,
2.7,calcCircularize@,
2.8,circularize@
).

function prelaunch {parameter m,p.
	set SHIP:CONTROL:pilotMainThrottle to 0.
	set throt to 0.
	local launchWindow is RDV["inclinedLaunchWindow"](targetBody).
	if launchWindow[0] - counter < TIME:seconds return.
	lock launchCountdown to launchWindow[0] - TIME:seconds.
	set launchHeading to launchWindow[1].
	SetAlarm(launchWindow[0],"launch").
	lock steer to HEADING(launchHeading, ASC["pitchTarget"](launchProfile)) + R(0,0,ASC["rollTarget"](launchProfile)).
	m["next"]().
}
function countdown{parameter m,p.
	if round(launchCountdown) <= 10 {
		if counter <= 0 {
			Notify("Launch").
			m["next"]().
		}
		else {
			Notify("T-"+counter).
			set counter to counter - 1.
			wait 1.
		}
	}
}
function launch{parameter m,p.
	lock throt to TLM["constantTWR"](2).
	UNTIL SHIP:availableThrust > 1 SYS["SafeStage"]().
	m["next"]().
}
function ascentWithBoosters{parameter m,p.
	if SYS["Burnout"]() {
		//SYS["SafeStage"]().
		STAGE.
		m["next"]().
	}
	else if STAGE:solidFuel = 0 m["next"]().
	else set launchProfile["a0"] to ALTITUDE.
}
function ascent{parameter m,p.
	SYS["Burnout"](TRUE, insertionStage).
	lock THROTTLE to throt.
	if Ap > launchAlt {
		set throt to 0.
		WAIT 1. UNTIL STAGE:NUMBER=insertionStage SYS["SafeStage"]().
		m["next"]().
	}
	else if ALTITUDE > BODY:ATM:height / 2 set throt to 1.
}
function coastToSpace{parameter m,p.
	if ALTITUDE > BODY:ATM:height {
		m["next"]().
	}
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
		set throt to 0.
		WAIT 1. UNTIL STAGE:NUMBER=orbitStage SYS["SafeStage"]().
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