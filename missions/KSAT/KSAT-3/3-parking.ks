local ORB is import("orbmech").
local MNV is import("maneuver").
local ISH is import("util/ish").

lock NORMALVEC to VCRS(SHIP:VELOCITY:ORBIT,-BODY:POSITION).

local maxInc is 0.1.
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

function coast{parameter M,P.
	print "coasting to burn" at (0,0).
	if eta_burn <= preburn {
		clearscreen.
		print "starting burn".
		set throt to 1.
		M["next"]().
	}
}
function correctInc{parameter M,P.
	if inc > maxInc {
		local Ran is ORB["Rt"(ORB["Van"]()).
		local Rdn is ORB["Rt"(ORB["Vdn"]()).
		local vnode is 0.
		if Ran > Rdn {
			lock steer to -NORMALVEC.
			lock eta_burn to ORB["etaAN"]().
			set vnode to MNV["VisViva"](Ran).
		}
		else {
			lock steer to NORMALVEC.
			lock eta_burn to ORB["etaDN"]().
			set vnode to MNV["VisViva"](Rdn).
		}
		set dv to 2*vnode*SIN(inc/2).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		M["next"]().
	} else M["jump"](3).
}
function burnInc{parameter M,P.
	print inc-maxInc at (0,1).
	print lastInc-inc at (0,2).
	if inc < maxInc OR inc > lastInc {
		set throt to 0.
		M["next"]().
	}
	else if eta_burn + fullburn < 1 {
		set throt to 0.01.
	}
	set lastInc to inc.
}
function correctAp{PARAMETER M,P.
	if not ISH["value"](ap, targetAp, 100) {
		if ap > targetAp {
			lock steer to RETROGRADE.
		}
		else {
			lock steer to PROGRADE.
		}
		lock eta_burn to ETA:periapsis
		set dv to MNV["ChangeApDeltaV"](targetAp).
		set preburn to MNV["GetManeuverTime"](dv/2).
		set fullburn to MNV["GetManeuverTime"](dv).
		M["next"]().
	} else M["jump"](3).
}
function burnAp{PARAMETER M,P.
	print ap at (0,1).
	print targetAp at (0,2).
	if ISH["value"](ap, targetAp, 100) {
		set throt to 0.
		M["next"]().
	}
	else if eta_burn + fullburn < 1 {
		set throt to 0.01.
	}
}
function correctEcc{PARAMETER M,P.
	if ecc > maxEcc {
		lock steer to PROGRADE.
		lock eta_burn to ETA:apoapsis.
		set dv to MNV["ChangePeDeltaV"](targetAp).
		set preburn to MNV["GetMeneuverTime"](dv/2).
		set fullburn to MNV["GetMeneuverTime"](dv).
		M["next"]().
	} else M["jump"](3).
}
function burnEcc{PARAMETER M,P.
	print ecc-maxEcc at (0,1).
	print lastEcc-ecc at (0,2).
	if ecc < maxEcc OR ecc > lastEcc {
		set throt to 0.
		M["next"]().
	}
	else if eta_burn + fullburn < 1 {
		set throt to 0.1.
	}
	set lastEcc to ecc.
}