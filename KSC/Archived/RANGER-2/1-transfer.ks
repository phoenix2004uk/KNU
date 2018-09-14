LOCAL MNV IS import("maneuver").
LOCAL partLib IS import("util/parts").
FUNCTION GetAbsPhaseAngle {
	parameter v1 IS TARGET, v2 IS SHIP,t IS TIME:SECONDS.
	RETURN VANG(BODY:position-positionAt(v1,t-0.001), BODY:position-positionAt(v2,t-0.001)).
}
FUNCTION GetRelPhaseAngle {
	parameter v1 IS TARGET, v2 IS SHIP,t IS TIME:SECONDS,dt IS 60.
	LOCAL a1 IS GetAbsPhaseAngle(v1,v2,t).
	LOCAL a2 IS GetAbsPhaseAngle(v1,v2,t+dt).
	IF a2>a1 RETURN -a1. RETURN a1.
}
FUNCTION CalcSMA {
	PARAMETER Ap,Pe,R IS BODY:RADIUS.
	RETURN (Pe+Ap)/2+R.
}
FUNCTION CalcPeriod {
	PARAMETER sma,tBody IS BODY.
	RETURN 2*CONSTANT:PI*SQRT(sma^3/tBody:MU).
}
FUNCTION GetCircTransferPhaseAngle {
	PARAMETER angFinal IS 0,vTarget IS TARGET.
	LOCAL R IS BODY:RADIUS.
	LOCAL a_target IS vTarget:OBT:SEMIMAJORAXIS.
	LOCAL T_target IS vTarget:OBT:PERIOD.
	LOCAL a_transfer IS CalcSMA(a_target-R,SHIP:OBT:SEMIMAJORAXIS-R).
	LOCAL T_transfer IS CalcPeriod(a_transfer).
	LOCAL n_target IS 360 / T_target.
	LOCAL dt_transfer IS n_target * T_transfer/2.
	RETURN angFinal - dt_transfer + 180.
}

SET events TO Lex(
"powersave_on", {PARAMETER mission,public.
	IF SHIP:ELECTRICCHARGE < 200 {
		Notify("Power Saving Mode").
		RT["off"]("HighGainAntenna5").
		mission["enable"]("powersave_off").
		mission["disable"]("powersave_on").
	}
},
"powersave_off", {PARAMETER mission,public.
	IF SHIP:ELECTRICCHARGE > 1000 {
		Notify("Power Restored").
		RT["on"]("HighGainAntenna5").
		mission["enable"]("powersave_on").
		mission["disable"]("powersave_off").
	}
}).
SET active TO 0.
LOCAL ang_minmus IS GetCircTransferPhaseAngle(0,Minmus).
LOCK ang_curr TO GetRelPhaseAngle(Minmus).
LOCK STEERING TO PROGRADE+R(0,0,90).
SET steps TO Lex(
"coast",{PARAMETER mission,public.
	PRINT "phase: "+ROUND(ang_minmus,1)+" = "+ROUND(ang_curr,1).
	IF ABS(ang_minmus-ang_curr) < 0.1 mission["next"]().
	WAIT 1.
	CLEARSCREEN.
},
"mnv",{PARAMETER mission,public.
	LOCAL dV IS MNV["ChangeApDeltaV"](Minmus:ALTITUDE).
	ADD NODE(TIME:SECONDS, 0, 0, dV).
	MNV["Steer"](NEXTNODE:DELTAV).
	mission["next"]().
},
"burn",{PARAMETER mission,public.
	LOCK THROTTLE TO 1.
	IF ALT:APOAPSIS>Minmus:ALTITUDE+Minmus:SOIRADIUS OR (SHIP:OBT:HASNEXTPATCH AND SHIP:OBT:NEXTPATCH:BODY=Minmus) {
		LOCK THROTTLE TO 0.
		mission["next"]().
	}
},
"end",{PARAMETER mission,public.
	partLib["DoPartModuleEvent"]("HighGainAntenna5","ModuleRTAntenna","activate").
	partLib["SetPartModuleField"]("HighGainAntenna5","ModuleRTAntenna","target","Mission Control").
	LOCK STEERING TO PROGRADE+R(0,0,90).
	mission["next"]().
}
).
