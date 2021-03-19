-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.9.1.0

extendedTabbing = {}

extendedTabbing.tabIndex = 1
extendedTabbing.indexTable = {}
extendedTabbing.vehicleTable = {}
extendedTabbing.selectedVehicle = {}
extendedTabbing.vehicleSlot = {}
extendedTabbing.isActive = false

function extendedTabbing:loadMap(name)
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, extendedTabbing.registerActionEvents);
end

function extendedTabbing:registerActionEvents()
	local actionEventId;
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_TABEXEC', self, extendedTabbing.findNearestVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_TABEXEC', self, extendedTabbing.tabToSelectedVehicle, true, false, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_NEXT', self, extendedTabbing.findNextVehicle, false, true, false, true, nil)	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV1', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV2', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV3', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
end

function extendedTabbing:loadMission()
	if not g_currentMission:getIsServer() then return; end
	
	local savegameDir = g_currentMission.missionInfo.savegameDirectory
	local player = g_currentMission.player.id
	
	if savegameDir ~= nil then
		local savegameFile = savegameDir.."/extendedTabbing.xml"
		

function extendedTabbing:getSortedTables(rootNode)
	local indexTable, vehicleTable = {}, {}
	
	for _, vehicle in pairs (g_currentMission.interactiveVehicles) do
		if vehicle.getIsEnterable ~= nil and vehicle:getIsEnterable() and vehicle:getIsTabbable() and vehicle ~= self then
			local distance = calcDistanceFrom(rootNode, vehicle.rootNode)
			table.insert(indexTable, distance)
			vehicleTable[distance] = vehicle
		end
	end
	-- sort the indices by distance
	table.sort(indexTable)
	
	return indexTable, vehicleTable
end

function extendedTabbing:findNearestVehicle(actionName, keyStatus, arg3, arg4, arg5)
	extendedTabbing.isActive = true
	local rootNode

	-- Find player's position first
	if g_currentMission.player ~= nil then
		rootNode = g_currentMission.player.rootNode
	end

	-- If in vehicle, replace position with vehicle's position
	if g_currentMission.controlledVehicle ~= nil then
		rootNode = g_currentMission.controlledVehicle.rootNode
	end

	extendedTabbing.indexTable, extendedTabbing.vehicleTable = extendedTabbing:getSortedTables(rootNode)
	extendedTabbing.tabIndex = 1
	
	extendedTabbing.selectedVehicle = extendedTabbing.vehicleTable[extendedTabbing.indexTable[extendedTabbing.tabIndex]] 
end

function extendedTabbing:findNextVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if not extendedTabbing.isActive then 
		return
	end
	
	extendedTabbing.tabIndex = extendedTabbing.tabIndex + 1
	
	if extendedTabbing.tabIndex > table.maxn(extendedTabbing.indexTable) then
		extendedTabbing.tabIndex = 1
	end
	
	local nextVehicle = extendedTabbing.vehicleTable[extendedTabbing.indexTable[extendedTabbing.tabIndex]]
	extendedTabbing.selectedVehicle = nextVehicle
end

function extendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)

	local slot = nil
	if actionName == "XTB_FAV1" then slot = 1; end
	if actionName == "XTB_FAV2" then slot = 2; end
	if actionName == "XTB_FAV3" then slot = 3; end
	
	if not extendedTabbing.isActive then
	-- Slot-Key pressed to Tab into Vehicle
		extendedTabbing.selectedVehicle = extendedTabbing.vehicleSlot[slot]
	elseif slot ~= nil then
	-- Slot-Key pressed to store vehicle into slot
		extendedTabbing.vehicleSlot[slot] = extendedTabbing.selectedVehicle
		--g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"), 2000)
		g_currentMission:showBlinkingWarning("Gespeichert: Slot "..tostring(slot), 2000)
		return
	end
	extendedTabbing.isActive = false
	if extendedTabbing.selectedVehicle ~= nil then 
		g_currentMission:requestToEnterVehicle(extendedTabbing.selectedVehicle)
		extendedTabbing.selectedVehicle = nil
	end
end	
            
function extendedTabbing:update(dt)	
	if extendedTabbing.isActive and extendedTabbing.selectedVehicle ~= nil then
--		if g_gui:getIsGuiVisible() and not g_flightAndNoHUDKeysEnabled then
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(0.5, 0.7, 0.03, "--> "..extendedTabbing.selectedVehicle:getName())
--		end
	end
end

addModEventListener(extendedTabbing);
