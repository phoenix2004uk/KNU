{
	SET RunTests TO {
		LOCK THROTTLE TO 1.
		STAGE. WAIT UNTIL STAGE:READY. STAGE.
		IF NOT assertEqual("AutoStage-NewStage=6",STAGE:NUMBER,6) RETURN FALSE.

		UNTIL ALT:PERIAPSIS > 70000 {
			IF ALT:RADAR < 20000 {
				IF Libs["system"]["Burnout"](FALSE) {
					PRINT TIME:SECONDS + " BURNOUT - Enable Infinite Fuel until over 20km".
					WAIT 1.
				}
			}
			ELSE {
				IF Libs["system"]["Burnout"](FALSE) {
					IF STAGE:NUMBER=6 {
						PRINT TIME:SECONDS + " BURNOUT - AutoStage(4) firing".
						Libs["system"]["AutoStage"](4).
						IF NOT assertEqual("AutoStage-NewStage=4",STAGE:NUMBER,4) RETURN FALSE.
					}
					ELSE IF STAGE:NUMBER=4 {
						PRINT TIME:SECONDS + " BURNOUT - Burnout(TRUE) firing autostage".
						Libs["system"]["Burnout"](TRUE).
						IF NOT assertEqual("AutoStage-NewStage=2",STAGE:NUMBER,2) RETURN FALSE.
					}
				}
				IF SHIP:LIQUIDFUEL < 50 {
					PRINT "50 fuel left - activate infinite fuel till orbit (and/or cheat into orbit)".
					PRINT "Unlocking throttle controls".
					UNLOCK THROTTLE.
					BREAK.
				}
			}

			WAIT 0.1.
		}
		WAIT UNTIL ALT:PERIAPSIS > 70000.
		RETURN TRUE.
	}.
}