COPYPATH("0:/libs/science.ks","1:/science.ks").
IF EXISTS ("1:/science.ks") {
	RUNPATH("1:/science.ks").
	LOCK STEERING TO PROGRADE.
	
	PRINT "Doing some Science!".
	DoScience(List("sensorThermometer","sensorBarometer"), TRUE).
	WAIT 10.
	
	PRINT "Raising Orbit".
	LOCK THROTTLE TO 1.
	WAIT UNTIL ALT:APOAPSIS > 255000.
	LOCK THROTTLE TO 0.
}
ELSE NotifyError("Download Failed: /libs/science.ks").