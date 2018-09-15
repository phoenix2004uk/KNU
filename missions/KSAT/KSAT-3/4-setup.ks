local MNV is import("maneuver").
LOCAL partLib IS import("util/parts").
FUNCTION CalcSMA {
	PARAMETER Ap,Pe,R IS BODY:RADIUS.
	RETURN (Pe+Ap)/2+R.
}
FUNCTION CalcPeriod {
	PARAMETER sma,tBody IS BODY.
	RETURN 2*CONSTANT:PI*SQRT(sma^3/tBody:MU).
}
FUNCTION GetCircTransferPhaseAngle {
	PARAMETER angFinal,vTarget IS TARGET.
	LOCAL R IS BODY:RADIUS.
	LOCAL a_target IS vTarget:OBT:SEMIMAJORAXIS.
	LOCAL T_target IS vTarget:OBT:PERIOD.
	LOCAL a_transfer IS CalcSMA(a_target-R,SHIP:OBT:SEMIMAJORAXIS-R).
	LOCAL T_transfer IS CalcPeriod(a_transfer).
	LOCAL n_target IS 360 / T_target.
	LOCAL dt_transfer IS n_target * T_transfer/2.
	RETURN angFinal - dt_transfer.
}
FUNCTION GetAbsPhaseAngle {
	parameter v1 IS TARGET, v2 IS SHIP,t IS TIME:SECONDS.
	RETURN VANG(BODY:position-positionAt(v1,t-0.001), BODY:position-positionAt(v2,t-0.001)).
}
FUNCTION GetRelPhaseAngle {
	parameter v1 IS TARGET, v2 IS SHIP,t IS TIME:SECONDS,dt IS 60.
	LOCAL a1 IS GetAbsPhaseAngle(v1,v2,t).
	LOCAL a2 IS GetAbsPhaseAngle(v1,v2,t+dt).
	IF a2>a1 RETURN -a1. RETURN a1.
}
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).

local transfer_angle is 120.
local phase_transfer is 0.
local targetAp is 750e3.
local targetSMA is Mun:radius + targetAp.
local allCallsigns IS List("Auxo","Karpo","Thallo").
local callsign is GetCallsign().
local dv is 0.
local preburn is 0.
local fullburn is 0.
local node_time is 0.

lock ap to ALT:apoapsis.
lock sma to SHIP:OBT:SemiMajorAxis.
lock eta_burn to node_time - preburn - TIME:SECONDS.
lock mnv_pct to 0.
lock orient to NORMALVEC.
lock steer to orient.
lock STEERING to steer.

set steps to Lex(
0,start@,
1,coast@,
2,wait_xfer_burn@,
3,calc_xfer_burn@,
4,do_xfer_burn@,
5,calc_circ_burn@,
6,do_circ_burn@,
7,done@
).

if callsign = allCallsigns[0] {
	set sequence to List(0,3,1,4,5,1,6,7).
}
else {
	set sequence to List(0,3,2,4,5,1,6,7).
	local follow is "".
	local first is Vessel("KSAT - Mun '"+allCallsigns[0]+"'").
	if callsign = allCallsigns[1] set follow to allCallsigns[0].
	if callsign = allCallsigns[2] set follow to allCallsigns[1].
	set TARGET to Vessel("KSAT - Mun '"+follow+"'").
	lock phase_current to GetRelPhaseAngle(TARGET).
	set phase_transfer to GetCircTransferPhaseAngle(transfer_angle).
	set targetAp to first:OBT:apoapsis.
	set targetSMA to first:OBT:SemiMajorAxis.
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
	lock mnv_pct to max(0,min(100000,targetAp-ap)/1000).
	print "xfer burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,0).
	m["next"]().
}
function wait_xfer_burn{parameter m,p.
	local phase_delta_start is preburn*360/SHIP:OBT:period.
	print "waiting for transfer angle: "+round(phase_transfer,3)+" - "+round(phase_delta_start,3)+" = "+round(phase_current,3) at (0,1).

	if phase_transfer - phase_delta_start - phase_current <= 5 {
		lock steer to PROGRADE.
	} else lock steer to orient.

	if phase_transfer - phase_delta_start - phase_current <= 0 {
		lock THROTTLE to mnv_pct.
		m["next"]().
	}
}
function coast{parameter m,p.
	print "coasting to burn: " + round(eta_burn,2) + "s (" + round(preburn,3)+"s)     " at (0,1).

	if eta_burn <= 60 lock steer to PROGRADE.
	else lock steer to orient.

	if eta_burn <= 0 {
		lock THROTTLE to mnv_pct.
		m["next"]().
	}
}
function do_xfer_burn{parameter m,p.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,2).
	print "target Ap: " + round(targetAp,3) + "m" at (0,3).
	print "delta: " + round(targetAp-ap) + "m @"+mnv_pct at (0,4).
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
	lock mnv_pct to max(0,min(100000,targetSMA-sma)/1000).
	print "circ burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,0).
	m["next"]().
}
function do_circ_burn{parameter m,p.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,2).
	print "target sma: " + round(targetSMA,3) + "m" at (0,3).
	print "delta: " + round(targetSMA-sma) + "m @"+mnv_pct at (0,4).
	if sma >= targetSMA {
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