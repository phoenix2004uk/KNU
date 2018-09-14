FUNCTION IsShipAtOrbit {
	PARAMETER theTarget,Ap,sma,precision IS 0.01.
	LOCAL T IS theTarget.
	LOCAL dAp IS Ap * precision.
	LOCAL dSMA IS sma * precision.
	IF T:OBT:APOAPSIS < Ap-dAp OR T:OBT:APOAPSIS > Ap+dAp RETURN FALSE.
	IF T:OBT:SEMIMAJORAXIS < sma-dSMA OR T:OBT:SEMIMAJORAXIS > sma+dSMA RETURN FALSE.
	RETURN TRUE.
}
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
	PARAMETER angFinal,vTarget IS TARGET.
	LOCAL R IS BODY:RADIUS.
	LOCAL a_target IS vTarget:OBT:SEMIMAJORAXIS.
	LOCAL T_target IS vTarget:OBT:PERIOD.
	LOCAL a_transfer IS CalcSMA(a_final-R,SHIP:OBT:SEMIMAJORAXIS-R).
	LOCAL T_transfer IS CalcPeriod(a_transfer).
	LOCAL n_target IS 360 / T_target.
	LOCAL dt_transfer IS n_target * T_transfer/2.
	RETURN angFinal - dt_transfer.
}
FUNCTION IsWithin {
	PARAMETER a,b,x.
	RETURN a > b-x AND a < b+x.
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
CLEARSCREEN.

LOCAL Notify IS {PARAMETER m,d IS 5. NotifyInfo(m,d,TRUE).}.

LOCAL startAP IS SHIP:OBT:APOAPSIS.
LOCAL targetAp IS 600000.
LOCAL targetSMA IS 600000+BODY:RADIUS.
LOCAL names IS List("'Eos'","'Hera'","'Hesperides'","'Nyx'").

IF SHIP:NAME="KSAT - LKO "+names[0] {
	Notify("Begining Transfer").
	WARPTO(TIME:SECONDS+ETA:PERIAPSIS-30).
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ETA:PERIAPSIS < 15.
	DoAccurateBurn(5,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:APOAPSIS, targetAp, deviation).
	}).
	Notify("Cirularizing").
	WARPTO(TIME:SECONDS+ETA:APOAPSIS-30).
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ETA:APOAPSIS < 15.
	DoAccurateBurn(5,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:SEMIMAJORAXIS, targetSMA, deviation).
	}).
}
ELSE {
	LOCAL targetNames IS Lexicon("B",names[0],"C",names[1],"D",names[2]).
	LOCAL thisTag IS CORE:TAG:SubString(6,1).
	SET TARGET TO Vessel("KSAT - LKO "+targetNames[thisTag]).
	Notify("Targetting: " + TARGET:NAME).
	Notify("Waiting for target orbit").
	WAIT UNTIL IsShipAtOrbit(TARGET, targetAp, targetSMA).
	Notify("Ready for transfer").

	LOCAL phase_transfer IS GetCircTransferPhaseAngle(90).
	LOCK phase_current TO GetRelPhaseAngle(TARGET).

	Notify("Waiting for phase angle: " + phase_transfer).
	SET WARP TO 4.
	WAIT UNTIL IsWithin(phase_current, phase_transfer, 5).
	SET WARP TO 0.

	LOCK STEERING TO PROGRADE.
	WAIT UNTIL IsWithin(phase_current, phase_transfer, 0.1).
	Notify("Begining Transfer").
	DoAccurateBurn(5,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:APOAPSIS, TARGET:OBT:APOAPSIS, deviation).
	}).

	Notify("Cirularizing").
	WARPTO(TIME:SECONDS+ETA:APOAPSIS-30).
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ETA:APOAPSIS < 15.
	DoAccurateBurn(1,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:SEMIMAJORAXIS, TARGET:OBT:SEMIMAJORAXIS, deviation).
	}).
}

Notify("Done").
LOCK STEERING TO PROGRADE+R(0,0,0).
WAIT 10.