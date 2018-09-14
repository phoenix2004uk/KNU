LOCAL MissionRunner IS import("mission_runner")["new"].

RUNPATH("0:/missions/ktest/test.ks").

{
	SET TERMINAL:WIDTH TO 160.
	CLEARSCREEN.

	IF NOT EXISTS("/etc/test_reboot") {

		test("mission runner stops and clearsup if end() is called with a step", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test0",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["end"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 2", "step 3")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2", "output: expected ["+output+"] to be equal [S1S2]").
		}).

		test("mission runner calls the same step repeatedly if next() is not called from the current step (test will terminate after 5 seconds if still running)", {
			LOCAL output IS "".
			LOCAL now IS TIME:SECONDS.
			LOCAL isvalid IS MissionRunner("test1",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	IF TIME:SECONDS - now > 5 mission["end"]().},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 2", "step 3")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertTrue(output:STARTSWITH("S1S2S2"), "output:STARTSWITH(S1S2S2) expected ["+output:STARTSWITH("S1S2S2")+"] to be TRUE")
			AND		assertTrue(output:ENDSWITH("S2S2S2"), "output:STARTSWITH(S2S2S2) expected ["+output:ENDSWITH("S2S2S2")+"] to be TRUE")
			AND		assertFalse(output:CONTAINS("S3"), "output:STARTSWITH(S3) expected ["+output:CONTAINS("S3")+"] to be FALSE").
		}).

		test("mission runner executes all steps in order", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test2",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 2", "step 3")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2S3", "output: expected ["+output+"] to equal [S1S2S3]").
		}).

		test("mission runner executes all steps in order if the sequence is omitted (or equal to 1)", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test3",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2S3", "output: expected ["+output+"] to equal [S1S2S3]").
		}).

		test("mission runner only executes specified steps", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test4",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 2")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2", "output: expected ["+output+"] to equal [S1S2]").
		}).

		test("mission runner can execute the same step multiple times in the sequence", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test5",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 2", "step 1", "step 3", "step 2", "step 3")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2S1S3S2S3", "output: expected ["+output+"] to equal [S1S2S1S3S2S3]").
		}).

		test("mission runner activates all defined events after each step if the active list is omitted (or set to 1)", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test6",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	},
					"event 3", { PARAMETER mission.		SET output TO output + "E3".	}
				),
				1
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1E2E3S2E1E2E3S3E1E2E3", "output: expected ["+output+"] to equal [S1E1E2E3S2E1E2E3S3E1E2E3]").
		}).

		test("mission runner executes all active events after each step", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test7",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	},
					"event 3", { PARAMETER mission.		SET output TO output + "E3".	}
				),
				List("event 1","event 2")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1E2S2E1E2S3E1E2", "output: expected ["+output+"] to equal [S1E1E2S2E1E2S3E1E2]").
		}).

		test("mission runner can add() a step to the end of the sequence", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 8",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														mission["add"]("step 3").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S2S3S3", "output: expected ["+output+"] to equal [S1S2S3S3]").
		}).

		test("mission runner can insert() a step as the next step of the sequence", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 9",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														mission["insert"]("step 3").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S3S2S3", "output: expected ["+output+"] to equal [S1S3S2S3]").
		}).

		test("mission runner cannot have an undefined step in the sequence",{
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 10",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				List("step 1", "step 4")
			).
			RETURN	assertFalse(isvalid, "isvalid: expected ["+isvalid+"] to be FALSE")
			AND		assertEqual(output, "", "output: expected ["+output+"] to equal []").
		}).

		test("mission runner cannot have an active event which isn't defined",{
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 11",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	},
					"event 3", { PARAMETER mission.		SET output TO output + "E3".	}
				),
				List("event 1", "event 4")
			).
			RETURN	assertFalse(isvalid, "isvalid: expected ["+isvalid+"] to be FALSE")
			AND		assertEqual(output, "", "output: expected ["+output+"] to equal []").
		}).

		test("mission runner cannot add() a step to the sequence that does not exist as a step, add() should return false and the runner continues", {
			LOCAL output IS "".
			LOCAL added IS TRUE.
			LOCAL isvalid IS MissionRunner("test 12",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														SET added TO mission["add"]("step 4").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertFalse(added, "added: expected ["+added+"] to equal [FALSE]")
			AND		assertEqual(output, "S1S2S3", "output: expected ["+output+"] to equal [S1S2S3]").
		}).

		test("mission runner cannot insert() a step to the sequence that does not exist as a step, insert() should return false and the runner continues", {
			LOCAL output IS "".
			LOCAL inserted IS TRUE.
			LOCAL isvalid IS MissionRunner("test 13",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														SET inserted TO mission["insert"]("step 4").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertFalse(inserted, "inserted: expected ["+inserted+"] to equal [FALSE]")
			AND		assertEqual(output, "S1S2S3", "output: expected ["+output+"] to equal [S1S2S3]").
		}).

		test("mission runner does not execute a disable()d event", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 14",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["disable"]("event 3").		mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	},
					"event 3", { PARAMETER mission.		SET output TO output + "E3".	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1E2E3S2E1E2S3E1E2", "output: expected ["+output+"] to equal [S1E1E2E3S2E1E2S3E1E2]").
		}).

		test("mission runner ignores a disable() event call if it doesn't exist", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 15",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["disable"]("event 7").		mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	},
					"event 3", { PARAMETER mission.		SET output TO output + "E3".	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1E2E3S2E1E2E3S3E1E2E3", "output: expected ["+output+"] to equal [S1E1E2E3S2E1E2E3S3E1E2E3]").
		}).

		test("mission runner executes enable()d events going forwards after the current step run", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 16",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".
														mission["enable"]("event 2").
														mission["next"]().	},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".
														mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	}
				),
				List("event 1")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1S2E1E2S3E1E2", "output: expected ["+output+"] to equal [S1E1S2E1E2S3E1E2]").
		}).

		test("mission runner cannot have multiple active events with the same name", {
			LOCAL output IS "".
			LOCAL isvalid IS MissionRunner("test 17",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	},
					"event 2", { PARAMETER mission.		SET output TO output + "E2".	}
				),
				List("event 1", "event 1")
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1E1", "output: expected ["+output+"] to equal [S1E1]").
		}).

		test("mission runner can add() a step with the name of one that exists in the sequence", {
			LOCAL output IS "".
			LOCAL addedStep IS FALSE.
			LOCAL isvalid IS MissionRunner("test 18",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														SET addedStep TO mission["add"]("step 2").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertTrue(addedStep, "addedStep: expected ["+addedStep+"] to be TRUE")
			AND		assertEqual(output, "S1E1S2E1S2E1", "output: expected ["+output+"] to equal [S1E1S2E1S2E1]").
		}).

		test("mission runner cannot enable() an event with the name of one that exists, enable should still return TRUE", {
			LOCAL output IS "".
			LOCAL addedEvent IS FALSE.
			LOCAL isvalid IS MissionRunner("test 19",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".
														SET addedEvent TO mission["enable"]("event 1").
														mission["next"]().	},
					"step 2", { PARAMETER mission.		SET output TO output + "S2".	mission["next"]().	}
				),
				1,
				Lex(
					"event 1", { PARAMETER mission.		SET output TO output + "E1".	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertTrue(addedEvent, "addedEvent: expected ["+addedEvent+"] to be TRUE")
			AND		assertEqual(output, "S1E1S2E1", "output: expected ["+output+"] to equal [S1E1S2E1]").
		}).

		test("mission runner can jump to and return to different steps", {
			LOCAL output IS "".

			LOCAL done4 IS FALSE.
			LOCAL isvalid IS MissionRunner("test 20",
				Lex(
					"step 1", { PARAMETER mission.		SET output TO output + "S1".	mission["jump"](2,1).	},
					"step 2", { PARAMETER mission.		IF NOT done4 {
															SET output TO output + "S2A".
															mission["jump"](2,0).
														}
														ELSE {
															SET output TO output + "S2B".
															mission["jump"](3).
														}
														},
					"step 3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	},
					"step 4", { PARAMETER mission.		SET output TO output + "S4".
														SET done4 TO TRUE.
														mission["next"]().
														},
					"step 5", { PARAMETER mission.		SET output TO output + "S5".	mission["next"]().	}
				)
			):call().
			RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
			AND		assertEqual(output, "S1S3S2AS4S2BS5", "output: expected ["+output+"] to equal [S1S3S2AS4S2BS5]").
		}).

		PRINT "System will reboot during the following test. press any key to continue.".
		LOG "" TO "/etc/test_reboot".
	}
	ELSE {
		PRINT "the following tests should resume from their state prior to the reboot. press any key to continue.".
		DELETEPATH("/etc/test_reboot").
	}

	TERMINAL:INPUT:GETCHAR().

	test("mission runner can resume an existing mission (with the same uid) from where it was (after a reboot), including the sequence and active event lists", {
		LOCAL output IS "".
		LOCAL uid IS "test 21".

		LOCAL backupExists IS EXISTS("/etc/runmode."+uid).
		LOCAL backupData IS List().
		IF backupExists SET backupData TO READJSON("/etc/runmode."+uid).
		LOCAL backupContains IS List(). //List("runmode","return","sequence","active")

		LOCAL isvalid IS MissionRunner(uid,
			Lex(
				"s1", { PARAMETER mission.
						SET output TO output + "S1".
						mission["disable"]("e2").
						//mission["remove"]("s4"). // not implemented
						mission["next"]().
				},
				"s2", { PARAMETER mission.
						SET output TO output + "S2".
						mission["next"]().
						PRINT "Press any key to reboot".
						TERMINAL:INPUT:GETCHAR().
						REBOOT.
				},
				"s3", { PARAMETER mission.		SET output TO output + "S3".	mission["next"]().	},
				"s4", { PARAMETER mission.		SET output TO output + "S4".	mission["next"]().	},
				"s5", { PARAMETER mission.		SET output TO output + "S5".	mission["next"]().	}
			),
			1,
			Lex(
				"e1", { PARAMETER mission.		SET output TO output + "E1".},
				"e2", { PARAMETER mission.		SET output TO output + "E2".},
				"e3", { PARAMETER mission.		SET output TO output + "E3".}
			)
		):call().
		RETURN	assertNotEqual(isvalid, FALSE, "isvalid expected ["+isvalid+"] not to be FALSE")
		AND		assertEqual(output, "S3E1E3S4E1E3S5E1E3", "output: expected ["+output+"] to equal [S3E1E3S4E1E3S5E1E3]")
		AND		assertTrue(backupExists, "backupExists: expected ["+backupExists+"] to be TRUE")
		AND		assertEqual(backupData[0], 2, "backupData[0]: expected ["+backupData[0]+"] to equal [3]")
		AND		assertEqual(backupData[1], "", "backupData[1]: expected ["+backupData[1]+"] to equal []")
		AND		assertEqual(backupData[2]:JOIN(","), "s1,s2,s3,s4,s5", "backupData[2]: expected ["+backupData[2]+"] to equal [s1,s2,s3,s4,s5]")
		AND		assertTrue(backupData[3]:CONTAINS("e1"), "backupData[3]:CONTAINS(e1) expected ["+backupData[3]:CONTAINS("e1")+"] to be TRUE")
		AND		assertFalse(backupData[3]:CONTAINS("e2"), "backupData[3]:CONTAINS(e2) expected ["+backupData[3]:CONTAINS("e2")+"] to be FALSE")
		AND		assertTrue(backupData[3]:CONTAINS("e3"), "backupData[3]:CONTAINS(e3) expected ["+backupData[3]:CONTAINS("e3")+"] to be TRUE").
	}).

	PRINT "press any key".
	TERMINAL:INPUT:GETCHAR().
	CLEARSCREEN.

	PRINT "TODO: Should events be re-run, resumed, or skipped upon restarting a mission sequence?".
	PRINT "TODO: can nest jump() calls".
}