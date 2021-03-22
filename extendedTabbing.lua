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
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FASTTAB', self, extendedTabbing.findNearestVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FASTTAB', self, extendedTabbing.tabToSelectedVehicle, true, false, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_EXECTAB', self, extendedTabbing.findNearestVehicle, false, true, false, true, nil)	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_PREV', self, extendedTabbing.findNextVehicle, false, true, false, true, nil)		
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_NEXT', self, extendedTabbing.findNextVehicle, false, true, false, true, nil)	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV1', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV2', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FAV3', self, extendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
end

function extendedTabbing:getSortedTables(rootNode)
	local indexTable, vehicleTable = {}, {}
	
	for _, vehicle in pairs (g_currentMission.interactiveVehicles) do
		if vehicle.getIsEnterable ~= nil and vehicle:getIsEnterable() and vehicle:getIsTabbable() then
			local distance = calcDistanceFrom(rootNode, vehicle.rootNode)
			table.insert(indexTable, distance)
			vehicleTable[distance] = vehicle
		end
	end
	
	local selfVehicle = g_currentMission.controlledVehicle
	if selfVehicle ~= nil then
		table.insert(indexTable, 0)
		vehicleTable[0] = selfVehicle
	end
	
	-- sort the indices by distance
	table.sort(indexTable)
	
	return indexTable, vehicleTable, selfVehicle ~= nil
end

function extendedTabbing:findNearestVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if extendedTabbing.isActive == true and actionName == "XTB_EXECTAB" then
		extendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)
		return
	end
	
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

	local insideVehicle
	extendedTabbing.indexTable, extendedTabbing.vehicleTable, insideVehicle = extendedTabbing:getSortedTables(rootNode)
	
	if actionName == "XTB_FASTTAB" and insideVehicle then
		extendedTabbing.tabIndex = 2
	else
		extendedTabbing.tabIndex = 1
	end
	
	extendedTabbing.selectedVehicle = extendedTabbing.vehicleTable[extendedTabbing.indexTable[extendedTabbing.tabIndex]] 
end

function extendedTabbing:findNextVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if not extendedTabbing.isActive then 
		return
	end
	
	local iterator = 0
	if actionName == "XTB_PREV" then iterator = -1; end
	if actionName == "XTB_NEXT" then iterator =  1; end
		
 	extendedTabbing.tabIndex = extendedTabbing.tabIndex + iterator
	
	local tabMax = table.maxn(extendedTabbing.indexTable)
	if extendedTabbing.tabIndex > tabMax then
		extendedTabbing.tabIndex = 1
	elseif extendedTabbing.tabIndex < 1 then
		extendedTabbing.tabIndex = tabMax
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
