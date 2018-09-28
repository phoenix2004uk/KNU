{
	function GetPitchTarget {
		parameter launchProfile.
		local currentAltitude is ALTITUDE.
		if ALTITUDE > launchProfile["a1"] set currentAltitude to (ALTITUDE + ALT:apoapsis) / 2.
		local kA is 85.
		local kB is BODY:ATM:height.
		local kC is 5.
		if currentAltitude <= launchProfile["a0"] return launchProfile["p0"].
		if currentAltitude >= launchProfile["aN"] return launchProfile["pN"].
		return MIN(launchProfile["p0"], MAX(launchProfile["pN"], kA * (LN(kB) - LN(currentAltitude)) / (LN(kB) - LN(launchProfile["a0"])) + kC)).
	}
	function GetRollTarget {
		parameter launchProfile.
		return -90 + MIN(90,MAX(0,90*(ALTITUDE-launchProfile["r0"])/launchProfile["rN"])).
	}
	export(Lex(
		"version", "2.0.0",
		"pitchTarget", GetPitchTarget@,
		"rollTarget", GetRollTarget@,
		"defaultProfile", Lex(
			"a0", 1000,
			"p0", 87.5,
			"aN", 60000,
			"pN", 0,
			"a1", 40000,
			"r0", 5000,
			"rN", 5000
		)
	)).
}