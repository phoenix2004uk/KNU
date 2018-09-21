Require(List("pioneer/ascent")).
FUNCTION UILn { PARAMETER t,p IS TERMINAL:WIDTH. IF t:TYPENAME="List" FOR v IN t UILn(v,p). ELSE PRINT "| "+t+":"+("|":PADLEFT(p-t:LENGTH-3)).}
FUNCTION UIVal { PARAMETER x,y,w,s,u IS "". PRINT (s+u):PADRIGHT(w) AT(x,y).}
FUNCTION UIMain {
	PARAMETER y,pitchTarget IS 0.
	LOCAL x IS 10. LOCAL w IS 15.
	UIVal(x,y,w,STAGE:NUMBER).
	UIVal(x,y+1,w,ROUND(STAGE:LIQUIDFUEL,1),"u").
	UIVal(x,y+2,w,ROUND(ALTITUDE,1),"m").
	UIVal(x,y+3,w,ROUND(pitchTarget,1),"°").
	UIVal(x,y+4,w,ROUND(ALT:APOAPSIS,1),"m").
	UIVal(x,y+5,w,ROUND(ALT:PERIAPSIS,1),"m").
	UIVal(x,y+6,w,ROUND(SHIP:OBT:INCLINATION,4),"°").
	UIVal(x,y+7,w,ROUND(SHIP:OBT:ECCENTRICITY,4)).
	UIVal(x,y+8,w,ROUND(SHIP:OBT:SEMIMAJORAXIS,2),"m").
	UIVal(x,y+9,w,ROUND(SHIP:OBT:PERIOD,2),"s").
	UIVal(x,y+10,w,ROUND(SHIP:LATITUDE,6),"°").
	UIVal(x,y+11,w,ROUND(SHIP:LONGITUDE,6),"°").
}
LOCAL DoUI IS UIMain@:bind(8).
LOCAL Notify IS {PARAMETER m,d IS 5. NotifyInfo(m,d,TRUE).}.

CLEARSCREEN.

LOCAL lastAscentStage IS 1.
LOCAL launchHeading IS 90.
LOCAL oFinal IS Lexicon(
	"Ap",List(100000,0),
	"inc",List(0,0),
	"ecc",List(0,0)
).
LOCAL oPark IS Lexicon(
	"Ap",100000,
	"Pe",90000
).
GLOBAL OrientShip IS { LOCK STEERING TO NORTH. WAIT 5.}.

PRINT "/=[ Target Orbit ]===============================\".
UILn(List("Ap{t}","i{t}","ε{t}")).
PRINT "|-[ Parking Orbit ]------------------------------|".
UILn(List("Ap{p}","Pe{p}")).
PRINT "|-[ Telemetry ]----------------------------------|".
UILn(List("Stage","Fuel","ALT","θ","Ap","Pe","i","ε","a","T","ϕ","λ")).
PRINT " ".

UIVal(10,1,15,ROUND(oFinal["Ap"][0],4)+"m [error:"+(10^oFinal["Ap"][1])+"%]").
UIVal(10,2,15,ROUND(oFinal["inc"][0],4)+"° [error:"+(10^oFinal["inc"][1])+"%]").
UIVal(10,3,15,ROUND(oFinal["ecc"][0],4)+" [error:"+(10^oFinal["ecc"][1])+"%]").
UIVal(10,5,15,ROUND(oPark["Ap"],2),"m").
UIVal(10,6,15,ROUND(oPark["Pe"],2),"m").

PreFlight().
Launch(launchHeading, lastAscentStage, oPark["Ap"], DoUI, FALSE).
DeployFairing("KW1mFairingPFE").
OrbitInsertion(lastAscentStage, 15, DoUI).
NotifyInfo("Discarding ascent stage").
StageTo(lastAscentStage-1).
FinalizeInsertion(oPark["Pe"], DoUI).

