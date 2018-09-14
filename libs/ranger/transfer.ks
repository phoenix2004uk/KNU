FUNCTION NORMALVEC {RETURN VCRS(SHIP:VELOCITY:ORBIT,BODY:POSITION).}
FUNCTION RADIALVEC {RETURN VCRS(SHIP:VELOCITY:ORBIT,NORMALVEC()).}
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
FUNCTION IsWithin {
	PARAMETER a,b,x,d IS 0.
	IF d>=0 AND a<b-x RETURN FALSE.
	IF d<=0 AND a>b+x RETURN FALSE.
	RETURN TRUE.
}
FUNCTION IsWithinTransferBody {
	PARAMETER bdy,pe,x,d IS 0.
	IF NOT SHIP:OBT:HASNEXTPATCH RETURN FALSE.
	LOCAL O IS SHIP:OBT:NEXTPATCH.
	RETURN O:BODY=bdy AND IsWithin(O:PERIAPSIS,Pe,x,d).
}
FUNCTION DoAccurateBurn {
	PARAMETER deviation, fCheck, steps IS 5.
	FROM {LOCAL n IS steps-1.} UNTIL n<0 STEP {SET n TO n-1.} DO {
		LOCAL n_dev IS 10^n*deviation.
		LOCAL tMAX IS 1/2^(steps-n-1).
		IF NOT fCheck(n_dev) {
			LOCK THROTTLE TO tMAX.
			WAIT UNTIL fCheck(n_dev).
			LOCK THROTTLE TO 0.
		}
	}
}