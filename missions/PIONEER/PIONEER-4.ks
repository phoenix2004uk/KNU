FUNCTION CheckFlameout {
	PARAMETER stageMin IS 0.
	IF NOT (DEFINED enList) LIST ENGINES IN enList.
	IF STAGE:NUMBER > stageMin FOR en IN enList IF en:FLAMEOUT {
		LOCK THROTTLE TO 0.
		STAGE.
		WAIT UNTIL STAGE:READY.
		LOCK THROTTLE TO 1.
		LIST ENGINES IN enList.
		BREAK.
	}
}

CLEARSCREEN.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
LOCK STEERING TO Heading(0, 87.5).
LOCK THROTTLE TO 1.
STAGE.

SET altSquash TO 0.
SET maxQ TO 0.
LOCK currAlt TO ALTITUDE - altSquash.
LOCK pitchTarget TO 2.47141E-8*currAlt^2 - 0.00275846*currAlt + 82.4446.
WHEN STAGE:NUMBER=3 THEN {
	IF ALTITUDE < 10000 {
		SET altSquash TO ALTITUDE.
		WHEN ALTITUDE > MAX(22000, 10000 + altSquash) THEN SET altSquash TO 0.
	}
}
LOCK STEERING TO Heading(0, MAX(0,MIN(90,pitchTarget))).
WHEN ALTITUDE > 30000 THEN {
	LOCK currAlt TO ALT:APOAPSIS.
	SET altSquash TO 0.
}
WHEN ALT:APOAPSIS > 60000 THEN LOCK pitchTarget TO 0.
UNTIL ALT:APOAPSIS > 100000 {
	IF SHIP:Q > maxQ SET maxQ TO SHIP:Q.
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 0).
	PRINT "ALT:   " + ROUND(ALTITUDE,1) + "m "						AT (0, 1).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 2).
	PRINT "sq:    " + ROUND(altSquash,1) + "m "						AT (0, 3).
	PRINT "  =>   " + ROUND(currAlt,1) + "m "						AT (0, 4).
	PRINT "θt:    " + ROUND(pitchTarget,2) + "°    "						AT (0, 5).
	PRINT "Q:     " + ROUND(SHIP:Q,2) + "atm "						AT (0, 6).
	PRINT "  =>   " + ROUND(SHIP:Q*CONSTANT:ATMtokPa,2) + "kPa "	AT (0, 7).
	PRINT "Qmax:  " + ROUND(maxQ,2) + "atm "							AT (0, 8).
	PRINT "  =>   " + ROUND(maxQ*CONSTANT:ATMtokPa,2) + "kPa "		AT (0, 9).
	IF ALTITUDE < 40000 CheckFlameout(3).
	ELSE CheckFlameout().
	WAIT 0.01.
	IF (ALT:RADAR > 100 AND SHIP:VERTICALSPEED < 10) OR STAGE:NUMBER=0 {
		// ABORT
		PRINT "Aborting - Failed to reach orbit".
		LOCK THROTTLE TO 0.
		LOCK STEERING TO SRFRETROGRADE.
		UNTIL STAGE:NUMBER = 0 {
			STAGE.
			WAIT UNTIL STAGE:READY.
		}
		WAIT UNTIL 0.
	}
}
CLEARSCREEN.

LOCK THROTTLE TO 0.
LOCK STEERING TO PROGRADE.
WAIT UNTIL ALTITUDE > 65000.
CheckFlameout().

PRINT "Coasting to Apoapsis".
WAIT UNTIL ETA:APOAPSIS<20.

UNTIL ALT:PERIAPSIS>15000 {
	LOCK THROTTLE TO 1.
	CheckFlameout().
	WAIT 0.1.
}
LOCK THROTTLE TO 0.
WAIT 0.5.
UNTIL STAGE:NUMBER=2 {
	STAGE.
	WAIT UNTIL STAGE:READY.
}

LOCK THROTTLE TO 1.
WAIT UNTIL ALT:PERIAPSIS>72000.
LOCK THROTTLE TO 0.