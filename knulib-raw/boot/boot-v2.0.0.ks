//{IF EXISTS("1:/boot/bootstrap.new") {LOCAL n IS scriptpath().DELETEPATH(n).MOVEPATH("1:/boot/bootstrap.new",n).REBOOT.}IF EXISTS("1:/boot/knuldr.new") {DELETEPATH("1:/boot/knuldr").MOVEPATH("1:/boot/knuldr.new","1:/boot/knuldr").REBOOT.}}
FUNCTION FnError {PARAMETER m,n IS 0.RETURN Lexicon("error",m,"errno",-ABS(n)).}
FUNCTION FnSuccess {PARAMETER m IS 1,n IS 1.RETURN Lexicon("value",m,"errno",ABS(n)).}
FUNCTION IsError {PARAMETER x.RETURN x:IsType("Lexicon") AND x["errno"]<1.}
FUNCTION IsSuccess {PARAMETER x.RETURN x:IsType("Lexicon") AND x["errno"]>0.}
FUNCTION OnError {PARAMETER x,f.IF IsError(x)f(x).RETURN x.}
FUNCTION OnSuccess {PARAMETER x,f.IF IsSuccess(x)f(x).RETURN x.}
FUNCTION OnResult {PARAMETER x,t,f.OnError(x,f).OnSuccess(x,t).RETURN x.}
FUNCTION KnuPanic {PARAMETER m.HUDTEXT("PANIC! "+m,5,2,30,RED,TRUE).WAIT 60.REBOOT.}
FUNCTION HasKSCConnection {IF ADDONS:AVAILABLE("RT") RETURN ADDONS:RT:HasKSCConnection(SHIP).ELSE RETURN HOMECONNECTION:ISCONNECTED AND HOMECONNECTION:DESTINATION="HOME".}
OnResult(({
	GLOBAL ERR_DL_CON IS -4.
	GLOBAL ERR_DL_404 IS -3.
	GLOBAL ERR_DL_SIZE IS -2.
	GLOBAL ERR_DL_EXIST IS -1.
	LOCAL transfer_delay IS FnSuccess.
	IF ADDONS:AVAILABLE("RT") SET transfer_delay TO {
		PARAMETER file_size.
		LOCAL packet_interval IS 0.3.
		LOCAL packet_size IS 2048. // bits
		LOCAL transfer_time IS 8 * packet_interval * file_size / packet_size + ADDONS:RT:KSCDELAY(SHIP).
		LOCAL start_time IS TIME:SECONDS.
		UNTIL TIME:SECONDS-start_time>transfer_time {
			IF NOT HasKSCConnection() RETURN FnError("Transfer interupted",ERR_DL_CON).
			WAIT 0.1.
		}
		RETURN FnSuccess().
	}.
	GLOBAL GetKSCFile IS {
		PARAMETER srcFilepath,dstFilepath IS srcFilepath,overwrite IS FALSE.
		IF (NOT overwrite) AND EXISTS(dstFilepath) RETURN FnError("Destination file exists: "+dstFilepath,ERR_DL_EXIST).	// ADDED LINE
		IF NOT HasKSCConnection() RETURN FnError("No connection to KSC",ERR_DL_CON).
		LOCAL file IS VOLUME(0):OPEN(srcFilepath).
		IF file:ISTYPE("Boolean") RETURN FnError("File not found: "+srcFilepath,ERR_DL_404).
		LOCAL free IS VOLUME(1):FREESPACE.
		LOCAL size IS file:SIZE.
		IF free<size RETURN FnError("Insufficient free space: "+srcFilepath+" ("+size+") > 1:("+free+")",ERR_DL_SIZE).
		LOCAL res IS transfer_delay(size).
		IF IsError(res) RETURN res.
		COPYPATH("0:"+srcFilepath,"1:"+dstFilepath).
		RETURN FnSuccess(dstFilepath).
	}.
	GLOBAL UpdateBootstrap IS {
		KnuPanic("Not implemented").
		// download update to /boot/bootstrap.new
		// reboot
	}.
	GLOBAL UpdateLoader IS {
		KnuPanic("Not implemented").
		// download update to /boot/knuldr.new
		// reboot
	}.
	GLOBAL GetLatestVersion IS {
		PARAMETER name, path, minOnly IS FALSE, vol IS 0.
		LOCAL itFiles IS VOLUME(vol):OPEN(path):LIST:VALUES:REVERSEITERATOR.
		LOCAL pattern IS "^"+name+"(-v[0-9]+(\.[0-9]+){0,3}){0,1}".
		IF minOnly SET pattern TO pattern + "\.min".
		UNTIL NOT itFiles:NEXT {
			IF itFiles:VALUE:NAME:MATCHESPATTERN(pattern+"\.ks$") {
				RETURN FnSuccess(itFiles:VALUE).
			}
		}
		RETURN FnError(name+" not found in "+path,ERR_DL_404).
	}.
	IF NOT EXISTS("/boot/knuldr") {
		IF SHIP:STATUS <> "PRELAUNCH" {
			PRINT "WARNING! KNULDR is missing".
			PRINT "Press Y to REBOOT, or N to wait for a KSC connection to download a new loader".
			UNTIL FALSE {
				LOCAL char IS TERMINAL:INPUT:GETCHAR().
				IF char="y" REBOOT.
				IF char="n" BREAK.
			}
			UNTIL HasKSCConnection()WAIT 60.
		}
		ELSE IF NOT HasKSCConnection() RETURN FnError("No connection to KSC").

		LOCAL res IS GetLatestVersion("knuldr","knulib").
		IF IsError(res) RETURN FnError("KNULDR not found at KSC").
		SET res TO GetKSCFile("knulib/"+res["value"],"boot/knuldr").
		IF IsSuccess(res) REBOOT.
		RETURN res.
	}
	RETURN FnSuccess().
}):call,{PARAMETER x.RUNPATH("/boot/knuldr").},{PARAMETER x.KnuPanic(x["error"]).}).