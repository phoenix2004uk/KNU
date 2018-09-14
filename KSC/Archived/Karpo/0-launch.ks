LOCAL partLib IS import("util/parts").
LOCAL SYS IS import("system").
LOCAL MNV IS import("maneuver").
LOCK NORMALVEC TO VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
LOCK Orient TO NORMALVEC.

LOCAL countdown IS 10.

SET steps TO Lex(
"countdown",{PARAMETER M,P.
	IF countdown > 0 {
		Notify("Launching in T-"+ROUND(countdown,0)).
		SET countdown TO countdown - 1.
		WAIT 1.
	}
	ELSE {
		Notify("T-0 Lift Off").
		SET asc TO import("prg/asc")["new"](Lex("heading", 90, "lastStage", 0, "alt", 100000)).
		M["next"]().
	}
},
"ascent",{PARAMETER M,P.
	IF asc() {purge("prg/asc"). M["next"]().}
},
"inspace",{PARAMETER M,P.
	Notify("Reached Space").
	partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
	PANELS ON.
	LIGHTS ON.

	LOCAL dV_insertion IS MNV["ChangePeDeltaV"](15000).
	LOCAL insertion_burntime IS MNV["GetManeuverTime"](dV_insertion).
	ADD NODE(TIME:SECONDS + ETA:APOAPSIS - insertion_burntime - 10, 0, 0, dV_insertion).

	M["enable"]("powersave_on").
	M["next"]().
},
"coast",{PARAMETER M,P.
	IF NEXTNODE:ETA < 30 MNV["Steer"](NEXTNODE:BURNVECTOR).
	IF NEXTNODE:ETA <= 0 M["next"]().
},
"insertion",{PARAMETER M,P.
	LOCK STEERING TO PROGRADE.
	IF ALT:PERIAPSIS < 15000 LOCK THROTTLE TO 1.
	ELSE {
		LOCK THROTTLE TO 0.
		REMOVE NEXTNODE.
		M["next"]().
	}
},
"drop_stage",{PARAMETER M,P.
	Notify("Dropping Ascent Stage").
	WAIT 0.5.
	UNTIL STAGE:NUMBER = 0 SYS["SafeStage"]().
	WAIT 2.
	SET circ TO import("prg/circ")["new"]("ap").
	M["next"]().
},
"circularize",{PARAMETER M,P.
	IF circ(){purge("prg/circ"). M["next"](). LOCK STEERING TO Orient.}
}
).