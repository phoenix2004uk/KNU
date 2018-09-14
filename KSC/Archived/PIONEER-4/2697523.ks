COPYPATH("0:/libs/science.ks","1:/science.ks").
IF EXISTS ("1:/science.ks") {
	LOCAL DeOrbitTime IS TIME:SECONDS + ETA:APOAPSIS + (25*60+1).
	LOCAL TargetPeA IS 31700.

	CLEARSCREEN.
	PRINT "Preparing De-Orbit Maneuver" AT(0,0).
	LOCK STEERING TO RETROGRADE.
	
	UNTIL DeOrbitTime - TIME:SECONDS < 0 {
		PRINT "T-" + ROUND(DeOrbitTime-TIME:SECONDS,1) + "s    " AT(0,1).
		WAIT 0.1.
	}
	
	PRINT "Starting Burn" AT(0,2).
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:PERIAPSIS < TargetPeA.
	
	PRINT "Throttling Down" AT(0,3).
	LOCK THROTTLE TO 0.
	LOCK STEERING TO SRFRETROGRADE.
	
	PRINT "Coasting to atmosphere re-entry" AT(0,4).
	WAIT UNTIL ALTITUDE < 70000.
	STAGE.
	
	UNTIL ALTITUDE < 20000 {
		PRINT "D-" + ROUND(ALT:RADAR, 1) + "m      " AT(0,5).
		WAIT 0.1.
	}
	PRINT "Deploy Parachutes" AT(0,5).
	STAGE.
	
	UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" {
		PRINT "D-" + ROUND(ALT:RADAR, 1) + "m      " AT(0,6).
		WAIT 0.1.
	}
	
	WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
	SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric"):DoAction("Toggle", True).

	PRINT "Do Some Science!" AT(0,7).
	RUNPATH("1:/science.ks").
	DoScience(List("sensorThermometer","sensorBarometer","sensorAccelerometer","science.module"), FALSE).
	DMScience(List("dmmagBoom"), FALSE).
}
ELSE NotifyError("Download Failed: /libs/science.ks").