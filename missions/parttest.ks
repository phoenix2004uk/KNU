FUNCTION RunTests
{
	PARAMETER partNames.
	FOR name IN partNames {
		LOCAL parts IS SHIP:PartsNamed(name).
		IF parts:LENGTH > 0 {
			PRINT "Running Part Test: " + name.
			parts[0]:GetModule("ModuleTestSubject"):DoEvent("Run Test").
		}
		ELSE {
			PRINT "Part Not Found: " + name.
		}
	}
}

RunTests(List()).
UNTIL STAGE:NUMBER = 1 { STAGE. WAIT 1. }