LOCAL MNV IS import("maneuver").
LOCAL SCI IS import("science").
LOCAL partLib IS import("util/parts").
LOCK NORMALVEC TO VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
LOCK RADIALVEC TO VCRS(SHIP:VELOCITY:ORBIT,NORMALVEC).

function doScience{
	PARAMETER trans.
	IF trans WAIT UNTIL HasKSCConnection().
	FOR ex IN LIST("sensorThermometer","sensorBarometer","dmmagBoom","rpwsAnt") {
		IF trans SCI["transmit"][ex]().
		SCI["run"][ex](trans).
	}
}

SET steps TO LEX(
0,burn1@,
1,burn2@,
2,coast@,
3,in_soi@,
4,low_science@,
5,sunburn@,
6,hi_science@,
7,atsun@
).

LOCK Orient TO PROGRADE+R(0,0,90).
LOCAL throt IS 0.
LOCK THROTTLE TO throt.

function burn1{PARAMETER M,P.
	MNV["Steer"](-NORMALVEC).
	SET throt TO 0.2.
	if SHIP:OBT:NEXTPATCH:PERIAPSIS < -40000 OR SHIP:OBT:NEXTPATCH:INCLINATION < 5 {
		SET throt TO 0.
		M["next"]().
	}
}
function burn2{PARAMETER M,P.
	MNV["Steer"](RADIALVEC).
	SET throt TO 0.2.
	if SHIP:OBT:NEXTPATCH:PERIAPSIS > 9000 {
		SET throt TO 0.
		M["next"]().
	}
}
function coast{PARAMETER M,P.
	MNV["Steer"](Orient).
	if SHIP:OBT:NEXTPATCH:BODY = Minmus {
		partLib["DoPartModuleAction"]("longAntenna","ModuleRTAntenna","deactivate").
		partLib["DoPartModuleAction"]("HighGainAntenna5","ModuleRTAntenna","deactivate").
		M["next"]().
	} ELSE M["end"]().
}
function in_soi{PARAMETER M,P.
	if BODY = Minmus {
		partLib["DoPartModuleEvent"]("HighGainAntenna5","ModuleRTAntenna","activate").
		M["next"]().
	}
}
function low_science{PARAMETER M,P.
	IF ALTITUDE < 30000 {
		doScience(0).
		MNV["Steer"](Orient).
		M["next"]().
	}
}
function sunburn{PARAMETER M,P.
	SET throt TO 1.
	IF SHIP:OBT:HASNEXTPATCH AND SHIP:OBT:NEXTPATCH:HASNEXTPATCH AND SHIP:OBT:NEXTPATCH:NEXTPATCH:BODY = Sun {
		SET throt TO 0.
		MNV["Steer"](Orient).
		M["next"]().
	}
}
function hi_science{PARAMETER M,P.
	IF ALTITUDE > 30000 {
		doScience(1).
		M["next"]().
	}
}
function atsun{PARAMETER M,P.
	MNV["Steer"](Orient).
	IF Body = Sun {
		doScience(1).
		M["next"]().
	}
}