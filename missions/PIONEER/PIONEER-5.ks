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
FUNCTION GetPitchTarget {
	PARAMETER currAlt IS ALTITUDE, startAlt IS 1000, limitAlt IS 60000, pitchMax IS 90, pitchMin IS 0.
	LOCAL kA IS 85.
	LOCAL kB IS 70000.
	LOCAL kC IS 5.
	IF currAlt <= startAlt RETURN pitchMax.
	IF currAlt >= limitAlt RETURN pitchMin.
	LOCAL P IS kA * (LN(kB)-LN(currAlt)) / (LN(kB)-LN(startAlt)) + kC.
	RETURN MIN(pitchMax, MAX(pitchMin, P)).
}

CLEARSCREEN.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

LOCAL maxQ IS 0.
LOCAL startAlt IS 1000.
LOCAL limitAlt IS 60000.
LOCAL pitchMax IS 87.5.
LOCAL launchHeading IS 0.

LOCK currAlt TO ALTITUDE.
LOCK pitchTarget TO GetPitchTarget(currAlt, startAlt, limitAlt, pitchMax).
LOCK STEERING TO Heading(0, pitchTarget).
LOCK THROTTLE TO 1.

STAGE.
IF STAGE:SolidFuel > 0 {
	WHEN STAGE:SolidFuel<10 THEN SET startAlt TO ALTITUDE.
}
UNTIL ALT:APOAPSIS > 100000 {
	IF SHIP:Q > maxQ SET maxQ TO SHIP:Q.
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 0).
	PRINT "ALT:   " + ROUND(ALTITUDE,1) + "m "						AT (0, 1).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 2).
	PRINT "sq:    " + ROUND(startAlt,1) + "m "						AT (0, 3).
	PRINT "θt:    " + ROUND(pitchTarget,2) + "°    "					AT (0, 4).
	PRINT "Q:     " + ROUND(SHIP:Q,2) + "atm "						AT (0, 5).
	PRINT "  =>   " + ROUND(SHIP:Q*CONSTANT:ATMtokPa,2) + "kPa "	AT (0, 6).
	PRINT "Qmax:  " + ROUND(maxQ,2) + "atm "							AT (0, 7).
	PRINT "  =>   " + ROUND(maxQ*CONSTANT:ATMtokPa,2) + "kPa "		AT (0, 8).
	//IF ALTITUDE > 40000 CheckFlameout(3). ELSE CheckFlameout().
	CheckFlameout(3).
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
PRINT "Coasting to edge of atmosphere...".

LOCK THROTTLE TO 0.
LOCK STEERING TO PROGRADE.
WAIT UNTIL ALTITUDE > 65000.
CheckFlameout(3).

PRINT "Coasting to Apoapsis".
WAIT UNTIL ETA:APOAPSIS<20.

PRINT "Begin Circularizing".
LOCK THROTTLE TO 1.
UNTIL ALT:PERIAPSIS>15000 {
	CheckFlameout(3).
	WAIT 0.1.
}
PRINT "Discarding fairings and ascent stage".
LOCK THROTTLE TO 0.
WAIT 0.5.
UNTIL STAGE:NUMBER=2 {
	STAGE.
	WAIT UNTIL STAGE:READY.
}
PRINT "Finalizing orbit".
LOCK THROTTLE TO 1.
WAIT UNTIL ALT:PERIAPSIS>72000.
LOCK THROTTLE TO 0.