{
	LOCAL ISH IS import("util/ish").
	LOCAL zero IS 1e-8.

	LOCAL C_DIVERGED IS 0.
	LOCAL C_END IS 1.
	LOCAL C_ISH IS 2.
	LOCAL C_MODE IS 3.
	LOCAL C_DIRECTION IS 4.
	LOCAL C_LAST_VALUE IS 5.
	LOCAL C_LAST_DELTA IS 6.

	LOCAL setLastValues IS {
		PARAMETER converge, lastValue, lastDelta.
		SET converge[C_LAST_VALUE] TO lastValue.
		SET converge[C_LAST_DELTA] TO lastDelta.
		SET converge[C_DIVERGED] TO 1.
		RETURN TRUE.
	}.

	LOCAL hasConverged IS {
		PARAMETER converge, value.

		SET value TO ROUND(value,5).
		LOCAL delta IS value - converge[C_LAST_VALUE].

		IF delta = 0 RETURN FALSE.

		// prevent diverging "backwards" from end value
		IF converge[C_DIRECTION] > 0 { // increasing value
			IF delta < 0 {
				RETURN TRUE.//setLastValues(converge, value, delta).
			}
		}
		ELSE IF converge[C_DIRECTION] < 0 {// decreasing value
			IF delta > 0 {
				RETURN TRUE.//setLastValues(converge, value, delta).
			}
		}
		ELSE { // approaching value either direction - check if delta has flipped
			IF ABS(delta-converge[C_LAST_DELTA]) > MAX(ABS(delta),ABS(converge[C_LAST_DELTA])) {
				RETURN TRUE.//setLastValues(converge, value, delta).
			}
		}
		//setLastValues(converge,value,delta).
		SET converge[C_LAST_VALUE] TO value.
		SET converge[C_LAST_DELTA] TO delta.

		// if we haven't flipped direction - return the ishyness
		RETURN ISH[converge[C_MODE]](value, converge[C_END], converge[C_ISH]).
	}.

	LOCAL create IS {
		PARAMETER start_value, end_value, ishyness, ish_mode IS "value".
		RETURN List(
			0,				// diverged
			end_value,		// end
			ishyness,		// ish
			ish_mode,		// mode
							// direction
			(end_value - start_value) / ABS(end_value - start_value),
			ROUND(start_value,5),	// last
			0				// lastDelta
		).
	}.

	export(Lex(
		"version", "1.0.6",
		"create", create,
		"check", hasConverged
	)).
}