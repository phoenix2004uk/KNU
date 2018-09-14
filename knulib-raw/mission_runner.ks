{
	LOCAL fake_event IS {
		PARAMETER private, key, name, mission, public.
		private["events"][name](mission, public).
		private["active"]:REMOVE(key).
		private["events"]:REMOVE(key).
	}.
	LOCAL trigger_event IS {
		PARAMETER private, public, name.
		IF NOT private["events"]:HASKEY(name) RETURN FALSE.
		LOCAL key IS name+TIME:SECONDS.
		private["active"]:ADD(key).
		SET private["events"][key] TO fake_event:bind(private,key,name).
	}.
	LOCAL jump_step IS {
		PARAMETER private, public, jumpTo, returnTo IS "".
		IF returnTo <> "" {
			SET private["return"] TO MAX(0,private["runmode"] + returnTo).
		}
		SET private["runmode"] TO MAX(0,private["runmode"] + jumpTo).
		runfile_save(private, public).
	}.
	LOCAL next_step IS {
		PARAMETER private, public.
		IF private["return"] <> "" {
			SET private["runmode"] TO private["return"].
			SET private["return"] TO "".
		}
		ELSE SET private["runmode"] TO private["runmode"] + 1.
		runfile_save(private, public).
	}.
	LOCAL add_step IS {
		PARAMETER private, public, stepName.
		IF NOT private["steps"]:HASKEY(stepName) RETURN FALSE.
		private["sequence"]:ADD(stepName).
		runfile_save(private, public).
		RETURN TRUE.
	}.
	LOCAL insert_step IS {
		PARAMETER private, public, stepName.
		IF NOT private["steps"]:HASKEY(stepName) RETURN FALSE.

		LOCAL newSequence IS List().
		LOCAL index IS 0.
		UNTIL index=MIN(private["runmode"]+1,private["sequence"]:LENGTH) {
			newSequence:ADD(private["sequence"][index]).
			SET index TO index + 1.
		}
		newSequence:ADD(stepName).
		UNTIL index=private["sequence"]:LENGTH {
			newSequence:ADD(private["sequence"][index]).
			SET index TO index + 1.
		}
		SET private["sequence"] TO newSequence.
		runfile_save(private, public).
		RETURN TRUE.
	}.
	LOCAL remove_event IS {
		PARAMETER private, public, name.
		private["active"]:REMOVE(name).
		runfile_save(private, public).
	}.
	LOCAL add_event IS {
		PARAMETER private, public, name.
		IF NOT private["events"]:HASKEY(name) RETURN FALSE.
		private["active"]:ADD(name).
		runfile_save(private, public).
		RETURN TRUE.
	}.

	LOCAL runfile_vars IS List("runmode","return","sequence","active").
	LOCAL runfile_load IS {
		PARAMETER private, public.
		IF NOT EXISTS(private["runfile"]) RETURN FALSE.
		LOCAL data IS READJSON(private["runfile"]).
		LOCAL iter IS runfile_vars:ITERATOR.
		UNTIL NOT iter:NEXT SET private[iter:VALUE] TO data[iter:INDEX].
		RETURN TRUE.
	}.
	LOCAL runfile_save IS {
		PARAMETER private, public.
		LOCAL data IS List().
		LOCAL iter IS runfile_vars:ITERATOR.
		UNTIL NOT iter:NEXT {
			data:ADD(private[iter:VALUE]).
		}
		WRITEJSON(data, private["runfile"]).
	}.
	LOCAL statefile_load IS {
		PARAMETER statefile, stateObject.
		IF NOT EXISTS(statefile) RETURN FALSE.
		LOCAL data IS READJSON(statefile).
		FOR key IN data SET stateObject[key] TO data[key].
	}.
	LOCAL statefile_save IS {
		PARAMETER statefile, stateObject.
		WRITEJSON(stateObject, statefile).
	}.
	LOCAL stop_runner IS {
		PARAMETER private, public.
		SET private["runmode"] TO private["sequence"]:LENGTH.
		destuctor(private, public).
	}.

	LOCAL main IS {
		PARAMETER private, public, interface.
		IF private["runmode"] < private["sequence"]:LENGTH {
			private["steps"][private["sequence"][private["runmode"]]](interface, public).

			LOCAL iter IS private["active"]:COPY:ITERATOR.
			UNTIL NOT iter:NEXT {
				private["events"][iter:VALUE](interface, public).
			}
			WAIT 0.
			RETURN FALSE.
		}
		destuctor(private, public).
		RETURN TRUE.
	}.

	LOCAL destuctor IS {
		PARAMETER private, public.
		DELETEPATH(private["runfile"]).
		DELETEPATH(private["statefile"]).
	}.

	LOCAL constructor IS {
		PARAMETER uid, stepMethods IS Lex(), stepSequence IS 1, eventMethods IS Lex(), eventsActive IS 1.

		LOCAL public IS Lex().
		LOCAL private IS Lex().
		SET private["uid"] TO uid.
		SET private["runmode"] TO 0.
		SET private["return"] TO "".
		SET private["runfile"] TO "/etc/runmode."+uid.
		SET private["statefile"] TO "/etc/state."+uid.

		IF NOT stepMethods:ISTYPE("Lexicon") RETURN FALSE.
		IF NOT (stepSequence:ISTYPE("List") OR stepSequence:ISTYPE("Scalar")) RETURN FALSE.
		IF NOT eventMethods:ISTYPE("Lexicon") RETURN FALSE.
		IF NOT (eventsActive:ISTYPE("List") OR eventsActive:ISTYPE("Scalar")) RETURN FALSE.

		// initialize steps
		SET private["steps"] TO stepMethods.
		{
			IF stepSequence:ISTYPE("Scalar") AND stepSequence = 1 {
				SET private["sequence"] TO stepMethods:KEYS.
			}
			ELSE {
				SET private["sequence"] TO List().
				IF stepSequence:ISTYPE("List") {
					FOR key IN stepSequence {
						IF NOT stepMethods:HASKEY(key) RETURN FALSE.
						private["sequence"]:ADD(key).
					}
				}
			}
		}

		// initialize events
		SET private["events"] TO eventMethods.
		SET private["active"] TO UNIQUESET().
		{
			LOCAL activateAllEvents IS eventsActive:ISTYPE("Scalar") AND eventsActive = 1.
			LOCAL activateEventList IS eventsActive:ISTYPE("List").
			FOR key IN eventMethods:KEYS {
				IF activateAllEvents OR (activateEventList AND eventsActive:CONTAINS(key)) {
					private["active"]:ADD(key).
				}
			}
		}

		// bind functions
		LOCAL interface IS Lex().
		SET interface["next"]			TO next_step		:bind(private, public).
		SET interface["jump"]			TO jump_step		:bind(private, public).
		SET interface["add"]			TO add_step			:bind(private, public).
		SET interface["insert"]			TO insert_step		:bind(private, public).
		SET interface["enable"]			TO add_event		:bind(private, public).
		SET interface["disable"]		TO remove_event		:bind(private, public).
		SET interface["trigger"]		TO trigger_event	:bind(private, public).
		SET interface["end"]			TO stop_runner		:bind(private, public).
		SET interface["save"]			TO statefile_save	:bind(private["statefile"]).
		SET interface["load"]			TO statefile_load	:bind(private["statefile"]).

		// load previous state or save new state
		IF NOT runfile_load(private, public) runfile_save(private, public).
		//return main.
		RETURN main:bind(private, public, interface).
	}.

	export(Lex(
		"version", "1.2.0",
		"new", constructor
	)).
}