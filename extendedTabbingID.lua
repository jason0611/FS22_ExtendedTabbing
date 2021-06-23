--
-- ExtendedTabbingID
-- Specialization for vehicles to create and store a unique ID
--
-- Jason06 / Glowins Mod-Schmiede
-- Version 0.0.0.1
--

function ExtendedTabbingID.prerequisitesPresent(specializations)
  return true
end

function ExtendedTabbingID.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedTabbingID)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", ExtendedTabbingID)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ExtendedTabbingID)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ExtendedTabbingID)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedTabbingID)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedTabbingID)
end

function ExtendedTabbingID:onPostLoad(savegame)
	local spec = self.spec_ExtendedTabbingID
	if spec == nil then return end
	
	spec.dirtyFlag = self:getNextDirtyFlag()
	
	if savegame ~= nil then	
		math.randomSeed(g_currentMission.environment.dayTime)
		local newID = self:getName()..tostring(math.random(10000))
		local xmlFile = savegame.xmlFile
		local key = savegame.key .. ".ExtendedTabbing"
		spec.ID = Utils.getNoNil(getXMLString(xmlFile, key.."#ID"), newID)
		dbgprint("onPostLoad : vehicleID = "..spec.ID)
	end
end

function ExtendedTabbingID:saveToXMLFile(xmlFile, key)
	local spec = self.spec_ExtendedTabbingID
	setXMLString(xmlFile, key.."#ID", spec.ID)
end

function ExtendedTabbingID:onReadStream(streamId, connection)
	local spec = self.spec_ExtendedTabbingID
	spec.ID = streamReadString(streamId)
end

function ExtendedTabbingID:onWriteStream(streamId, connection)
	local spec = self.spec_ExtendedTabbingID
	streamWriteString(streamId, spec.ID)
end
	
function ExtendedTabbingID:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_ExtendedTabbingID
		if streamReadBool(streamId) then
			spec.ID = streamReadString(streamId)
		end;
	end
end

function ExtendedTabbingID:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_ExtendedTabbingID
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteString(streamId, spec.ID)
		end
	end
end