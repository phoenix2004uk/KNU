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
		WAIT UNTIL m:HASDATA.
		IF transmit m:TRANSMIT.
		IF toggle m:TOGGLE.
	}
}
FUNCTION SQScience {
	PARAMETER transmit IS True.
	DoScience(List("sensorThermometer","sensorBarometer"), "ModuleScienceExperiment", transmit).
	IF SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" RETURN DoScience(List("sensorAccelerometer"), "ModuleScienceExperiment", transmit).
}
FUNCTION DMScience {
	PARAMETER transmit IS True.
	RETURN DoScience(List("dmmagBoom"), "DMModuleScienceAnimate", transmit, True).
}


LOCK Asl TO ALTITUDE.
LOCK Vvert TO SHIP:VERTICALSPEED.
LOCK Vsurf TO VELOCITY:SURFACE:MAG.
LOCAL PMbay IS SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric").

LOCK STEERING TO Heading(90,90).
LOCK THROTTLE TO ALT:APOAPSIS < 253000.

// trigger heat shield test
WHEN Asl > 46000 AND Asl < 51000 AND Vsurf > 1030 AND Vsurf < 1380 THEN {
	PRINT "Testing Heat Shield".
	SHIP:PartsNamed("HeatShield0")[0]:GetModule("ModuleTestSubject"):DoEvent("Run Test").
}
// trigger realchute test
WHEN Asl>6000 AND Asl<10000 AND Vvert < 0 AND Vsurf > 130 AND Vsurf < 230 THEN {
	PRINT "Testing RealChute Parachutes".
	STAGE.
}

WHEN Asl > 1000 THEN {
	SQScience().
	WHEN Asl > 18100 THEN {
		SQScience().
		WHEN Asl > 70100 THEN {
			PMbay:DoAction("Toggle", True).
			SQScience().
			DMScience().
			IF APOAPSIS > 250100 {
				WHEN Asl > 250100 THEN {
					SQScience().
					DMScience().
				}
			}
			WHEN Asl < 70000 THEN {
				PMbay:DoAction("Toggle", False).
			}
		}
	}
	WHEN Vvert < 0 THEN {
		STAGE.
		LOCK STEERING TO SRFRETROGRADE.
		WHEN ALT:RADAR < 2500 THEN {
			STAGE.
			WAIT 0.
			STAGE.
			LOCK STEERING TO Heading(90, 90).
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