FUNCTION TTI {
	PARAMETER altitudeMargin.
	LOCAL g0 IS BODY:MU / BODY:RADIUS^2.
	LOCAL u IS -SHIP:VERTICALSPEED.
	LOCAL d IS ALT:RADAR - altitudeMargin.
	RETURN (SQRT(u^2 + 2*g0*d) - u) / g0.
}
FUNCTION localG {
	RETURN BODY:MU / (BODY:RADIUS + ALTITUDE)^2.
}
FUNCTION hoverThrust {
	PARAMETER vel IS 0.
	IF SHIP:AVAILABLETHRUST = 0 RETURN 0.
	RETURN MAX(0, MIN(1, SHIP:MASS*(localG()+vel)/SHIP:AVAILABLETHRUST)).
}
FUNCTION distanceToLatLng {
	PARAMETER loc.
	LOCAL r_dis IS loc:DISTANCE.
	LOCAL v_dis IS ALTITUDE - loc:TERRAINHEIGHT.
	LOCAL dis2 IS r_dis^2 - v_dis^2.
	IF dis2 > 0 RETURN SQRT(dis2).
	RETURN 0.
}
FUNCTION MaxAcceleration {
	RETURN SHIP:AVAILABLETHRUST / SHIP:MASS.
}
FUNCTION SteerReverse {
	IF VERTICALSPEED < 0 RETURN SRFRETROGRADE.
	RETURN UP.
}

CLEARSCREEN.
LOCAL WP IS ALLWAYPOINTS()[0].
LOCAL pos IS WP:GEOPOSITION.
LOCAL steer_dir IS pos:HEADING.
LOCAL steer_pitch IS 90.
LOCK THROTTLE TO 1.
LOCK STEERING TO HEADING(steer_dir,steer_pitch)+R(0,0,0).

function launch {
	PARAMETER mission,public.
	GEAR OFF.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	WAIT 2.
	STAGE.
	mission["next"]().
}
function get_to_500 {
	PARAMETER mission,public.
	IF ALTITUDE > 500 {
		mission["enable"]("ui").
		SET steer_pitch TO 90.
		LOCK THROTTLE TO hoverThrust(-VERTICALSPEED).
		IF (distanceToLatLng(pos)/GROUNDSPEED)-2 <= GROUNDSPEED / MaxAcceleration() {
			LOCK STEERING TO SRFRETROGRADE.
			WAIT 2.
			mission["next"]().
		}
	}
	ELSE IF ALTITUDE > 100 {
		SET steer_pitch TO 50.
	}
}
function hover {
	PARAMETER mission,public.
	LOCK STEERING TO SteerReverse().
	IF TTI(0) <= ABS(VERTICALSPEED / MaxAcceleration()) mission["next"]().
	IF GROUNDSPEED <= 1 LOCK THROTTLE TO 0.
	IF GROUNDSPEED < 10 LOCK THROTTLE TO 0.2.
	ELSE LOCK THROTTLE TO 0.5.
}
function descend {
	PARAMETER mission,public.
	LOCK THROTTLE TO 1.
	LOCK STEERING TO UP.
	mission["disable"]("ui").
	GEAR ON.
	mission["next"]().
}
function land {
	PARAMETER mission,public.
	IF ABS(VERTICALSPEED) < 2 LOCK THROTTLE TO hoverThrust(-0.2).
	IF STATUS = "LANDED" mission["next"]().
}
SET steps TO Lex(
	0,launch@,
	1,get_to_500@,
	2,hover@,
	3,descend@,
	4,land@
).
SET events TO Lex(
"ui",{PARAMETER mission, public.
	PRINT "hspeed: " + ROUND(GROUNDSPEED,1)+"  " AT(0,0).
	PRINT "vspeed: " + ROUND(VERTICALSPEED,1)+"  " AT(0,1).
	PRINT "distance: " + ROUND(distanceToLatLng(pos),1)+"  " AT(0,2).
	PRINT "dtime: " + ROUND(distanceToLatLng(pos)/GROUNDSPEED,2)+"  " AT(0,3).
	PRINT "atime: " + ROUND(GROUNDSPEED / MaxAcceleration(),2)+"  " AT(0,4).
	PRINT "TTI:" + ROUND(TTI(0),1) AT(0,5).
}).
SET active TO 0.