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
	function solarAnomaly {
		parameter orbitable.
		//return degmod( orbitable:OBT:LAN + ARCTAN( COS(orbitable:OBT:inclination) * TAN( orbitable:OBT:trueAnomaly + orbitable:OBT:argumentOfPeriapsis ) ) ).
		return degmod( orbitable:OBT:LAN + orbitable:OBT:argumentOfPeriapsis + orbitable:OBT:trueAnomaly).
	}

	function transferAnomalyCirc {
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

	function transferEtaCirc {
		parameter transfer_anomaly, target_orbital is TARGET, source_orbital is SHIP.

		// target parameters
		local n_target is 360 / target_orbital:OBT:period.
		local s0_target is solarAnomaly(target_orbital).

		// source parameters
		local n_source is 360 / source_orbital:OBT:period.
		local s0_source is solarAnomaly(source_orbital).

		// eta parameters
		local theta_current is degmod( s0_target - s0_source).
		local dTheta is degmod( theta_current - transfer_anomaly).
		local n_diff is abs( n_target - n_source ).

		return dTheta / n_diff.
	}

	// finds the relative AN/DN between 2 orbitables
	// returns a Lexicon with keys "AN","DN","next","other"
	//  - AN/DN: the true anomaly of the AN/DN nodes
	//  - next: either "AN" or "DN" depending which is the next node
	//  - other: the opposite of next
	function relativeNodes {
		parameter target_orbitable is TARGET, source_orbitable is SHIP.

		local src_r is source_orbitable:position - BODY:position.
		local src_v is source_orbitable:velocity:orbit.

		local tgt_r is target_orbitable:position - BODY:position.
		local tgt_v is target_orbitable:velocity:orbit.

		// angular momentum
		// h = r x v
		local src_h is VCRS(src_r,src_v).
		local tgt_h is VCRS(tgt_r,tgt_v).

		// line of nodes
		local v_nodes is VCRS(src_h, tgt_h).

		// vector normal of line of nodes and position vector
		local v_nodes_normal is VCRS(src_h, v_nodes).

		// angle between nodes normal and position tells us which half of the orbit we are in
		local ang_position is VANG(src_r, v_nodes_normal).

		// angle between current position and line of nodes is the AN
		local ang_to_an is VANG(v_nodes,src_r).
		local ang_to_dn is VANG(-v_nodes,src_r).

		local result is Lex().
		// since angle to AN/DN is relative, depending on which half of the orbit we are in
		// we need to add twice the angle difference of the next node to the other node
		// now we know which node is the next node
		if ang_position > 90 {
			set ang_to_dn to ang_to_dn + 2*ang_to_an.
			set result["next"] to "AN".
			set result["other"] to "DN".
		}
		else {
			set ang_to_an to ang_to_an + 2*ang_to_dn.
			set result["next"] to "DN".
			set result["other"] to "AN".
		}
		set result["AN"] to mod(360+source_orbitable:OBT:trueAnomaly+ang_to_an,360).
		set result["DN"] to mod(360+source_orbitable:OBT:trueAnomaly+ang_to_dn,360).

		return result.
	}

	// finds the relative inclination between 2 orbitables
	function relativeInclination {
		parameter target_orbitable is TARGET, source_orbitable is SHIP.

		local src_r is source_orbitable:position - BODY:position.
		local src_v is source_orbitable:velocity:orbit.

		local tgt_r is target_orbitable:position - BODY:position.
		local tgt_v is target_orbitable:velocity:orbit.

		// angular momentum
		// h = r x v
		local src_h is VCRS(src_r,src_v).
		local tgt_h is VCRS(tgt_r,tgt_v).

		return VANG(src_h, tgt_h).
	}

	// returns a List(launchTime, launchHeading) to launch into the plane of a target orbitable
	// ascent_time_mins: how long (in mins) to get into orbit - used to offset the launchTime
	function inclinedLaunchWindow {
		parameter target_orbitable, ascent_time_mins is 3.

		local deltaLng is 0.
		local launchHeading is 90.
		local currentLng is BODY:rotationAngle + SHIP:geoPosition:LNG.
		local targetAN is target_orbitable:OBT:LAN.
		local targetDN is targetAN + 180.

		// make sure AN/DN are ahead of us
		if targetAN < currentLng set targetAN to targetAN + 360.
		if targetDN < currentLng set targetDN to targetDN + 360.

		// use whichever node is closer
		if targetAN < targetDN {
			set deltaLng to targetAN - currentLng.
			set launchHeading to 90-target_orbitable:OBT:inclination.
		}
		else {
			set deltaLng to targetDN - currentLng.
			set launchHeading to 90+target_orbitable:OBT:inclination.
		}

		// take into account launch body rotation during ascent
		local launchBodyRotationRate is 360 / BODY:rotationPeriod.
		set deltaLng to deltaLng - ascent_time_mins/2 * launchBodyRotationRate.

		// how long till the launch window
		local waitTime is deltaLng / launchBodyRotationRate.

		return List(waitTime + TIME:seconds, launchHeading).
	}

	export(Lex(
		"version", "1.2.0",
		"U0", solarAnomaly@,
		"transferAnomalyCirc", transferAnomalyCirc@,
		"transferEtaCirc", transferEtaCirc@,
		"relativeNodes", relativeNodes@,
		"relativeInclination", relativeInclination@,
		"inclinedLaunchWindow", inclinedLaunchWindow@
	)).
}