-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.9.0.0

extendedTabbing = {}

extendedTabbing.tabIndex = 1
extendedTabbing.indexTable = {}
extendedTabbing.vehicleTable = {}
extendedTabbing.selectedVehicle = {}
extendedTabbing.isActive = false

function extendedTabbing.prerequisitesPresent(specializations)
  return true
end

function extendedTabbing.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", extendedTabbing)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", extendedTabbing)
end

function extendedTabbing:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		extendedTabbing.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;
			-- self:addActionEvent(self.actionEvents, InputAction[actionName], self, myObject.actionCallback, triggerKeyUp, triggerKeyDown, triggerAlways, isActive, nil);
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_TABEXEC', self, extendedTabbing.findNearestVehicle, false, true, false, true, nil)
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_TABEXEC', self, extendedTabbing.tabToSelectedVehicle, true, false, false, true, nil)
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_NEXT', self, extendedTabbing.findNextVehicle, false, true, false, true, nil)
		end		
	end
end

function extendedTabbing:getSortedTable(rootNode)
	local indexTable, vehicleTable = {}, {}
	
	for _, vehicle in pairs (g_currentMission.interactiveVehicles) do
		if vehicle.getIsEnterable ~= nil and vehicle:getIsEnterable() and vehicle:getIsTabbable() and vehicle ~= self then
			local distance = calcDistanceFrom(rootNode, vehicle.rootNode)
			table.insert(indexTable, distance)
			vehicleTable[distance] = vehicle
		end
	end
				
	return indexTable, vehicleTable
end

function extendedTabbing:findNearestVehicle()
	extendedTabbing.isActive = true
	local rootNode = self.rootNode
	
	extendedTabbing.indexTable, extendedTabbing.vehicleTable = extendedTabbing:getSortedTable(rootNode)
	extendedTabbing.tabIndex = 1

	local nearestVehicle = extendedTabbing.vehicleTable[extendedTabbing.indexTable[1]] 

	extendedTabbing.selectedVehicle = nearestVehicle
	return
end

function extendedTabbing:findNextVehicle(self)
	if not extendedTabbing.isActive then 
		return
	end
	
	extendedTabbing.tabIndex = extendedTabbing.tabIndex + 1
	
	if extendedTabbing.tabIndex > table.maxn(extendedTabbing.indexTable) then
		extendedTabbing.tabIndex = 1
	end
	
	local nextVehicle = extendedTabbing.vehicleTable[extendedTabbing.indexTable[extendedTabbing.tabIndex]]
	extendedTabbing.selectedVehicle = nextVehicle
	return
end

function extendedTabbing:tabToSelectedVehicle(self)
	extendedTabbing.isActive = false
	if extendedTabbing.selectedVehicle ~= nil then 
		g_currentMission:requestToEnterVehicle(extendedTabbing.selectedVehicle)
	end
end	
            

function extendedTabbing:onUpdate(dt)	
	if self.getIsActive ~= nil and self:getIsActive() and self.getIsEntered ~= nil and self:getIsEntered() and extendedTabbing.isActive then
		if not g_gui:getIsGuiVisible() and not g_flightAndNoHUDKeysEnabled then
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(0.5, 0.5, 0.03, "--> "..extendedTabbing.selectedVehicle:getName())
		end
	end
end
