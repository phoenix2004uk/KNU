{
	SET RunTests TO {

		PRINT "Verify the following in Kerbal Engineer or MechJeb...".

		PRINT " ".
		PRINT "availableThrust = " + Libs["telemetry"]["availableThrust"]().
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		IF NOT assertEqual("availableThrust",user_input,"Y") RETURN FALSE.

		PRINT " ".
		PRINT "currentISP = " + Libs["telemetry"]["currentISP"]().
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		IF NOT assertEqual("currentISP",user_input,"Y") RETURN FALSE.

		RETURN TRUE.
	}.
}