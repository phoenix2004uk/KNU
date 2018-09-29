{
	LOCAL GetPart IS {
		PARAMETER partName, partIndex IS 0.
		LOCAL partList IS SHIP:PartsDubbed(partName).
		IF partList:LENGTH > partIndex {
			RETURN partList[partIndex].
		}
		RETURN FALSE.
	}.
	LOCAL GetPartModule IS {
		PARAMETER partName, moduleName, partIndex IS 0.
		LOCAL part IS GetPart(partName, partIndex).
		IF JF(part) RETURN FALSE.
		RETURN part:GetModule(moduleName).
	}.
	LOCAL DoPartModuleEvent IS {
		PARAMETER partName, moduleName, eventName, partIndex IS 0.
		LOCAL module IS GetPartModule(partName, moduleName, partIndex).
		IF JF(module) OR NOT module:HASEVENT(eventName) RETURN FALSE.
		module:DoEvent(eventName).
		RETURN TRUE.
	}.
	LOCAL DoPartModuleAction IS {
		PARAMETER partName, moduleName, actionName, actionValue IS TRUE, partIndex IS 0.
		LOCAL module IS GetPartModule(partName, moduleName, partIndex).
		IF JF(module) OR NOT module:HASACTION(actionName) RETURN FALSE.
		module:DoAction(actionName, actionValue).
		RETURN TRUE.
	}.
	LOCAL GetPartModuleField IS {
		PARAMETER partName, moduleName, fieldName, partIndex IS 0.
		LOCAL module IS GetPartModule(partName, moduleName, partIndex).
		IF JF(module) OR NOT module:HASFIELD(fieldName) RETURN FALSE.
		RETURN module:GetField(fieldName).
	}.
	LOCAL SetPartModuleField IS {
		PARAMETER partName, moduleName, fieldName, fieldValue, partIndex IS 0.
		LOCAL module IS GetPartModule(partName, moduleName, partIndex).
		IF JF(module) OR NOT module:HASFIELD(fieldName) RETURN FALSE.
		module:SetField(fieldName, fieldValue).
		RETURN TRUE.
	}.
	LOCAL DoModuleEvent IS {
		PARAMETER moduleName, eventName.
		FOR module IN SHIP:MODULESNAMED(moduleName) {
			IF module:part:ship=SHIP and module:HASEVENT(eventName) module:DoEvent(eventName).
		}
	}.
	LOCAL DoModuleAction IS {
		PARAMETER moduleName, actionName, actionValue IS TRUE.
		FOR module IN SHIP:MODULESNAMED(moduleName) {
			IF module:part:ship=SHIP and module:HASACTION(actionName) module:DoAction(actionName, actionValue).
		}
	}.

	export(Lex(
		"version", "1.1.1",
		"GetPart", GetPart,
		"GetPartModule", GetPartModule,
		"DoPartModuleEvent", DoPartModuleEvent,
		"DoPartModuleAction", DoPartModuleAction,
		"GetPartModuleField", GetPartModuleField,
		"SetPartModuleField", SetPartModuleField,
		"DoModuleEvent", DoModuleEvent,
		"DoModuleAction", DoModuleAction
	)).
}