{
	LOCAL GetPartModule IS import("util/parts")["GetPartModule"].
	LOCAL EXPERIMENT_WAIT_TIME IS 10.
	LOCAL SQUAD_SCIENCE_MODULE IS "ModuleScienceExperiment".
	LOCAL DMAGIC_SCIENCE_MODULE IS "DMModuleScienceAnimate".
	LOCAL ER_SURFACE_ONLY IS -1.
	LOCAL ER_NO_PART IS -2.
	LOCAL ER_NO_CONNECTION IS -3.
	LOCAL ER_INOPERABLE IS -4.
	LOCAL ER_HAS_DATA IS -5.
	LOCAL ER_TIMED_OUT IS -6.
	LOCAL ER_NO_DATA IS -7.
	LOCAL standardExperiments IS List(
		"sensorThermometer","sensorBarometer","sensorAccelerometer","sensorGravimeter","sensorAtmosphere","science.module","GooExperiment"
	).
	LOCAL dmExperiments IS List("dmmagBoom","rpwsAnt").
	LOCAL surfaceExperiments IS List("sensorAccelerometer").
	LOCAL _DoExperiment IS {
		PARAMETER partName, moduleName, doToggle, surfaceOnly, doTransmit IS TRUE, index IS 0.

		IF surfaceOnly AND (AIRSPEED>0.1 OR STATUS="SPLASHED") {
			RETURN ER_SURFACE_ONLY.
		}
		LOCAL module IS GetPartModule(partName, moduleName, index).
		IF JF(module) {
			RETURN ER_NO_PART.
		}
		IF module:HASDATA {
			RETURN ER_HAS_DATA.
		}
		IF module:INOPERABLE {
			RETURN ER_INOPERABLE.
		}
		module:DEPLOY.
		LOCAL t IS TIME:SECONDS.
		UNTIL module:HASDATA {
			IF TIME:SECONDS-t > EXPERIMENT_WAIT_TIME {
				RETURN ER_TIMED_OUT.
			}
		}
		IF doToggle module:TOGGLE.
		IF doTransmit {
			IF NOT HasKSCConnection() {
				RETURN ER_NO_CONNECTION.
			}
			ELSE {
				module:TRANSMIT.
				WAIT UNTIL NOT module:HASDATA.
			}
		}
		RETURN 0.
	}.

	LOCAL _TransmitExperiment IS {
		PARAMETER partName, moduleName, index IS 0.
		IF NOT HasKSCConnection() RETURN ER_NO_CONNECTION.
		LOCAL module IS GetPartModule(partName, moduleName, index).
		IF JF(module) RETURN ER_NO_PART.
		IF NOT module:HASDATA RETURN ER_NO_DATA.
		module:TRANSMIT.
		WAIT UNTIL NOT module:HASDATA.
		RETURN 0.
	}.

	LOCAL _ResetExperiment IS {
		PARAMETER partName, moduleName, index IS 0.

		LOCAL module IS GetPartModule(partName, moduleName, index).
		IF JF(module) {
			RETURN ER_NO_PART.
		}
		IF module:INOPERABLE {
			RETURN ER_INOPERABLE.
		}
		IF module:HASDATA module:RESET.
		WAIT 2.
		RETURN 0.
	}.

	LOCAL runExperiments IS Lex().
	LOCAL resetExperiments IS Lex().
	LOCAL transmitExperiments IS Lex().

	FOR ex IN standardExperiments {
		SET runExperiments[ex] TO _DoExperiment:bind(ex):bind(SQUAD_SCIENCE_MODULE):bind(FALSE).
		SET transmitExperiments[ex] TO _TransmitExperiment:bind(ex):bind(SQUAD_SCIENCE_MODULE).
		SET resetExperiments[ex] TO _ResetExperiment:bind(ex):bind(SQUAD_SCIENCE_MODULE).
	}

	FOR ex IN dmExperiments {
		SET runExperiments[ex] TO _DoExperiment:bind(ex):bind(DMAGIC_SCIENCE_MODULE):bind(TRUE).
		SET transmitExperiments[ex] TO _TransmitExperiment:bind(ex):bind(DMAGIC_SCIENCE_MODULE).
		SET resetExperiments[ex] TO _ResetExperiment:bind(ex):bind(DMAGIC_SCIENCE_MODULE).
	}

	FOR ex IN runExperiments:KEYS {
		SET runExperiments[ex] TO runExperiments[ex]:bind(surfaceExperiments:CONTAINS(ex)).
	}

	export(Lex(
		"version", "1.0.1",
		"run", runExperiments,
		"transmit", transmitExperiments,
		"reset", resetExperiments
	)).
}