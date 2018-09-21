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

LOCAL lastAscentStage IS 2.
LOCAL launchHeading IS 5.
LOCAL targetApA IS List(493234,499314).
LOCAL targetPeA IS List(493101,499106).
LOCAL targetInc IS List(83.1,83.6).
LOCAL eccMax IS 0.0021.

LOCAL scanner IS SHIP:PartsNamed("SCANsat.Scanner")[0].
LOCAL scannerModule IS scanner:GetModule("SCANsat").

LOCAL maxQ IS 0.
Launch(launchHeading, lastAscentStage, targetApA[0], {
	PARAMETER pitchTarget.
	IF SHIP:Q > maxQ SET maxQ TO SHIP:Q.
	PRINT "Stage: " + STAGE:NUMBER									AT (0, 0).
	PRINT "Fuel:  " + ROUND(STAGE:LIQUIDFUEL,1) + "u       "		AT (0, 1).
	PRINT "ALT:   " + ROUND(ALTITUDE,1) + "m "						AT (0, 2).
	PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 3).
	PRINT "θt:    " + ROUND(pitchTarget,2) + "°    "			AT (0, 4).
	PRINT "inc:   " + ROUND(SHIP:OBT:INCLINATION,2) + "°    "		AT (0, 5).
	PRINT "ecc:   " + ROUND(SHIP:OBT:ECCENTRICITY,4) + "       "	AT (0, 6).
}).

OrbitInsertion(lastAscentStage).

NotifyInfo("Discarding fairings and ascent stage").
UNTIL STAGE:NUMBER=lastAscentStage-1 {
	STAGE.
	WAIT UNTIL STAGE:READY.
}

FinalizeInsertion(targetPeA[0]).
LOCAL correction IS TRUE.
UNTIL correction=FALSE {
	SET correction TO FALSE.
	IF SHIP:OBT:INCLINATION < targetInc[0] {
		NotifyInfo("Correcting Inclination").
		SET correction TO TRUE.
		LOCK STEERING TO NORMALVEC().
		WAIT UNTIL SHIP:LATITUDE < 1 AND SHIP:LATITUDE > -1.
		LOCK THROTTLE TO 0.5.
		UNTIL SHIP:OBT:INCLINATION > targetInc[0] {
			PRINT "inc:   " + ROUND(SHIP:OBT:INCLINATION,2) + "°    "		AT (0, 5).
			WAIT 0.1.
		}
		LOCK THROTTLE TO 0.
	}
	ELSE IF SHIP:OBT:INCLINATION > targetInc[1] {
		NotifyInfo("Correcting Inclination").
		SET correction TO TRUE.
		LOCK STEERING TO -1*NORMALVEC().
		WAIT UNTIL SHIP:LATITUDE < 1 AND SHIP:LATITUDE > -1.
		LOCK THROTTLE TO 0.5.
		UNTIL SHIP:OBT:INCLINATION < targetInc[1] {
			PRINT "inc:   " + ROUND(SHIP:OBT:INCLINATION,2) + "°    "		AT (0, 5).
			WAIT 0.1.
		}
		LOCK THROTTLE TO 0.
	}

	IF ALT:APOAPSIS > targetApA[1] {
		NotifyInfo("Correcting Apoapsis").
		SET correction TO TRUE.
		LOCK STEERING TO RETROGRADE.
		WAIT UNTIL ETA:PERIAPSIS < 10.
		LOCK THROTTLE TO 0.5.
		UNTIL ALT:APOAPSIS <= targetApA[1] {
			PRINT "ApA:   " + ROUND(ALT:APOAPSIS,1) + "m "					AT (0, 3).
			WAIT 0.1.
		}
		LOCK THROTTLE TO 0.
	}

	IF SHIP:OBT:ECCENTRICITY > eccMax {
		NotifyInfo("Correcting Eccentricity").
		SET correction TO TRUE.
		LOCK STEERING TO PROGRADE.
		WAIT UNTIL ETA:APOAPSIS < 10.
		LOCK THROTTLE TO 0.5.
		UNTIL SHIP:OBT:ECCENTRICITY < eccMax {
			PRINT "ecc:   " + ROUND(SHIP:OBT:ECCENTRICITY,4) + "       "	AT (0, 6).
			WAIT 0.1.
		}
		LOCK THROTTLE TO 0.
	}
}
LOCK STEERING TO UP + R(0,0,90).
NotifyInfo("Deploying "+scanner:TITLE).
scannerModule:DoEvent("start scan: radar").
WAIT 10.
NotifyInfo("SCANsat Altitude: " + scannerModule:GetField("scansat altitude")).