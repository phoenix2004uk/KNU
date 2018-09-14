FUNCTION DoExperiment {
	PARAMETER partName, doTransmit, sciModule, maxTime IS 20.
	IF doTransmit AND NOT HasKSCConnection() RETURN List(-1,"No connection to KSC").
	FOR p IN SHIP:PartsNamed(partName) {
		LOCAL m IS p:GetModule(sciModule).
		IF NOT m:INOPERABLE {
			m:DEPLOY.
			LOCAL t IS TIME:SECONDS.
			UNTIL m:HASDATA {
				IF TIME:SECONDS-t>maxTime RETURN List(-2,"Experiment timed out: "+partName).
				WAIT 0.1.
			}
			WAIT UNTIL m:HASDATA OR TIME:SECONDS-t>maxTime.
			IF doTransmit AND m:HASDATA m:TRANSMIT.
			RETURN List(1,m).
		}
	}
	RETURN List(0,"Experiment not available or inoperable: "+partName).
}
FUNCTION DoScience {
	PARAMETER experiments, doTransmit IS TRUE, module IS "ModuleScienceExperiment", maxTime IS 10.
	LOCAL res IS Queue().
	FOR x IN experiments res:PUSH(DoExperiment(x, doTransmit, module, maxTime)).
	FOR r IN res IF r[0]<1 NotifyError("Science: " + r[1]).
	RETURN res.
}
FUNCTION DMScience {
	PARAMETER experiments, doTransmit IS TRUE, module IS "DMModuleScienceAnimate", maxTime IS 10.
	LOCAL res IS DoScience(experiments, doTransmit, module, maxTime).
	FOR r IN res IF r[0]=1 r[1]:TOGGLE.
	RETURN res.
}
FUNCTION DumpScience {
	PARAMETER partName, allParts IS FALSE, sciModule IS "ModuleScienceExperiment".
	FOR p IN SHIP:PartsNamed(partName) {
		LOCAL m IS p:GetModule(sciModule).
		IF m:HASDATA m:DUMP.
		IF NOT m:INOPERABLE m:RESET.
		IF NOT allParts BREAK.
	}
}
FUNCTION DMDumpScience { PARAMETER partName, allParts IS FALSE. DumpScience(partName, allParts, "DMModuleScienceAnimate").}