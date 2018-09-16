LOCAL partLib IS import("util/parts").
LOCAL SYS IS import("system").
LOCAL MNV IS import("maneuver").
LOCAL SCI IS import("science").
CLEARSCREEN.

function doScience{
	SCI["run"]["dmmagBoom"]().
	SCI["run"]["rpwsAnt"]().
}

local targetAP is 1000000.
local targetPE is 250000.
local lastStage is 0.
local launchHeading is 0.

LOCAL countdown IS 10.
SET steps TO Lex(
"countdown",{parameter m,p.
	IF countdown > 0 {
		Notify("Launching in T-"+ROUND(countdown,0)).
		SET countdown TO countdown - 1.
		WAIT 1.
	}
	ELSE {
		Notify("T-0 Lift Off").
		SET asc TO import("prg/asc")["new"](Lex("heading", launchHeading, "lastStage", lastStage, "alt", targetAP)).
		m["next"]().
	}
},
"ascent",{parameter m,p.
	IF asc() {
		purge("prg/asc").
		m["next"]().
	}
},
"inspace",{parameter m,p.
	Notify("Reached Space").
	partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
	PANELS ON.
	LIGHTS ON.

	UNTIL STAGE:NUMBER = lastStage SYS["SafeStage"]().

	doScience().

	m["next"]().
},
"coast",{parameter m,p.
	IF ETA:APOAPSIS < 30 {
		lock steering to prograde+r(0,0,0).
	}
	IF ETA:APOAPSIS <= 10 {
		m["next"]().
	}
},
"insertion",{parameter m,p.
	lock steering to prograde+r(0,0,0).
	lock THROTTLE to 1.
	if alt:periapsis > targetPE {
		lock THROTTLE to 0.
		m["next"]().
	}
},
"doScience",{parameter m,p.
	doScience().
	m["next"]().
}).