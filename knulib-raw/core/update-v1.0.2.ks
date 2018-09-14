{
	DELETEPATH("1:/mission/").

	LOCAL callsign IS GetCallsign().
	LOCAL shipClass IS GetShipClass().
	LOCAL missionTag IS GetMissionTag().

	LOCAL updatePaths IS List(
		callsign+".ks",
		callsign+"/update.ks",
		missionTag+"/"+callsign+".ks",
		missionTag+"/"+callsign+"/update.ks"
	).
	FOR updateFile IN updatePaths {
		IF EXISTS("0:/KSC/" + updateFile) {
			LOCAL filepath IS PATH("0:/KSC/" + updateFile).
			LOCAL parent IS ""+filepath:PARENT.
			IF NOT download(filepath:NAME,parent:SUBSTRING(2,parent:LENGTH-2)) KnuPanic(filepath:NAME, "download").
			MOVEPATH("1:/home/"+filepath:NAME, "1:/mission/main.ks").
			MOVEPATH("0:/KSC/"+updateFile, "0:/KSC/Archived/"+callsign+"/"+TIME:SECONDS+".ks").
			BREAK.
		}
	}
	export(Lex("version","1.0.2")).
}