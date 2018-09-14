{
	Require(List("science")).
	GLOBAL SCIENCE_EC_WAIT IS 0.50.
	FUNCTION GetShipPowerLevel {
		FOR res IN SHIP:RESOURCES {
			IF res:NAME = "ELECTRICCHARGE" {
				RETURN res:AMOUNT / res:CAPACITY.
			}
		}
		RETURN FALSE.
	}
	FUNCTION DoScienceRanger {
		PARAMETER experiments, doTransmit IS TRUE, module IS "ModuleScienceExperiment", maxTime IS 10.
		LOCAL res IS Queue().
		FOR x IN experiments {
			WAIT UNTIL GetShipPowerLevel() > SCIENCE_EC_WAIT.
			res:PUSH(DoExperiment(x, doTransmit, module, maxTime)).
		}
		FOR r IN res IF r[0]<1 NotifyError("Science: " + r[1]).
		RETURN res.
	}
	FUNCTION DMScienceRanger {
		PARAMETER experiments, doTransmit IS TRUE, module IS "DMModuleScienceAnimate", maxTime IS 10.
		LOCAL res IS DoScience(experiments, doTransmit, module, maxTime).
		FOR r IN res IF r[0]=1 r[1]:TOGGLE.
		RETURN res.
	}
	GLOBAL DoScience IS DoScienceRanger@.
	GLOBAL DMScience IS DMScienceRanger@.
}