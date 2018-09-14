{
	LOCAL ascent IS import("programs/ascent").
	LOCAL change_circ IS import("programs/change_circ").
	LOCAL descent IS import("programs/descent").
	LOCAL partLib IS import("util/parts").
	LOCAL stringLib IS import("util/strings").
	LOCAL str_pad IS stringLib["str_pad"].
	LOCAL vsprintf IS stringLib["vsprintf"].
	LOCAL ISH IS import("util/ish").
	LOCAL MNV IS import("maneuver").

	// set some action groups
	ON AG1 {CORE:DoEvent("open terminal").PRESERVE.}
	ON AG2 {REBOOT.}
	ON AG3 {KUniverse:REVERTTOLAUNCH().}
	ON ABORT {KUniverse:REVERTTO("VAB").}
	TOGGLE AG1.

	LOCAL LOCK METS TO str_pad("M+"+ROUND(MET,0),10).

	IF RUNMODE >=0 AND RUNMODE <20 {

		// Ap, inc, ecc
		LOCAL parkingOrbit IS List(150E3, 0, 0).
		//LOCAL ascent IS PRG["init"]("ascent",Lex(
		//	"lastStage", 1,
			//"heading", 90
			//"inclination", 6 // => heading -= inclination
		//	"orbit", Lst(150E3, 0), //"parkingAltitude", 150E3,
			//"profile", List(1000, 87.5, 60000, 30000),
			//"srbPitch", FALSE,
		//)).
		// fairings deployed during an event

		IF RUNMODE=0 {
			LOCAL now IS MET.
			LOCAL LOCK LCT TO MET - now - 10.
			Notify("Launching in ...").
			PRINT METS+" Launch Countdown".
			UNTIL LCT >= 0 {
				Notify("T"+ROUND(LCT,0)+" ...").
				WAIT 1.
			}
			PRINT METS.
			Notify("Lift Off").
			ascent["init"]().
		}

		IF RUNMODE > 0 AND RUNMODE < 11 {
			ascent["SetLastAscentStage"](1).
			//ascent["SetLaunchHeading"](90).
			ascent["SetParkingOrbit"](parkingOrbit[0], parkingOrbit[1], parkingOrbit[2]).
			//ascent["SetFairingName"]("").
			ascent["SetLaunchProfile"](1000, 87.5, 60000, 0, 30000).
			//ascent["DisableSRBPitch"]().
			ascent["duringAscent"]({
				PRINT METS+" Altitude: "+str_pad(ROUND(ALTITUDE,2)+"m",10).
			}).
			ascent["onEngineShutdown"]({
				Notify(METS+" Main Engine Shutdown").
			}).
			ascent["onEnterSpace"]({
				Notify(METS+" We have left the atmosphere").
				partLib["DoPartModuleEvent"]("mediumDishAntenna","ModuleRTAntenna","activate").
				partLib["SetPartModuleField"]("mediumDishAntenna","ModuleRTAntenna","target","Mission Control").
				PANELS ON.
			}).
			ascent["duringOrbitInsertion"]({
				PRINT METS+" Periapsis: "+str_pad(ROUND(ALT:PERIAPSIS,2)+"m",10).
			}).
			ascent["onOrbitInsertion"]({
				Notify(METS+" Beginning Orbital Insertion").
			}).
			ascent["duringCircularization"]({
				PRINT METS+" eccentricity: "+str_pad(ROUND(SHIP:OBT:ECCENTRICITY,4),10).
			}).
			ascent["onCircularization"]({
				Notify(METS+" Circularization Complete").
			}).

			ascent["run"]().
			ascent["purge"]().
		}
		LOCK STEERING TO PROGRADE.
		WAIT 10.
		IF RUNMODE>=11 AND RUNMODE <17 {
			change_circ["init"](Lex(
				"targetAltitude", parkingOrbit[0],
				"maxThrust", 0.2
			)).
			change_circ["addEventListener"](change_circ["events"]["onStart"], {PARAMETER args.
				Notify(METS+" Performing Corrections").
			}).
			change_circ["addEventListener"](change_circ["events"]["onAddNode"], {PARAMETER args.
				PRINT METS+" New Maneuver".
				PRINT NEXTNODE.
			}).
			change_circ["addEventListener"](change_circ["events"]["duringCoast"], {PARAMETER args.
				//PRINT "Node in T-"+NEXTNODE:ETA.
			}).
			change_circ["addEventListener"](change_circ["events"]["onBurn"], {PARAMETER args.
				Notify(METS+" Starting Burn").
				print args.
			}).
			change_circ["addEventListener"](change_circ["events"]["duringBurn"], {PARAMETER args.
				PRINT vsprintf("R: {0} Ra: {1} Rp: {2} Ecc: {3} Inc: {4}", List(SHIP:OBT:SEMIMAJORAXIS, ALT:APOAPSIS, ALT:PERIAPSIS, SHIP:OBT:ECCENTRICITY, SHIP:OBT:INCLINATION)).
			}).
			change_circ["addEventListener"](change_circ["events"]["afterBurn"], {PARAMETER args.
				Notify(METS+" Burn Complete").
			}).
			change_circ["run"]().
			change_circ["purge"]().
		}
		IF RUNMODE = 17 {
			Notify(METS+" Performing 1 full orbit").
			WAIT 5.
			LOCAL doneTime IS TIME:SECONDS+SHIP:OBT:PERIOD.
			WARPTO(doneTime).
			WAIT UNTIL doneTime - TIME:SECONDS <= 0.
			SET WARP TO 0.
			SetRunmode(20).
		}
		IF RUNMODE = 20 {
			//descent["setReEntryPeriapsis"](25000).
			descent["setReEntryStage"](0).
			//descent["setParachuteStage"](0).
			//descent["setParachuteAltitude"](15000).
			descent["init"]().
		}
		IF RUNMODE >= 21 AND RUNMODE < 25 {
			Notify(METS+" Begin Descent").
			descent["run"]().
		}
		IF RUNMODE = 25 {
			Notify(METS+" Mission Complete").
			SetRunmode(99).
		}
		IF RUNMODE=911 {
			Notify("Performing Corrections...").
			IF NOT ISH["value"](ALT:APOAPSIS, parkingOrbit[0],1E3) {

				LOCAL hohmann_dV IS MNV["GetHohmannDeltaV"](parkingOrbit[0]).
				LOCAL tMax IS 0.2.

				LOCAL hohmann_preburn IS MNV["GetManeuverTime"](hohmann_dV[0]/2, tMax).
				LOCAL hohmann_fullburn IS MNV["GetManeuverTime"](hohmann_dV[0]/2, tMax).
				LOCAL burn_time IS TIME:SECONDS.

				IF parkingOrbit[0] > ALT:APOAPSIS {
					SET burn_time TO burn_time + ETA:PERIAPSIS.
				}
				ELSE {
					SET burn_time TO burn_time + ETA:APOAPSIS.
				}
				LOCAL hohmann_mnv IS NODE(burn_time, 0, 0, hohmann_dV[0]).
				ADD hohmann_mnv.
				LOCK STEERING TO hohmann_mnv:BURNVECTOR.
				WAIT UNTIL TIME:SECONDS+30 >= burn_time - hohmann_preburn.
				SET WARP TO 0.
				WAIT UNTIL TIME:SECONDS >= burn_time - hohmann_preburn.
				LOCK THROTTLE TO tMax.
				WAIT UNTIL TIME:SECONDS + hohmann_fullburn >= burn_time - hohmann_preburn.
				LOCK THROTTLE TO 0.
				LOCK STEERING TO PROGRADE.
				REMOVE hohmann_mnv.

				SET hohmann_preburn TO MNV["GetManeuverTime"](hohmann_dV[1]/2, tMax).
				SET hohmann_fullburn TO MNV["GetManeuverTime"](hohmann_dV[1]/2, tMax).
				SET burn_time TO TIME:SECONDS.
				IF ALT:PERIAPSIS < parkingOrbit[0] {
					SET burn_time TO burn_time + ETA:APOAPSIS.
				}
				ELSE {
					SET burn_time TO burn_time + ETA:PERIAPSIS.
				}
				SET hohmann_mnv TO NODE(burn_time, 0, 0, hohmann_dV[1]).
				ADD hohmann_mnv.
				LOCK STEERING TO hohmann_mnv:BURNVECTOR.
				WAIT UNTIL TIME:SECONDS+30 >= burn_time - hohmann_preburn.
				SET WARP TO 0.
				WAIT UNTIL TIME:SECONDS >= burn_time - hohmann_preburn.
				LOCK THROTTLE TO tMax.
				WAIT UNTIL TIME:SECONDS + hohmann_fullburn >= burn_time - hohmann_preburn.
				LOCK THROTTLE TO 0.
				LOCK STEERING TO PROGRADE.
				REMOVE hohmann_mnv.
			}

			SetRunmode(99).
			Notify(METS+" Mission Complete").
		}
	}
}