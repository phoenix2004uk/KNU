COPYPATH("0:/libs/science.ks","1:/science.ks").

CLEARSCREEN.
PRINT "Preparing De-Orbit over North Pole".
LOCK STEERING TO RETROGRADE.
WAIT UNTIL ETA:APOAPSIS < 590.
LOCK THROTTLE TO 1.
WAIT UNTIL ALT:PERIAPSIS < 5000.
LOCK THROTTLE TO 0.
LOCK STEERING TO SRFRETROGRADE.
PRINT "Coasting to atmosphere re-entry".
WAIT UNTIL ALTITUDE < 70000.
STAGE.
WAIT UNTIL ALTITUDE < 20000.
STAGE.

WAIT UNTIL SHIP:STATUS="LANDED" OR SHIP:STATUS="SPLASHED".
WAIT UNTIL VELOCITY:SURFACE:MAG < 0.1.
SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric"):DoAction("Toggle", True).

RUNPATH("1:/science.ks").
DoScience(List("sensorThermometer","sensorBarometer","sensorAccelerometer","science.module"), FALSE).
DMScience(List("dmmagBoom"), FALSE).