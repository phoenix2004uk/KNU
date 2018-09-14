FUNCTION GetPhaseAngle {
	parameter phaseTarget, phaseTime IS TIME:SECONDS.
	RETURN VANG(
		BODY:position - positionAt(SHIP, phaseTime-0.001),
		BODY:position - positionAt(phaseTarget, phaseTime-0.001)
	).
}