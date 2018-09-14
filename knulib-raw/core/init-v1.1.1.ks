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
			SET callsign TO launchName.
			SET shipClass TO launchName.
			SET missionTag TO launchName:SUBSTRING(0,index).
		}
		ELSE IF launchName:MATCHESPATTERN("^[A-Z]+ - [A-Z0-9 _]+$") {
			SET callsign TO launchName:SUBSTRING(index+2, len-index-2).
			SET shipClass TO launchName.
			SET missionTag TO launchName:SUBSTRING(0,index-1).
		}
		ELSE IF launchName:MATCHESPATTERN("^[A-Z]+-[0-9]+ ("+char(34)+"|')[A-Za-z0-9 _]+("+char(34)+"|')$") {
			LOCAL index2 IS launchName:FIND(" ").
			SET callsign TO launchName:SUBSTRING(index2+2, len-index2-3).
			SET shipClass TO launchName:SUBSTRING(0,index2-1).
			SET missionTag TO launchName:SUBSTRING(0,index).
		}
		SET SHIP:NAME TO callsign.

		Write("/etc/callsign",callsign).
		Write("/etc/class",shipClass).
		Write("/etc/mission",missionTag).
	}

	IF NOT HasKSCConnection() KnuPanic("No connection to KSC").
	import("core/update").
	purge("core/update").
	export(Lex("version","1.1.1")).
}