{
	// ARIA-1				mission=ARIA	shipName=callsign=ARIA-1
	// KSAT-1B				mission=KSAT	shipName=callsign=KSAT-1B
	// SCAN - Maxwell I		mission=SCAN	shipName=SCAN - Maxwell I		callsign=Maxwell I
	// KSAT-2 "Hubble"		mission=KSAT	shipName=KSAT-2					callsign=Hubble
	IF NOT EXISTS("/etc/callsign") {
		LOCAL launchName IS SHIP:NAME.

		LOCAL missionTag IS launchName.
		LOCAL shipClass IS launchName.
		LOCAL callsign IS launchName.

		LOCAL len IS launchName:LENGTH.
		LOCAL index IS launchName:FIND("-").
		IF launchName:MATCHESPATTERN("^[A-Z]+-[0-9]+[a-zA-Z_]{0,1}$") {
			SET missionTag TO launchName:SUBSTRING(0,index).
			SET shipClass TO launchName.
			SET callsign TO launchName.
		}
		ELSE IF launchName:MATCHESPATTERN("^[A-Z]+ - [A-Z0-9 _]+$") {
			SET missionTag TO launchName:SUBSTRING(0,index-1).
			SET shipClass TO launchName.
			SET callsign TO launchName:SUBSTRING(index+2, len-index-2).
		}
		ELSE IF launchName:MATCHESPATTERN("^[A-Z]+-[0-9]+ ("+char(34)+"|')[A-Za-z0-9 _]+("+char(34)+"|')$") {
			SET missionTag TO launchName:SUBSTRING(0,index).
			LOCAL index2 IS launchName:FIND(" ").
			SET shipClass TO launchName:SUBSTRING(0,index2).
			SET callsign TO launchName:SUBSTRING(index2+2, len-index2-1).
		}
		SET SHIP:NAME TO callsign.

		Write("/etc/callsign",callsign).
		Write("/etc/class",shipClass).
		Write("/etc/mission",missionTag).
	}

	IF NOT HasKSCConnection() KnuPanic("No connection to KSC").

	DELETEPATH("1:/mission/").

	LOCAL callsign IS GetCallsign().
	LOCAL shipClass IS GetShipClass().
	LOCAL missionTag IS GetMissionTag().

	LOCAL orderedMissionFiles IS List(
		callsign+".ks",
		callsign+"/main.ks",
		missionTag+"/"+callsign+".ks",
		missionTag+"/"+callsign+"/main.ks",
		shipClass+".ks",
		shipClass+"/main.ks",
		missionTag+"/"+shipClass+".ks",
		missionTag+"/"+shipClass+"/main.ks",
		missionTag+".ks",
		missionTag+"/main.ks",
		"main.ks"
	).
	LOCAL mission_file IS FALSE.
	FOR possibleFile IN orderedMissionFiles {
		IF EXISTS("0:/missions/"+possibleFile) {
			SET mission_file TO "0:/missions/" + possibleFile.
			BREAK.
		}
	}
	IF mission_file {
		LOCAL mission_filepath IS path(mission_file).
		LOCAL mission_folder IS ""+mission_filepath:PARENT.
		LOCAL mission_filename IS mission_filepath:NAME:REPLACE(".ks","").

		LOCAL iterator IS OPEN(mission_folder):LIST:VALUES:ITERATOR.
		UNTIL NOT iterator:NEXT {
			LOCAL current IS iterator:VALUE.
			IF current:NAME:MATCHESPATTERN("^"+mission_filename+"(\.[^\.]+){0,1}\.ks$") {
				LOCAL main_name IS current:NAME:REPLACE(mission_filename,"main").
				IF NOT download(current:NAME,mission_folder:SUBSTRING(2,mission_folder:LENGTH-2)) KnuPanic(current:NAME,"download").
				MOVEPATH("1:/home/"+current:NAME, "1:/mission/"+main_name).
			}
		}
	}
	ELSE PRINT "no mission available".

	export(Lex("version","1.0.5")).
}