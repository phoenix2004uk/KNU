LOCAL scanner IS SHIP:PartsNamed("SCANsat.Scanner24")[0].
LOCAL sciModule IS scanner:GetModule("SCANexperiment").
Notify("Analyzing " + scanner:TITLE + " Data").
sciModule:DoEvent("analyze data: multispectral").