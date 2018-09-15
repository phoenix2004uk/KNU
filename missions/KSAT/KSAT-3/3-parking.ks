local ORB is import("orbmech").
local MNV is import("maneuver").
local ISH is import("util/ish").
function doBurn {
	parameter testEnd.
	if testEnd {
		set throt to 0.
		return 1.
	}
	if throt=0.1 and eta_burn+fullburn <= 1 {
		set eta_burn to eta_burn + 9.
		set throt to 0.01.
	}
	else if throt=1 and eta_burn+fullburn <= 1 {
		set eta_burn to eta_burn + 9.
		set throt to 0.1.
	}
	return 0.
}
lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).

local maxInc is 0.01.
local targetAp is 50000.
local maxEcc is 0.0001.
lock inc to ship:obt:inclination.
lock ap to alt:apoapsis.
lock ecc to ship:obt:eccentricity.
set lastInc to inc.
set lastEcc to ecc.
local throt is 0.
local eta_burn is 0.
local dv is 0.
local preburn is 0.
local fullburn is 0.
lock orient to NORMALVEC.
lock steer to orient.
lock STEERING to steer.
lock THROTTLE to throt.

set steps to Lex(
0,coast@,
1,correctInc@,
2,burnInc@,
3,correctAp@,
4,burnAp@,
5,correctEcc@,
6,burnEcc@
).
set sequence to List(1,0,2,3,0,4,5,0,6).
clearscreen.
function coast{parameter M,P.
	print "coasting to burn: " + round(eta_burn,2) + "s (-" + round(preburn,3)+"s)     " at (0,0).
	if eta_burn <= preburn {
		set throt to 1.
		M["next"]().
	}
}
function correctInc{parameter M,P.
	print "inc: " + inc + ">" + maxInc at (0,1).
	if inc > maxInc {
		local Ran is ORB["Rt"](ORB["Van"]()).
		local Rdn is ORB["Rt"](ORB["Vdn"]()).
		local vnode is 0.
		local node_time is 0.
		local sma is ship:obt:semiMajorAxis.
		if Ran > Rdn {
			lock steer to -NORMALVEC.
			set node_time to TIME:SECONDS + ORB["etaAN"]().
			set vnode to MNV["VisViva"](sma,Ran).
		}
		else {
			lock steer to NORMALVEC.
			set node_time to TIME:SECONDS + ORB["etaDN"]().
			set vnode to MNV["VisViva"](sma,Rdn).
		}
		lock eta_burn to node_time - TIME:SECONDS.
		set dv to 2*vnode*SIN(inc/2).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		print "burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,2).
		M["next"]().
	} else M["jump"](3).
}
function burnInc{parameter M,P.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,0).
	print maxInc-inc at (0,3).
	print inc-lastInc at (0,4).
	if doBurn(inc < maxInc or round(inc - lastInc,6) > 0) M["next"]().
	set lastInc to inc.
}
function correctAp{PARAMETER M,P.
	print "ap: " + ap + "<>" + targetAp at (0,5).
	if not ISH["value"](ap, targetAp, 100) {
		if ap > targetAp {
			lock steer to RETROGRADE.
		}
		else {
			lock steer to PROGRADE.
		}
		set node_time to TIME:SECONDS + ETA:periapsis.
		lock eta_burn to node_time - TIME:SECONDS.
		set dv to MNV["ChangeApDeltaV"](targetAp).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		print "burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,6).
		M["next"]().
	} else M["jump"](3).
}
function burnAp{PARAMETER M,P.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,0).
	print ap at (0,7).
	print targetAp at (0,8).
	if doBurn(ISH["value"](ap, targetAp, 100)) M["next"]().
}
function correctEcc{PARAMETER M,P.
	print "ecc: " + ecc + ">" + maxEcc at (0,9).
	if ecc > maxEcc {
		lock steer to PROGRADE.
		set node_time to TIME:SECONDS + ETA:apoapsis.
		lock eta_burn to node_time - TIME:SECONDS.
		set dv to MNV["ChangePeDeltaV"](targetAp).
		set preburn to MNV["GetMeneuverTime"](dv/2).
		set fullburn to MNV["GetMeneuverTime"](dv).
		print "burn: "+round(dv,2)+"m/s in "+round(fullburn,2)+"s ("+round(preburn,2)+"s)" at (0,10).
		M["next"]().
	} else M["jump"](3).
}
function burnEcc{PARAMETER M,P.
	print "burntime: " + round(eta_burn+fullburn,3) + "s" at (0,0).
	print maxEcc-ecc at (0,11).
	print ecc-lastEcc at (0,12).
	if doBurn(ecc < maxEcc or round(ecc - lastEcc,6) > 0) M["next"]().
	set lastEcc to ecc.
}