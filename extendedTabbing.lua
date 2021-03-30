-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.9.2.0

extendedTabbing = {}

-- general data
extendedTabbing.tabIndex = 1
extendedTabbing.indexTable = {}
extendedTabbing.vehicleTable = {}
extendedTabbing.selectedVehicle = {}
extendedTabbing.isActive = false

-- local player data
extendedTabbing.data = {}
extendedTabbing.data.playerID = ""
extendedTabbing.data.playerName = ""
extendedTabbing.data.slot = {}
extendedTabbing.needsUpdate = false

-- all player data
extendedTabbing.dataBase = {}
-- extendedTabbing.dataBase.playerID = ""
-- extendedTabbing.dataBase.playerName = ""
-- extendedTabbing.dataBase.slot = {0, 0, 0}

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

function extendedTabbing:loadMap(name)
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, extendedTabbing.registerActionEvents);
	
	-- debug printing
	print("extendedTabbing :: loadMap : started")
	
	-- Load Database, if MP-Server or SP
	if g_currentMission:getIsServer() then
		print("ExtendedTabbing :: loadMap : Is gameserver, loading DB")
		if  g_currentMission.missionInfo.savegameDirectory ~= nil then
			local dataBaseFile = g_currentMission.missionInfo.savegameDirectory .. "/extendedTabbing.xml"
			if fileExists(dataBaseFile) then
				local xmlFile = loadXMLFile("dataBase", dataBaseFile)
				local xmlPlayerKey = ""				

				local loadedEntry = {}	
				loadedEntry.slot = {0, 0, 0}			

				local xmlPlayerID
				local xmlPlayerName
				local xmlSlot1
				local xmlSlot2
				local xmlSlot3
				
				local playerAnz = 0

				while (true) do
					xmlPlayerKey = string.format("extendedTabbing.player(%d)#", playerAnz)
					
					xmlPlayerID  	= xmlPlayerKey .. "playerID"
					xmlPlayerName 	= xmlPlayerKey .. "playerName"
					xmlSlot1		= xmlPlayerKey .. "slot1"
					xmlSlot2		= xmlPlayerKey .. "slot2"
					xmlSlot3		= xmlPlayerKey .. "slot3"

					if not hasXMLProperty(xmlFile, xmlPlayerID) then break; end;
					
					loadedEntry.playerID 	= getXMLString(xmlFile, xmlPlayerID)
					loadedEntry.playerName 	= getXMLString(xmlFile, xmlPlayerName)
					if hasXMLProperty(xmlFile, xmlSlot1) then loadedEntry.slot[1]	= getXMLInt(xmlFile, xmlSlot1); end
					if hasXMLProperty(xmlFile, xmlSlot2) then loadedEntry.slot[2]	= getXMLInt(xmlFile, xmlSlot2); end
					if hasXMLProperty(xmlFile, xmlSlot3) then loadedEntry.slot[3]	= getXMLInt(xmlFile, xmlSlot3); end
					
					playerAnz = playerAnz + 1
					
					if extendedTabbing.dataBase.PlayerID == "" then
						extendedTabbing.dataBase = {}
					end
					table.insert(extendedTabbing.dataBase, loadedEntry)
					
				-- Debug printing
					print("extendedTabbing :: loadMap : Step "..tostring(playerAnz))
					print_r(extendedTabbing.dataBase)
				end
			end
		else
			print("ExtendedTabbing :: loadMap : No dataBase found")
		end
	else
		print("ExtendedTabbing :: loadMap : No gameserver, abortig...")
	end
	
	-- debug printing
	print("extendedTabbing :: loadMap : ended")
	
end

-- Grundlegende Informationen speichern: Relevant für MP-Server und SP, nicht notwendig für MP-Client
-- Ausführung bei jedem Speichervorgang
function extendedTabbing.saveDataBase(missionInfo)

--	debug printing
	print("ExtendedTabbing :: saveDataBase : starting")
	print_r(extendedTabbing.dataBase)
