{
	LOCAL SYS IS import("system").

	LOCAL GetPitchTarget IS {
		PARAMETER current_altitude,start_altitude, end_altitude, start_pitch, end_pitch.
		LOCAL kA IS 85.
		LOCAL kB IS 70000.
		LOCAL kC IS 5.
		IF current_altitude <= start_altitude RETURN start_pitch.
		IF current_altitude >= end_altitude RETURN end_pitch.
		RETURN MIN(start_pitch, MAX(end_pitch, kA * (LN(kB) - LN(current_altitude)) / (LN(kB) - LN(start_altitude)) + kC)).
	}.

	LOCAL step_prelaunch IS {
		PARAMETER private, mission, public.

		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		LOCK THROTTLE TO 0.
		LOCK STEERING TO HEADING(private["heading"], 90) + R(0,0,-90).

		mission["next"]().
	}.

	LOCAL step_launch IS {
		PARAMETER private, mission, public.

		LOCK THROTTLE TO 1.
		UNTIL SHIP:AVAILABLETHRUST > 1 SYS["SafeStage"]().

		IF private["srbPitch"] AND STAGE:SolidFuel > 50 {
			set private[50] to STAGE:number.
			mission["enable"]("srbPitch").
		}

		mission["enable"]("burnout").
		mission["next"]().
	}.

	LOCAL step_ascent IS {
		PARAMETER private, mission, public.

		LOCAL current_altitude IS ALTITUDE.
		IF ALTITUDE > private["profile"]["a1"] {
			SET current_altitude TO (ALTITUDE + ALT:APOAPSIS) / 2.
		}
		LOCAL LOCK pitch_target TO GetPitchTarget(
			current_altitude,
			private["profile"]["a0"],
			private["profile"]["aN"],
			private["profile"]["p0"],
			private["profile"]["pN"]).
		LOCAL LOCK rot TO R(0,0,-90 + MIN(90,MAX(0,90*(ALTITUDE-private["rollAlt"])/private["rollDis"]))).
		LOCK STEERING TO HEADING(private["heading"], pitch_target) + rot.

		LOCK THROTTLE TO 1.

		IF ALT:APOAPSIS > private["alt"] {
			LOCK THROTTLE TO 0.
			mission["trigger"]("meco").
			mission["next"]().
		}
	}.

	LOCAL step_coasting_to_space IS {
		PARAMETER private, mission, public.
		LOCK THROTTLE TO 0.
		LOCK STEERING TO HEADING(private["heading"], 0).
		IF ALTITUDE > 70010 {
			LOCK STEERING TO PROGRADE.
			mission["next"]().
		}
	}.

	LOCAL evt_burnout IS {
		PARAMETER private, mission, public.
		if STAGE:NUMBER = private[50] and SYS["Burnout"]() SYS["SafeStage"]().
		else SYS["Burnout"](TRUE, private["lastStage"]).
	}.

	// this event adjusts ascent profile when using SRB launch to prevent excessive pitching when they shut off
	LOCAL evt_srbpitch IS {
		PARAMETER private, mission, public.
		IF STAGE:SolidFuel < 10 {
			SET private["profile"]["a0"] TO ALTITUDE.
			mission["disable"]("srbPitch").
		}
	}.

	LOCAL prgSteps IS Lex(
		"prelaunch", step_prelaunch,
		"launch", step_launch,
		"ascent", step_ascent,
		"coast", step_coasting_to_space
	).
	LOCAL prgSequence IS prgSteps:KEYS.
	LOCAL prgEvents IS Lex(
		"burnout", evt_burnout,
		"srbPitch", evt_srbpitch
	).
	LOCAL prgActiveEvents IS List().

	LOCAL constructor IS {
		PARAMETER args IS Lex(), userEvents IS Lex().

		LOCAL private IS Lex(
			"alt", 100000,
			"heading", 90,
			"lastStage", 2,
			"srbPitch", TRUE,
			"rollAlt", 5000,
			"rollDis", 5000,
			"profile", Lex(
				"a0", 1000,
				"p0", 87.5,
				"aN", 60000,
				"pN", 0,
				"a1", 40000
			),
			50, -1	// used for staging solid boosters without cutting throttle
		).
		FOR key IN private:KEYS IF args:HASKEY(key) SET private[key] TO args[key].

		LOCAL steps IS Lex().
		{
			FOR key IN prgSteps:KEYS {
				SET steps[key] TO prgSteps[key]:bind(private).
			}
		}
		LOCAL sequence IS prgSequence:COPY.

		// add program and user evets/triggers
		// triggers avialable: meco
		LOCAL events IS Lex().
		LOCAL active IS prgActiveEvents:COPY.
		{
			FOR key IN prgEvents:KEYS {
				SET events[key] TO prgEvents[key]:bind(private).
			}
			FOR key IN userEvents:KEYS {
				IF NOT events:HASKEY(key) SET events[key] TO userEvents[key].
			}
		}

		RETURN MissionRunner["new"]("asc", steps, sequence, events, active).
	}.

	export(Lex(
		"version", "1.0.4",
		"new", constructor
	)).
}