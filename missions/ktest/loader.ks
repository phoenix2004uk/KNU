LOCAL getFileNameFormat IS {
	PARAMETER fileName, ver IS "".
	IF ver:LENGTH = 0 {
		RETURN "^" + fileName + "(-v\d+\.\d+\.\d+){0,1}\.ks$".
	}
	ELSE {
		SET ver TO ver:REPLACE("*","\d+").
		RETURN "^" + fileName + "-v" + ver:REPLACE(".","\.") + "\.ks$".
	}
}.

SET TERMINAL:WIDTH TO 160.
CLEARSCREEN.
RUNPATH("0:/missions/ktest/test.ks").

test("getFileNameFormat() accepts no version parameters", {
	LOCAL output IS getFileNameFormat("file").
	RETURN assertEqual(output, "^file(-v\d+\.\d+\.\d+){0,1}\.ks$", "output: expected ["+output+"] to equal [^file(-v\d+\.\d+\.\d+){0,1}\.ks$]").
}).

test("getFileNameFormat() accepts a version parameter (1.0.0)", {
	LOCAL output IS getFileNameFormat("file","1.0.0").
	RETURN assertEqual(output, "^file-v1\.0\.0\.ks$", "output: expected ["+output+"] to equal [^file-v1\.0\.0\.ks$]").
}).

test("getFileNameFormat() should match filenames with or without a version", {
	LOCAL format IS getFileNameFormat("file").
	LOCAL testName1 IS "file.ks".
	LOCAL testName2 IS "file-v1.0.0.ks".

	RETURN	assertTrue(testName1:MATCHESPATTERN(format), "testName1: expected ["+testName1:MATCHESPATTERN(format)+"] to be TRUE")
	AND		assertTrue(testName2:MATCHESPATTERN(format), "testName2: expected ["+testName2:MATCHESPATTERN(format)+"] to be TRUE").
}).

test("getFileNameFormat(1.0.0) should only match filenames with -v1.0.0", {
	LOCAL format IS getFileNameFormat("file", "1.0.0").
	LOCAL testName1 IS "file.ks".
	LOCAL testName2 IS "file-v1.0.0.ks".

	RETURN	assertFalse(testName1:MATCHESPATTERN(format), "testName1: expected ["+testName1:MATCHESPATTERN(format)+"] to be FALSE")
	AND		assertTrue(testName2:MATCHESPATTERN(format), "testName2: expected ["+testName2:MATCHESPATTERN(format)+"] to be TRUE").
}).

test("getFileNameFormat(1.0.*) should match filenames with -v1.0.*", {
	LOCAL format IS getFileNameFormat("file", "1.0.*").
	LOCAL testName1 IS "file.ks".
	LOCAL testName2 IS "file-v1.0.0.ks".
	LOCAL testName3 IS "file-v1.0.1.ks".

	RETURN	assertFalse(testName1:MATCHESPATTERN(format), "testName1: expected ["+testName1:MATCHESPATTERN(format)+"] to be FALSE")
	AND		assertTrue(testName2:MATCHESPATTERN(format), "testName2: expected ["+testName2:MATCHESPATTERN(format)+"] to be TRUE")
	AND		assertTrue(testName3:MATCHESPATTERN(format), "testName3: expected ["+testName3:MATCHESPATTERN(format)+"] to be TRUE").
}).