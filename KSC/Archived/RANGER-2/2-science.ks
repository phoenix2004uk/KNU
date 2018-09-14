LOCAL SCI IS import("science").
function doScience{
	PARAMETER trans.
	IF trans WAIT UNTIL HasKSCConnection().
	FOR ex IN LIST("sensorThermometer","sensorBarometer","dmmagBoom","rpwsAnt") {
		IF trans SCI["transmit"][ex]().
		SCI["run"][ex](trans).
	}
}
doScience(0).