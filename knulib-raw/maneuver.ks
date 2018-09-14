{
	LOCAL TLM IS import("telemetry").

	LOCAL VisViva IS {
		PARAMETER sma, altN, oBody IS BODY.

		LOCAL mu IS oBody:MU.
		LOCAL rN IS altN + oBody:RADIUS.

		RETURN SQRT(mu * ( (2/rN) - (1/sma) )).
	}.

	LOCAL GetSMA IS {
		PARAMETER Ap, Pe, rBody IS BODY:RADIUS.
		RETURN (Ap+Pe)/2+rBody.
	}.

	LOCAL GetManeuverTime IS {
		PARAMETER dV, thrustFactor IS 1.

		// Δv = ∫a dt [0->tN]
		// a  = F/(M0 - ΔM*t)
		// Δv = ∫F/(M0 - ΔM*t) dt [0->tN]
		// ΔM = F / Isp*g0
		// Δv = ∫F/(M0 - (F / Isp*g0)*t) dt [0->tN]
		// tN = g0 * M0 * Isp * (1 - e^(-Δv/(g0*Isp)))/F

		LOCAL F IS TLM["availableThrust"]().	// available thrust in Kgm/s
		LOCAL M0 IS SHIP:MASS * 1000.			// current mass in Kg
		LOCAL e IS CONSTANT:E.
		LOCAL Isp IS TLM["currentISP"]().
		LOCAL g0 IS 9.80665.					//9.81. Kerbin:MU / Kerbin:RADIUS^2.
		IF Isp=0 RETURN 2^64.
		RETURN g0 * M0 * Isp * (1 - e^(-ABS(dV) / (g0 * Isp) ) ) / (F * thrustFactor).
	}.

	LOCAL GetHohmannDeltaV IS {
		PARAMETER ap_new.

		LOCAL alt_start IS ALT:PERIAPSIS.
		IF ap_new < ALT:APOAPSIS SET alt_start TO ALT:APOAPSIS.
		LOCAL sma_start IS SHIP:OBT:SEMIMAJORAXIS.
		LOCAL sma_transfer IS (alt_start + ap_new)/2 + BODY:RADIUS.
		LOCAL sma_end IS ap_new + BODY:RADIUS.

		LOCAL v_start IS VisViva(sma_start, alt_start).
		LOCAL v_transfer IS VisViva(sma_transfer, alt_start).
		LOCAL v_circ IS VisViva(sma_transfer, ap_new).
		LOCAL v_end IS VisViva(sma_end, ap_new).

		RETURN List(v_transfer-v_start,v_end-v_circ).
	}.

	// ecc = (Ap-Pe) / (Ap+Pe)
	// Pe = Ap*(1 - ecc) / (1 + ecc)
	// Ap = Pe*(1 + ecc) / (1 - ecc)
	LOCAL GetPeriapsisFromEcc IS {
		PARAMETER Ap, ecc.
		RETURN Ap*(1-ecc)/(1+ecc).
	}.
	LOCAL GetApoapsisFromEcc IS {
		PARAMETER Pe, ecc.
		RETURN Pe*(1+ecc)/(1-ecc).
	}.

	LOCAL ChangePeDeltaV IS {
		PARAMETER target_pe.
		LOCAL current_sma IS SHIP:OBT:SEMIMAJORAXIS.
		LOCAL new_sma IS GetSMA(ALT:APOAPSIS, target_pe).
		LOCAL v0_ap IS VisViva(current_sma, ALT:APOAPSIS).
		LOCAL v1_ap IS VisViva(new_sma, ALT:APOAPSIS).
		RETURN v1_ap - v0_ap.
	}.

	LOCAL ChangeApDeltaV IS {
		PARAMETER target_ap.
		LOCAL current_sma IS SHIP:OBT:SEMIMAJORAXIS.
		LOCAL new_sma IS GetSMA(ALT:PERIAPSIS, target_ap).
		LOCAL v0_pe IS VisViva(current_sma, ALT:PERIAPSIS).
		LOCAL v1_pe IS VisViva(new_sma, ALT:PERIAPSIS).
		RETURN v1_pe - v0_pe.
	}.

	LOCAL Steer IS {
		PARAMETER steer_dir, deviation IS 1.
		LOCK STEERING TO steer_dir.
		LOCAL steer_vector IS steer_dir.
		IF steer_vector:ISTYPE("Direction") SET steer_vector TO steer_vector:VECTOR.
		WAIT UNTIL VANG(SHIP:FACING:FOREVECTOR, steer_vector) <= MAX(0.01, deviation).
	}.

	LOCAL ExecuteNode IS {
		LOCAL LOCK max_acceleration TO SHIP:AVAILABLETHRUST / SHIP:MASS.
		LOCAL dv IS NEXTNODE:DELTAV.
		LOCK THROTTLE TO MIN(1, NEXTNODE:DELTAV:MAG / max_acceleration).
		LOCK STEERING TO NEXTNODE:DELTAV.
		UNTIL 0 {
			IF VDOT(dv, NEXTNODE:DELTAV) < 0 {
				LOCK THROTTLE TO 0.
				BREAK.
			}
			IF NEXTNODE:DELTAV:MAG < 0.01 {
				WAIT UNTIL VDOT(dv, NEXTNODE:DELTAV) < 0.5.
				BREAK.
			}
		}
		LOCK THROTTLE TO 0.
	}.

	export(Lex(
		"version", "1.3.2",
		"VisViva", VisViva,
		"GetSMA", GetSMA,
		"GetManeuverTime", GetManeuverTime,
		"GetHohmannDeltaV", GetHohmannDeltaV,
		"GetPeFromEcc", GetPeriapsisFromEcc,
		"GetApFromEcc", GetApoapsisFromEcc,
		"ChangeApDeltaV", ChangeApDeltaV,
		"ChangePeDeltaV", ChangePeDeltaV,
		"Steer", Steer,
		"Exec", ExecuteNode
	)).
}