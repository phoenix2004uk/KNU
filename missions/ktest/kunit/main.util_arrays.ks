{
	//usort PARAMETER array,cmp.
	FUNCTION test_usort {
		LOCAL usort IS Libs["util/arrays"]["usort"].

		LOCAL unsortedNumbers IS List(9,4,3,8,7,8,0,1,-1,9).
		LOCAL orderedNumbers IS List(-1,0,1,3,4,7,8,8,9,9).
		LOCAL cmpNum IS {
			PARAMETER A,B.
			RETURN A-B.
		}.
		LOCAL sortedNumbers IS usort(unsortedNumbers, cmpNum).
		IF NOT assertTrue("usort(unsortedNumbers,cmpNum)=orderedNumbers", sortedNumbers:JOIN(",")=orderedNumbers:JOIN(",")) {
			PRINT unsortedNumbers.
			PRINT orderedNumbers.
			PRINT sortedNumbers.
			WAIT 10.
			RETURN FALSE.
		}

		LOCAL unsortedStrings IS List("the2","cat","sat","on","the1","mat","2   ","times","3   ","equals","seven","-1  ",".","-","#compare","10  ","20  ","-10 ").
		LOCAL orderedStrings IS List("#compare","-","-1  ","-10 ",".","10  ","2   ","20  ","3   ","cat","equals","mat","on","sat","seven","the1","the2","times").

		LOCAL cmpString IS {
			PARAMETER A,B.
			IF A<B RETURN -1.
			IF A>B RETURN 1.
			RETURN 0.
		}.
		LOCAL sortedStrings IS usort(unsortedStrings, cmpString).
		IF NOT assertTrue("usort(unsortedStrings,cmpString)=orderedStrings", sortedStrings:JOIN(",")=orderedStrings:JOIN(",")) {
			PRINT unsortedStrings.
			PRINT orderedStrings.
			PRINT sortedStrings.
			WAIT 10.
			RETURN FALSE.
		}

		LOCAL callsign IS "craft".
		LOCAL shipClass IS "class".
		LOCAL missionTag IS "mission".
		LOCAL unsortedMissionFiles IS List(
			List("main.ks","/class"),
			List("main.ks","/mission/class"),
			List("main.ks","/craft"),
			List("main.ks","/mission/craft"),
			List("main.ks","/"),
			List("main.ks","/mission"),
			List("mission.ks","/"),
			List("craft.ks","/mission"),
			List("class.ks","/"),
			List("craft.ks","/"),
			List("class.ks","/mission")
		).
		LOCAL orderedMissionFiles IS List(
			List("craft.ks","/"),
			List("main.ks","/craft"),
			List("craft.ks","/mission"),
			List("main.ks","/mission/craft"),

			List("class.ks","/"),
			List("main.ks","/class"),
			List("class.ks","/mission"),
			List("main.ks","/mission/class"),

			List("mission.ks","/"),
			List("main.ks","/mission"),

			List("main.ks","/")
		).
		LOCAL RateMissionPath IS {
			PARAMETER fileName, folderPath.
			LOCAL pathCount IS folderPath:SEGMENTS:LENGTH.
			LOCAL MAX_DEPTH IS 2.
			LOCAL folderName IS folderPath:NAME.
			IF fileName=callsign+".ks" RETURN 0 + MAX_DEPTH * pathCount.
			IF fileName=shipClass+".ks" RETURN 4 + MAX_DEPTH * pathCount.
			IF fileName=missionTag+".ks" RETURN 8 + MAX_DEPTH * pathCount.
			IF folderName=callsign RETURN 1 + MAX_DEPTH * (pathCount-1).
			IF folderName=shipClass RETURN 5 + MAX_DEPTH * (pathCount-1).
			IF folderName=missionTag RETURN 9 + MAX_DEPTH * (pathCount-1).
			RETURN 13 + MAX_DEPTH * (pathCount-1).
		}.
		LOCAL cmpMissionFiles IS {
			PARAMETER a,b.
			LOCAL ax IS RateMissionPath(a[0],path(a[1])).
			LOCAL bx IS RateMissionPath(b[0],path(b[1])).
			RETURN ax - bx.
		}.
		LOCAL sortedMissionFiles IS usort(unsortedMissionFiles:COPY, cmpMissionFiles).
		IF NOT assertTrue("usort(unsortedMissionFiles,cmpMissionFiles)=orderedMissionFiles", sortedMissionFiles:JOIN(",")=orderedMissionFiles:JOIN(",")) {
			FOR whichList IN List(unsortedMissionFiles, orderedMissionFiles, sortedMissionFiles) {
				LOCAL index IS 0.
				UNTIL index=whichList:LENGTH {
					LOCAL entry IS whichList[index].
					SET whichList[index] TO entry[1]+" "+entry[0].
					SET index TO index + 1.
				}
			}
			WAIT 5.
			PRINT unsortedMissionFiles.
			PRINT orderedMissionFiles.
			PRINT sortedMissionFiles.
			RETURN FALSE.
		}

		RETURN TRUE.
	}

	SET RunTests TO {
		IF NOT test_usort() RETURN FALSE.

		RETURN TRUE.
	}.
}