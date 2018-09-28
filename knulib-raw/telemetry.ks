{

	// Current available thrust in Kgm/s
	function GetAvailableThrust {
		//LIST ENGINES IN enList.
		//LOCAL T IS 0.
		//FOR en IN enList {
		//	IF en:IGNITION AND NOT en:FLAMEOUT {
		//		SET T TO T + en:AVAILABLETHRUST * 1000.
		//	}
		//}
		//RETURN T.
		RETURN SHIP:AVAILABLETHRUST * 1000.
	}

	function GetCurrentISP {
		// Isp = ΣT / Σm
		// m   = T / Isp
		// Isp = ΣT / Σ(T/Isp)

		LIST ENGINES IN enList.
		LOCAL T IS 0.
		LOCAL m IS 0.
		FOR en IN enList {
			IF en:IGNITION AND NOT en:FLAMEOUT {
				SET T TO T + en:AVAILABLETHRUST * 1000.
				SET m TO m + en:AVAILABLETHRUST * 1000 / en:ISP.
			}
		}
		IF m=0 RETURN 0.
		RETURN T / m.
	}

	function GetTimeToImpact {
		PARAMETER altitudeMargin.

		// assume g is g0{body}
		LOCAL g0 IS BODY:MU / (BODY:RADIUS+ALTITUDE)^2.
		LOCAL u IS SHIP:VERTICALSPEED.
		LOCAL d IS ALT:RADAR - altitudeMargin.

		// d = u * t + 1/2*g*t^2
		// (g/2)t^2 + (u)t - d =0
		// ax^2 + bx +c = 0
		// x = (-b +- sqrt( b^2 - 4ac )) / 2a
		// t = (-u +- sqrt( u^2 - 4*g/2*-d )) / 2*g/2
		// t = (-u +- sqrt( u^2 + 2g*d)) / g
		// we only want positive time, so
		// t = (sqrt(u^2 + 2g*d) - u) / g

		// WHEN TTI <= MNV_TIME(SHIP:VERTICALSPEED) BURN AT FULL THROTTLE

		RETURN (SQRT(u^2 + 2*g0*d) + u) / g0.
	}

	function GetConstantTWR {
		parameter twr.
		local F is SHIP:availableThrust * 1000.
		if F = 0 return 0.
		local g1 is BODY:mu / (BODY:radius+ALTITUDE)^2.
		local maxTWR is F / (SHIP:mass * 1000 * g1).
		return max(0,min(1,twr / maxTWR)).
	}

	export(Lex(
		"version", "1.2.0",
		"availableThrust", GetAvailableThrust@,
		"currentISP", GetCurrentISP@,
		"timeToImpact", GetTimeToImpact@,
		"constantTWR", GetConstantTWR@,
	)).
}