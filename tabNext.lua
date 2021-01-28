--
-- FillLevel Warning for LS 19
--
-- # Author:  	LSM/Sachsenfarmer/Jason0611
-- # date: 		25.11.19/17.01.21
-- # Version: 2.0.0.2
-- 
--

tabNext = {}
tabNext.MOD_NAME = g_currentModName


function tabNext.prerequisitesPresent(specializations)
  return true
end

function tabNext.registerEventListeners(vehicleType)
--	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", tabNext)
--	SpecializationUtil.registerEventListener(vehicleType, "onLoad", tabNext)
--	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", tabNext)
--	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", tabNext)
--    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", tabNext)
--    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", tabNext)
--    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", tabNext)
--    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", tabNext)
--    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", tabNext)
end

function tabNext:onLoad(savegame)
--	local spec = self.spec_fillLevelWarning
--	self.RULaktive = false
--	self.BeepAktive1 = false
--    self.lastBeep = 0
--    self.thisBeep = 0
--	self.attacheble = hasXMLProperty(self.xmlFile, "vehicle.attachable")
--	self.brand = getXMLString (self.xmlFile, "vehicle.storeData.brand")
--	self.loud = 1
--    self.beepIntervall = 2000
--    
--    spec.dirtyFlag = self:getNextDirtyFlag()
--
----[[
--	alertMode:
--		+1 : Alert if vehicle gets full
--		 0 : Alert disabled
--		-1 : Alert if vehicle gets empty
----]]
--	self.alertMode = 0
--
--    fillType_DIESEL = g_fillTypeManager:getFillTypeIndexByName("DIESEL")
--    fillType_DEF = g_fillTypeManager:getFillTypeIndexByName("DEF")
--    fillType_AIR = g_fillTypeManager:getFillTypeIndexByName("AIR")
end

function tabNext:onPostLoad(savegame)
--	local spec = self.spec_fillLevelWarning
--	if spec == nil then return end
--	
--	if savegame ~= nil then	
--		local xmlFile = savegame.xmlFile
--		local key = savegame.key .. ".tabNext"
--		
--		self.alertMode = Utils.getNoNil(getXMLInt(xmlFile, key.."#alertMode"), self.alertMode)
--		self.loud = Utils.getNoNil(getXMLInt(xmlFile, key.."#alertUnmuted"), self.loud)
--		
--		print("FillLevelWarning: Loaded data for "..self:getName()..": AlertMode = "..tostring(self.alertMode).." / Unmuted = "..tostring(self.loud))
--	end
end

function tabNext:saveToXMLFile(xmlFile, key)
--	setXMLInt(xmlFile, key.."#alertMode", self.alertMode)
--	setXMLInt(xmlFile, key.."#alertUnmuted", self.loud)
end

function tabNext:onRegisterActionEvents(isActiveForInput)
--	if self.isClient then
--		tabNext.actionEvents = {} 
--		if self:getIsActiveForInput(true) then 
--			local actionEventId;
--			_, actionEventId = self:addActionEvent(tabNext.actionEvents, 'FLW_TOGGLESOUND', self, tabNext.TOGGLE_SOUND, false, true, false, true, nil)
--			_, actionEventId = self:addActionEvent(tabNext.actionEvents, 'FLW_TOGGLEMODE', self, tabNext.TOGGLE_MODE, false, true, false, true, nil)
--		end		
--	end
end

function tabNext:onReadStream(streamId, connection)
--	self.alertMode = streamReadInt8(streamId)
--	self.loud = streamReadInt8(streamId)
end

function tabNext:onWriteStream(streamId, connection)
--	streamWriteInt8(streamId, self.alertMode)
--	streamWriteInt8(streamId, self.loud)
end
	
function tabNext:onReadUpdateStream(streamId, timestamp, connection)
--	if not connection:getIsServer() then
--		local spec = spec.spec_fillLevelWarning
--		if streamReadBool(streamId) then
--			self.alertMode = streamReadInt8(streamId)
--			self.loud = streamReadInt8(streamId)
--		end;
--	end
end

function tabNext:onWriteUpdateStream(streamId, connection, dirtyMask)
--	if connection:getIsServer() then
--		local spec = self.spec_fillLevelWarning
--		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
--			streamWriteInt8(streamId, self.alertMode)
--			streamWriteInt8(streamId, self.loud)
--		end
--	end
end
	
function tabNext:onUpdate(dt)	
	if self:getIsActive() and self:getIsEntered() then
	end
end
