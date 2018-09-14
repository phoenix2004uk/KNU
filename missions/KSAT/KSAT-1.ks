Require(List("pioneer/ascent")).

FUNCTION WarpToKSC {
	SET WARP TO 4.
	WAIT UNTIL NOT HasKSCConnection(). WAIT 5. WAIT UNTIL HasKSCConnection() AND HOMECONNECTION:DESTINATION="HOME".
	SET WARP TO 0. WAIT UNTIL KUNIVERSE:TIMEWARP:ISSETTLED.
}
FUNCTION UIData { PARAMETER x,y,w,s,u IS "". PRINT (s+u):PADRIGHT(w) AT (x,y).}
FUNCTION MainUI {
	PARAMETER y, pitchTarget IS 0.
	LOCAL x IS 10. LOCAL w IS 15.
	UIData(x,y,w,STAGE:NUMBER).
	UIData(x,y+1,w,ROUND(STAGE:LIQUIDFUEL,1),"u").
	UIData(x,y+2,w,ROUND(ALTITUDE,1),"m").
	UIData(x,y+3,w,ROUND(pitchTarget,1),"°").
	UIData(x,y+4,w,ROUND(ALT:APOAPSIS,1),"m").
	UIData(x,y+5,w,ROUND(ALT:PERIAPSIS,1),"m").
	UIData(x,y+6,w,ROUND(SHIP:OBT:INCLINATION,4),"°").
	UIData(x,y+7,w,ROUND(SHIP:OBT:ECCENTRICITY,4)).
	UIData(x,y+8,w,ROUND(SHIP:OBT:SEMIMAJORAXIS,2),"m").
	UIData(x,y+9,w,ROUND(SHIP:OBT:PERIOD,2),"s").
	UIData(x,y+10,w,ROUND(SHIP:LATITUDE,6),"°").
	UIData(x,y+11,w,ROUND(SHIP:LONGITUDE,6),"°").
}
LOCAL UpdateUI IS MainUI@:bind(8).

CLEARSCREEN.

LOCAL lastAscentStage IS 1.
LOCAL launchHeading IS 90.

LOCAL PTarget IS BODY:ROTATIONPERIOD / 6.
LOCAL orbitParameters IS Lexicon(
	"Ap", List(750000,-1),
	"inc", List(0,0),
	"sma", List(((BODY:MU*PTarget^2)^(1/3)) / (2*CONSTANT:PI)^(2/3),-4)
).
LOCAL parkingOrbit IS Lexicon(
	"Ap", 100000,
	"Pe", 80000
).
GLOBAL OrientShip IS { LOCK STEERING TO PROGRADE+R(0,0,0). }.

PRINT "╔═╡ Target Orbit ╞═══════════════════════════════╗".
PRINT "║ a{t}:"+"║":PADLEFT(43).
PRINT "║ i{t}:"+"║":PADLEFT(43).
PRINT "║ Ap{t}:"+"║":PADLEFT(42).
PRINT "╟─┤ Parking Orbit ├──────────────────────────────╢".
PRINT "║ Ap{p}:"+"║":PADLEFT(42).
PRINT "║ Pe{p}:"+"║":PADLEFT(42).
PRINT "╟─┤ Telemetry ├──────────────────────────────────╢".
PRINT "║ Stage:"+"║":PADLEFT(42).
PRINT "║ Fuel:"+"║":PADLEFT(43).
PRINT "║ ALT:"+"║":PADLEFT(44).
PRINT "║ θ:"+"║":PADLEFT(46).
PRINT "║ Ap:"+"║":PADLEFT(45).
PRINT "║ Pe:"+"║":PADLEFT(45).
PRINT "║ i:"+"║":PADLEFT(46).
PRINT "║ ε:"+"║":PADLEFT(46).
PRINT "║ a:"+"║":PADLEFT(46).
PRINT "║ T:"+"║":PADLEFT(46).
PRINT "║ ϕ:"+"║":PADLEFT(46).
PRINT "║ λ:"+"║":PADLEFT(46).
PRINT "╚════════════════════════════════════════════════╝".

UIData(10,1,15,ROUND(orbitParameters["sma"][0],4) + "m [error:"+(10^orbitParameters["sma"][1])+"%]").
UIData(10,2,15,ROUND(orbitParameters["inc"][0],4) + "° [error:"+(10^orbitParameters["inc"][1])+"%]").
UIData(10,3,15,ROUND(orbitParameters["Ap"][0],4) + "m [error:"+(10^orbitParameters["Ap"][1])+"%]").
UIData(10,5,15,ROUND(parkingOrbit["Ap"],2),"m").
UIData(10,6,15,ROUND(parkingOrbit["Pe"],2),"m").

PreFlight().
Launch(launchHeading, lastAscentStage, parkingOrbit["Ap"], UpdateUI).
DeployFairing("fairingSize1").
OrbitInsertion(lastAscentStage, 15, UpdateUI).
NotifyInfo("Discarding ascent stage").
StageTo(lastAscentStage-1).
FinalizeInsertion(parkingOrbit["Pe"], UpdateUI).

PANELS ON.
LOCAL rt1 IS SHIP:PartsNamed("HighGainAntenna5")[0].
LOCAL dish1 IS rt1:GetModule("ModuleRTAntenna").
dish1:DoEvent("activate").
dish1:SetField("target", "active-vessel").
LOCAL rt2 IS SHIP:PartsNamed("longAntenna")[0].
LOCAL antenna1 IS rt2:GetModule("ModuleRTAntenna").
antenna1:DoEvent("activate").
LOCAL rt3 IS SHIP:PartsNamed("RTShortAntenna1")[0].
LOCAL antenna2 IS rt3:GetModule("ModuleRTAntenna").
antenna2:DoEvent("deactivate").
WAIT 5.

WarpToKSC().
DELETEPATH("1:/pioneer"). Require(List("pioneer/maneuver")).

FOR exp IN List(0,-1,-2,-3,-4,-5) {
	LOCAL acc IS 10^exp.
	LOCAL pct IS acc/100.
	LOCAL tMAX IS MAX(0.001,MIN(1,acc)).
	LOCAL cor IS Lexicon().
	FOR prm IN orbitParameters:KEYS {
		LOCAL tvalue IS orbitParameters[prm][0].
		LOCAL tmin IS tvalue*(1-pct).
		LOCAL tmax IS tvalue*(1+pct).
		IF prm="inc" {
			SET tmin TO tvalue.
			SET tmax TO 180*(1+pct).
		}
		IF orbitParameters[prm][1] <= exp SET cor[prm] TO List(tmin,tmax).
	}
	IF cor:LENGTH=0 BREAk.
	PerformCorrections(cor,tMAX,1,UpdateUI,OrientShip).
}

OrientShip().
WarpToKSC().
DELETEPATH("1:/pioneer").
WAIT 120.