{
	export(Lex(
		"version","1.0.0",
		"pitchTarget",{parameter A.local B is ALTITUDE.if ALTITUDE>A["a1"]set B to(ALTITUDE+ALT:apoapsis)/2.local D is BODY:ATM:height.if B<=A["a0"]return A["p0"].if B>=A["aN"]return A["pN"].return MIN(A["p0"],MAX(A["pN"],85*(LN(D)-LN(B))/(LN(D)-LN(A["a0"]))+5)).},
		"rollTarget",{parameter A.return -90+MIN(90,MAX(0,90*(ALTITUDE-A["r0"])/A["rN"])).},
		"defaultProfile",Lex("a0",1000,"p0",87.5,"aN",60000,"pN",0,"a1",40000,"r0",5000,"rN",5000)
	)).
}