FUNCTION NORMALVEC {RETURN VCRS(SHIP:VELOCITY:ORBIT,BODY:POSITION).}
FUNCTION IsWithin {
	PARAMETER a,b,x,d IS 0.
	IF d>=0 AND a<b-x RETURN FALSE.
	IF d<=0 AND a>b+x RETURN FALSE.
	RETURN TRUE.
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
LOCAL Notify IS {PARAMETER m,d IS 5. NotifyInfo(m,d,TRUE).}.

FUNCTION ExecuteFlightPlan {
	PARAMETER flightPlan, cbAfterStep IS FALSE.
	LOCAL orbitName IS Lexicon("Pe","Periapsis","Ap","Apoapsis","inc","Inclination").
	LOCAL dmodName IS Lexicon("+","Raising","-","Lowering").
	LOCAL rounding IS Lexicon("Ap",1,"Pe",1,"inc",5,"ecc",5).
	LOCAL suffix IS Lexicon("Ap","m","Pe","m","inc","°","ecc","").
	LOCAL iterFlight IS flightPlan:ITERATOR.
	Notify("Executing Flight Plan").
	UNTIL NOT iterFlight:NEXT {
		LOCAL fp IS iterFlight:VALUE.
		LOCAL dmod IS 1.
		LOCAL tn IS TIME:SECONDS.
		IF fp[0]="Ap" SET tn TO tn+ETA:APOAPSIS.
		ELSE IF fp[0]="Pe" SET tn TO tn+ETA:PERIAPSIS.

		IF fp[1]="-" SET dmod TO -1.

		LOCK metric TO SHIP:OBT:APOAPSIS.
		IF fp[2]="Ap" {
			LOCK fpSteer TO dmod*PROGRADE:VECTOR.
		}
		ELSE IF fp[2]="Pe" {
			LOCK fpSteer TO dmod*PROGRADE:VECTOR.
			LOCK metric TO SHIP:OBT:PERIAPSIS.
		}
		ELSE IF fp[2]="inc" {
			LOCK fpSteer TO dmod*NORMALVEC().
			LOCK metric TO SHIP:OBT:INCLINATION.
		}

		Notify("Warping to " + orbitName[fp[0]]).
		WARPTO(tn - 30).
		Notify(dmodName[fp[1]] + " " + orbitName[fp[2]] + " to: " + ROUND(fp[3],rounding[fp[2]]) + suffix[fp[2]] + ", ±" + fp[4] + suffix[fp[2]]).
		LOCK STEERING TO fpSteer.
		WAIT UNTIL tn - TIME:SECONDS < 15.
		DoAccurateBurn(fp[4],{
			PARAMETER deviation.
			PRINT ("Check: " + ROUND(metric,rounding[fp[2]]) + suffix[fp[2]] + " = " + ROUND(fp[3],rounding[fp[2]]) + suffix[fp[2]] + " ±" + fp[4] + suffix[fp[2]]):PADRIGHT(TERMINAL:WIDTH) AT (0,0).
			RETURN IsWithin(metric, fp[3], deviation, dmod).
		},3).
		IF cbAfterStep:ISTYPE("Delegate") cbAfterStep().
		Notify("New " + orbitName[fp[2]] + " is " + ROUND(metric,rounding[fp[2]]) + suffix[fp[2]]).
	}
}
CLEARSCREEN.
GLOBAL OrientShip IS { LOCK STEERING TO PROGRADE+R(0,0,0). WAIT 10. }.
OrientShip().
ExecuteFlightPlan(List(
	List("Pe","+","Ap",4.35E6,1E3),
	List("Ap","+","inc",25,0.5),
	List("Pe","-","Ap",1.5E6,1E3)
),OrientShip).
OrientShip().