function true_anomaly_nodes {
	LOCAL V1 IS 180 - SHIP:OBT:ARGUMENTOFPERIAPSIS.
	LOCAL V2 IS 360 - SHIP:OBT:ARGUMENTOFPERIAPSIS.
	RETURN Lex("DN",V1,"AN",V2).
}
function eccentric_anomaly {
	PARAMETER true_anomaly_deg.
	LOCAL eccentric_anomaly_deg IS ARCCOS( (SHIP:OBT:ECCENTRICITY+COS(true_anomaly_deg)) / (1 + SHIP:OBT:ECCENTRICITY*COS(true_anomaly_deg)) ).
	IF true_anomaly_deg > 180 {
		SET eccentric_anomaly_deg TO 360 - eccentric_anomaly_deg.
	}
	RETURN eccentric_anomaly_deg.
}
function mean_anomaly {
	PARAMETER eccentric_anomaly_deg.
	RETURN eccentric_anomaly_deg - SHIP:OBT:ECCENTRICITY*SIN(eccentric_anomaly_deg)*CONSTANT:RadToDeg.
}
function alt_at_anomaly {
	PARAMETER U.
	RETURN (SHIP:OBT:SEMIMAJORAXIS*(1-SHIP:OBT:ECCENTRICITY^2))/(1+SHIP:OBT:ECCENTRICITY*COS(U)).
}
function vel_at_altitude {
	PARAMETER R.
	RETURN SQRT( BODY:MU * (2/R - 1/SHIP:OBT:SEMIMAJORAXIS) ).
}
function eta_to_an {
	LOCAL n IS 360 / SHIP:OBT:PERIOD.

	LOCAL V0 IS SHIP:OBT:TRUEANOMALY.
	LOCAL E0 IS eccentric_anomaly(V0).
	LOCAL M0 IS mean_anomaly(E0).

	LOCAL V1 IS 360 - SHIP:OBT:ARGUMENTOFPERIAPSIS.
	LOCAL E1 IS eccentric_anomaly(V1).
	LOCAL M1 IS mean_anomaly(E1).

	LOCAL t IS (M1-M0) / n.
	IF t < 0 SET t TO t + SHIP:OBT:PERIOD.
	RETURN t.
}
function eta_to_dn {
	LOCAL n IS 360 / SHIP:OBT:PERIOD.

	LOCAL V0 IS SHIP:OBT:TRUEANOMALY.
	LOCAL E0 IS eccentric_anomaly(V0).
	LOCAL M0 IS mean_anomaly(E0).

	LOCAL V1 IS 180 - SHIP:OBT:ARGUMENTOFPERIAPSIS.
	LOCAL E1 IS eccentric_anomaly(V1).
	LOCAL M1 IS mean_anomaly(E1).

	LOCAL t IS (M1-M0) / n.
	IF t < 0 SET t TO t + SHIP:OBT:PERIOD.
	RETURN t.
}
LOCAL ISH IS import("util/ish").
LOCAL MNV IS import("maneuver").

LOCK NORMALVEC TO VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).

LOCAL targetAp IS 50000.
LOCAL maxEcc IS 0.0001.
LOCAL maxInc IS 0.1.
LOCAL throt IS 0.
LOCAL eta_burn IS 0.
LOCAL dv IS 0.
LOCAL preburn IS 0.
LOCAL fullburn IS 0.
LOCK orient TO NORMALVEC.
LOCK steer TO srient.
LOCK STEERING TO steer.
LOCK THROTTLE TO throt.

function correctInc{PARAMETER M,P.
	IF SHIP:OBT:INCLINATION > maxInc {
		LOCAL Ran IS alt_at_anomaly(360 - SHIP:OBT:ARGUMENTOFPERIAPSIS).
		LOCAL Rdn IS alt_at_anomaly(180 - SHIP:OBT:ARGUMENTOFPERIAPSIS).
		LOCAL vnode IS 0.
		IF Ran > Rdn {
			LOCK steer TO -NORMALVEC.
			LOCK eta_burn TO eta_to_an().
			SET vnode TO vel_at_altitude(Ran).
		}
		ELSE {
			LOCK steer TO NORMALVEC.
			LOCK eta_burn TO eta_to_dn().
			SET vnode TO vel_at_altitude(Rdn).
		}
		SET dv TO 2*vnode*SIN(SHIP:OBT:INCLINATION/2).
		SET preburn TO MNV["GetManeuverTime"](dv/2).
		SET fullburn TO MNV["GetManeuverTime"](dv).
		M["next"]().
	} ELSE M["jump"](3).
}
function coast{PARAMETER M,P.
	IF eta_burn <= preburn {
		SET throt TO 1.
		M["next"]().
	}
}
function burnInc{PARAMETER M,P.
	// TODO: need to use converge!
	IF SHIP:OBT:INCLINATION < maxInc {
		SET throt TO 0.
		M["next"]().
	}
	ELSE IF eta_burn + fullburn < 1 {
		SET throt TO 0.01.
	}
}
function correctAp{PARAMETER M,P.
	IF NOT ISH["value"](ALT:APOAPSIS, targetAp, 100) {
		IF ALT:APOAPSIS > targetAp {
			LOCK steer TO RETROGRADE.
		}
		ELSE {
			LOCK steer TO PROGRADE.
		}
		LOCK eta_burn TO ETA:PERIAPSIS.
		SET dv TO MNV["ChangeApDeltaV"](targetAp).
		SET preburn TO MNV["GetManeuverTime"](dv/2).
		SET fullburn TO MNV["GetManeuverTime"](dv).
		M["next"]().
	} ELSE M["jump"](3).
}
// coast
function burnAp{PARAMETER M,P.
	IF ISH["value"](ALT:APOAPSIS, targetAp, 100) {
		SET throt TO 0.
		M["next"]().
	}
	ELSE IF eta_burn + fullburn < 1 {
		SET throt TO 0.01.
	}
}
function correctEcc{PARAMETER M,P.
	IF SHIP:OBT:ECCENTRICITY > maxEcc {
	} ELSE M["jump"](3).
}
// coast
function burnEcc{PARAMETER M,P.
}


function calc3 {

	LOCAL Ran IS alt_at_anomaly(360 - SHIP:OBT:ARGUMENTOFPERIAPSIS).
	LOCAL Rdn IS alt_at_anomaly(180 - SHIP:OBT:ARGUMENTOFPERIAPSIS).
	LOCAL vnode IS 0.
	IF Ran > Rdn {
		LOCK steer TO -NORMALVEC.
		LOCK node_eta TO eta_to_an().
		SET vnode TO vel_at_altitude(Ran).
	}
	ELSE {
		LOCK steer TO NORMALVEC.
		LOCK node_eta TO eta_to_dn().
		SET vnode TO vel_at_altitude(Rdn).
	}
	LOCK STEERING TO steer.
	LOCAL dv IS 2*vnode*SIN(SHIP:OBT:INCLINATION/2).

	PRINT "eta:  "+node_eta.
	PRINT "time: "+(TIME:SECONDS+node_eta).
	PRINT "dv:   "+dv.
}

CLEARSCREEN.
calc3().
WAIT UNTIL 0.