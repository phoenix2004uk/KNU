{LOCAL Z IS import("system").LOCAL Y IS{PARAMETER A,B,D,F,H.IF A<=B RETURN F. IF A>=D RETURN H. RETURN MIN(F,MAX(H,85*(LN(7E4)-LN(A))/(LN(7E4)-LN(B))+5)).}.export(Lex("version","1.0.4","new",{PARAMETER A IS Lex(),B IS Lex().LOCAL D IS Lex("alt",1E5,"heading",90,"lastStage",2,"srbPitch",1,"rollAlt",5E3,"rollDis",5E3,"profile",Lex("a0",1E3,"p0",87.5,"aN",6E4,"pN",0,"a1",4E4)).FOR F IN D:KEYS IF A:HASKEY(F)SET D[F]TO A[F].LOCAL H IS Lex(0,({PARAMETER A,B,D.Z["Burnout"](1,A["lastStage"]).}):bind(D),1,({PARAMETER A,B,D.IF STAGE:SolidFuel<9{SET A["profile"]["a0"]TO ALTITUDE.B["disable"](1).}}):bind(D)).FOR F IN B:KEYS IF NOT H:HASKEY(F) SET H[F]TO B[F].RETURN MissionRunner["new"]("asc",Lex(0,({PARAMETER A,B,D.SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.LOCK THROTTLE TO 0.LOCK STEERING TO HEADING(A["heading"],90)+R(0,0,-90). B["next"]().}):bind(D),1,({PARAMETER A,B,D.LOCK THROTTLE TO 1.UNTIL SHIP:AVAILABLETHRUST>1 Z["SafeStage"]().IF A["srbPitch"]AND STAGE:SolidFuel>50 B["enable"](1).B["enable"](0).B["next"]().}):bind(D),2,({PARAMETER A,B,D.LOCAL F IS ALTITUDE. IF ALTITUDE>A["profile"]["a1"]SET F TO(ALTITUDE+ALT:APOAPSIS)/2.LOCAL LOCK H TO Y(F,A["profile"]["a0"],A["profile"]["aN"],A["profile"]["p0"],A["profile"]["pN"]).LOCAL LOCK J TO R(0,0,-90+MIN(90,MAX(0,90*(ALTITUDE-A["rollAlt"])/A["rollDis"]))).LOCK STEERING TO HEADING(A["heading"],H)+J. LOCK THROTTLE TO 1.IF ALT:APOAPSIS>A["alt"]{LOCK THROTTLE TO 0.B["next"]().}}):bind(D),3,({PARAMETER A,B,D.LOCK THROTTLE TO 0.LOCK STEERING TO HEADING(A["heading"],0).IF ALTITUDE>70010{LOCK STEERING TO PROGRADE. B["next"]().}}):bind(D)),1,H,0).})).}