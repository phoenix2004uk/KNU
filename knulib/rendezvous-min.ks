{function Z{parameter value.if value>360 return mod(value,360).if value<0 until value>=0 set value to value+360. return value.}function Y{parameter orbitable.return Z(orbitable:OBT:LAN+orbitable:OBT:argumentOfPeriapsis+orbitable:OBT:trueAnomaly).}export(Lex("version","1.1.0","U0",Y@,"VTransferCirc",{parameter A,B is TARGET,D is SHIP,F IS BODY. return Z(180+A-CONSTANT:PI*SQRT(((D:OBT:semiMajorAxis+B:OBT:semiMajorAxis)/2)^3/F:MU)*360/B:OBT:period).},"etaTransferCirc",{parameter A,B is TARGET,D is SHIP. return Z(Z(Y(B)-Y(D))-A)/abs(360/B:OBT:period-360/D:OBT:period).})).}