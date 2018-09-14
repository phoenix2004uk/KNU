{
	DELETEPATH("1:/mission/").
	LOCAL callsign IS GetCallsign().
	LOCAL dirpath IS "/KSC/"+callsign+"/".
	IF EXISTS("0:/"+dirpath) {
		LOCAL dir IS OPEN("0:/"+dirpath).
		IF dir:LIST:LENGTH > 0 {
			LOCAL filename IS dir:LIST:VALUES[0]:NAME.
			IF NOT download(filename, dirpath) KnuPanic(filename, "download").
			MOVEPATH("1:/home/"+filename, "1:/mission/main.ks").
			MOVEPATH("0:"+dirpath+filename, "0:/KSC/Archived/"+callsign+"/"+filename).
		}
	}
	export(Lex("version","1.1.0")).
}