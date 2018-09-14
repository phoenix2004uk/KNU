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
	DoScience(List("sensorThermometer","sensorBarometer"),m,transmit).
	IF SHIP:STATUS="LANDED" DoScience(List("sensorAccelerometer"),m,transmit).
}
FUNCTION DMScience {
	PARAMETER transmit IS True.
	RETURN DoScience(List("dmmagBoom"),"DMModuleScienceAnimate",transmit,True).
}

PRINT "Coasting to De-Orbit".

LOCAL PMbay IS SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric").

LOCAL t0 IS TIME:SECONDS.
LOCAL tN IS t0+950.

WAIT UNTIL tN-TIME:SECONDS<60.
SET WARP TO 0.
WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.
LOCK STEERING TO RETROGRADE.
WAIT UNTIL tN-TIME:SECONDS<5.
UNTIL ALT:PERIAPSIS<35000 {
	LOCK THROTTLE TO 1.
	WAIT 0.1.
}
LOCK THROTTLE TO 0.
LOCK STEERING TO SRFRETROGRADE.
WAIT 1.
PMbay:DoAction("Toggle",True).
UNTIL STAGE:NUMBER = 1 STAGE.
WAIT UNTIL ALTITUDE < 10000.
UNTIL STAGE:NUMBER = 0 STAGE.

WAIT UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED".
WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
PMbay:DoAction("Toggle", True).
SQScience(False).
DMScience(False).