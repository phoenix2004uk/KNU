set SYS to import("system").
set SCI to import("science").
set ASC to import("ascent").
set TLM to import("telemetry").

local launchProfile is ASC["defaultProfile"].
local counter is 10.
local launchCountdown is counter.
local launchHeading is 90.

lock steer to UP.
lock STEERING to steer.
set throt to 0.
lock THROTTLE to throt.

// setup abort procedure
ON ABORT {
	main["enable"]("abort").
}

set events to Lex(
	"abort", deployChutes@
).
set active to 0.
set steps to Lex(
0,	prelaunch@,
1,	countdown@,
2,	launch@,
3,	ascentWithBoosters@,
4,	ascent@,
5,	doScience@,
6,	triggerAbort@,
7,	land@,
8,	done@
).

local lastSpeed is 0.
function deployChutes{parameter m,p.
	if SHIP:verticalSpeed < lastSpeed {
		set lastSpeed to SHIP:verticalSpeed.
		return.
	}
	if STAGE:number > 1 and SHIP:velocity:surface:mag < 250 and SHIP:verticalSpeed < 0 {
		until STAGE:number = 1 SYS["SafeStage"]().

	}
	if not GEAR and ALT:RADAR < 500 {
		GEAR ON.
		unlock STEERING.
	}
}


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
	m["next"]().
}
function ascentWithBoosters{parameter m,p.
	if SYS["Burnout"]() {
		STAGE.
		m["next"]().
	}
	else if STAGE:solidFuel = 0 m["next"]().
	else set launchProfile["a0"] to ALTITUDE.
}
function ascent{parameter m,p.
	SYS["Burnout"](TRUE, 2).
	lock THROTTLE to throt.
	if SHIP:parts:length < 16 or SHIP:LiquidFuel = 0 m["next"]().
}
function doScience{parameter m,p.
	if ALTITUDE > 20000 or ALT:apoapsis < 20000 {
		SCI["run"]["science.module"](FALSE).
		SCI["run"]["GooExperiment"](FALSE,0).
		m["next"]().
	}
}
function triggerAbort{parameter m,p.
	m["enable"]("abort").
	lock steer to srfRetrograde.
	m["next"]().
}
function land{parameter m,p.
	if STATUS = "LANDED" {
		m["next"]().
	}
}
function done{parameter m,p.
	SCI["run"]["GooExperiment"](FALSE,1).
	m["next"]().
}