FOR p IN SHIP:PartsNamed("R8winglet") {
	LOCAL m IS p:GetModule("ModuleControlSurface").
	FOR f IN List("Pitch","Yaw","Roll") {
		m:SetField(f, TRUE).
	}
}
LOCAL c IS SHIP:PartsTagged("PIONEER - 2")[0].
SET c:TAG TO "PIONEER-2".
LOCAL m IS c:GetModule("kOSProcessor").
m:DEACTIVATE.
m:ACTIVATE.