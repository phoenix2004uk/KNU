LOCAL partLib IS import("util/parts").
LOCAL SYS IS import("system").
LOCAL MNV IS import("maneuver").
LOCAL countdown IS 10.

set TARGET to Minmus.

SET steps TO Lex(
"window",{PARAMETER mission,public.
	LOCAL ang IS BODY:ROTATIONANGLE + SHIP:GEOPOSITION:LNG.
	LOCAL tar IS Minmus:OBT:LAN.
	CLEARSCREEN.
	PRINT "Minmus: "+tar AT(0,0).
	PRINT "KSC: "+ang AT(0,1).
	WAIT 1.
	IF ABS(ang-tar)<3
		mission["next"]().
},
"countdown",{PARAMETER mission,public.
	IF countdown > 0 {
		Notify("Launching in T-"+ROUND(countdown,0)).
		SET countdown TO countdown - 1.
		WAIT 1.
	}
	ELSE {
		Notify("T-0 Lift Off").
		SET asc TO import("prg/asc")["new"](Lex("heading", 84, "lastStage", 0, "alt", 100000)).
		mission["next"]().
	}
},
"ascent",{PARAMETER mission,public.
	IF asc() {purge("prg/asc"). mission["next"]().}
},
"inspace",{PARAMETER mission,public.
	Notify("Reached Space").
	partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
	PANELS ON.
	LIGHTS ON.

	LOCAL dV_insertion IS MNV["ChangePeDeltaV"](15000).
	LOCAL insertion_burntime IS MNV["GetManeuverTime"](dV_insertion).
	ADD NODE(TIME:SECONDS + ETA:APOAPSIS - insertion_burntime - 10, 0, 0, dV_insertion).

	mission["enable"]("powersave_on").
	mission["next"]().
},
"coast",{PARAMETER mission,public.
	IF NEXTNODE:ETA < 30 MNV["Steer"](NEXTNODE:BURNVECTOR).
	IF NEXTNODE:ETA <= 0 mission["next"]().
},
"insertion",{PARAMETER mission,public.
	LOCK STEERING TO PROGRADE+R(0,0,90).
	IF ALT:PERIAPSIS < 15000 LOCK THROTTLE TO 1.
	ELSE {
		LOCK THROTTLE TO 0.
		REMOVE NEXTNODE.
		mission["next"]().
	}
},
"drop_stage",{PARAMETER mission,public.
	Notify("Dropping Ascent Stage").
	WAIT 0.5.
	UNTIL STAGE:NUMBER = 0 SYS["SafeStage"]().
	WAIT 2.
	mission["next"]().
	SET circ TO import("prg/circ")["new"]("ap").
},
"circularize",{PARAMETER mission,public.
	IF circ(){purge("prg/circ"). mission["next"](). LOCK STEERING TO PROGRADE+R(0,0,90).}
}
).