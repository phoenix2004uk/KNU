set SYS to import("system").
set MNV to import("maneuver").
set ASC to import("ascent").
set ORD to import("ordinal").
set TLM to import("telemetry").
set PRT to import("util/parts").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n+" margin","").AddAlarm("Raw",t,n,"").}
function EtaAlarm{parameter n.
	for alarm in ListAlarms("All") if alarm:name = n return alarm:remaining.
	return -1.
}

wait until SHIP=KUNIVERSE:activeVessel.
wait until SHIP:unpacked.

local launchAlt is 100e3.
local launchHeading is 90.
local counter is 10.
local launchCountdown is counter.
local launchProfile is ASC["defaultProfile"].
local insertionStage is 4.
local orbitStage is 3.
local chuteStage is 1.

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

local abortModes is Lex(
"PRELAUNCH", abortAscentKerbin@,
"FLYING", abortAscentKerbin@,
"SUBORBITAL", abortAscentKerbin@
).

function abortAscentKerbin {parameter m.
	lock THROTTLE to 0.
	wait 0.
	PRT["DoModuleEvent"]("ModuleDecouple", "decouple").
	PRT["DoModuleEvent"]("ModuleEngines", "activate engine").
	wait 10.
	lock STEERING to srfRetrograde.
	wait until SHIP:verticalSpeed < 0.
	local lastSpeed is 0.
	if ALT:RADAR < 3000 {
		PRT["DoModuleAction"]("RealChuteModule", "deploy chute").
	}
	else {
		until SHIP:verticalSpeed > lastSpeed {set lastSpeed to SHIP:verticalSpeed. wait 1.}
		wait until SHIP:velocity:surface:mag < 250 or ALT:RADAR < 3000.
		PRT["DoModuleAction"]("RealChuteModule", "arm parachute").
	}
	PRT["DoModuleEvent"]("ModuleDecouple", "jettison heat shield").
	wait until ALT:RADAR < 500.
	GEAR ON.
	unlock STEERING.
	m["end"]().
	m["jump"](-1).
}

local letAbort is FALSE.
ON ABORT { set letAbort to TRUE. }
set events to Lex(
	"abort", {parameter m,p.
		if letAbort and abortModes:hasKey(STATUS) abortModes[STATUS](m).
	}
).

set steps to Lex(
0,	prelaunch@,
1,	countdown@,
2,	launch@,
3,	ascentWithBoosters@,
4,	ascent@,
5,	coastToSpace@,
6,	inspace@,
7,	calcInsertion@,
8,	insertion@,
9,	calcCircularize@,
10,	circularize@,
11,	startOrbits@,
12,	finishOrbits@,
13,	deorbit@,
14, landed@
).

function prelaunch {parameter m,p.
	set SHIP:CONTROL:pilotMainThrottle to 0.
	set throt to 0.
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
	if STAGE:solidFuel = 0 m["jump"](2).
	else m["next"]().
}
function ascentWithBoosters{parameter m,p.
	if SYS["Burnout"]() {
		SYS["SafeStage"]().
		m["next"]().
	}
	else set launchProfile["a0"] to ALTITUDE.
}
function ascent{parameter m,p.
	SYS["Burnout"](TRUE, orbitStage).
	lock THROTTLE to throt.
	if Ap > launchAlt {
		set throt to 0.
		WAIT 1. UNTIL STAGE:NUMBER<=insertionStage SYS["SafeStage"]().
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
function startOrbits{parameter m,p.
	SetAlarm(TIME:seconds + 72*60*60,"72hr").
	m["next"]().
}
function finishOrbits{parameter m,p.
	if EtaAlarm("72hr") < 0 m["next"]().
}
function deorbit{parameter m,p.
	lock steer to RETROGRADE.
	wait 10.
	set throt to 1.
	wait until Pe < 25000.
	set throt to 0.
	lock steer to srfRetrograde.
	wait until ALTITUDE < BODY:ATM:height.
	UNTIL STAGE:NUMBER=chuteStage SYS["SafeStage"]().
	PANELS OFF.
	wait until ALT:RADAR < 500.
	GEAR ON.
	unlock STEERING.
	m["next"]().
}
function landed{parameter m,p.
	if STATUS = "LANDED" or STATUS = "SPLASHED" {
		SAS ON.
		m["next"]().
	}
}