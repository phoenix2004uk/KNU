FUNCTION DoScience
{
	PARAMETER ex.
	FOR n IN ex:KEYS {
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule("ModuleScienceExperiment").
		m:DoAction(ex[n],TRUE).
	}
}

SET ex TO Lexicon(
 "sensorThermometer", "Log Temperature",
 "sensorBarometer", "Log Pressure Data"
).

DoScience(ex).
LOCK STEERING TO Heading(90, 90).
LOCK THROTTLE TO 1.
STAGE.
WAIT 1.
DoScience(ex).
WAIT UNTIL SHIP:VERTICALSPEED <= 0.
IF ALTITUDE > 18000 DoScience(ex).