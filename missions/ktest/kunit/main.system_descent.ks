{
	SET RunTests TO {
		WAIT UNTIL ALT:RADAR < 70000.
		PRINT "Dropping orbital stage".
		Libs["system"]["SafeStage"]().
		IF NOT assertEqual("SafeStage-NewStage=1",STAGE:NUMBER,1) RETURN FALSE.

		LOCK STEERING TO SRFRETROGRADE.
		WAIT UNTIL ALT:RADAR < 20000.
		PRINT "Last stage - deploying parachutes".
		Libs["system"]["SafeStage"]().
		IF NOT assertEqual("SafeStage-NewStage=0",STAGE:NUMBER,0) RETURN FALSE.

		WAIT UNTIL STATUS="LANDED" OR STATUS="SPLASHED".
		PRINT "We made it".
		RETURN TRUE.
	}.
}