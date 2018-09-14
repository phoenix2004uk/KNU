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

SET active TO 0.
//SET sequence TO 1.
SET steps TO Lex(
"countdown", {PARAMETER mission, public.
	IF countdown > 0 {
		Notify("Launching in T-"+ROUND(countdown,0)).
		SET countdown TO countdown - 1.
		WAIT 1.
	}
	ELSE {
		Notify("T-0 Lift Off").
		SET asc TO import("prg/asc")["new"](Lex("heading", 90, "lastStage", 1, "alt", 150000)).
		mission["next"]().
	}
},
"ascent", {PARAMETER mission, public.
	IF asc() {
		purge("prg/asc").
		mission["next"]().
	}
},
"inspace", {PARAMETER mission, public.
	Notify("Reached Space").
	RT["on"]("mediumDishAntenna","Mission Control").
	PANELS ON.

	LOCAL dV_insertion IS MNV["ChangePeDeltaV"](15000).
	LOCAL insertion_burntime IS MNV["GetManeuverTime"](dV_insertion).
	ADD NODE(TIME:SECONDS + ETA:APOAPSIS - insertion_burntime - 10, 0, 0, dV_insertion).

	mission["enable"]("powersave_on").

	IF NEXTNODE:ETA > 60 {
		WARPTO(TIME:SECONDS + NEXTNODE:ETA - 30).
	}

	mission["next"]().
},
"coast_insertion", {PARAMETER mission, public.
	IF NEXTNODE:ETA < 30 {
		MNV["Steer"](NEXTNODE:BURNVECTOR).
	}
	IF NEXTNODE:ETA <= 0 {
		mission["next"]().
	}
},
"insertion", {PARAMETER mission, public.
	LOCK STEERING TO PROGRADE.
	IF ALT:PERIAPSIS < 15000 {
		LOCK THROTTLE TO 1.
	}
	ELSE {
		LOCK THROTTLE TO 0.
		REMOVE NEXTNODE.
		mission["next"]().
	}
},
"drop_ascent_stage", {PARAMETER mission, public.
	Notify("Dropping Ascent Stage").

	WAIT 0.5.
	UNTIL STAGE:NUMBER = 1 SYS["SafeStage"]().
	WAIT 2.
	mission["next"]().
	SET circ TO import("prg/circ")["new"]("ap").
},
"circularize", {PARAMETER mission, public.
	IF circ() {
		purge("prg/circ").
		mission["next"]().
	}
},
"perform_orbit", {PARAMETER mission, public.
	Notify("Performing a full orbit").
	public:ADD("alarm",ADDALARM("Raw",TIME:SECONDS+SHIP:OBT:PERIOD,"Orbit","Orbit "+BODY:NAME)).
	mission["next"]().
},
"orbit_complete", {PARAMETER mission, public.
	IF public["alarm"]:REMAINING <= 0 {
		DELETEALARM(public["alarm"]:ID).
		Notify("De-Orbiting").
		MNV["Steer"](RETROGRADE:VECTOR).
		mission["next"]().
	}
},
"deorbit", {PARAMETER mission, public.
	LOCK THROTTLE TO 1.
	IF SHIP:OBT:PERIAPSIS < 30000 {
		LOCK THROTTLE TO 0.
		SET reen TO import("prg/reen")["new"](0).
		mission["next"]().
	}
},
"reentry", {PARAMETER mission, public.
	IF reen() {
		purge("prg/reen").
		mission["next"]().
	}
}).
SET events TO Lex(
"powersave_on", {PARAMETER mission, public.
	IF SHIP:ELECTRICCHARGE < 200 {
		Notify("Power Saving Mode").
		RT["off"]("mediumDishAntenna").
		mission["enable"]("powersave_off").
		mission["disable"]("powersave_on").
	}
},
"powersave_off", {PARAMETER mission, public.
	IF SHIP:ELECTRICCHARGE > 1000 {
		Notify("Power Restored").
		RT["on"]("mediumDishAntenna").
		mission["enable"]("powersave_on").
		mission["disable"]("powersave_off").
	}
}).