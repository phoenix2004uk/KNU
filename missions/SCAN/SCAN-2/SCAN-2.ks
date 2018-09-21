CLEARSCREEN.
LOCAL lastAscentStage IS 1.
LOCAL Notify IS {PARAMETER m,d IS 5. NotifyInfo(m,d,TRUE).}.
GLOBAL OrientShip IS { LOCK STEERING TO NORTH. WAIT 5.}.

Require(List("pioneer/ascent")).
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
PreFlight().
Launch(launchHeading, lastAscentStage, oPark["Ap"]).
DeployFairing("KW1mFairingPFE").
OrbitInsertion(lastAscentStage, 15).
Notify("Discarding ascent stage").
StageTo(lastAscentStage-1).
FinalizeInsertion(oPark["Pe"]).

PANELS ON.
LIGHTS ON.
LOCAL rt IS "ModuleRTAntenna".
DoPartEvent("longAntenna",rt,"activate").
WAIT 5.

DELETEPATH("1:/pioneer").
Require(List("pioneer/maneuver")).
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
	PerformCorrections(cor,tMAX,1,FALSE,OrientShip).
}
OrientShip().

DELETEPATH("1:/pioneer").
Require(List("ranger/transfer")).
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
		RETURN IsWithinTransferBody(TARGET,100000,50000,-1)
			OR IsWithin(SHIP:OBT:APOAPSIS, TARGET:OBT:APOAPSIS+1e6, deviation, 1).
	},4).
}
IF SHIP:OBT:HASNEXTPATCH Notify("Transfer Success").
ELSE Notify("We missed!").
Notify("Waiting further correction maneuvers").
OrientShip().