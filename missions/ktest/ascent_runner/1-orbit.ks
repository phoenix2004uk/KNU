CLEARSCREEN.

// imports
LOCAL partLib IS import("util/parts").
LOCAL MNV IS import("maneuver").

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
"perform_orbit", {PARAMETER mission, public.
	Notify("Performing a full orbit").
	mission["enable"]("powersave_on").
	public:ADD("alarm",ADDALARM("Raw",TIME:SECONDS+SHIP:OBT:PERIOD,"Orbit","Orbit "+BODY:NAME)).
	mission["next"]().
},
"orbit_complete", {PARAMETER mission, public.
	IF public["alarm"]:REMAINING <= 0 {
		DELETEALARM(public["alarm"]:ID).
		mission["next"]().
	}
}).