set ORD to import("ordinal").
set SCI to import("science").

function SetAlarm{parameter t,n.AddAlarm("Raw",t-30,n,"margin").AddAlarm("Raw",t,n,"").}
wait until SHIP:unpacked.

lock STEERING to ORD["sun"]().

set steps to Lex(
0,	lowScience@,
1,	highScience@
).

function lowScience{parameter m,p.
	if ALTITUDE < 30000 {
		SCI["run"]["dmmagBoom"]().
		SCI["run"]["rpwsAnt"]().
		m["next"]().
	}
}
function highScience{parameter m,p.
	if ALTITUDE > 30000 {
		SCI["run"]["dmmagBoom"]().
		SCI["run"]["rpwsAnt"]().
		m["next"]().
	}
}