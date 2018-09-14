Require(List("pioneer/ascent")).
FUNCTION WarpToKSC {SET WARP TO 4. WAIT UNTIL NOT HasKSCConnection(). WAIT 5. WAIT UNTIL HasKSCConnection() AND HOMECONNECTION:DESTINATION="HOME". SET WARP TO 0. WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.}
FUNCTION UILn { PARAMETER t,p IS TERMINAL:WIDTH. IF t:TYPENAME="List" FOR v IN t UILn(v,p). ELSE PRINT "║ "+t+":"+("║":PADLEFT(p-t:LENGTH-3)).}
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

CLEARSCREEN.
{
	LIST TARGETS IN currentVessels.
	LOCAL n IS -1.
	LOCAL names IS List("'Eos'","'Hera'","'Hesperides'","'Nyx'").
	LOCAL tags IS List("A","B","C","D").
	FOR v IN currentVessels IF v:NAME:StartsWith("KSAT") SET n TO n + 1.
	SET CORE:PART:TAG TO "KSAT-2"+tags[n].
	SET SHIP:NAME TO "KSAT - LKO "+names[n].
}

LOCAL lastAscentStage IS 1.
LOCAL launchHeading IS 90.
LOCAL oFinal IS Lexicon(
	"Ap",List(250000,-2),
	"inc",List(0,0),
	"ecc",List(0,-1)
).
LOCAL oPark IS Lexicon(
	"Ap",100000,
	"Pe",80000
).
GLOBAL OrientShip IS { LOCK STEERING TO PROGRADE+R(0,0,0). }.

PRINT "╔═╡ Target Orbit ╞═══════════════════════════════╗".
UILn(List("Ap{t}", "i{t}", "ε{t}")).
PRINT "╟─┤ Parking Orbit ├──────────────────────────────╢".
UILn(List("Ap{p}", "Pe{p}")).
PRINT "╟─┤ Telemetry ├──────────────────────────────────╢".
UILn(List("Stage", "Fuel", "ALT", "θ", "Ap", "Pe", "i", "ε", "a", "T", "ϕ", "λ")).
PRINT "╚════════════════════════════════════════════════╝".

UIVal(10,1,15,ROUND(oFinal["Ap"][0],4) + "m [error:"+(10^oFinal["Ap"][1])+"%]").
UIVal(10,2,15,ROUND(oFinal["inc"][0],4) + "° [error:"+(10^oFinal["inc"][1])+"%]").
UIVal(10,3,15,ROUND(oFinal["ecc"][0],4) + " [error:"+(10^oFinal["ecc"][1])+"%]").
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
{
	SHIP:PartsNamed("longAntenna")[0]:GetModule("ModuleRTAntenna"):DoEvent("activate").
	SHIP:PartsNamed("RTShortAntenna1")[0]:GetModule("ModuleRTAntenna"):DoEvent("deactivate").
	LOCAL rtTargets IS List(Mun,Minmus,"active-vessel").
	LOCAL rtList IS SHIP:PartsNamed("HighGainAntenna5").
	FROM {LOCAL x IS 0.} UNTIL x=MIN(rtList:LENGTH,rtTargets:LENGTH) STEP {SET x TO x+1.} DO {
		LOCAL dish IS rtList[x]:GetModule("ModuleRTAntenna").
		dish:DoEvent("activate").
		dish:SetField("target", rtTargets[x]).
	}
}
WAIT 5.

WarpToKSC().
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
WarpToKSC().
DELETEPATH("1:/pioneer").
WAIT 30.