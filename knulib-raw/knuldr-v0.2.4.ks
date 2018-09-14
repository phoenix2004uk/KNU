{
	LOCAL import_stack IS STACK().
	LOCAL imported IS Lex().
	GLOBAL import IS {
		PARAMETER libName.
		IF imported:HASKEY(libName) RETURN imported[libName].
		IF NOT EXISTS("/lib/"+libName) {
			LOCAL libVersion IS GetLatestVersion(libName,"/knulib").
			IF NOT(libVersion AND GetKSCFile(libVersion, "/lib/"+libName)) KnuPanic(libName,"import").
		}
		RUNPATH("/lib/"+libName).
		LOCAL object IS import_stack:POP.
		SET imported[libName] TO object.
		RETURN object.
	}.
	GLOBAL export IS {
		PARAMETER libObject.
		import_stack:PUSH(libObject).
	}.
	GLOBAL purge IS {
		PARAMETER libs.
		using(libs,{
			PARAMETER libName.
			DELETEPATH("/lib/"+libName).
			imported:REMOVE(libName).
		}).
	}.
}
FUNCTION using {
	PARAMETER var, cb.
	IF var:ISTYPE("Enumerable") FOR val IN var cb(val).
	ELSE cb(var).
}

// downloads and overwrites a file into 0:/home (waits for KSC connection unless waitForConnection is FALSE, in which case GetKSCFile can raise an ER_CON error)
// will raise ER_404 if the remote file does not exist, and ER_SIZE if not enough local space
FUNCTION download {
	PARAMETER srcName, srcPath, dstName IS srcName, waitForConnection IS TRUE.
	IF waitForConnection UNTIL HasKSCConnection() WAIT 1.
	RETURN GetKSCFile(srcPath+"/"+srcName, "/home/"+dstName, 1).
}
FUNCTION Read {
	PARAMETER A.
	IF EXISTS(A) RETURN OPEN(A):READALL:STRING.
	RETURN FALSE.
}
FUNCTION Write {
	PARAMETER A,B.
	IF NOT EXISTS(A) CREATE(A).
	OPEN(A):WRITE(B:TOSTRING).
}
FUNCTION GetCallsign {
	RETURN Read("/etc/callsign").
}
FUNCTION GetShipClass {
	RETURN Read("/etc/class").
}
FUNCTION GetMissionTag {
	RETURN Read("/etc/mission").
}
FUNCTION Notify {
	PARAMETER message, doEcho IS FALSE.
	HUDTEXT(message, 5, 4, 20, BLUE, doEcho).
}

IF STATUS = "PRELAUNCH" {
	import("core/init").
	purge("core/init").
}
UNTIL 0 {
	IF EXISTS("1:/mission/main.ks") {
		GLOBAL MissionRunner IS import("mission_runner").
		SET steps TO Lex().
		SET sequence TO 1.
		SET events TO Lex().
		SET active TO 1.
		{
			RUNPATH("1:/mission/main.ks").
		}
		LOCAL main IS MissionRunner["new"]("main",steps,sequence,events,active).
		UNTIL 0 IF main() BREAK.
		DELETEPATH("1:/mission").
		Notify("Checking for new instructions", TRUE).
	}
	WAIT 60.
	IF HasKSCConnection() {
		import("core/update").
		purge("core/update").
		IF EXISTS("1:/mission/main.ks") {
			DELETEPATH("1:/lib").
			REBOOT.
		}
	}
}