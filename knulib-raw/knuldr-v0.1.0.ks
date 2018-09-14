{LOCAL Z IS STACK().LOCAL Y IS LEX().LOCAL X IS {PARAMETER A.RETURN EXISTS("1:/lib/"+A+".min.ks") OR EXISTS("1:/lib/"+A+".ks").}.LOCAL W IS {PARAMETER A.IF EXISTS("1:/lib/"+A+".min.ks") RUNPATH("1:/lib/"+A+".min.ks").ELSE RUNPATH("1:/lib/"+A+".ks").}.LOCAL U IS GetKSCFile@.GLOBAL GetLib IS {PARAMETER A.LOCAL D IS U("knulib/"+A+".min.ks","lib/"+A+".min.ks").IF IsError(D)AND D["errno"]=ERR_DL_404 RETURN U("knulib/"+A+".ks","lib/"+A+".ks").RETURN D.}.GLOBAL GetFile IS {PARAMETER A,B IS A,D IS 0.RETURN U(A,"home/"+B,D).}.GLOBAL onetime IS {PARAMETER A.LOCAL B IS import(A).purge(A).RETURN B.}.GLOBAL import IS{PARAMETER A.Z:push(A).IF NOT X(A)OnError(GetLib(A),{PARAMETER B.IF B["errno"]<>ERR_DL_EXIST KnuPanic(B["error"]).}).W(A).RETURN Y[A].}.GLOBAL export IS{PARAMETER A.SET Y[Z:pop()] TO A.}.GLOBAL purge IS {PARAMETER A.DELETEPATH("1:/lib/"+A+".min.ks").DELETEPATH("1:/lib/"+A+".ks").}.GLOBAL libs IS {PARAMETER A.LOCAL B IS Lex().FOR D IN A {LOCAL F IS import(D).FOR H IN F:KEYS IF H<>"version" SET B[H] TO F[H].}SET B["purge"] TO ({PARAMETER J.FOR K IN J purge(K).}):bind(A).RETURN B.}.}
{
	IF SHIP:STATUS = "PRELAUNCH" {
		LOCAL runner IS import("mission_runner").
		runner["init"](onetime("knub")["return"]).
	}
	ELSE {
		// get runlevel
		// continue mission
	}
}