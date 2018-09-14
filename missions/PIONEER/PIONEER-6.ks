COPYPATH("0:/libs/pioneer.ks","1:/pioneer.ks").
IF NOT EXISTS ("1:/pioneer.ks") {
	NotifyError("Download Failed: /libs/pioneer.ks").
	NotifyInfo("Rebooting System in 10 seconds").
	WAIT 10.
	REBOOT.
}
RUNPATH("1:/pioneer.ks").

CLEARSCREEN.
PreFlight().

LOCAL lastAscentStage IS 3.
LOCAL launchHeading IS 0.
LOCAL targetApA IS 100000.

LOCAL maxQ IS 0.
Launch(launchHeading, lastAscentStage, targetApA, {
	PARAMETER data.
	IF SHIP:Q > maxQ SET maxQ TO SHIP:Q.
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 0).
	PRINT "Fuel:  " + ROUND(STAGE:LIQUIDFUEL,1) + "u       "		AT (0, 1).
	PRINT "ALT:   " + ROUND(ALTITUDE,1) + "m "						AT (0, 2).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 3).
	PRINT "θt:    " + ROUND(data["pitchTarget"],2) + "°    "			AT (0, 4).
	PRINT "Q:     " + ROUND(SHIP:Q,2) + "atm "						AT (0, 5).
	PRINT "  =>   " + ROUND(SHIP:Q*CONSTANT:ATMtokPa,2) + "kPa "	AT (0, 6).
	PRINT "Qmax:  " + ROUND(maxQ,2) + "atm "							AT (0, 7).
	PRINT "  =>   " + ROUND(maxQ*CONSTANT:ATMtokPa,2) + "kPa "		AT (0, 8).
}).

OrbitInsertion(lastAscentStage).

NotifyInfo("Discarding fairings and ascent stage").
UNTIL STAGE:NUMBER=lastAscentStage-1 {
	STAGE.
	WAIT UNTIL STAGE:READY.
}
FinalizeInsertion().