{
GLOBAL HUD_TOPLFT IS 1.
GLOBAL HUD_TOPMID IS 2.
GLOBAL HUD_TOPRGT IS 3.
GLOBAL HUD_MID IS 4.
GLOBAL HUD_STATUS IS 5.
GLOBAL FUNCTION NotifyError {
	PARAMETER msg, dly IS 5, doEcho IS TRUE.
	HUDTEXT("Error: "+msg, dly, HUD_TOPMID, 30, RED, doEcho).
}
GLOBAL FUNCTION NotifyInfo {
	PARAMETER msg, dly IS 5, doEcho IS TRUE.
	HUDTEXT(msg, dly, HUD_MID, 24, CYAN, doEcho).
}
GLOBAL FUNCTION HasKSCConnection {
	IF ADDONS:AVAILABLE("RT") RETURN ADDONS:RT:HasKSCConnection(SHIP).
	ELSE RETURN HOMECONNECTION:ISCONNECTED.
}
FUNCTION CoreTag {
	IF CORE:TAG:LENGTH = 0 {
		LOCAL name IS SHIP:NAME.
		IF name:MatchesPattern("^[A-Z]+ - ") {
			LOCAL i IS name:Find("-")+2.
			SET name TO name:SubString(i, name:LENGTH-i).
		}
		SET CORE:PART:TAG TO name.
	}
	RETURN CORE:TAG.
}
FUNCTION GroupTag {
	LOCAL name IS CoreTag().
	IF name:MatchesPattern("-[0-9]+[a-zA-Z]{0,1}$") SET name TO name:SubString(0, name:FindLast("-")).
	RETURN name.
}
FUNCTION VesselScript {
	RETURN "0:/missions/" + GroupTag() + "/" + CoreTag() + ".ks".
}
FUNCTION GroupScript {
	RETURN "0:/missions/" + GroupTag() + ".ks".
}
FUNCTION UpdateScript {
	RETURN "0:/KSC/" + CoreTag() + ".ks".
}
FUNCTION HasUpdates {
	RETURN EXISTS(UpdateScript()).
}
FUNCTION RunScript {
	PARAMETER src,tgt.
	COPYPATH(src, tgt).
	IF EXISTS(tgt) {
		RUNPATH(tgt).
		DELETEPATH(tgt).
		RETURN TRUE.
	}
	NotifyError("Download Failed").
	RETURN FALSE.
}
FUNCTION RunUpdates {
	LOCAL src IS UpdateScript().
	NotifyInfo("Receiving New Instructions from KSC..."). WAIT 5.
	IF RunScript(src,"1:/update.ks") {
		MOVEPATH(src,"0:/KSC/Archived/" + CoreTag() + "/" + ROUND(TIME:SECONDS) + ".ks").
	}
}
FUNCTION RunMission {
	PARAMETER src.
	NotifyInfo("Mission Start in T-10seconds..."). WAIT 10.
	RunScript(src,"1:/mission.ks").
}
CLEARSCREEN.
IF SHIP:STATUS = "PRELAUNCH" {
	IF NOT HasKSCConnection() {
		NotifyError("No Connection to KSC!").
		PRINT "Rebooting in 10 seconds...". WAIT 10.
		REBOOT.
	}
	IF HasUpdates() RunUpdates().
	IF EXISTS(VesselScript()) {
		RunMission(VesselScript()).
	}
	ELSE IF EXISTS(GroupScript()) {
		RunMission(GroupScript()).
	}
}
UNTIL 0 {
	IF HasKSCConnection() IF HasUpdates() {
		SET WARP TO 0.
		WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.
		RunUpdates().
	}
	WAIT 10.
}
}