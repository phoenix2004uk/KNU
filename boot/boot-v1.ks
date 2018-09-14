{
GLOBAL HUD_TOPLFT IS 1.
GLOBAL HUD_TOPMID IS 2.
GLOBAL HUD_TOPRGT IS 3.
GLOBAL HUD_MID IS 4.
GLOBAL HUD_STATUS IS 5. // top middle with set font size
GLOBAL FUNCTION NotifyError {
	PARAMETER message.
	PARAMETER delay IS 5.
	PARAMETER doEcho IS TRUE.
	HUDTEXT(message, 5, HUD_TOPMID, 30, RED, doEcho).
}
GLOBAL FUNCTION NotifyInfo {
	PARAMETER message.
	PARAMETER delay IS 5.
	PARAMETER doEcho IS TRUE.
	HUDTEXT(message, 5, HUD_MID, 24, CYAN, doEcho).
}
GLOBAL FUNCTION HasKSCConnection {
	IF ADDONS:AVAILABLE("RT") RETURN ADDONS:RT:HasKSCConnection(SHIP).
	ELSE RETURN HOMECONNECTION:ISCONNECTED.
}
FUNCTION GetCoreTag {
	IF CORE:TAG:LENGTH = 0 {
		SET CORE:PART:TAG TO SHIP:NAME.
	}
	RETURN CORE:TAG.
}
FUNCTION MissionGroup {
	LOCAL name IS GetCoreTag().
	IF name:MatchesPattern("-[0-9]+$") SET name TO name:SubString(0, name:FindLast("-")).
	IF name:MatchesPattern("^[A-Z]+ - ") {
		LOCAL i IS name:Find("-")+2.
		SET name TO name:SubString(i, name:LENGTH-i).
	}
	RETURN name.
}
FUNCTION MissionFolder {
	LOCAL group IS MissionGroup().
	IF group:LENGTH > 0 RETURN group + "/".
	ELSE RETURN group.
}
FUNCTION MissionFilePath {
	RETURN MissionFolder():TOUPPER + GetCoreTag() + ".ks".
}
IF SHIP:STATUS = "PRELAUNCH" {
	IF NOT HasKSCConnection() {
		NotifyError("No Connection to KSC!").
		PRINT "Rebooting in 10 seconds...".
		WAIT 10.
		REBOOT.
	}
	IF EXISTS("0:/missions/" + MissionFilePath()) {
		COPYPATH("0:/missions/" + MissionFilePath(), "1:/mission.ks").
	}
	ELSE IF EXISTS("0:/missions/" + MissionGroup() + ".ks") {
		COPYPATH("0:/missions/" + MissionGroup() + ".ks", "1:/mission.ks").
	}
	IF EXISTS("1:/mission.ks") {
		NotifyInfo("Mission Start in T-10seconds...").
		WAIT 10.
		CLEARSCREEN.
		RUNPATH("1:/mission.ks").
		DELETEPATH("1:/mission.ks").
	}
	ELSE NotifyError("Mission Download Failed!").
}
UNTIL 0 {
	IF HasKSCConnection() {
		IF EXISTS("0:/KSC/" + GetCoreTag() + ".ks") {
			NotifyInfo("Receiving New Instructions from KSC...").
			SET WARP TO 0.
			WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.
			COPYPATH("0:/KSC/" + GetCoreTag() + ".ks", "1:/update.ks").
			WAIT 5.
			IF EXISTS("1:/update.ks") {
				//DELETEPATH("0:/KSC/" + GetCoreTag() + ".ks").
				MOVEPATH("0:/KSC/" + GetCoreTag() + ".ks", "0:/KSC/Archived/" + GetCoreTag() + ".ks." + ROUND(TIME:SECONDS) + ".purged").
				RUNPATH("1:/update.ks").
				DELETEPATH("1:/update.ks").
			}
			ELSE NotifyError("Download Failed!").
		}
	}
	WAIT 10.
}
}