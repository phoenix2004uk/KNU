GLOBAL INF IS NotifyInfo@.GLOBAL ERR IS NotifyError@.
FUNCTION NORMALVEC {RETURN VCRS(SHIP:VELOCITY:ORBIT,BODY:POSITION).}
FUNCTION RADIALVEC {RETURN VCRS(SHIP:VELOCITY:ORBIT,NORMALVEC()).}
FUNCTION CheckFlameout {LIST ENGINES IN enList. FOR en IN enList IF en:FLAMEOUT RETURN TRUE. RETURN FALSE.}
FUNCTION SafeStage { PARAMETER sMin IS 0.
	IF STAGE:NUMBER>sMin {
		LOCAL Tp IS THROTTLE.
		LOCK THROTTLE TO 0.
		STAGE. WAIT UNTIL STAGE:READY.
		LOCK THROTTLE TO Tp.
	}
}
FUNCTION StageTo { PARAMETER sTo. UNTIL STAGE:NUMBER=sTo SafeStage().}
FUNCTION AutoStage { PARAMETER sMin. UNTIL NOT CheckFlameout() {SafeStage(sMin).WAIT 0.}}
FUNCTION DeployFairing { PARAMETER pName,eName IS "deploy",mName IS "ModuleProceduralFairing".
	FOR p IN f SHIP:PartsDubbed(pName):GetModule(mName):DoEvent(eName).
}
FUNCTION GetPitchTarget { PARAMETER currAlt IS ALTITUDE,startAlt IS 1000,limitAlt IS 60000,pitchMax IS 90,pitchMin IS 0.
	LOCAL kA IS 85.
	LOCAL kB IS 70000.
	LOCAL kC IS 5.
	IF currAlt<=startAlt RETURN pitchMax.
	IF currAlt>=limitAlt RETURN pitchMin.
	LOCAL P IS kA*(LN(kB)-LN(currAlt))/(LN(kB)-LN(startAlt))+kC.
	RETURN MIN(pitchMax,MAX(pitchMin, P)).
}
FUNCTION PreFlight {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	LOCK THROTTLE TO 0.
	LOCK STEERING TO Heading(90,90).
}
FUNCTION LaunchAbortConditions { PARAMETER lastStage. RETURN STAGE:NUMBER=lastStage AND CheckFlameout().}
FUNCTION DoLaunchAbort {
	INF("Launch Abort Activated").
	LOCK THROTTLE TO 0.
	LOCK STEERING TO SRFRETROGRADE.
	StageTo(0).
	WAIT UNTIL 0.
}
FUNCTION Launch { PARAMETER launchHeading,lastStage,targetApA,cb IS FALSE.
	LOCAL startAlt IS 1000.
	LOCAL limitAlt IS 60000.
	LOCAL pitchMax IS 87.5.
	LOCK currAlt TO ALTITUDE.
	LOCK pitchTarget TO GetPitchTarget(currAlt,startAlt,limitAlt,pitchMax).
	LOCK STEERING TO Heading(launchHeading,pitchTarget).
	LOCK THROTTLE TO 1.
	SafeStage().
	IF STAGE:SolidFuel>0 WHEN STAGE:SolidFuel<10 THEN SET startAlt TO ALTITUDE.
	UNTIL ALT:APOAPSIS>targetApA {
		AutoStage(lastStage).
		IF cb:ISTYPE("Delegate") cb(pitchTarget).
		WAIT 0.01.
		IF LaunchAbortConditions(lastStage) DoLaunchAbort().
	}
	LOCK THROTTLE TO 0.
	INF("Coasting to edge of atmosphere").
	WAIT UNTIL ALTITUDE>69000.
}
FUNCTION OrbitInsertion { PARAMETER lastStage,marginApA IS 15.
	AutoStage(lastStage).
	INF("Coasting to Apoapsis").
	WAIT UNTIL ETA:APOAPSIS<(marginApA+30).
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ETA:APOAPSIS<marginApA.
	INF("Begin Orbital Insertion").
	LOCK THROTTLE TO 1.
	UNTIL ALT:PERIAPSIS>15000 {
		AutoStage(lastStage).
		WAIT 0.1.
	}
	LOCK THROTTLE TO 0.
	WAIT 0.5.
}
FUNCTION FinalizeInsertion { PARAMETER targetPeA IS 72000.
	LOCK STEERING TO PROGRADE.
	INF("Finalizing Orbit").
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:PERIAPSIS>targetPeA.
	LOCK THROTTLE TO 0.
}
FUNCTION RaiseApoapsis { PARAMETER newApA,waitTime IS ETA:PERIAPSIS,leadTime IS 0,cb IS FALSE.
	IF newApA<=ALT:Apoapsis RETURN.
	LOCAL burnTime IS TIME:SECONDS+waitTime.
	LOCK STEERING TO PROGRADE.
	INF("Waiting for burn time").
	UNTIL burnTime-TIME:SECONDS<leadTime {
		IF cb:ISTYPE("Delegate") cb(burnTime-TIME:SECONDS).
		WAIT 0.1.
	}
	INF("Raising Apoapsis").
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:APOAPSIS>=newApA.
	LOCK THROTTLE TO 0.
}
FUNCTION DeOrbit { PARAMETER newPeA IS 30000,waitTime IS ETA:APOAPSIS,leadTime IS 0,cb IS FALSE.
	IF newPeA>=ALT:PERIAPSIS RETURN.
	LOCAL burnTime IS TIME:SECONDS+waitTime.
	LOCK STEERING TO RETROGRADE.
	INF("Waiting for burn time").
	UNTIL burnTime-TIME:SECONDS<leadTime {
		IF cb:ISTYPE("Delegate") cb(burnTime-TIME:SECONDS).
		WAIT 0.1.
	}
	INF("Performing De-Orbit").
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:PERIAPSIS <= newPeA.
	LOCK THROTTLE TO 0.
}
FUNCTION PerformReEntry { PARAMETER stageChutes IS 0,cb IS FALSE.
	INF("Coasting to atmosphere re-entry").
	LOCK STEERING TO SRFRETROGRADE.
	WAIT UNTIL ALTITUDE<70000.
	INF("Entering Upper Atmosphere").
	StageTo(stageChutes+1).
	UNTIL ALTITUDE < 20000 {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	INF("Arming Parachutes").
	SafeStage(stageChutes).
	UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED" {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	UNLOCK STEERING.
	UNTIL FALSE {
		WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
		WAIT 10.
		IF VELOCITY:SURFACE:MAG < 0.1 BREAK.
	}
}
FUNCTION CorrectInclination {
	PARAMETER incMin, incMax, tMax IS 0.5, cb IS FALSE.
	LOCAL inc IS SHIP:OBT:INCLINATION.
	IF inc >= incMin AND inc <= incMax RETURN FALSE.
	INF("Correcting Inclination").
	LOCAL vNorm IS NORMALVEC().
	WAIT UNTIL ABS(SHIP:LATITUDE) < 10.
	IF SHIP:LATITUDE > 0 { IF inc < incMin LOCK STEERING TO vNorm. ELSE LOCK STEERING TO -1*vNorm. }
	ELSE { IF inc < incMin LOCK STEERING TO -1*vNorm. ELSE LOCK STEERING TO vNorm. }
	WAIT UNTIL ABS(SHIP:LATITUDE) < 1.
	LOCK THROTTLE TO tMax.
	UNTIL SHIP:OBT:INCLINATION > incMin AND SHIP:OBT:INCLINATION < incMax {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	LOCK THROTTLE TO 0.
	RETURN TRUE.
}
FUNCTION CorrectApoapsis {
	PARAMETER apMin, apMax, tMax IS 0.5, cb IS FALSE.
	LOCAL ap IS ALT:APOAPSIS.
	IF ap >= apMin AND ap <= apMax RETURN FALSE.
	INF("Correcting Apoapsis").
	WAIT UNTIL ETA:PERIAPSIS < 10+30.
	IF ap < apMin LOCK STEERING TO PROGRADE.
	ELSE LOCK STEERING TO RETROGRADE.
	WAIT UNTIL ETA:PERIAPSIS < 10.
	LOCK THROTTLE TO tMax.
	UNTIL ALT:APOAPSIS > apMin AND ALT:APOAPSIS < apMax {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	LOCK THROTTLE TO 0.
	RETURN TRUE.
}
FUNCTION CorrectEccentricity {
	PARAMETER eccMin, eccMax, cMode IS 1, tMax IS 0.5, cb IS FALSE.
	LOCAL eccMin IS ABS(eccMin).
	LOCAL eccMax IS ABS(eccMax).
	LOCAL ecc IS SHIP:OBT:ECCENTRICITY.
	IF ecc >= eccMin AND ecc <= eccMax RETURN FALSE.
	INF("Correcting Eccentricity").
	LOCAL tN IS TIME:SECONDS.
	IF cMode=1 SET tN TO tN + ETA:APOAPSIS.
	ELSE SET tN TO tN + ETA:PERIAPSIS.
	WAIT UNTIL tN - TIME:SECONDS < 10+30.
	IF ecc < eccMin LOCK STEERING TO cMode*RETROGRADE:VECTOR.
	ELSE LOCK STEERING TO cMode*PROGRADE:VECTOR.
	WAIT UNTIL tN - TIME:SECONDS < 10.
	LOCK THROTTLE TO tMax.
	UNTIL SHIP:OBT:ECCENTRICITY > eccMin AND SHIP:OBT:ECCENTRICITY < eccMax {
		IF cb:ISTYPE("Delegate") cb().
		WAIT 0.1.
	}
	LOCK THROTTLE TO 0.
	RETURN TRUE.
}