--	--

	local dataBaseFile = missionInfo.savegameDirectory .. "/extendedTabbing.xml"
	local xmlFile = createXMLFile("dataBase", dataBaseFile, "extendedTabbing")
	
	if xmlFile == nil then return false; end;
	local i = 0
	for _, dbEntry in pairs(extendedTabbing.dataBase) do
		if dbEntry.slot ~= nil and (dbEntry.slot[1] ~= 0 or dbEntry.slot[2] ~= 0 or dbEntry.slot[3] ~= 0) then
			xmlPlayerKey = string.format("extendedTabbing.player(%d)#", i)
		
			xmlPlayerID  	= xmlPlayerKey .. "playerID"
			xmlPlayerName 	= xmlPlayerKey .. "playerName"
			xmlSlot1		= xmlPlayerKey .. "slot1"
			xmlSlot2		= xmlPlayerKey .. "slot2"
			xmlSlot3		= xmlPlayerKey .. "slot3"
		
			setXMLString(xmlFile, xmlPlayerID, dbEntry.playerID)
			setXMLString(xmlFile, xmlPlayerName, dbEntry.playerName)
			if dbEntry.slot[1] ~= nil then setXMLInt(xmlFile, xmlSlot1, dbEntry.slot[1]) end
			if dbEntry.slot[2] ~= nil then setXMLInt(xmlFile, xmlSlot2, dbEntry.slot[2]) end
			if dbEntry.slot[3] ~= nil then setXMLInt(xmlFile, xmlSlot3, dbEntry.slot[3]) end
		
		-- Debug printing
			print("extendedTabbing :: saveDataBase : saved entry for "..dbEntry.playerName)
		end
		i = i + 1
	end
	saveXMLFile(xmlFile)
	delete(xmlFile)
	
--	debug printing
	print("ExtendedTabbing :: saveDataBase : ending")
--	--
	
end 

function extendedTabbing:loadPlayer(xmlFilename, playerStyle, creatorConnection, isOwner)
	local userId = self.userId
	
	-- 	debug printing
	print("ExtendedTabbing :: loadUserId for UserId: "..tostring(userId))
--	--

	local user = g_currentMission.userManager:getUserByUserId(userId)	
	
	if user == nil then 
		print("ExtendedTabbing :: loadPlayerData : No user found")
		return false 
	end
	
	extendedTabbing.data.playerID = user.uniqueUserId
	extendedTabbing.data.playerName = user.nickname

	-- if MP-Client only, we will get the rest data later, else we have to get the assigned vehicles from the database
	if g_currentMission:getIsServer() then 
		extendedTabbing:loadPlayerData(extendedTabbing.data.playerID)
	end
end

-- Individuelle Informationen für den jeweiligen Spieler aus der DB abrufen: Relevant für MP-Server und SP
function extendedTabbing:loadPlayerData(playerID)

-- 	debug printing
	print("ExtendedTabbing :: loadPlayerData : PlayerID: "..tostring(playerID))
--	--

	for _, entry in pairs(extendedTabbing.dataBase) do
		if entry.playerID == playerID then
			local slot = {}
			for i = 1, 3 do
				extendedTabbing.data.slot[i] = entry.slot[i]
			end
			break
		end
	end
	
--	debug printing
	print("ExtendedTabbing :: loadPlayerData : data:")
	print_r(extendedTabbing.data)
--	--

end

-- Individuelle Informationen für den jeweiligen Spieler in die Datenbank schreiben: Relevant für MP-Server und SP
function extendedTabbing:updateDataBase(updateEntry)
	local playerAnz = table.maxn(extendedTabbing.dataBase)
	local dbEntry
	local dbEntryFound = false
	for i = 1, playerAnz do
		dbEntry = table.remove(extendedTabbing.dataBase, i)
		if dbEntry.playerID == updateEntry.playerID then
			dbEntryFound = true
			dbEntry = updateEntry
		end
		table.insert(extendedTabbing.dataBase, i, dbEntry)
		
		-- debug printing
		print_r(extendedTabbing.dataBase)
		--	--
	end
	-- Not found: Create new entry
	if not dbEntryFound then table.insert(extendedTabbing.dataBase, updateEntry); end
end

-- Übertragung vom Server zum Client (Server-Seite)
function extendedTabbing:writeStream(streamId, connection)
-- 	debug printing
	print("ExtendedTabbing :: writeStream : starting")
--	--
	if not connection.isServer then
		streamWriteInt8(streamId, table.maxn(extendedTabbing.dataBase))
		local tmpVehicle, tmpVehicleId
		for _, entry in pairs(extendedTabbing.dataBase) do
			streamWriteString(streamId, entry.playerID)
			streamWriteString(streamId, entry.playerName)
			for i = 1, 3 do
				tmpVehicleId = entry.slot[i]
				if tmpVehicleId == nil then
					tmpVehicleId = 0
				end
				streamWriteInt16(streamId, tmpVehicleId)
			end
		end
	end
