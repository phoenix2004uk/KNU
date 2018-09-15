{
	GLOBAL KnuPanic IS{PARAMETER A,B.HUDTEXT("KNUPANIC!",5,2,30,RED,TRUE).PRINT ER_LAST+"@"+B+":"+A. WAIT 60.REBOOT.}.
	GLOBAL HasKSCConnection IS{IF ADDONS:AVAILABLE("RT") RETURN ADDONS:RT:HasKSCConnection(SHIP).ELSE RETURN HOMECONNECTION:ISCONNECTED.}.

	LOCAL ER_CON IS -4.
	LOCAL ER_404 IS -3.
	LOCAL ER_SIZE IS -2.
	LOCAL ER_EXIST IS -1.

	LOCAL ER_LAST IS 0.
	GLOBAL Error IS {
		PARAMETER errno, value IS FALSE.
		SET ER_LAST TO errno.
		RETURN value.
	}.
	GLOBAL Success IS {
		PARAMETER value IS TRUE.
		SET ER_LAST TO 0.
		RETURN value.
	}.
	GLOBAL LastError IS {
		LOCAL errno IS ER_LAST.
		SET ER_LAST TO 0.
		RETURN errno.
	}.
	GLOBAL JF IS {
		PARAMETER value.
		RETURN value:ISTYPE("Boolean") AND NOT value.
	}.

	GLOBAL GetKSCFile IS {
		PARAMETER srcFilepath, dstFilepath IS srcFilepath, overwrite IS 0.
		IF (NOT overwrite) AND EXISTS(dstFilepath) RETURN Error(ER_EXIST).
		IF NOT HasKSCConnection() RETURN Error(ER_CON).
		LOCAL file IS VOLUME(0):OPEN(srcFilepath).
		IF JF(file) RETURN Error(ER_404).
		IF VOLUME(1):FREESPACE<file:SIZE RETURN Error(ER_SIZE).
		COPYPATH("0:"+srcFilepath,"1:"+dstFilepath).
		RETURN Success().
	}.

	GLOBAL GetLatestVersion IS {
		PARAMETER name, path, minOnly IS 0, vol IS 0.
		LOCAL realPath IS path(path+"/"+name).
		SET name TO realPath:NAME.
		SET path TO "/" + realPath:PARENT:SEGMENTS:JOIN("/").
		LOCAL itFiles IS VOLUME(vol):OPEN(path):LIST:VALUES:REVERSEITERATOR.
		UNTIL NOT itFiles:NEXT {
			IF itFiles:VALUE:NAME:MATCHESPATTERN("^"+name+"(-v[0-9]+(\.[0-9]+){0,3}){0,1}(-min){"+minOnly+",1}\.ks$") {
				RETURN Success(path+"/"+itFiles:VALUE).
			}
		}
		RETURN Error(ER_404).
	}.
	IF NOT EXISTS("/boot/knuldr") {
		IF NOT GetKSCFile(GetLatestVersion("knuldr","/knulib"), "/boot/knuldr", SHIP:STATUS="PRELAUNCH") {
			IF ER_LAST <> ER_EXIST KnuPanic(scriptpath(),57).	// SET KNUPANIC LINE NUMBER
		}
	}
}
RUNPATH("/boot/knuldr").