{
	LOCAL MNV IS import("maneuver").
	LOCAL ISH IS import("util/ish").

	LOCAL WARP_THRESHOLD IS 60.
	LOCAL WARP_END_TIME IS 30.
	LOCAL LATE_BURN_ETA IS 9.
	LOCAL ECCENTRICITY_TARGET IS 0.
	LOCAL ECCENTRICITY_ISHYNESS IS 0.001.

	LOCAL step_calculate_mnv IS {
		PARAMETER private, mission, public.

		LOCAL dV_circularize IS private["dvfn"]().
		SET public["half_burn_duration"] TO MNV["GetManeuverTime"](dV_circularize/2).

		LOCAL etaToBurn IS private["eta"]().

		IF etaToBurn > SHIP:OBT:PERIOD/2 {
			SET etaToBurn TO LATE_BURN_ETA.
		}
		SET public["timeOfBurn"] TO TIME:SECONDS + etaToBurn.

		Add NODE(public["timeOfBurn"], 0, 0, dV_circularize).
		MNV["Steer"](NEXTNODE:DELTAV).
		SET public["lastEcc"] TO ROUND(SHIP:OBT:ECCENTRICITY,5).
		mission["save"](public).
		mission["next"]().
	}.
	LOCAL step_coast_mnv IS {
		PARAMETER private, mission, public.

		IF NOT public:HASKEY("timeOfBurn") mission["load"](public).

		IF public["timeOfBurn"]-TIME:SECONDS-public["half_burn_duration"]-WARP_END_TIME <= 0 {
			mission["next"]().
		}
	}.
	LOCAL step_execute_mnv IS {
		PARAMETER private, mission, public.

		IF NOT public:HASKEY("timeOfBurn") mission["load"](public).

		IF public["timeOfBurn"]-TIME:SECONDS - public["half_burn_duration"] <= 0 {
			MNV["Steer"](NEXTNODE:DELTAV).
			LOCK THROTTLE TO 1.
			IF ISH["value"](SHIP:OBT:ECCENTRICITY, ECCENTRICITY_TARGET, ECCENTRICITY_ISHYNESS) OR ROUND(SHIP:OBT:ECCENTRICITY,5) > public["lastEcc"] {
				LOCK THROTTLE TO 0.
				REMOVE NEXTNODE.
				mission["next"]().
			}
			SET public["lastEcc"] TO ROUND(SHIP:OBT:ECCENTRICITY,5).
		}
	}.

	LOCAL constructor IS {
		PARAMETER mnv_position, events IS Lex(), active IS 1.

		LOCAL private IS Lex().
		IF mnv_position = "ap" {
			SET private["dvfn"] TO { RETURN MNV["ChangePeDeltaV"](ALT:APOAPSIS). }.
			SET private["eta"] TO { RETURN ETA:APOAPSIS. }.
		}
		ELSE IF mnv_position = "pe" {
			SET private["dvfn"] TO { RETURN MNV["ChangeApDeltaV"](ALT:PERIAPSIS). }.
			SET private["eta"] TO { RETURN ETA:PERIAPSIS. }.
		}
		ELSE RETURN FALSE.
		LOCAL steps IS Lex(
			0,step_calculate_mnv:bind(private),
			1,step_coast_mnv:bind(private),
			2,step_execute_mnv:bind(private)
		).

		RETURN MissionRunner["new"]("circ", steps, 1, events, active).
	}.

	export(Lex(
		"version", "1.0.7",
		"new", constructor
	)).
}