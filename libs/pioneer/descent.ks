Require(List("pioneer/util")).
FUNCTION DeOrbit {
	PARAMETER newPeA IS 30000,waitTime IS ETA:APOAPSIS,leadTime IS 0,cb IS FALSE.
	IF newPeA>=ALT:PERIAPSIS RETURN.
	LOCAL burnTime IS TIME:SECONDS+waitTime.
	LOCK STEERING TO RETROGRADE.
	NotifyInfo("Waiting for burn time").
	UNTIL burnTime-TIME:SECONDS<leadTime {
		IF cb:ISTYPE("Delegate") cb(burnTime-TIME:SECONDS).
		WAIT 0.1.
	}
	NotifyInfo("Performing De-Orbit").
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:PERIAPSIS <= newPeA.
	LOCK THROTTLE TO 0.
}
FUNCTION PerformReEntry {
	PARAMETER stageChutes IS 0,cb IS FALSE.
	NotifyInfo("Coasting to atmosphere re-entry").
	LOCK STEERING TO SRFRETROGRADE.
	WAIT UNTIL ALTITUDE<70000.
	NotifyInfo("Entering Upper Atmosphere").
	StageTo(stageChutes+1).
	UNTIL ALTITUDE < 20000 {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	NotifyInfo("Arming Parachutes").
	SafeStage(stageChutes).
	UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	UNLOCK STEERING.
	UNTIL FALSE {
		WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
		WAIT 10.
		IF VELOCITY:SURFACE:MAG < 0.1 BREAK.
	}
}