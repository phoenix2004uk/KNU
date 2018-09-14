FOR lib IN List("pioneer") {
	IF NOT EXISTS("1:/"+lib+".ks") COPYPATH("0:/libs/"+lib+".ks","1:/"+lib+".ks").
	IF NOT EXISTS("1:/"+lib+".ks") {
		NotifyError("Download Failed: /libs/"+lib+".ks").
		NotifyInfo("Rebooting System in 5 seconds").
		WAIT 5.
		REBOOT.
	}
	RUNPATH("1:/"+lib+".ks").
}

CLEARSCREEN.

LOCAL targetApA IS List(145000,155000).
LOCAL targetInc IS List(5,7).
LOCAL targetEcc IS List(0,0.005).

PRINT "TApA: " + ROUND(targetApA[0],1) + "m <-> " + ROUND(targetApA[1],1) + "m".
PRINT "TPeA: Not Set".
PRINT "Tecc: " + ROUND(targetEcc[0],4) + " <-> " + ROUND(targetEcc[1],4).
PRINT "Tinc: " + ROUND(targetInc[0],4) + "° <-> " + ROUND(targetInc[1],4) + "°".
PRINT "=-----------------------------------------------=".
FUNCTION UpdateUI {
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 5).
	PRINT "Fuel:  " + ROUND(STAGE:LIQUIDFUEL,1) + "u       "		AT (0, 6).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 7).
	PRINT "PeA:   " + ROUND(ALT:PERIAPSIS,1) + "m "					AT (0, 8).
	PRINT "inc:   " + ROUND(SHIP:OBT:INCLINATION,4) + "°       "	AT (0, 9).
	PRINT "ecc:   " + ROUND(SHIP:OBT:ECCENTRICITY,4) + "       "	AT (0, 10).
}
UpdateUI().

LOCAL correction IS TRUE.
LOCAL maxLoops IS 2.
UNTIL correction=FALSE OR maxLoops=0 {
	SET correction TO FALSE.
	SET maxLoops TO maxLoops - 1.
	LOCAL tBurn IS 0.5.
	IF CorrectInclination(targetInc[0],targetInc[1], tBurn, UpdateUI@) SET correction TO TRUE.
	LOCK STEERING TO NORTH+R(0,0,0).
	IF CorrectApoapsis(targetApA[0],targetApA[1], tBurn, UpdateUI@) SET correction TO TRUE.
	LOCK STEERING TO NORTH+R(0,0,0).
	IF CorrectEccentricity(targetEcc[0], targetEcc[1], 1, tBurn, UpdateUI@) SET correction TO TRUE.
	LOCK STEERING TO NORTH+R(0,0,0).
}
UpdateUI().
NotifyInfo("Corrections Complete").
LOCK STEERING TO NORTH+R(0,0,0).