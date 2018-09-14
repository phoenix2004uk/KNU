FUNCTION GetPitchTarget {
	PARAMETER currAlt IS ALTITUDE.
	LOCAL kA IS 2.47141E-8.
	LOCAL kB IS -0.00275846.
	LOCAL kC IS 82.4446.
	RETURN kA*currAlt^2 + kB*currAlt + kC.
}
FUNCTION GetPitchTarget {
	PARAMETER currAlt IS ALTITUDE, startAlt IS 1000, limitAlt IS 60000, pitchMax IS 90, pitchMin IS 0.
	LOCAL A IS SQRT(limitAlt-startAlt).
	RETURN pitchMax * (A - SQRT(currAlt-startAlt)) / A.
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