{
	SET RunTests TO {
		LOCAL repeatableExperiments IS List("sensorThermometer","sensorBarometer","sensorAccelerometer","sensorGravimeter","sensorAtmosphere").
		LOCAL nonRepeatableExperiments IS List("science.module","GooExperiment").
		LOCAL dmExperiments IS List("dmmagBoom").
		LOCAL surfaceExperiments IS List("sensorAccelerometer").

		LOCAL ER_SURFACE_ONLY IS -1.
		LOCAL ER_NO_PART IS -2.
		LOCAL ER_NO_CONNECTION IS -3.
		LOCAL ER_INOPERABLE IS -4.
		LOCAL ER_HAS_DATA IS -5.
		LOCAL ER_TIMED_OUT IS -6.
		LOCAL ER_NO_DATA IS -7.

		LOCAL thermo IS "sensorThermometer".
		LOCAL magnet IS "dmmagBoom".
		LOCAL materials IS "science.module".
		LOCAL seismic IS "sensorAccelerometer".
		LOCAL goo IS "GooExperiment".

		LOCAL ex IS magnet.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				ER_NO_PART)		RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_PART)		RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			ER_NO_PART)		RETURN FALSE.

		SET ex TO thermo.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_DATA)		RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			ER_HAS_DATA)	RETURN FALSE.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](TRUE),			0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_DATA)		RETURN FALSE.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.

		SET ex TO materials.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_DATA)		RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			ER_HAS_DATA)	RETURN FALSE.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			ER_INOPERABLE)	RETURN FALSE.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				ER_INOPERABLE)	RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_DATA)		RETURN FALSE.

		SET ex TO goo.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE, 0),		0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE, 1),		0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			ER_HAS_DATA)	RETURN FALSE.
		IF NOT assertEqual("reset "+ex,						Libs["science"]["reset"][ex](),				0)				RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](),			ER_NO_DATA)		RETURN FALSE.
		IF NOT assertEqual("transmit "+ex,					Libs["science"]["transmit"][ex](1),			0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](TRUE, 0),		0)				RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](TRUE, 1),		ER_INOPERABLE)	RETURN FALSE.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](TRUE),			ER_INOPERABLE)	RETURN FALSE.

		SET ex TO seismic.
		IF NOT assertEqual("run "+ex,						Libs["science"]["run"][ex](FALSE),			0)				RETURN FALSE.

		PRINT "Prepare tests for during flight and landing".
		WHEN ALT:RADAR > 3000 THEN {
			PRINT "Running Atmospheric Science Tests...".
			assertEqual("run "+ex,							Libs["science"]["run"][ex](FALSE),			ER_SURFACE_ONLY).
			WHEN STATUS="LANDED" THEN {
				WAIT 10.
				PRINT "Finishing Science Tests...".
				PRINT "NOTE: previous result may have already said all pass regardless of these tests".
				IF NOT assertEqual("run "+seismic,			Libs["science"]["run"][seismic](FALSE),		ER_HAS_DATA)	RETURN FALSE.
				IF NOT assertEqual("transmit "+seismic,		Libs["science"]["transmit"][seismic](),		0)				RETURN FALSE.
				IF NOT assertEqual("run "+seismic,			Libs["science"]["run"][seismic](FALSE),		0)				RETURN FALSE.
			}
		}

		RETURN TRUE.
	}.
}