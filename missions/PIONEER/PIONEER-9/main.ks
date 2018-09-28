set SYS to import("system").
set TLM to import("telemetry").
set MNV to import("maneuver").

function hoverThrust {
	parameter relativeVelocity IS 0.
	IF SHIP:availableThrust = 0 return 0.
	local ga is BODY:MU / (BODY:RADIUS + ALTITUDE)^2.
	return MAX(0, MIN(1, SHIP:mass*(ga+relativeVelocity-SHIP:verticalSpeed)/SHIP:availableThrust)).
}
function descentVector {
	if SHIP:verticalSpeed >= 0 or SHIP:groundSpeed < 1 return UP.
	else return SRFRETROGRADE.
}

set steps to Lex(
0,	launch@,
1,	ascent@,
2,	waitingForDescent@,
3,	descent@,
4,	hover@,
5,	land@
).

function launch{parameter m,p.
	lock STEERING to HEADING(270,80).
	set THROTTLE to 1.
	stage.
	m["next"]().
}
// ascent to an altitude
function ascent{parameter m,p.
	if SYS["Burnout"]() {
		set THROTTLE to 0.
		stage.
		m["next"]().
	}
}
function waitingForDescent{parameter m,p.
	lock STEERING to descentVector().
	if SHIP:verticalSpeed < 0 {
		m["next"]().
	}
}
// perform suicide burn to 10m above ground
function descent{parameter m,p.
	if SHIP:verticalSpeed >= 0 m["next"]().
	else if TLM["timeToImpact"](10) <= MNV["GetManeuverTime"](SHIP:verticalSpeed) set THROTTLE to 1.
}
// hover and kill horizontal speed
function hover{parameter m,p.
	lock THROTTLE to hoverThrust().
	if SHIP:liquidFuel < 18 m["next"]().
}
// descend and land safely - descent speed 10% of radar altitude
function land{parameter m,p.
	lock STEERING TO UP.
	GEAR ON.
	lock THROTTLE to hoverThrust(-MIN(10,MAX(3,ALT:RADAR/10))).
	if ALT:RADAR < 10 and SHIP:verticalSpeed < 0.1 and SHIP:groundSpeed < 0.1 {
		lock THROTTLE to 0.
		unlock STEERING.
		m["next"]().
	}
}