{LOCAL Z IS{PARAMETER A,B,D IS FALSE. SET A TO A+"".IF B<0 SET B TO A:LENGTH+B. IF B>A:LENGTH RETURN "".IF JF(D)SET D TO MAX(0,A:LENGTH-B).IF D<0 SET D TO MAX(0,A:LENGTH-B+D).RETURN A:SUBSTRING(B,D).}.LOCAL Y IS{PARAMETER A,B IS " ".SET A TO A+"".IF A:STARTSWITH(B){LOCAL D IS 0.UNTIL D=A:LENGTH{IF A[D]<>B RETURN Z(A,D).SET D TO D+1.}RETURN "".}RETURN A.}.LOCAL X IS{PARAMETER A,B IS " ".SET A TO A+"".IF A:ENDSWITH(B){LOCAL D IS A:LENGTH-1.UNTIL D<0{IF A[D]<>B RETURN Z(A,0,D+1).SET D TO D-1.}RETURN "".}RETURN A.}.LOCAL U IS{PARAMETER A,B.SET A TO A+"".LOCAL D IS "".UNTIL B<1{SET D TO D+A. SET B TO B-1.}RETURN D.}.export(Lex("version","1.0.1","substr",Z,"ltrim",Y,"rtrim",X,"trim",{PARAMETER A,B IS " ".SET A TO A+"".RETURN Y(X(A,B),B).},"str_repeat",U,"str_pad",{PARAMETER A,B,D IS " ",F IS 1.SET A TO A+"".LOCAL H IS B-A:LENGTH. IF H<1 RETURN A. LOCAL J IS U(D,H).IF F=-1 RETURN J+A. IF F=1 RETURN A+J. RETURN Z(J,0,FLOOR(H/2))+A+Z(J,FLOOR(H/2)).},"vsprintf",{PARAMETER A,B.LOCAL D IS B. IF NOT B:IsType("Lexicon"){SET D TO Lex().LOCAL F IS B:ITERATOR. UNTIL NOT F:NEXT SET D[F:INDEX]TO F:VALUE.}LOCAL H IS A. FOR J IN D:KEYS SET H TO H:REPLACE("{"+J+"}",""+D[J]).RETURN H.})).}