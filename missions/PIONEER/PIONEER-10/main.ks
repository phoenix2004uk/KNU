set TLM to import("telemetry").
set MNV to import("maneuver").

function hoverThrust {
	parameter relativeVelocity IS 0.
	IF SHIP:availableThrust = 0 return 0.
	local ga is BODY:MU / (BODY:RADIUS + ALTITUDE)^2.
	return MAX(0, MIN(1, SHIP:mass*(ga+relativeVelocity-SHIP:verticalSpeed)/(SHIP:availableThrust*COS(VANG(UP:vector,SHIP:facing:foreVector))))).
}
function descentVector {
	if SHIP:verticalSpeed >= 0 or SHIP:groundSpeed < 1 return UP.
	else return SRFRETROGRADE.
}

function surface_translate {
	parameter vec_direction, rcsThrottle is 1.
	local vec_heading is max(0.01,min(1,rcsThrottle)) * VXCL(UP:vector,vec_direction):normalized.

	set SHIP:control:starboard	to vec_heading * SHIP:facing:starVector.
	set SHIP:control:top		to vec_heading * SHIP:facing:topVector.
	set SHIP:control:fore		to vec_heading * SHIP:facing:foreVector.
	RCS ON.
}
function translate_off {
	RCS OFF.
	set SHIP:control:starboard to 0.
	set SHIP:control:top to 0.
	set SHIP:control:fore to 0.
}
function stop_translate {
	until SHIP:groundSpeed < 0.1 {
		surface_translate(srfRetrograde:vector, SHIP:groundSpeed).
		wait 0.
	}
	translate_off().
}

function geoOffsetFromShip {
	parameter x, y.
	local east is VCRS(NORTH:vector, UP:vector).
	return BODY:geoPositionOf(SHIP:position + x*NORTH:vector + y*east).
}
function positionOffsetFromShip {
	parameter x, y.
	local point is geoOffsetFromShip(x, y).
	return point:altitudePosition(point:terrainHeight).
}
function getSlopeAtOffset {
	parameter x, y.
	local j is positionOffsetFromShip(x+5,y).
	local k is positionOffsetFromShip(x-2.5,y+4.33).
	local l is positionOffsetFromShip(x-2.5,y-4.33).
	return VCRS(l - j, k - j).
}
function seekFlatSlope {
	parameter maxSlope is 5, step is 5.

	local x is 0.
	local y is 0.
	local slopeAngle is 90.
	local east is VCRS(NORTH:vector, UP:vector).
	until 0 {
		local groundNormal is getSlopeAtOffset(x,y).
		set slopeAngle to VANG(groundNormal, UP:vector).
		if slopeAngle < maxSlope break.

		local downhill is VXCL(UP:vector, groundNormal).
		set x to x + step * COS(VANG(downhill, NORTH:vector)).
		set y to y + step * COS(VANG(downhill, east)).
	}
	return List(x, y).
}

set steps to Lex(
0,	waitingForStart@,
1,	deorbit@,
2,	suicideBurn@,
3,	hover@,
4,	seek@,
5,	moveToLandingSite@,
6,	killSurfaceSpeed@,
7,	land@
).

function waitingForStart{parameter m,p.
	print "Press any key to begin".
	TERMINAL:INPUT:GETCHAR().
	clearscreen.
	lock STEERING to RETROGRADE.
	wait 10.
	m["next"]().
}
function deorbit{parameter m,p.
	local horiz is SQRT(SHIP:velocity:surface:mag^2 - SHIP:verticalSpeed^2).
	if horiz < 10 {
		lock STEERING to descentVector().
		lock THROTTLE to 0.
		if SHIP:verticalSpeed < 0 m["next"]().
	}
	else {
		lock THROTTLE to 1.
	}
}
// perform suicide burn to 10m above ground
function suicideBurn{parameter m,p.
	if SHIP:verticalSpeed >= 0 m["next"]().
	else if TLM["timeToImpact"](50) <= MNV["GetManeuverTime"](SHIP:velocity:surface:mag) set THROTTLE to 1.
	else set THROTTLE to 0.
}
// hover and kill horizontal speed
function hover{parameter m,p.
	lock THROTTLE to hoverThrust().
	lock STEERING to UP.
	stop_translate().
	m["next"]().
}
// find landing site
local landing_location is 0.
function seek{parameter m,p.
	local slope is seekFlatSlope().
	set landing_location to geoOffsetFromShip(slope[0], slope[1]).
	m["next"]().
}
// translate to landing site
function moveToLandingSite{parameter m,p.
	if not (defined lastValue) set lastValue to 2^64.
	local vertical_landing_area is landing_location:altitudePosition(ALTITUDE).
	local landing_distance is vertical_landing_area:mag.
	if landing_distance > lastValue stop_translate().
	if landing_distance < 10 m["next"]().
	else if SHIP:groundSpeed < 10 surface_translate(vertical_landing_area).
	else translate_off().
	set lastValue to landing_distance.
}
function killSurfaceSpeed{parameter m,p.
	stop_translate().
	m["next"]().
}
// descend and land safely - descent speed 10% of radar altitude
function land{parameter m,p.
	lock STEERING TO UP.
	GEAR ON.
	lock THROTTLE to hoverThrust(-MIN(10,MAX(1,ALT:RADAR/10))).
	if ALT:RADAR < 10 and SHIP:verticalSpeed < 0.1 and SHIP:groundSpeed < 0.1 {
		lock THROTTLE to 0.
		unlock STEERING.
		m["next"]().
	}
}