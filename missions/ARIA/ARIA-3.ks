LOCAL sci_p TO List("sensorThermometer","sensorBarometer","sensorAccelerometer").
LOCAL sci_m TO "ModuleScienceExperiment".
LOCAL dm_p TO List("dmmagBoom").
LOCAL dm_m TO "DMModuleScienceAnimate".
FUNCTION DoScience {
	PARAMETER x,m,t.
	FOR n IN x {
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule(m).
		m:DEPLOY.
		WAIT UNTIL m:HASDATA.
		LOCAL tv IS 0.
		LOCAL rv IS 0.
		FOR d IN m:DATA {
			SET tv TO tv+d:TRANSMITVALUE. SET rv TO rv+d:SCIENCEVALUE.
		}
		IF tv>0.2 AND t=1 {
			IF ADDONS:RT:HasKSCConnection(SHIP) m:TRANSMIT.
		}
		WAIT 0.
	}
}
DoScience(dm_p,dm_m,1).
WAIT 9.
LOCK STEERING TO Heading(90,87).
STAGE.
DoScience(sci_p,sci_m,1).
WAIT UNTIL SHIP:VERTICALSPEED <= 0.
IF ALTITUDE>70000 {
	DoScience(sci_p,sci_m,1).
	DoScience(dm_p,dm_m,1).
}
WAIT UNTIL ALTITUDE>18000 AND ALTITUDE<60000.
DoScience(sci_p,sci_m,1).
WAIT UNTIL ALT:RADAR<5000.
STAGE.
WAIT UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED".
DoScience(sci_p,sci_m,0).
DoScience(dm_p,dm_m,0).