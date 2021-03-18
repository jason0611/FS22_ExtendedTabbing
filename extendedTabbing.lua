-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.0.1.1

extendedTabbing = {}
extendedTabbing.MOD_NAME = g_currentModName

extendedTabbing.tabIndex = 1
extendedTabbing.vehicleTable = {}
extendedTabbing.selectedVehicle = {}


function extendedTabbing.prerequisitesPresent(specializations)
  return true
end

function extendedTabbing.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", extendedTabbing)
end

function extendedTabbing:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		extendedTabbing.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;
			-- self:addActionEvent(self.actionEvents, InputAction[actionName], self, myObject.actionCallback, triggerKeyUp, triggerKeyDown, triggerAlways, isActive, nil);
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_TABEXEC', extendedTabbing.findNearestVehicle, false, true, false, true, nil)
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_TABEXEC', self, extendedTabbing.tabToSelectedVehicle, true, false, false, true, nil)
			_, actionEventId = self:addActionEvent(extendedTabbing.actionEvents, 'XTB_NEXT', self, extendedTabbing.findNextVehicle, false, true, false, true, nil)
		end		
	end
end

function extendedTabbing:getSortedTable()
	local initTable
	
	for _, vehicle in pairs (g_currentMission.interactiveVehicles) do
		if vehicle.getIsEnterable ~= nil and vehicle:getIsEnterable() and vehicle:getIsTabbable() and vehicle ~= self then
			local distance = calcDistanceFrom(self.rootNode, vehicle.rootNode)
			table.insert(initTable, distance, vehicle)
		end
	end
	return table.sort(initTable)
end

function extendedTabbing:findNearestVehicle()

--[[
--	if self:getIsEntered() then
		local nextVehicleExists = false
		local nextVehicle, nextDistance
		for _, vehicle in pairs (g_currentMission.interactiveVehicles) do
			if vehicle.getIsEnterable ~= nil and vehicle:getIsEnterable() and vehicle:getIsTabbable() and vehicle ~= self then
				local distance = calcDistanceFrom(self.rootNode, vehicle.rootNode)
				if not nextVehicleExists or distance < nextDistance then
					nextVehicle = vehicle
					nextDistance = distance
					nextVehicleExists = true
				end
			end
		end
		if not nextVehicleExists then return end
		g_currentMission:requestToEnterVehicle(nextVehicle)
--	end
]]--

	extendedTabbing.vehicleTable = extendedTabbing:getSortedTable()
	extendedTabbing.tabIndex = 1

	local nearestVehicle = extendedTabbing.vehicleTable[1] 

	print("extendedTabbing::findNearestVehicle : ", nearestVehicle:getName())

	extendedTabbing.selectedVehicle = nearestVehicle
	return
end

function extendedTabbing:findNextVehicle()
	extendedTabbing.tabIndex = extendedTabbing.tabIndex + 1
	if extendedTabbing.tabIndex > #extendedTabbing.vehicleTable then
		extendedTabbing.tabIndex = 1
	end
	
	local nextVehicle = extendedTabbing.vehicleTable[extendedTabbing.tabIndex]
	
	print("extendedTabbing::findNextVehicle : ", extendedTabbing.tabIndex, nextVehicle:getName())

	extendedTabbing.selectedVehicle = nextVehicle
	return
end

function extendedTabbing:tabToSelectedVehicle()
	g_currentMission:requestToEnterVehicle(extendedTabbing.selectedVehicle)
end	
            

function extendedTabbing:onUpdate(dt)	
	if self:getIsActive() and self:getIsEntered() then
	end
end