end

-- Übertragung vom Server zum Client (Client-Seite)
function extendedTabbing:readStream(streamId, connection)
-- 	debug printing
	print("ExtendedTabbing :: readStream : starting")
--	--
	if connection.isServer then
		extendedTabbing.dataBase = {}
		local n = streamReadInt8(streamId)
		for _ = 1, n do
			local entry = {}
			local tmpVehicleId
			entry.playerID = streamReadString(streamId)
			entry.playerName = streamReadString(streamId)
			for i = 1, 3 do
				entry.slot[i] = readStreamInt16(streamId)
			end
			table.insert(extendedTabbing.dataBase, entry)
		end
		-- Get the needed data and disregard the rest
		extendedTabbing:loadPlayerData(extendedTabbing.data.playerID)
		extendedTabbing.dataBase = {}
	end
end

function extendedTabbing:writeUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		streamWriteBool(streamId, extendedTabbing.needsUpdate)
		if extendedTabbing.needsUpdate then
			streamWriteString(streamId, extendedTabbing.data.playerID)
			streamWriteString(streamId, extendedTabbing.data.playerName)
			for i = 1, 3 do
				streamWriteInt16(streamId, extendedTabbing.data.slot[i])
			end
		end
		extendedTabbing.needsUpdate = false
	end
end

function extendedTabbing:readUpdateStream(streamId, timestamp, connection)
	local loadEntry = {}
	loadEntry.slot = {}
	if not connection:getIsServer() then
		if streamReadBool(streamId) then
			streamReadString(streamId, loadEntry.playerID)
			streamReadString(streamId, loadEntry.playerName)
			for i = 1, 3 do
				streamReadInt16(streamId, loadEntry.slot[i])
			end
		end
		extendedTabbing.updateDataBase(loadEntry)
	end
end

-- Hauptfunktionen --
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

function extendedTabbing:getVehicleById(vehicleId)
	for _, vehicle in pairs(g_currentMission.vehicles) do
		if vehicle.id == vehicleId then
			return vehicle
		end
	end
	return nil
end

function extendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)

	local slot = 0
	if actionName == "XTB_FAV1" then slot = 1; end
	if actionName == "XTB_FAV2" then slot = 2; end
	if actionName == "XTB_FAV3" then slot = 3; end
	
	if not extendedTabbing.isActive then
	-- Slot-Key pressed to Tab into Vehicle
		local selectedId = extendedTabbing.data.slot[slot]
		extendedTabbing.selectedVehicle = extendedTabbing:getVehicleById(selectedId)
	elseif slot ~= 0 and extendedTabbing.selectedVehicle ~= nil then
	-- Slot-Key pressed to store vehicle into slot
		extendedTabbing.data.slot[slot] = extendedTabbing.selectedVehicle.id
		--g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"), 2000)
		g_currentMission:showBlinkingWarning("Gespeichert: Slot "..tostring(slot).."("..tostring(extendedTabbing.data.slot[slot])..")", 2000)
		extendedTabbing.needsUpdate = true
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
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, 0.7, 0.03, "--> "..extendedTabbing.selectedVehicle:getName())
	end
	if extendedTabbing.needsUpdate then
		if g_currentMission:getIsServer() then 
			extendedTabbing:updateDataBase(extendedTabbing.data)
			extendedTabbing.needsUpdate = false
		end
	end
end

-- Register mod to event management
addModEventListener(extendedTabbing);

-- Load Database on start -- realized by "loadMap"
-- Mission00.load = Utils.appendedFunction(Mission00.load, extendedTabbing.loadDataBase)

-- Get unique User-Id on joining
Player.load = Utils.appendedFunction(Player.load, extendedTabbing.loadPlayer)

-- Transfer information from server to client on joining
Player.readStream = Utils.appendedFunction(Player.readStream, extendedTabbing.readStream)
Player.writeStream = Utils.appendedFunction(Player.writeStream, extendedTabbing.writeStream)

-- Update information from client to server while playing
Player.readUpdateStream = Utils.appendedFunction(Player.readUpdateStream, extendedTabbing.readUpdateStream)
Player.writeUpdateStream = Utils.appendedFunction(Player.writeUpdateStream, extendedTabbing.writeUpdateStream)

-- Include database-information while saving gamedata
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, extendedTabbing.saveDataBase)
