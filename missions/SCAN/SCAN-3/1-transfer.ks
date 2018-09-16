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
lock eta_burn to node_time - preburn - TIME:seconds.

lock orient to PROGRADE+R(0,0,0).
lock steer to orient.
lock STEERING to steer.

set steps to Lex(
0,calc_xfer_burn@,
1,coast_to_burn@,
2,do_xfer_burn@,
3,coast_prep@,
4,coast_soi@,
5,check_inc@,
6,correct_inc@,
7,do_capture@,
8,prep_circ@,
9,do_circ@,
10,end@
).

function calc_xfer_burn{parameter m,p.
	clearscreen.
	set dv to MNV["ChangeApDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	local transfer_anomaly to RDV["VTransferCirc"](0, Minmus).
	set node_time to TIME:seconds + RDV["etaTransferCirc"](transfer_anomaly, Minmus).

	print "xfer burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,0).
	m["next"]().
}
function coast_to_burn{parameter m,p.
	print "coasting to burn: " + round(eta_burn,2) + "s (" + round(preburn,3)+"s)     " at (0,1).

	if eta_burn <= 60 lock steer to PROGRADE.
	else lock steer to orient.

	if eta_burn <= 0 {
		lock THROTTLE to 1.
		m["next"]().
	}
}
function do_xfer_burn{parameter m,p.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,2).
	print "target Ap: " + round(targetAp,3) + "m" at (0,3).
	print "delta: " + round(targetAp-ap) + "m".
	if SHIP:OBT:hasNextPatch and SHIP:OBT:nextPatch:body = Minmus {
		lock THROTTLE to 0.1.
		if SHIP:OBT:nextPatch:periapsis < 50000 {
			lock THROTTLE to 0.
			m["next"]().
		}
	}
	else if ap >= targetAp {
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
		lock steer to NORMALVEC.
		WAIT 30.
		lock THROTTLE to 0.5.
	}
	else if SHIP:OBT:inclination > 79.8 {
		lock steer to -NORMALVEC.
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
	if ap <= 77305 {
		lock THROTTLE to 0.
		m["next"]().
	}
}
function prep_circ{parameter m,p.
	if HasKSCConnection() {
		SET circ TO import("prg/circ")["new"]("ap").
		m["next"]().
	}
}
function do_circ{parameter m,p.
	IF circ(){purge("prg/circ"). mission["next"]().}
}
function end{parameter m,p.
	lock steer to orient.
	if ap >= 71210 and ap <= 77305 and SHIP:OBT:eccentricity < 0.003 and SHIP:OBT:inclination >= 79.2 and SHIP:OBT:inclination <= 79.8 {
		local scanner is SHIP:PartsNamed("SCANsat.Scanner")[0].
		local scannerModule is scanner:GetModule("SCANsat").
		NotifyInfo("Deploying "+scanner:title).
		scannerModule:DoEvent("start scan: radar").
		WAIT 10.
		NotifyInfo("SCANsat Altitude: " + scannerModule:GetField("scansat altitude")).
	}
	else NotifyInfo("incorrect orbit alignment").
	m["next"]().
}