PANELS ON.
LIGHTS ON.
LOCAL rt IS "ModuleRTAntenna".
DoPartEvent("longAntenna",rt,"activate").
WAIT 5.

DELETEPATH("1:/pioneer"). Require(List("pioneer/maneuver")).
FOR exp IN List(0,-1,-2,-3,-4,-5) {
	LOCAL acc IS 10^exp.
	LOCAL pct IS acc/100.
	LOCAL tMAX IS MAX(0.001,MIN(1,acc)).
	LOCAL cor IS Lexicon().
	FOR prm IN oFinal:KEYS {
		LOCAL tvalue IS oFinal[prm][0].
		LOCAL tmin IS tvalue*(1-pct).
		LOCAL tmax IS tvalue*(1+pct).
		IF prm="inc" {
			SET tmin TO MAX(0,tvalue-180*pct).
			SET tmax TO MIN(90,tvalue+180*pct).
		}
		ELSE IF prm="ecc" {
			SET tmin TO MAX(0,tvalue-pct).
			SET tmax TO MIN(1,tvalue+pct).
		}
		IF oFinal[prm][1] <= exp SET cor[prm] TO List(tmin,tmax).
	}
	IF cor:LENGTH=0 BREAk.
	PerformCorrections(cor,tMAX,1,DoUI,OrientShip).
}

OrientShip().
DELETEPATH("1:/pioneer"). Require(List("ranger/transfer")).
{
	Notify("Target: Mun").
	SET TARGET TO Mun.
	LOCAL phase_transfer IS GetCircTransferPhaseAngle().
	LOCK phase_current TO GetRelPhaseAngle(TARGET).
	Notify("Waiting for phase angle: " + phase_transfer).
	SET WARP TO 4.
	WAIT UNTIL IsWithin(phase_current, phase_transfer, 10).
	SET WARP TO 0.
	WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL IsWithin(phase_current, phase_transfer, 0.1).
	Notify("Begining Transfer").
	DoAccurateBurn(1000,{
		PARAMETER deviation.
		RETURN IsWithinTransferBody(TARGET,40000,15000,-1)
			OR IsWithin(SHIP:OBT:APOAPSIS, TARGET:OBT:APOAPSIS+1e6, deviation, 1).
	},4).
}

OrientShip().
DELETEPATH("1:/ranger").
WAIT UNTIL HasKSCConnection().
Require(List("ranger/science")).
IF SHIP:OBT:HASNEXTPATCH {
	WarpFor(SHIP:OBT:NEXTPATCHETA - 30).
	DoPartEvent("longAntenna",rt,"deactivate").
	DoPartEvent("HighGainAntenna5",rt,"activate").
	SetPartField("HighGainAntenna5",rt,"target","KSAT - LKO 'Eos'").
	WAIT UNTIL SHIP:OBT:BODY=Mun. WAIT 30.
	SET SCIENCE_EC_WAIT TO 0.65.
	DoScience(List("sensorThermometer","sensorBarometer"),TRUE).
	DMScience(List("dmmagBoom","rpwsAnt"),TRUE).
	WAIT 600.
	WarpFor(ETA:PERIAPSIS-30).
	DoScience(List("sensorThermometer","sensorBarometer"),FALSE).
	DMScience(List("dmmagBoom","rpwsAnt"),FALSE).
	WAIT UNTIL HasKSCConnection().
	FOR p IN List("sensorThermometer","sensorBarometer")
		SHIP:PartsNamed(p)[0]:GetModule("ModuleScienceExperiment"):TRANSMIT.
	FOR p IN List("dmmagBoom","rpwsAnt")
		SHIP:PartsNamed(p)[0]:GetModule("DMModuleScienceAnimate"):TRANSMIT.
	LOCK STEERING TO RETROGRADE.
	LOCK THROTTLE TO 1.
	WAIT UNTIl ALT:PERIAPSIS < 0.
	LOCK THROTTLE TO 0.
}
ELSE Notify("We missed!").