local MNV is import("maneuver").
LOCAL partLib is import("util/parts").

// because kos MOD handles negatives differently
function degmod {
	parameter value.
	if value > 360 return mod(value, 360).
	if value < 0 until value >= 0 set value to value + 360.
	return value.
}

function anomaly_of_transfer_circ {
	parameter final_separation, target_orbital is TARGET, source_orbital is SHIP, parentBody IS BODY.

	local a_source is source_orbital:OBT:semiMajorAxis.
	local a_target is target_orbital:OBT:semiMajorAxis.
	local n_target is 360 / target_orbital:OBT:period.

	local a_transfer is (a_source + a_target) / 2.
	local T_transfer is CONSTANT:PI*SQRT(a_transfer^3/parentBody:MU).

	local dTheta_of_target_during_transfer is n_target * T_transfer.

	// adding 180 since we start 180' from where we finish
	local anomaly_between_vessels_before_transfer is final_separation - dTheta_of_target_during_transfer + 180.

	return degmod(anomaly_between_vessels_before_transfer).
}

function solar_anomaly {
	parameter orbitable.
	return degmod( orbitable:OBT:LAN + orbitable:OBT:argumentOfPeriapsis + orbitable:OBT:trueAnomaly).
}

function eta_to_transfer_circ {
	parameter transfer_anomaly, target_orbital is TARGET, source_orbital is SHIP, parentBody IS BODY.

	// target parameters
	local n_target is 360 / target_orbital:OBT:period.
	local s0_target is solar_anomaly(target_orbital).

	// source parameters
	local n_source is 360 / source_orbital:OBT:period.
	local s0_source is solar_anomaly(source_orbital).

	// eta parameters
	local theta_current is degmod( s0_target - s0_source).
	local dTheta is degmod( theta_current - transfer_anomaly).
	local n_diff is abs( n_target - n_source ).

	return dTheta / n_diff.
}

lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).

local separation_angle is 120.
local targetAp is 750e3.
local targetSMA is Mun:radius + targetAp.
local allCallsigns is List("Auxo","Karpo","Thallo").
local callsign is GetCallsign().
local dv is 0.
local preburn is 0.
local fullburn is 0.
local node_time is 0.
local throt_pct_limit is 100000.
local throt_pct_exponent is 0.25.

lock ap to ALT:apoapsis.
lock sma to SHIP:OBT:semiMajorAxis.
lock eta_burn to node_time - preburn - TIME:SECONDS.
lock mnv_pct to 0.
lock orient to NORMALVEC.
lock steer to orient.
lock STEERING to steer.

set steps to Lex(
0,start@,
1,coast@,
2,align_xfer_burn@,
3,calc_xfer_burn@,
4,do_xfer_burn@,
5,calc_circ_burn@,
6,do_circ_burn@,
7,fine_tune_sma@,
8,done@
).

if callsign = allCallsigns[0] {
	set sequence to List(0,3,1,4,5,1,6,7,8).
}
else {
	set sequence to List(0,3,2,1,4,5,1,6,7,8).
	local follow is "".
	local first is Vessel("KSAT - Mun '"+allCallsigns[0]+"'").
	if callsign = allCallsigns[1] set follow to allCallsigns[0].
	if callsign = allCallsigns[2] set follow to allCallsigns[1].
	set TARGET to Vessel("KSAT - Mun '"+follow+"'").

	set targetSMA to first:OBT:semiMajorAxis.
}

function start{parameter m,p.
	partLib["DoPartModuleAction"]("longAntenna","ModuleRTAntenna","deactivate").
	partLib["DoPartModuleAction"]("HighGainAntenna5","ModuleRTAntenna","deactivate").
	M["next"]().
}
function calc_xfer_burn{parameter m,p.
	clearscreen.
	set dv to MNV["ChangeApDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set node_time to TIME:seconds + ETA:periapsis.
	lock mnv_pct to 1-(1-min((targetAp-ap)/throt_pct_limit,1))^throt_pct_exponent.

	print "xfer burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,0).
	m["next"]().
}
function align_xfer_burn{parameter m,p.
	local transfer_anomaly to anomaly_of_transfer_circ(separation_angle).
	set node_time to TIME:seconds + eta_to_transfer_circ(transfer_anomaly).

	m["next"]().
}
function coast{parameter m,p.
	print "coasting to burn: " + round(eta_burn,2) + "s (" + round(preburn,3)+"s)     " at (0,1).

	if eta_burn <= 60 lock steer to PROGRADE.
	else lock steer to orient.

	if eta_burn <= 0 {
		lock THROTTLE to max(0.001,min(1,mnv_pct)).
		m["next"]().
	}
}
function do_xfer_burn{parameter m,p.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,2).
	print "target Ap: " + round(targetAp,3) + "m" at (0,3).
	print "delta: " + round(targetAp-ap) + "m @"+round(mnv_pct*100,2)+"%" at (0,4).
	if ap >= targetAp {
		lock THROTTLE to 0.
		m["next"]().
	}
}
function calc_circ_burn{parameter m,p.
	clearscreen.
	set dv to MNV["ChangePeDeltaV"](targetAp).
	set preburn to MNV["GetManeuverTime"](dv/2).
	set fullburn to MNV["GetManeuverTime"](dv).
	set node_time to TIME:seconds + ETA:apoapsis.
	lock mnv_pct to 1-(1-min((targetSMA-sma)/throt_pct_limit,1))^throt_pct_exponent.

	print "circ burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,0).
	m["next"]().
}
function do_circ_burn{parameter m,p.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,2).
	print "target sma: " + round(targetSMA,3) + "m" at (0,3).
	print "delta: " + round(targetSMA-sma) + "m @"+round(mnv_pct*100,2)+"%" at (0,4).
	if sma >= targetSMA {
		lock THROTTLE to 0.
		lock steer to RETROGRADE.
		WAIT 10.
		lock THROTTLE to 0.00001.
		m["next"]().
	}
}
function fine_tune_sma{parameter m,p.
	if sma <= targetSMA {
		lock THROTTLE to 0.
		m["next"]().
	}
}
function done{parameter m,p.
	partLib["DoPartModuleEvent"]("longAntenna","ModuleRTAntenna","activate").
	partLib["DoPartModuleEvent"]("HighGainAntenna5","ModuleRTAntenna","activate").
	lock steer to orient.
	M["next"]().
}