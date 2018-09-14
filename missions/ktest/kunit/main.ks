FUNCTION cleanup {

	DELETEPATH("1:/lib").
	DELETEPATH("1:/mission").

}

FUNCTION main {

	IF NOT RunTestScript("util/strings") RETURN FALSE.
	IF NOT RunTestScript("util/arrays") RETURN FALSE.
	IF NOT RunTestScript("science") RETURN FALSE.
	IF NOT RunTestScript("util/ish") RETURN FALSE.

	CLEARSCREEN.
	PRINT "NOW GET TO ORBIT...".
	PRINT "Meanwhile we will test system libs: Burnout, SafeStage, AutoStage".
	PRINT "If a Burnout occurs below 20km ALT:RADAR, we will not autostage".
	PRINT "otherwise autostage will occur".
	PRINT " ".
	IF NOT RunTestScript("system","system_launch") RETURN FALSE.


	PRINT "Resuming Tests in 10seconds".
	WAIT 10.
	CLEARSCREEN.
	IF NOT RunTestScript("util/parts") RETURN FALSE.
	PRINT "Deploy Solar Panels".
	PANELS ON.

	WAIT 10.
	CLEARSCREEN.
	IF NOT RunTestScript("telemetry") RETURN FALSE.
	IF NOT RunTestScript("maneuver") RETURN FALSE.

	WAIT 10.
	CLEARSCREEN.
	PRINT " ".
	PRINT "Orbital tests complete - we'll handle the rest from here - sit back and watch till we land...".
	PRINT "staging will be called using SafeStage".

	IF NOT RunTestScript("system","system_descent") RETURN FALSE.

	PRINT "Test will end in 30 seconds".
	WAIT 30.

	RETURN TRUE.
}

// get KTest lib
LOCAL KTest IS import("util/ktest").
GLOBAL assertEqual IS KTest["assertEqual"].
GLOBAL assertNotEqual IS KTest["assertNotEqual"].
GLOBAL assertTrue IS KTest["assertTrue"].
GLOBAL assertFalse IS KTest["assertFalse"].
GLOBAL assertFalse IS KTest["assertFalse"].
GLOBAL RunTestScript IS KTest["RunTestScript"].

// helps find minified errors
// ((SET|LOCAL)[^.]*[^)\.0-9]+|RETURN ([^.)]+))\.[^ })]{1}

// set some action groups
ON AG1 {CORE:DoEvent("open terminal").PRESERVE.}
ON AG2 {REBOOT.}
ON AG3 {KUniverse:REVERTTOLAUNCH().}
ON ABORT {KUniverse:REVERTTO("VAB").}
TOGGLE AG1.

// set terminal
SET TERMINAL:WIDTH TO 100.
SET TERMINAL:HEIGHT TO 40.
WAIT 1.
// start testing
CLEARSCREEN.
UNTIL 0 {
	PRINT "Select a testing method".
	PRINT "0) exit back to VAB".
	PRINT "1) main - full test suite".
	PRINT "2) util/arrays".
	PRINT "3) util/strings".
	PRINT "4) util/parts".
	PRINT "5) science".
	PRINT "6) ish".
	PRINT " ".
	PRINT "At any time during testing the following action groups are available:".
	PRINT "  AG1 opens the terminal".
	PRINT "  AG2 reboots the processor".
	PRINT "  AG3 reverts the flight".
	PRINT "  ABORT reverts back to the VAB".
	PRINT " ".
	LOCAL test_selection IS TERMINAL:INPUT:GETCHAR():TONUMBER(-1).
	LOCAL test_result IS FALSE.
	CLEARSCREEN.
	IF test_selection=0 TOGGLE ABORT.
	ELSE IF test_selection=1 SET test_result TO main().
	ELSE IF test_selection>=2 AND test_selection<=6 {
		LOCAL test_suites IS List("util/arrays","util/strings","util/parts","science","util/ish").
		SET test_result TO RunTestScript(test_suites[test_selection-2]).
	}
	IF test_result {
		PRINT "Test Success".
	}
	ELSE {
		PRINT "Test Failed".
	}
	PRINT "Press any key to return to main menu".
	TERMINAL:INPUT:GETCHAR().
	CLEARSCREEN.
}
IF test_result TOGGLE ABORT.
ELSE PRINT "Test Failed".
CLEARSCREEN.

// finished - but don't end otherwise our test action groups stop working
cleanup().
WAIT UNTIL 0.