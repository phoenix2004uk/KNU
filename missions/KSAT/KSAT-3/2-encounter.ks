LOCAL MNV IS import("maneuver").
LOCAL SCI IS import("science").
LOCAL partLib IS import("util/parts").
LOCK NORMALVEC TO VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
LOCK RADIALVEC TO VXCL(PROGRADE:VECTOR, UP:VECTOR).

SET steps TO LEX(
0,correction@,
1,coast@,
2,in_soi@,
3,capture@,
4,coast2@,
5,orbit1@,
6,calc@,
7,circularize@
).

LOCK Orient TO NORMALVEC.
LOCAL throt IS 0.
LOCK THROTTLE TO throt.

function correction{PARAMETER M,P.
	if SHIP:OBT:NEXTPATCH:PERIAPSIS < 0 {
		MNV["Steer"](RETROGRADE).
		SET throt TO 0.2.
	}
	else if SHIP:OBT:NEXTPATCH:PERIAPSIS > 50000 {
		MNV["Steer"](PROGRADE).
		SET throt TO 0.2.
	}
	else {
		SET throt TO 0.
		M["next"]().
	}
}
function coast{PARAMETER M,P.
	LOCK STEERING TO Orient.
	if SHIP:OBT:NEXTPATCH:BODY = Mun {
		partLib["DoPartModuleAction"]("longAntenna","ModuleRTAntenna","deactivate").
		partLib["DoPartModuleAction"]("HighGainAntenna5","ModuleRTAntenna","deactivate").
		M["next"]().
	} ELSE M["end"]().
}
function in_soi{PARAMETER M,P.
	if BODY = Mun AND ETA:PERIAPSIS < 10 {
		MNV["Steer"](RETROGRADE).
		partLib["DoPartModuleEvent"]("HighGainAntenna5","ModuleRTAntenna","activate").
		M["next"]().
	}
}
function capture{PARAMETER M,P.
	LOCK STEERING TO RETROGRADE.
	SET throt TO 1.
	IF ALT:APOAPSIS > 0 AND ALT:APOAPSIS < 250000 {
		SET throt TO 0.
		M["next"]().
	}
}
function coast2{PARAMETER M,P.
	LOCK STEERING TO Orient.
	IF ETA:APOAPSIS < ETA:PERIAPSIS {
		M["next"]().
	}
}
function orbit1{PARAMETER M,P.
	LOCK STEERING TO Orient.
	IF ETA:PERIAPSIS < ETA:APOAPSIS {
		M["next"]().
	}
}
function calc{PARAMETER M,P.
	IF HasKSCConnection() {
		SET circ TO import("prg/circ")["new"]("pe").
		M["next"]().
	}
}
function circularize{PARAMETER M,P.
	IF circ(){
		purge("prg/circ").
		LOCK STEERING TO Orient.
		partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
		M["next"]().
	}
}