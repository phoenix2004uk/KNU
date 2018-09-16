LOCAL MNV IS import("maneuver").
LOCAL RDV IS import("rendezvous").
LOCAL partLib IS import("util/parts").
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).
lock RADIALVEC to VXCL(PROGRADE:VECTOR, UP:VECTOR).

local targetAp IS Minmus:ALTITUDE + Minmus:soiRadius.
local node_time is 0.
local preburn is 0.
local fullburn is 0.

lock ap to ALT:apoapsis.
lock pe to ALT:periapsis.
lock eta_burn to node_time - preburn - TIME:seconds.

lock orient to PROGRADE+R(0,0,0).
lock steer to orient.
lock STEERING to steer.

set steps to Lex(
1,prep_correction@,
2,do_correction@,
3,coast_prep@,
4,coast_soi@,
5,check_inc@,
6,correct_inc@,
7,do_capture@,
8,prep_circ@,
9,do_circ@,
10,end@
).
function prep_correction{parameter m,p.
	lock steer to RETROGRADE.
	WAIT 10.
	lock THROTTLE to 1.
	m["next"]().
}
function do_correction{parameter m,p.
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Minmus {
		lock THROTTLE to 0.1.
		if SHIP:OBT:nextPatch:periapsis < 500000 {
			lock THROTTLE to 0.
			m["next"]().
		}
	}
	else if ap <= Minmus:altitude-Minmus:soiRadius {
		lock THROTTLE to 0.
		m["end"]().
	}
}
function coast_prep{parameter m,p.
	partLib["DoPartModuleAction"]("longAntenna","ModuleRTAntenna","deactivate").
	partLib["DoPartModuleEvent"]("mediumDishAntenna","ModuleRTAntenna","activate").
	partLib["SetPartModuleField"]("mediumDishAntenna","ModuleRTAntenna","target",Kerbin).
	lock steer to orient.
	M["next"]().
}
function coast_soi{parameter m,p.
	if BODY = Minmus {
		WAIT 30.
		m["next"]().
	}
}
function check_inc{parameter m,p.
	if SHIP:OBT:inclination < 79.2 {
		lock steer to -NORMALVEC.
		WAIT 30.
		lock THROTTLE to 0.5.
	}
	else if SHIP:OBT:inclination > 79.8 {
		lock steer to NORMALVEC.
		WAIT 30.
		lock THROTTLE to 0.5.
	}
	m["next"]().
}
function correct_inc{parameter m,p.
	if SHIP:OBT:inclination <= 79.8 and SHIP:OBT:inclination >= 79.2 {
		lock THROTTLE to 0.
		lock steer to orient.
		m["next"]().
	}
}
function do_capture{parameter m,p.
	if ETA:periapsis < 60 lock steer to RETROGRADE.
	if ETA:periapsis < 10 {
		lock THROTTLE to 1.
	}
	if ap>0 and pe<=77219 {
		lock THROTTLE to 0.
		m["next"]().
	}
}
function prep_circ{parameter m,p.
	if HasKSCConnection() {
		SET circ TO import("prg/circ")["new"]("pe").
		m["next"]().
	}
}
function do_circ{parameter m,p.
	IF circ(){purge("prg/circ"). m["next"]().}
}
function end{parameter m,p.
	lock steer to orient.
	if ap >= 71210 and ap <= 77305 and SHIP:OBT:eccentricity < 0.003 and SHIP:OBT:inclination >= 79.2 and SHIP:OBT:inclination <= 79.8 {
		local scanner is SHIP:PartsNamed("SCANsat.Scanner")[0].
		local scannerModule is scanner:GetModule("SCANsat").
		Notify("Deploying "+scanner:title).
		scannerModule:DoEvent("start scan: radar").
		WAIT 10.
		Notify("SCANsat Altitude: " + scannerModule:GetField("scansat altitude")).
	}
	else Notify("incorrect orbit alignment").
	m["next"]().
}