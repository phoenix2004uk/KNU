FUNCTION DoScience
{
	PARAMETER ex.
	IF NOT ADDONS:RT:HasKSCConnection(SHIP) {
		PRINT "No Connection - Aborting Science".
		RETURN.
	}
	FOR n IN ex:KEYS {
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule("ModuleScienceExperiment").
		m:DoAction(ex[n],TRUE).
		WAIT 0.
	}
}

SET ex TO Lexicon(
 "sensorThermometer", "Log Temperature",
 "sensorBarometer", "Log Pressure Data",	
 "sensorAccelerometer", "Log Seismic Data"	
).

DoScience(ex).
PRINT "Launching in 20s".
WAIT 20.
LOCK STEERING TO Heading(90, 90).
LOCK THROTTLE TO 1.
STAGE.
DoScience(ex).
WAIT 20.
WAIT UNTIL SHIP:VERTICALSPEED <= 0.
IF ALTITUDE > 18000 {
	DoScience(ex).
}