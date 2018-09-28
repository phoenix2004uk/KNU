set SYS to import("system").
set TLM to import("telemetry").
set MNV to import("maneuver").
set SCI to import("science").
function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
wait until SHIP:unpacked.

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
	parameter maxSlope is 5.

	local x is 0.
	local y is 0.
	local slopeAngle is 90.
	local east is VCRS(NORTH:vector, UP:vector).
	until 0 {
		local groundNormal is getSlopeAtOffset(x,y).
		set slopeAngle to VANG(groundNormal, UP:vector).
		if slopeAngle < maxSlope break.

		local downhill is VXCL(UP:vector, groundNormal).
		set x to x + min(10,slopeAngle-maxSlope) * COS(VANG(downhill, NORTH:vector)).
		set y to y + min(10,slopeAngle-maxSlope) * COS(VANG(downhill, east)).
	}
	return List(x, y).
}

local descentLongitude is
	//List(74,75). // PIONEER-3a
	//List(-155,-154). // PIONEER-3b
	//List(-60,-59). // PIONEER-3c
	//List(14,15). // PIONEER-3d
	List(49,50). // PIONEER-3f

function doScience {
	parameter exp.
	wait until SHIP:ElectricCharge > 400.
	SCI["run"][exp]().
	wait 10.
}

set steps to Lex(
0,	waitingForStart@,
1,	deorbit@,
2,	suicideBurn@,
3,	hover@,
4,	seek@,
5,	moveToLandingSite@,
6,	killSurfaceSpeed@,
7,	land@,
8,	runExperiments@,
9,	done@
).

function waitingForStart{parameter m,p.
	lock STEERING to RETROGRADE.
	if SHIP:longitude > descentLongitude[0] and SHIP:longitude < descentLongitude[1] {
		m["next"]().
	}
}
function deorbit{parameter m,p.
	local horiz is SQRT(SHIP:velocity:surface:mag^2 - SHIP:verticalSpeed^2).
	if horiz < 10 {
		lock STEERING to descentVector().
		lock THROTTLE to 0.
		until STAGE:number=0 {wait 1. stage.}
		if SHIP:verticalSpeed < 0 m["next"]().
	}
	else {
		lock THROTTLE to 1.
	}
	SYS["Burnout"](TRUE).
}
local suicideBurnStarted is false.
function suicideBurn{parameter m,p.
	if SHIP:verticalSpeed >= 0 m["next"]().
	local TTI is TLM["timeToImpact"](50).
	local TTD is MNV["GetManeuverTime"](SHIP:velocity:surface:mag).
	if TTI <= TTD {
		set THROTTLE to 1.
		set suicideBurnStarted to true.
	}
	else {
		if suicideBurnStarted set THROTTLE to 0.3.
		else set THROTTLE to 0.
	}
}
function hover{parameter m,p.
	lock THROTTLE to hoverThrust().
	lock STEERING to UP.
	stop_translate().
	m["next"]().
}
local landing_location is 0.
function seek{parameter m,p.
	local slope is seekFlatSlope().
	set landing_location to geoOffsetFromShip(slope[0], slope[1]).
	m["next"]().
}
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
function land{parameter m,p.
	lock STEERING TO LOOKDIRUP(UP:vector,SUN:position).
	GEAR ON.
	lock THROTTLE to hoverThrust(-MIN(10,MAX(1,ALT:RADAR/10))).
	if ALT:RADAR < 10 and SHIP:verticalSpeed < 0.1 and SHIP:groundSpeed < 0.1 {
		lock THROTTLE to 0.
		unlock STEERING.
		m["next"]().
	}
}
function runExperiments{parameter m,p.
	doScience("dmmagBoom").
	doScience("sensorAccelerometer").
	doScience("sensorThermometer").
	doScience("sensorBarometer").
	m["next"]().
}
local finished is false.
function done{parameter m,p.
	if not finished lock STEERING to LOOKDIRUP(getSlopeAtOffset(0,0),SUN:position).
	set finished to true.
	wait 600.
}