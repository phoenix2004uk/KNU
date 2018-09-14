FUNCTION DoScience {
	PARAMETER experiments,module,transmit,toggle IS False.
	IF transmit AND NOT HasKSCConnection() {
		PRINT "No Connection to Transmit Science".
		RETURN False.
	}
	FOR n IN experiments {
		PRINT "Doing Science: "+n.
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule(module).
		m:DEPLOY.
		LOCAL t IS TIME:SECONDS.
		WAIT UNTIL m:HASDATA OR TIME:SECONDS-t>10.
		IF transmit AND m:HASDATA m:TRANSMIT.
		IF toggle m:TOGGLE.
	}
}
FUNCTION SQScience {
	PARAMETER transmit IS True.
	DoScience(List("sensorThermometer","sensorBarometer"),"ModuleScienceExperiment",transmit).
	IF SHIP:STATUS="LANDED" RETURN DoScience(List("sensorAccelerometer","science_module"),"ModuleScienceExperiment",transmit).
	IF SHIP:STATUS="SPLASHED" RETURN DoScience(List("science_module"),"ModuleScienceExperiment",transmit).
}
FUNCTION DMScience {
	PARAMETER transmit IS True.
	RETURN DoScience(List("dmmagBoom"),"DMModuleScienceAnimate",transmit,True).
}
LOCK Asl TO ALTITUDE.
LOCK ApA TO ALT:APOAPSIS.
LOCK PeA TO ALT:PERIAPSIS.
LOCK Vvert TO SHIP:VERTICALSPEED.
LOCK Vsurf TO VELOCITY:SURFACE:MAG.
LOCAL PMbay IS SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric").
LOCK STEERING TO Heading(90,90).
LOCK THROTTLE TO 1.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
WHEN Asl>1000 AND Vvert>100 THEN{
	LOCK STEERING TO Heading(90,45+(10000-Asl)/100*5).
WHEN Asl>10000 THEN{
	LOCK STEERING TO Heading(90,30+(40000-Asl)/2000).
WHEN Asl>30000 THEN{
	LOCK STEERING TO SRFPROGRADE.
WHEN ApA>55000 THEN{
	LOCK STEERING TO Heading(90,0).
}}}}
WHEN Vvert<0 AND Asl<70100 THEN {
	UNTIL STAGE:NUMBER=1 {STAGE.}
	WHEN Asl>6000 AND Asl<10000 AND Vsurf>130 AND Vsurf<230 THEN STAGE.
	WHEN Asl<5000 THEN STAGE.
}
STAGE.
LIST ENGINES IN elist.
UNTIL ApA>80000 { FOR e IN elist { IF e:FLAMEOUT {
	STAGE. WAIT UNTIL STAGE:READY.
	LIST ENGINES IN elist. BREAK.
}} WAIT 0.1.}
LOCK THROTTLE TO 0.

WAIT UNTIL Asl>70100.
PMbay:DoAction("Toggle",True).
SQScience(False).
LOCK STEERING TO PROGRADE.

PRINT "Coasting to Apoapsis".
WAIT UNTIL ETA:APOAPSIS<20.
UNTIL PeA>70100 {
	LOCK THROTTLE TO 1.
	IF ETA:APOAPSIS>20 {
		PRINT "Coasting to Apoapsis".
		LOCK THROTTLE TO 0.
		WAIT UNTIL ETA:APOAPSIS<10.
	}
}
LOCK THROTTLE TO 0.