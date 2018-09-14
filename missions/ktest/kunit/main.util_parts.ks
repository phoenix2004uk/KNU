{
	SET RunTests TO {
		PRINT "Deploy Dish and point to Kerbin".
		IF NOT assertEqual("antenna status=off",
			Libs["util/parts"]["GetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","status"),
			"off") RETURN FALSE.

		Libs["util/parts"]["DoPartModuleEvent"]("RTGigaDish1","ModuleRTAntenna","Activate").
		IF NOT assertEqual("antenna status=operational",
			Libs["util/parts"]["GetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","status"),
			"operational") RETURN FALSE.

		Libs["util/parts"]["SetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","target",Kerbin).
		IF NOT assertEqual("antenna target=Kerbin",
			Libs["util/parts"]["GetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","target"),
			Kerbin) RETURN FALSE.

		Libs["util/parts"]["SetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","target","Mission Control").
		IF NOT assertEqual("antenna target=Mission Control",
			Libs["util/parts"]["GetPartModuleField"]("RTGigaDish1","ModuleRTAntenna","target"),
			"Mission Control") RETURN FALSE.

		RETURN TRUE.
	}.
}