{
	LOCAL assertEqual IS {
		PARAMETER name, result, expected.
		PRINT "".
		PRINT name + " expects value = '" + expected + "'".
		IF result=expected PRINT " => PASS".
		ELSE {
			PRINT " => actual value: '" + result + "'".
			RETURN FALSE.
		}
		PRINT name + " expected type: " + expected:TYPENAME.
		IF result:TYPENAME = expected:TYPENAME PRINT " => PASS".
		ELSE {
			PRINT " => actual type: " + result:TYPENAME.
			RETURN FALSE.
		}
		RETURN TRUE.
	}.

	LOCAL assertNotEqual IS {
		PARAMETER name, result, expected.
		PRINT "".
		PRINT name + " expects value <> '" + expected + "'".
		IF result<>expected PRINT " => PASS".
		ELSE {
			PRINT " => actual value: '" + result + "'".
			RETURN FALSE.
		}
		RETURN TRUE.
	}.

	LOCAL assertTrue IS {
		PARAMETER name, result.
		PRINT "".
		PRINT name + " expects TRUE".
		IF result:ISTYPE("Boolean") {
			IF result=TRUE PRINT " => PASS".
			ELSE {
				PRINT " => FAIL".
				RETURN FALSE.
			}
		}
		ELSE {
			PRINT " => FAIL NOT BOOLEAN".
			RETURN FALSE.
		}
		RETURN TRUE.
	}.

	LOCAL assertFalse IS {
		PARAMETER name, result.
		PRINT "".
		PRINT name + " expects FALSE".
		IF result:ISTYPE("Boolean") {
			IF result=FALSE PRINT " => PASS".
			ELSE {
				PRINT " => FAIL".
				RETURN FALSE.
			}
		}
		ELSE {
			PRINT " => FAIL NOT BOOLEAN".
			RETURN FALSE.
		}
		RETURN TRUE.
	}.

	LOCAL RunTestScript IS {
		PARAMETER libName, testName IS libName:REPLACE("/","_").
		GLOBAL Libs IS Lex().

		IF NOT HasKSCConnection() {
			PRINT "Waiting for KSC connection...".
			WAIT UNTIL HasKSCConnection().
		}

		SET Libs[libName] TO import(libName).
		PRINT "KTest Suite Running: " + libName.
		GLOBAL RunTests IS FALSE.
		RUNPATH("/mission/main."+testName+".ks").
		IF NOT JF(RunTests) RETURN RunTests().
		RETURN TRUE.
	}.

	export(Lex(
		"version", "1.0.0",
		"assertEqual", assertEqual,
		"assertNotEqual", assertNotEqual,
		"assertTrue", assertTrue,
		"assertFalse", assertFalse,
		"RunTestScript", RunTestScript
	)).
}