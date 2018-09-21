COPYPATH("0:/libs/science.ks","1:/science.ks").
IF EXISTS ("1:/science.ks") {
	RUNPATH("1:/science.ks").
	LOCAL DeOrbitTime IS TIME:SECONDS + ETA:APOAPSIS.
	LOCAL TargetPeA IS 51610.
	
	PRINT "Coasting to Apoapsis".
	WAIT UNTIL ALTITUDE > 250100.
	PRINT "Doing some Science!".
	DoScience(List("science.module"), FALSE).

	
	PRINT "Preparing De-Orbit Maneuver".
	LOCK STEERING TO RETROGRADE.

	UNTIL DeOrbitTime - TIME:SECONDS < 0 {
		PRINT "T-" + ROUND(DeOrbitTime-TIME:SECONDS,1) + "s    " AT(0,4).
		WAIT 0.1.
	}

	PRINT "Starting Burn".
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:PERIAPSIS < TargetPeA.

	LOCK THROTTLE TO 0.
	LOCK STEERING TO SRFRETROGRADE.

	PRINT "Coasting to atmosphere re-entry".
	WAIT UNTIL ALTITUDE < 70000.
	STAGE.

	PRINT "Atmospheric Re-Entry".
	UNTIL ALTITUDE < 20000 {
		PRINT "D-" + ROUND(ALT:RADAR, 1) + "m      " AT(0,8).
		WAIT 0.1.
	}
	PRINT "Deploy Parachutes" AT(0,8).
	STAGE.

	UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" {
		PRINT "D-" + ROUND(ALT:RADAR, 1) + "m      " AT(0,9).
		WAIT 0.1.
	}

	UNTIL FALSE {
		WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
		WAIT 10.
		IF VELOCITY:SURFACE:MAG < 0.1 BREAK.
	}
	SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric"):DoAction("Toggle", True).

	PRINT "Do Some Science!".
	DoScience(List("sensorThermometer","sensorBarometer","sensorAccelerometer"), FALSE).
	DMScience(List("dmmagBoom"), FALSE).
	
}
ELSE NotifyError("Download Failed: /libs/science.ks").