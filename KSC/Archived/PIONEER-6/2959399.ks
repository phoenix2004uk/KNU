FOR lib IN List("pioneer","science") {
	IF NOT EXISTS("1:/"+lib+".ks") COPYPATH("0:/libs/"+lib+".ks","1:/"+lib+".ks").
	IF NOT EXISTS("1:/"+lib+".ks") {
		NotifyError("Download Failed: /libs/"+lib+".ks").
		NotifyInfo("Rebooting System in 5 seconds").
		WAIT 5.
		REBOOT.
	}
}
RUNPATH("1:/pioneer.ks").
RUNPATH("1:/science.ks").

//LOCAL DeOrbitTime IS ETA:APOAPSIS + (13*60+44).
LOCAL DeOrbitTime IS 2961839.57 - TIME:SECONDS.
LOCAL TargetPeA IS 26700.

CLEARSCREEN.

//RaiseApoapsis?
DeOrbit(TargetPeA, DeOrbitTime, 0, {
	PARAMETER timeRemaining.
	PRINT "T-" + ROUND(timeRemaining, 1) + "s      " AT(0,1).
}).
PerformReEntry(0, {
	PRINT "D-" + ROUND(ALT:RADAR, 1) + "m      " AT(0,1).
}).

SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric"):DoAction("Toggle", True).
NotifyInfo("Do Some Science!").
DoScience(List("sensorThermometer","sensorBarometer","sensorAccelerometer","science.module"), FALSE).
DMScience(List("dmmagBoom"), FALSE).