// tester
GLOBAL currentLine IS 3.
FUNCTION test {
	PARAMETER description, testFunction.
	LOCAL thisLine IS currentLine.
	SET currentLine TO currentLine + 1.
	PRINT "[ RUNNING  ] "+description AT (0, thisLine).
	WAIT 0.1.
	IF NOT testFunction()	{ PRINT "FAILED  " AT (2, thisLine). }
	ELSE					{ PRINT "PASSED  " AT (2, thisLine). }
	SET currentLine TO currentLine + 1.
	WAIT 0.1.
}
FUNCTION assertEqual {
	PARAMETER testValue, expectedValue, errorMessage.
	IF testValue:TYPENAME = expectedValue:TYPENAME AND testValue = expectedValue RETURN TRUE.
	PRINT "  > " + errorMessage AT (0, currentLine).
	SET currentLine TO currentLine + 1.
	RETURN FALSE.
}
FUNCTION assertNotEqual {
	PARAMETER testValue, expectedNotValue, errorMessage.
	IF testValue:TYPENAME <> expectedNotValue:TYPENAME OR testValue <> expectedNotValue RETURN TRUE.
	PRINT "  > " + errorMessage AT (0, currentLine).
	SET currentLine TO currentLine + 1.
	RETURN FALSE.
}
FUNCTION assertFalse {
	PARAMETER testValue, errorMessage.
	IF testValue:ISTYPE("Boolean") AND testValue=FALSE RETURN TRUE.
	PRINT "  > " + errorMessage AT (0, currentLine).
	SET currentLine TO currentLine + 1.
	RETURN FALSE.
}
FUNCTION assertTrue {
	PARAMETER testValue, errorMessage.
	IF testValue:ISTYPE("Boolean") AND testValue=TRUE RETURN TRUE.
	PRINT "  > " + errorMessage AT (0, currentLine).
	SET currentLine TO currentLine + 1.
	RETURN FALSE.
}