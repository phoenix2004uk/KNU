FUNCTION DoScience {
	PARAMETER experiments,module,transmit,toggle IS False.
	IF transmit AND NOT HasKSCConnection() {
		PRINT "No Connection to Transmit Science".
		RETURN False.
	}
	FOR n IN experiments {
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule(module).
		IF NOT m:INOPERABLE {
			m:DEPLOY.
			LOCAL t IS TIME:SECONDS.
			WAIT UNTIL m:HASDATA OR TIME:SECONDS-t>10.
			IF transmit AND m:HASDATA m:TRANSMIT.
			IF toggle m:TOGGLE.
		}
	}
}
FUNCTION SQScience {
	PARAMETER transmit IS True.
	LOCAL m IS "ModuleScienceExperiment".
	DoScience(List("sensorThermometer","sensorBarometer","science.module"),m,transmit).
	IF SHIP:STATUS="LANDED" RETURN DoScience(List("sensorAccelerometer","science.module"),m,transmit).
	IF SHIP:STATUS="SPLASHED" RETURN DoScience(List("science.module"),m,transmit).
}
FUNCTION DMScience {
	PARAMETER transmit IS True.
	RETURN DoScience(List("dmmagBoom"),"DMModuleScienceAnimate",transmit,True).
}
// F(P) = C-A*(X-B)/(L-B)
FUNCTION FP {
	PARAMETER X,B,L,C,A.
	RETURN C-A*(X-B)/(L-B).
}
LOCK Asl TO ALTITUDE.
LOCK ApA TO ALT:APOAPSIS.
LOCK PeA TO ALT:PERIAPSIS.
LOCK Vvert TO SHIP:VERTICALSPEED.
LOCK Vsurf TO VELOCITY:SURFACE:MAG.
LOCAL PMbay IS SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric").
LOCK STEERING TO Heading(90,89.5).
LOCK THROTTLE TO 1.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SET Abo TO 0.
//WHEN Asl>1000 AND Vvert>100 THEN{
WHEN STAGE:NUMBER = 3 THEN {
	SET Abo TO Asl.
	LOCK STEERING TO Heading(90,MIN(90,FP(Asl,Abo,15000,90,40))).
	WHEN Asl>15000 THEN{
		LOCK STEERING TO Heading(90,FP(Asl,15000,30000,50,30)).
		WHEN Asl>30000 THEN{
			SET Abo TO ApA.
			LOCK STEERING TO Heading(90,FP(ApA,Abo,50000,20,10)).
			WHEN ApA>50000 THEN LOCK STEERING TO Heading(90, 0).
		}
	}
}
WHEN Vvert<0 AND Asl<70100 THEN {
	UNTIL STAGE:NUMBER=1 STAGE.
	WHEN Asl<5000 THEN STAGE.
}
STAGE.
LOCAL Tprev IS SHIP:AVAILABLETHRUST.
UNTIL ApA>85000 {
	IF SHIP:AVAILABLETHRUST<Tprev-10 {
		STAGE. WAIT UNTIL STAGE:READY.
		SET Tprev TO SHIP:AVAILABLETHRUST.
	}
	WAIT 0.1.
}
LOCK THROTTLE TO 0.
LOCK STEERING TO PROGRADE.

WAIT UNTIL Asl>70100.
PANELS ON.
PMbay:DoAction("Toggle",True).
SQScience(False).

PRINT "Coasting to Apoapsis".
WAIT UNTIL ETA:APOAPSIS<20.
UNTIL PeA>70100 {
	LOCK THROTTLE TO 1.
	IF SHIP:AVAILABLETHRUST<Tprev-10 {
		STAGE. WAIT UNTIL STAGE:READY.
		SET Tprev TO SHIP:AVAILABLETHRUST.
	}
	WAIT 0.1.
}
LOCK THROTTLE TO 0.