{
	// because kos MOD handles negatives differently
	function degmod {
		parameter value.
		if value > 360 return mod(value, 360).
		if value < 0 until value >= 0 set value to value + 360.
		return value.
	}

	// gets a true anomaly in the solar prime reference frame
	// allows us to compare true anomaly across different orbitals
	function solar_anomaly {
		parameter orbitable.
		//return degmod( orbitable:OBT:LAN + ARCTAN( COS(orbitable:OBT:inclination) * TAN( orbitable:OBT:trueAnomaly + orbitable:OBT:argumentOfPeriapsis ) ) ).
		return degmod( orbitable:OBT:LAN + orbitable:OBT:argumentOfPeriapsis + orbitable:OBT:trueAnomaly).
	}

	function anomaly_of_transfer_circ {
		parameter final_separation, target_orbital is TARGET, source_orbital is SHIP, parentBody IS BODY.

		local a_source is source_orbital:OBT:semiMajorAxis.
		local a_target is target_orbital:OBT:semiMajorAxis.
		local n_target is 360 / target_orbital:OBT:period.

		local a_transfer is (a_source + a_target) / 2.
		local T_transfer is CONSTANT:PI*SQRT(a_transfer^3/parentBody:MU).

		local dTheta_of_target_during_transfer is n_target * T_transfer.

		// adding 180 since we start 180' from where we finish
		local anomaly_between_vessels_before_transfer is final_separation - dTheta_of_target_during_transfer + 180.

		return degmod(anomaly_between_vessels_before_transfer).
	}

	function eta_to_transfer_circ {
		parameter transfer_anomaly, target_orbital is TARGET, source_orbital is SHIP.

		// target parameters
		local n_target is 360 / target_orbital:OBT:period.
		local s0_target is solar_anomaly(target_orbital).

		// source parameters
		local n_source is 360 / source_orbital:OBT:period.
		local s0_source is solar_anomaly(source_orbital).

		// eta parameters
		local theta_current is degmod( s0_target - s0_source).
		local dTheta is degmod( theta_current - transfer_anomaly).
		local n_diff is abs( n_target - n_source ).

		return dTheta / n_diff.
	}

	export(Lex(
		"version", "1.0.5",
		"VTransferCirc", anomaly_of_transfer_circ@,
		"etaTransferCirc", eta_to_transfer_circ@
	)).
}