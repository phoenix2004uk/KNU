{DELETEPATH("1:/mission/").LOCAL A IS GetCallsign().LOCAL B IS GetMissionTag().FOR F IN List(A+".ks",A+"/update.ks",B+"/"+A+".ks",B+"/"+A+"/update.ks")IF EXISTS("0:/KSC/"+F){LOCAL H IS PATH("0:/KSC/"+F).LOCAL J IS ""+H:PARENT. IF NOT download(H:NAME,J:SUBSTRING(2,J:LENGTH-2))KnuPanic(H:NAME,"download").MOVEPATH("1:/home/"+H:NAME,"1:/mission/main.ks").MOVEPATH("0:/KSC/"+F,"0:/KSC/Archived/"+A+"/"+TIME:SECONDS+".ks").BREAK.}export(Lex("version","1.0.2")).}