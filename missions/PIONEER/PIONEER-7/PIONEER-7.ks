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
LOCAL launchHeading IS 90.
LOCAL targetApA IS List(100000,120000).
LOCAL targetPeA IS List(100000,120000).
LOCAL targetInc IS List(-1,1).
LOCAL targetEcc IS List(0,0.1).

LOCAL maxQ IS 0.
Launch(launchHeading, lastAscentStage, targetApA[1], {
	PARAMETER pitchTarget.
	IF SHIP:Q > maxQ SET maxQ TO SHIP:Q.
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 0).
	PRINT "Fuel:  " + ROUND(STAGE:LIQUIDFUEL,1) + "u       "		AT (0, 1).
	PRINT "ALT:   " + ROUND(ALTITUDE,1) + "m "						AT (0, 2).
	PRINT "θt:    " + ROUND(pitchTarget,2) + "°    "					AT (0, 3).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 4).
	PRINT "PeA:   " + ROUND(ALT:PERIAPSIS,1) + "m "					AT (0, 5).
	PRINT "inc:   " + ROUND(SHIP:OBT:INCLINATION,2) + "°    "		AT (0, 6).
	PRINT "ecc:   " + ROUND(SHIP:OBT:ECCENTRICITY,4) + "       "	AT (0, 7).
}).

DeployFairing("fairingSize1").
LOCK STEERING TO NORTH+R(0,0,0).

OrbitInsertion(lastAscentStage).

NotifyInfo("Discarding ascent stage").
UNTIL STAGE:NUMBER=lastAscentStage-1 {
	STAGE.
	WAIT UNTIL STAGE:READY.
}

FinalizeInsertion(targetPeA[0]).
LOCK STEERING TO NORTH+R(0,0,0).