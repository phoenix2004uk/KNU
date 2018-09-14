Require(List("pioneer/util")).
FUNCTION FnCb {PARAMETER c,w IS 0.01. IF c:ISTYPE("Delegate") c(). WAIT w.}
FUNCTION GetPitchTarget {
	PARAMETER aN,a0,aM,pM,p0. LOCAL kA IS 85. LOCAL kB IS 70000. LOCAL kC IS 5.
	IF aN<=a0 RETURN pM. IF aN>=aM RETURN p0.
	RETURN MIN(pM,MAX(p0,kA*(LN(kB)-LN(aN))/(LN(kB)-LN(a0))+kC)).
}
FUNCTION PreFlight {SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. LOCK THROTTLE TO 1. LOCK STEERING TO Heading(90,90).}
FUNCTION LaunchAbortConditions {PARAMETER x. RETURN STAGE:NUMBER=x AND CheckFlameout().}
FUNCTION DoLaunchAbort {
	NotifyError("Launch Abort").
	LOCK THROTTLE TO 0.
	LOCK STEERING TO SRFRETROGRADE.
	StageTo(0).
	WAIT UNTIL 0.
}
FUNCTION Launch {
	PARAMETER t_dir,s_n,t_Ap,f IS FALSE, srb IS TRUE.
	LOCAL a0 IS 1000. LOCAL pM IS 87.5. LOCAL aM IS 60000.
	LOCK aN TO ALTITUDE.
	LOCK pT TO GetPitchTarget(aN,a0,aM,pM,0).
	LOCK STEERING TO Heading(t_dir,pT).
	WHEN ALT:APOAPSIS > 40000 THEN LOCK aN TO (ALTITUDE+ALT:APOAPSIS)/2.
	STAGE.
	IF srb AND STAGE:SolidFuel>50 WHEN STAGE:SolidFuel<10 THEN SET a0 TO ALTITUDE.
	UNTIL ALT:APOAPSIS>t_Ap {
		AutoStage(s_n).
		IF f:ISTYPE("Delegate") FnCb(f:bind(pT)).
		IF LaunchAbortConditions(s_n) DoLaunchAbort().
	}
	LOCK THROTTLE TO 0.
	FnCb(f).
	NotifyInfo("Coasting to edge of atmosphere").
	WAIT UNTIL ALTITUDE>69000.
}
FUNCTION OrbitInsertion {
	PARAMETER lastStage,marginApA IS 10,f IS FALSE.
	AutoStage(lastStage).
	NotifyInfo("Coasting to Apoapsis").
	LOCK STEERING TO PROGRADE.
	WAIT UNTIL ALTITUDE>70500.
	WarpFor(ETA:APOAPSIS-30-marginApA).
	NotifyInfo("Orbital Insertion").
	WAIT UNTIL ETA:APOAPSIS<marginApA.
	LOCK THROTTLE TO 1.
	UNTIL ALT:PERIAPSIS>15000 {
		AutoStage(lastStage).
		FnCb(f).
	}
	LOCK THROTTLE TO 0.
	FnCb(f,0.5).
}
FUNCTION FinalizeInsertion {
	PARAMETER targetPeA IS 72000,f IS FALSE.
	LOCK STEERING TO PROGRADE.
	IF ETA:APOAPSIS > 30 AND ETA:APOAPSIS < 999 WarpFor(ETA:APOAPSIS-10).
	NotifyInfo("Finalizing Orbit").
	WAIT UNTIL ETA:APOAPSIS<10.
	LOCK THROTTLE TO 1.
	UNTIL ALT:PERIAPSIS>targetPeA {
		FnCb(f).
	}
	LOCK THROTTLE TO 0.
	FnCb(f).
}