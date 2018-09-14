FUNCTION CheckFlameout {
	PARAMETER enList.
	IF STAGE:NUMBER > 0 FOR en IN enList IF en:FLAMEOUT {
		LOCK THROTTLE TO 0.
		STAGE.
		WAIT UNTIL STAGE:READY.
		LOCK THROTTLE TO 1.
		enList:CLEAR.
		LIST ENGINES IN enList.
		BREAK.
	}
	RETURN enList.
}

FUNCTION ExecuteProfile {
	PARAMETER dir, profile, altStart IS 0, pitchStart IS 90.
	
	LOCAL altEnd IS 0.
	LOCAL pitchEnd IS 90.
	LOCAL pitchTarget IS 90.
	
	LOCK currAlt TO ALTITUDE.
	
	LIST ENGINES IN enList.
	FROM { LOCAL i IS 0. } UNTIL i=profile:LENGTH STEP { SET i TO i + 3. } DO {
		PRINT "Ascent Stage: " + (1+i/3) AT (0,1).
		SET altEnd TO profile[i].
		SET pitchEnd TO profile[i+1].
		IF profile[i+2]=1 {
			IF profile[i-1]=0 SET altStart TO MIN(altStart,ALT:APOAPSIS).
			LOCK currAlt TO ALT:APOAPSIS.
		}
		
		LOCK STEERING TO Heading(dir, pitchTarget).
		
		UNTIL currAlt >= altEnd {
			SET enList TO CheckFlameout(enList).
			SET pitchTarget TO pitchStart - (pitchStart-pitchEnd) * (currAlt - altStart) / (altEnd - altStart).
			PRINT "Current Alt: " + currAlt AT (0,2).
			PRINT "Pitch Target: " + pitchTarget AT (0,3).
			WAIT 0.1.
		}
		
		SET altStart TO altEnd.
		SET pitchStart TO pitchEnd.
	}
}

SET altitudeProfile To List(
	1000,	90,	0,
	12000,	80,	0,
	20000,	40,	0,
	30000,	30,	0,
	40000,	20,	1,
	50000,	10,	1,
	60000,	0,	1,
	100000,	0,	1
).

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
LOCK STEERING TO Heading(0, 90).
LOCK THROTTLE TO 1.
STAGE.
ExecuteProfile(0, altitudeProfile).
LOCK THROTTLE TO 0.
LOCK STEERING TO PROGRADE.

PRINT "Coasting to Apoapsis".
WAIT UNTIL ETA:APOAPSIS<20.

LIST ENGINES IN enList.
UNTIL ALT:PERIAPSIS>10000 {
	LOCK THROTTLE TO 1.
	SET enList TO CheckFlameout(enList).
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