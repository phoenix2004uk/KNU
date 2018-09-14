CLEARSCREEN.

LOCAL scanner IS SHIP:PartsNamed("SCANsat.Scanner")[0].
LOCAL sciModule IS scanner:GetModule("SCANexperiment").
NotifyInfo("Analyzing " + scanner:TITLE + " Data").
sciModule:DoEvent("analyze data: radar").
WAIT 10.