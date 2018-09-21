FOR lib IN List("pioneer","science") {
	COPYPATH("0:/libs/"+lib+".ks","1:/"+lib+".ks").
	RUNPATH("1:/"+lib+".ks").
}
DoScience(List("science.module"), FALSE).
DeOrbit(20000, 30).
PerformReEntry().
SHIP:PartsNamed("ServiceBay.125")[0]:GetModule("ModuleAnimateGeneric"):DoAction("Toggle", True).
DoScience(List("sensorThermometer","sensorBarometer","sensorAccelerometer"), FALSE).
DMScience(List("dmmagBoom"), FALSE).