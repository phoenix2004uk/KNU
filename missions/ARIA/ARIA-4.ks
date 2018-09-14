LOCAL sci_p TO List("sensorThermometer","sensorBarometer","sensorAccelerometer").
LOCAL sci_m TO "ModuleScienceExperiment".
LOCAL dm_p TO List("dmmagBoom").
LOCAL dm_m TO "DMModuleScienceAnimate".
FUNCTION SCI {
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
	IF t=2 m:TOGGLE.
}
}
CLEARSCREEN.
LOCK v TO SHIP:VERTICALSPEED.
LOCK h TO ALTITUDE.
LOCK STEERING TO Heading(0,90).
STAGE.
UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" {
	PRINT h AT(0,0).
	PRINT v AT(0,1).
	IF h>70000 {
		SCI(sci_p,sci_m,1).
		SCI(dm_p,dm_m,2).
	}
	IF h>18000 AND h<60000 AND v<0 SCI(sci_p,sci_m,1).
	IF (ALT:RADAR<2500 AND v<0) OR (h<4000 AND v>-170 AND v<-60) STAGE.
	WAIT 0.
}
SCI(sci_p,sci_m,0).
SCI(dm_p,dm_m,0).