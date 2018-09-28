set SYS to import("system").
set SCI to import("science").

// setup abort procedure
ON ABORT {
	main["enable"]("abort").
}

set events to Lex(
	"abort", deployChutes@
).
set active to 0.
set steps to Lex(
0,	launch@,
1,	ascent@,
2,	doScience@,
3,	triggerAbort@,
4,	land@,
5,	done@
).

function deployChutes{parameter m,p.
	if STAGE:number > 0 and SHIP:velocity:surface:mag < 250 and SHIP:verticalSpeed < 0 {
		until STAGE:number = 0 SYS["SafeStage"]().
	}
	if not GEAR and ALT:RADAR < 500 {
		GEAR ON.
	}
}

function launch{parameter m,p.
	lock STEERING to UP.
	STAGE.
	m["next"]().
}
function ascent{parameter m,p.
	if SYS["burnout"](TRUE) m["next"]().
}
function doScience{parameter m,p.
	SCI["run"]["science.module"](FALSE).
	SCI["run"]["GooExperiment"](FALSE,0).
	m["next"]().
}
function triggerAbort{parameter m,p.
	m["enable"]("abort").
	m["next"]().
}
function land{parameter m,p.
	if STATUS = "LANDED" {
		m["next"]().
	}
}
function done{parameter m,p.
	SCI["run"]["GooExperiment"](FALSE,1).
	m["next"]().
}