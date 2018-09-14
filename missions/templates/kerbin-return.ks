CLEARSCREEN.

// imports
LOCAL partLib IS import("util/parts").
LOCAL SYS IS import("system").
LOCAL MNV IS import("maneuver").

LOCAL countdown IS 10.

LOCAL RT IS Lex(
	"on", {PARAMETER name,dishTarget IS 0.
		partLib["DoPartModuleEvent"](name,"ModuleRTAntenna","activate").
		IF dishTarget partLib["SetPartModuleField"](name,"ModuleRTAntenna","target",dishTarget).
	},
	"off", {PARAMETER name.
		partLib["DoPartModuleAction"](name,"ModuleRTAntenna","deactivate").
	}
).

SET events TO Lex(
"powersave_on", {PARAMETER mission,public.
	IF SHIP:ELECTRICCHARGE < 200 {
		Notify("Power Saving Mode").
		RT["off"]("mediumDishAntenna").
		mission["enable"]("powersave_off").
		mission["disable"]("powersave_on").
	}
},
"powersave_off", {PARAMETER mission,public.
	IF SHIP:ELECTRICCHARGE > 1000 {
		Notify("Power Restored").
		RT["on"]("mediumDishAntenna").
		mission["enable"]("powersave_on").
		mission["disable"]("powersave_off").
	}
}).
SET active TO 0.

SET steps TO Lex(
"location", {PARAMETER mission,public.
	mission["enable"]("powersave_on").
	MNV["Steer"](RETROGRADE:VECTOR).
	mission["next"]().
},
"deorbit", {PARAMETER mission,public.
	LOCK THROTTLE TO 1.
	IF SHIP:OBT:PERIAPSIS < 30000 {
		LOCK THROTTLE TO 0.
		SET reen TO import("prg/reen")["new"](0).
		mission["disable"]("powersave_on").
		mission["disable"]("powersave_off").
		mission["next"]().
	}
},
"reentry", {PARAMETER mission,public.
	IF reen() {
		purge("prg/reen").
		mission["next"]().
	}
}).