FUNCTION DoScience {
	PARAMETER experiments,module,transmit,toggle IS False.
	IF transmit AND NOT ADDONS:RT:HasKSCConnection(SHIP) {
		PRINT "No Connection to Transmit Science".
		RETURN False.
	}
	FOR n IN experiments {
		PRINT "Doing Science: " + n.
		LOCAL p IS SHIP:PartsNamed(n)[0].
		LOCAL m IS p:GetModule(module).
		m:DEPLOY.
		LOCAL t IS TIME:SECONDS.
		WAIT UNTIL m:HASDATA OR TIME:SECONDS - t > 10.
		IF transmit AND m:HASDATA m:TRANSMIT.
		IF toggle m:TOGGLE.
	}
}
FUNCTION SQScience {
	PARAMETER transmit IS True.
	DoScience(List("sensorThermometer","sensorBarometer"), "ModuleScienceExperiment", transmit).
	IF SHIP:STATUS="LANDED" RETURN DoScience(List("sensorAccelerometer","science_module"), "ModuleScienceExperiment", transmit).
	IF SHIP:STATUS="SPLASHED" RETURN DoScience(List("science_module"), "ModuleScienceExperiment", transmit).
}
FUNCTION DMScience {
	PARAMETER transmit IS True.
	RETURN DoScience(List("dmmagBoom"), "DMModuleScienceAnimate", transmit, True).
}


LOCK Asl TO ALTITUDE.
LOCK Vvert TO SHIP:VERTICALSPEED.
LOCK Vsurf TO VELOCITY:SURFACE:MAG.
LOCAL PMbay IS SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric").

LOCK STEERING TO Heading(270,90).
LOCK THROTTLE TO ALT:APOAPSIS < 253000.


WHEN Asl > 500 OR Vvert > 100 THEN {
	LOCK STEERING TO Heading(270, 88).
	WHEN Vvert > 250 THEN LOCK STEERING TO SRFPROGRADE.
	
	WHEN SHIP:AVAILABLETHRUST < 1 THEN {
		LOCK STEERING TO SRFRETROGRADE.
		
		// parachute tests
		IF Asl > 9000 {
			WHEN Asl > 9000 AND Asl < 13000 AND Vsurf > 180 AND Vsurf < 270 THEN {
				UNTIL STAGE:NUMBER = 2 STAGE.
			}
		}
		IF Asl > 6000 {
			WHEN Asl > 6000 AND Asl < 10000 AND Vsurf > 130 AND Vsurf < 230 THEN {
				UNTIL STAGE:NUMBER = 1 STAGE.
			}
		}
		IF Asl > 2000 {
			WHEN Asl > 2000 AND Asl < 9000 AND Vsurf > 180 AND Vsurf < 320 THEN {
				UNTIL STAGE:NUMBER = 0 STAGE.
			}
		}
		
		WHEN ALT:RADAR < 2000 THEN {
			UNTIL STAGE:NUMBER = 0 STAGE.
			LOCK STEERING TO Heading(90, 90).
			GEAR ON.
		}
	}
}

CLEARSCREEN.

STAGE. 
WAIT UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED".
WAIT UNTIL Vsurf < 0.1.
PMbay:DoAction("Toggle", True).
SQScience(False).
DMScience(False).