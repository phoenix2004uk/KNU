LOCAL MNV IS import("maneuver").
LOCAL partLib IS import("util/parts").
LOCK NORMALVEC TO VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
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

LOCAL dV IS MNV["ChangeApDeltaV"](Mun:ALTITUDE).
LOCAL preBurnTime IS MNV["GetManeuverTime"](dV/2).
LOCAL ang_rate IS 360 / SHIP:OBT:PERIOD.
LOCAL ang_delta IS preBurnTime * ang_rate.
LOCAL ang_mun IS GetCircTransferPhaseAngle(0,Mun).
LOCK ang_curr TO GetRelPhaseAngle(Mun).
LOCK Orient TO NORMALVEC.
LOCK STEERING TO Orient.
CLEARSCREEN.
	PRINT "θ{node}:     " + ROUND(ang_mun,2)+"   " AT (0,0).
	PRINT "Δθ{preburn}: " + ROUND(ang_delta,2)+"    " AT (0,2).
SET steps TO Lex(
"coast",{PARAMETER M,P.
	LOCAL ang IS ABS(ang_mun-ang_curr).
	PRINT "θ{rel}:      " + ROUND(ang,2)+"   " AT (0,1).
	IF ang < ang_delta M["next"]().
},
"mnv",{PARAMETER M,P.
	SET WARP TO 0.
	ADD NODE(TIME:SECONDS, 0, 0, dV).
	MNV["Steer"](NEXTNODE:DELTAV).
	M["next"]().
},
"burn",{PARAMETER M,P.
	CLEARSCREEN.
	LOCK THROTTLE TO 1.
	IF ALT:APOAPSIS>Mun:ALTITUDE+Mun:SOIRADIUS OR (SHIP:OBT:HASNEXTPATCH AND SHIP:OBT:NEXTPATCH:BODY=Mun) {
		LOCK THROTTLE TO 0.
		M["next"]().
	}
},
"end",{PARAMETER M,P.
	partLib["DoPartModuleEvent"]("HighGainAntenna5","ModuleRTAntenna","activate").
	partLib["SetPartModuleField"]("HighGainAntenna5","ModuleRTAntenna","target",Kerbin).
	LOCK STEERING TO Orient.
	REMOVE NEXTNODE.
	M["next"]().
}
).