-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.0.1.0

tabNext = {}
tabNext.MOD_NAME = g_currentModName


function tabNext.prerequisitesPresent(specializations)
  return true
end

function tabNext.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", tabNext)
end

function tabNext:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		tabNext.actionEvents = {} 
		if self:getIsActiveForInput(true) then 
			local actionEventId;
			_, actionEventId = self:addActionEvent(tabNext.actionEvents, 'TBN_TABNEXT', self, tabNext.tabToNextVehicle, false, true, false, true, nil)
		end		
	end
end
	
function tabNext:tabToNextVehicle()
	if self:getIsEntered() then
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
	end
end

function tabNext:onUpdate(dt)	
	if self:getIsActive() and self:getIsEntered() then
	end
end
