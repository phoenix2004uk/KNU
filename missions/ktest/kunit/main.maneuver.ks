{

	SET RunTests TO {

		PRINT "Put yourself in an eccentric orbit with e >= 0.8".
		WAIT UNTIL SHIP:OBT:ECCENTRICITY >= 0.8.

		PRINT "Verify the following in Kerbal Engineer or MechJeb...".

		PRINT " ".
		PRINT "VisViva speed at Apoapsis = " + Libs["maneuver"]["VisViva"](SHIP:OBT:SEMIMAJORAXIS,SHIP:OBT:APOAPSIS).
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		assertEqual("VisViva Ap",user_input,"Y").

		PRINT " ".
		PRINT "VisViva speed at Periapsis = " + Libs["maneuver"]["VisViva"](SHIP:OBT:SEMIMAJORAXIS,SHIP:OBT:PERIAPSIS).
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		assertEqual("VisViva Pe",user_input,"Y").

		PRINT " ".
		PRINT "GetManeuverTime 1000m/s = " + Libs["maneuver"]["GetManeuverTime"](1000).
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		assertEqual("GetManeuverTime 1000m/s",user_input,"Y").

		PRINT " ".
		PRINT "Checking Hohmann dV calculations, GetHohmannDeltaVCirc will not be accurate for eccenentric orbits".
		PRINT "GetHohmannDeltaVElipse is slower, but more accurate, and will be used when calling GetHohmannDeltaV with e>=0.01".

		PRINT " ".
		PRINT "GetHohmannDeltaVCirc 500km = " + Libs["maneuver"]["GetHohmannDeltaVCirc"](500000).
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		assertEqual("GetHohmannDeltaVCirc 500km",user_input,"Y").

		PRINT " ".
		PRINT "GetHohmannDeltaVElipse 500km = " + Libs["maneuver"]["GetHohmannDeltaVElipse"](500000).
		PRINT "is this correct? [Y/N]".
		SET user_input TO TERMINAL:INPUT:GETCHAR().
		assertEqual("GetHohmannDeltaVElipse 500km",user_input,"Y").

		RETURN TRUE.
	}.
}