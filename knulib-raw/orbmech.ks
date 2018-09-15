{
	function true_anomaly_an {
		local w is ship:obt:argumentOfPeriapsis.
		if ship:obt:inclination < 0 set w to w+180.
		return mod(360 - w,360).
	}
	function true_anomaly_dn {
		local w is ship:obt:argumentOfPeriapsis.
		if ship:obt:inclination < 0 set w to w+180.
		return mod(540 - w,360).
	}
	function eccentric_anomaly {
		parameter true_anomaly_deg.
		local eccentric_anomaly_deg is ARCCOS( (ship:obt:eccentricity+COS(true_anomaly_deg)) / (1 + ship:obt:eccentricity*COS(true_anomaly_deg)) ).
		if true_anomaly_deg > 180 {
			set eccentric_anomaly_deg to 360 - eccentric_anomaly_deg.
		}
		return eccentric_anomaly_deg.
	}
	function mean_anomaly {
		parameter eccentric_anomaly_deg.
		return eccentric_anomaly_deg - ship:obt:eccentricity*SIN(eccentric_anomaly_deg)*CONSTANT:RadToDeg.
	}
	function alt_at_anomaly {
		parameter anomaly_deg.
		return (ship:obt:semiMajorAxis*(1-ship:obt:eccentricity^2))/(1+ship:obt:eccentricity*COS(anomaly_deg)).
	}
	function eta_to_anomaly {
		parameter anomaly_deg.

		local n is 360 / ship:obt:period.

		local V0 is ship:obt:trueAnomaly.
		local E0 is eccentric_anomaly(V0).
		local M0 is mean_anomaly(E0).

		local V1 is anomaly_deg.
		local E1 is eccentric_anomaly(V1).
		local M1 is mean_anomaly(E1).

		local t is (M1 - M0) / n.
		if t < 0 set t to t + ship:obt:period.
		return t.
	}
	function eta_to_an {
		return eta_to_anomaly(true_anomaly_an()).
	}
	function eta_to_dn {
		return eta_to_anomaly(true_anomaly_dn()).
	}
	export(Lex(
		"version", "1.0.0",
		"Van", true_anomaly_an@,
		"Vdn", true_anomaly_dn@,
		"E", eccentric_anomaly@,
		"M", mean_anomaly@,
		"Rt", alt_at_anomaly@,
		"eta", eta_to_anomaly@,
		"etaAN", eta_to_an@,
		"etaDN", eta_to_dn@
	)).
}