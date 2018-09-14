{
	LOCAL SYS IS import("system").

	LOCAL step_reentry IS {
		PARAMETER entryStage, entryAltitude, mission, public.
		LOCK STEERING TO RETROGRADE.
		IF ALTITUDE < entryAltitude {
			UNTIL STAGE:NUMBER = entryStage SYS["SafeStage"]().
			mission["next"]().
		}
	}.
	LOCAL step_descent IS {
		PARAMETER descentAltitude, mission, public.
		LOCK STEERING TO SRFRETROGRADE.
		IF ALT:RADAR < descentAltitude {
			mission["next"]().
		}
	}.
	LOCAL step_landing IS {
		PARAMETER mission, public.
		UNLOCK STEERING.
		IF STATUS="LANDED" OR STATUS="SPLASHED" {
			mission["next"]().
		}
	}.

	LOCAL constructor IS {
		PARAMETER entryStage, descentAltitude IS 2500, entryAltitude IS -1, events IS Lex(), active IS 1.

		IF entryAltitude = -1 {
			IF BODY:ATM:EXISTS SET entryAltitude TO BODY:ATM:HEIGHT*0.98.
			ELSE SET entryAltitude TO ALTITUDE.
		}

		LOCAL steps IS Lex(
			0,step_reentry:bind(entryStage, entryAltitude),
			1,step_descent:bind(descentAltitude),
			2,step_landing
		).

		RETURN MissionRunner["new"]("reen", steps, 1, events, active).
	}.

	export(Lex(
		"version", "1.0.3",
		"new", constructor
	)).
}