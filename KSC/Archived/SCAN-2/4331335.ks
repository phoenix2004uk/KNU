CLEARSCREEN.
Require(List("pioneer/util","ranger/transfer")).
LOCAL Notify IS {PARAMETER m,d IS 5. NotifyInfo(m,d,TRUE).}.
GLOBAL OrientShip IS { LOCK STEERING TO NORTH. WAIT 5.}.

IF SHIP:OBT:HASNEXTPATCH {
	WarpFor(SHIP:OBT:NEXTPATCHETA*3/16).
	LOCAL rt IS "ModuleRTAntenna".
	DoPartEvent("longAntenna",rt,"deactivate").
	DoPartEvent("HighGainAntenna5",rt,"activate").
	SetPartField("HighGainAntenna5",rt,"target","KSAT - LKO 'Eos'").

	LOCK STEERING TO NORMALVEC().
	WAIT 10.
	DoAccurateBurn(1,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:NEXTPATCH:INCLINATION, 45, deviation, 1).
	},4).

	LOCK STEERING TO PROGRADE.
	WAIT 10.
	DoAccurateBurn(5,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:NEXTPATCH:INCLINATION, 85.2, deviation, 1).
	},4).
	OrientShip().

	WarpFor(SHIP:OBT:NEXTPATCHETA - 30).
	WAIT UNTIL SHIP:OBT:BODY=Mun. WAIT 30.

	LOCK STEERING TO NORMALVEC().
	WAIT 10.
	DoAccurateBurn(0.25,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:INCLINATION, 85.2, deviation, 1).
	},4).
	OrientShip().

	WarpFor(ETA:PERIAPSIS-30).
	LOCK STEERING TO RETROGRADE.
	WAIT UNTIL ETA:PERIAPSIS < 15.
	DoAccurateBurn(500,{
		PARAMETER deviation.
		RETURN SHIP:OBT:APOAPSIS>0 AND IsWithin(SHIP:OBT:APOAPSIS, 405283, deviation, -1).
	},4).
	OrientShip().

	WarpFor(ETA:APOAPSIS-30).
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ETA:APOAPSIS < 15.
	DoAccurateBurn(500,{
		PARAMETER deviation.
		RETURN IsWithin(SHIP:OBT:PERIAPSIS, 405108, deviation, 1).
	},4).
	OrientShip().

	LOCAL scanner IS SHIP:PartsNamed("SCANsat.Scanner")[0].
	LOCAL scannerModule IS scanner:GetModule("SCANsat").
	NotifyInfo("Deploying "+scanner:TITLE).
	scannerModule:DoEvent("start scan: radar").
	WAIT 10.
	NotifyInfo("SCANsat Altitude: " + scannerModule:GetField("scansat altitude")).
}
OrientShip().