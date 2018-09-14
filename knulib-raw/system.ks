{
	LOCAL engineList IS List().
	LIST ENGINES IN engineList.

	LOCAL SafeStage IS {
		IF STAGE:NUMBER = 0 RETURN.
		STAGE.
		WAIT UNTIL STAGE:READY.
		LIST ENGINES IN engineList.
	}.

	LOCAL AutoStage IS {
		// need to handle Ulage motors!
		PARAMETER manualCall, minimumStage IS 0.
		IF manualCall AND NOT Burnout(FALSE) RETURN.
		LOCAL currentThrottle IS THROTTLE.
		IF SHIP:AVAILABLETHRUST < 10 {LOCK THROTTLE TO 0. WAIT 1.}
		UNTIL NOT Burnout(FALSE) OR STAGE:NUMBER = minimumStage SafeStage().
		WAIT 0.5.
		LOCK THROTTLE TO currentThrottle.
	}.

	LOCAL Burnout IS {
		PARAMETER doAutoStage IS FALSE, minimumStage IS 0.
		FOR en IN engineList {
			IF en:IGNITION AND en:FLAMEOUT {
				IF doAutoStage AutoStage(FALSE, minimumStage).
				RETURN TRUE.
			}
		}
		RETURN FALSE.
	}.

	export(Lex(
		"version", "1.0.3",
		"SafeStage", SafeStage,
		"AutoStage", AutoStage:bind(TRUE),
		"Burnout", Burnout
	)).
}