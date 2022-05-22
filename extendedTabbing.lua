-- Extended Tabbing for LS 19
--
-- Author: Jason06 / Glowins Mod-Schmiede
-- Version: 1.9.0.3
--

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName)
GMSDebug:enableConsoleCommands()

ExtendedTabbing = {}

-- general data
ExtendedTabbing.tabIndex = 1
ExtendedTabbing.indexTable = {}
ExtendedTabbing.vehicleTable = {}
ExtendedTabbing.selectedVehicle = {}
ExtendedTabbing.selectedDistance = 0
ExtendedTabbing.previewTable = {}
ExtendedTabbing.previewIndexTable = {}
ExtendedTabbing.changingImpossible = false
ExtendedTabbing.isActive = false
ExtendedTabbing.needsServerUpdate = false
ExtendedTabbing.needsDBUpdate = false
ExtendedTabbing.initSlotKeys = true
ExtendedTabbing.vehiclesHaveChanged = false
ExtendedTabbing.selfID = 0
ExtendedTabbing.farmID = 0

ExtendedTabbing.actionEvents = {}

ExtendedTabbing.actionEventText = {}
for i=1,5 do
	ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV"..tostring(i).."_FREE")
end

-- local player data
ExtendedTabbing.data = {}

-- client player data (used for tranfer)
ExtendedTabbing.clientData = {}

-- all player data (to use on mp-server)
ExtendedTabbing.dataBase = {}

function ExtendedTabbing:registerActionEvents()
	local actionEventId
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FASTTAB', self, ExtendedTabbing.findNearestVehicle, false, true, false, true, nil)
	g_inputBinding:setActionEventTextVisibility(actionEventId, false)
	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_FASTTAB', self, ExtendedTabbing.tabToSelectedVehicle, true, false, false, true, nil)
	g_inputBinding:setActionEventTextVisibility(actionEventId, false)
	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_EXECTAB', self, ExtendedTabbing.findNearestVehicle, false, true, false, true, nil)
	g_inputBinding:setActionEventTextVisibility(actionEventId, false)	
	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_TOGGLEHELP', self, ExtendedTabbing.toggleHelp, false, true, false, true, nil)
	g_inputBinding:setActionEventTextVisibility(actionEventId, true)
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)	
	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_PREV', self, ExtendedTabbing.findNextVehicle, false, true, false, true, nil)	
	g_inputBinding:setActionEventTextVisibility(actionEventId, ExtendedTabbing.isActive)
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)	
	
	_, actionEventId = g_inputBinding:registerActionEvent('XTB_NEXT', self, ExtendedTabbing.findNextVehicle, false, true, false, true, nil)	
	g_inputBinding:setActionEventTextVisibility(actionEventId, ExtendedTabbing.isActive)
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
		
	for slot=1,5 do
		_, ExtendedTabbing.actionEvents[slot] = g_inputBinding:registerActionEvent('XTB_FAV'..tostring(slot), self, ExtendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
   		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
   		ExtendedTabbing:updateSlots()
	end
end

function ExtendedTabbing:loadMap(name)
	dbgprint("loadMap : started")
	
	dbgprint("loadMap : isServer: "..tostring(g_currentMission:getIsServer()))
	dbgprint("loadMap : isClient: "..tostring(g_currentMission:getIsClient()))
	dbgprint("loadMap : isDediServer: "..tostring(g_dedicatedServerInfo ~= nil))
	
	ExtendedTabbing.dataBase = {}
	
	ExtendedTabbing.selfID = g_currentMission.playerUserId
	dbgprint("loadMap : selfID :"..tostring(ExtendedTabbing.selfID))
	
	math.randomseed(g_currentMission.environment.dayTime)
	
	-- Load Database if MP-Server or SP
	if g_currentMission:getIsServer() then
		print("ExtendedTabbing :: loadMap : Gameserver: Loading DB")
		if  g_currentMission.missionInfo.savegameDirectory ~= nil then
			local dataBaseFile = g_currentMission.missionInfo.savegameDirectory .. "/extendedtabbing.xml"
			if fileExists(dataBaseFile) then
				--local xmlFile = loadXMLFile("dataBase", dataBaseFile)
				local xmlPlayerKey = "ExtendedTabbing"	
				local xmlFile = XMLFile.loadIfExists("dataBase", dataBaseFile, xmlPlayerKey)
				
				local loadedEntry
				local xmlPlayerID
				local xmlPlayerName
				local xmlShowSlots
				local xmlSlotID={}
				
				local pkey = 0
				while (true) do
					loadedEntry = {}	
					loadedEntry.playerID = ""
					loadedEntry.playerName = ""
					loadedEntry.showSlots = true
					loadedEntry.slotID = {"", "", "", "", ""}
					
					xmlPlayerKey = string.format("ExtendedTabbing.player(%d)", pkey)
					
					xmlPlayerID  	= xmlPlayerKey .. "#playerID"
					xmlPlayerName 	= xmlPlayerKey .. "#playerName"
					xmlShowSlots	= xmlPlayerKey .. "#showSlots"
					for s=1,5 do
					    xmlSlotID[s] = xmlPlayerKey .. "#slot"..tostring(s).."ID"
					end
					
					--if not hasXMLProperty(xmlFile, xmlPlayerID) then break; end;
					if not xmlFile:hasProperty(xmlPlayerID) then break; end;
					
					loadedEntry.playerID 	= xmlFile:getString(xmlPlayerID)
					loadedEntry.playerName 	= xmlFile:getString(xmlPlayerName)
					
					if xmlFile:hasProperty(xmlShowSlots) then 
						loadedEntry.showSlots = xmlFile:getBool(xmlShowSlots)
					else	
						loadedEntry.showSlots = true
					end
					
					for s=1,5 do
					    if xmlFile:hasProperty(xmlSlotID[s]) then loadedEntry.slotID[s] = xmlFile:getString(xmlSlotID[s]); end
					end	
					ExtendedTabbing:updateDataBase(loadedEntry)
					pkey = pkey + 1												
					dbgprint("loadMap : Step "..tostring(pkey)..": Database state:")
					dbgprint_r(ExtendedTabbing.dataBase)
				end
				dbgprint("loadMap : Database loading finished")
			else
				print("ExtendedTabbing :: loadMap : No database to load, starting with empty one")
			end
		else
			print("ExtendedTabbing :: loadMap : Info: New savegame, starting with empty database")
		end
	else
		print("ExtendedTabbing :: loadMap : Just client, no database needed")
	end
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ExtendedTabbing.registerActionEvents);
	dbgprint("loadMap : ended")
end

-- Grundlegende Informationen speichern: Relevant für MP-Server und SP, nicht notwendig für MP-Client
-- Ausführung bei jedem Speichervorgang
function ExtendedTabbing.saveDataBase(missionInfo)

	dbgprint("saveDataBase : starting")
	dbgprint_r(ExtendedTabbing.dataBase)

	local xmlPlayerKey = "ExtendedTabbing"
	local dataBaseFile = missionInfo.savegameDirectory .. "/extendedtabbing.xml"
	local xmlFile = XMLFile.create("dataBase", dataBaseFile, xmlPlayerKey)
	
	if xmlFile == nil then 
		print("ExtendedTabbing :: saveDataBase : Error: Couldn't save dataBase")
		return false; 
	end;
	
	local xmlPlayerID
	local xmlPlayerName
	local xmlShowSlots
	local xmlSlotID={}
	
	local pkey = 0
	for _, dbEntry in pairs(ExtendedTabbing.dataBase) do
		if dbEntry.slotID ~= nil and dbEntry.playerID ~= nil and dbEntry.playerID ~= "" then
			local toBeSaved = false
			xmlPlayerKey 	= string.format("ExtendedTabbing.player(%d)",pkey)
			xmlPlayerID  	= xmlPlayerKey .. "#playerID"
			xmlPlayerName = xmlPlayerKey .. "#playerName"
			xmlShowSlots	= xmlPlayerKey .. "#showSlots"
			for s=1,5 do
				xmlSlotID[s] = xmlPlayerKey.."#slot"..tostring(s).."ID"
				if dbEntry.slotID[s] ~= nil and dbEntry.slotID[s] ~= "" then xmlFile:setString(xmlSlotID[s], dbEntry.slotID[s]); toBeSaved = true; end
			end
			if toBeSaved then
				xmlFile:setString(xmlPlayerID, dbEntry.playerID)
				xmlFile:setString(xmlPlayerName, dbEntry.playerName)
				xmlFile:setBool(xmlShowSlots, dbEntry.showSlots)
				print("ExtendedTabbing :: saveDataBase : saved entry for "..tostring(dbEntry.playerName))
				pkey = pkey + 1
			else
				print("ExtendedTabbing :: saveDataBase : nothing to save for "..tostring(dbEntry.playerName))
			end
		else
			print("ExtendedTabbing :: saveDataBase : nothing to save for "..tostring(dbEntry.playerName))
		end
	end
	xmlFile:save()
	xmlFile:delete()
	dbgprint("saveDataBase : ending")
end 

function ExtendedTabbing:loadPlayer(xmlFilename, playerStyle, creatorConnection, isOwner)
	if g_currentMission:getIsServer() then 
		local userId = self.userId
		local localUser = (g_currentMission.player == nil) -- On first load on MP-host or in SP, player isn't initiated
		local loadEntry = {}
		
		dbgprint("loadPlayer : local user (selfID):        "..tostring(ExtendedTabbing.selfID))
		dbgprint("loadPlayer : loading user (self.userId): "..tostring(userId))
	
		local user = g_currentMission.userManager:getUserByUserId(userId)
		if user == nil then 
			print("ExtendedTabbing :: loadPlayer : Error: Server-Mode, but no user given. Aborting...")
			return false 
		end
		loadEntry.playerID = user.uniqueUserId
		loadEntry.playerName = user.nickname
		loadEntry.showSlots = true
		loadEntry.slotID = {"", "", "", "", ""}

		dbgprint("loadPlayer : Player: "..tostring(loadEntry.playerName))
		dbgprint("loadPlayer : PlayerID: "..tostring(loadEntry.playerID))
	
		-- Individuelle Informationen für den jeweiligen Spieler aus der DB abrufen oder anlegen
		local found = false
		local n = 1
		while true do
			if ExtendedTabbing.dataBase[n] == nil then break; end
			if ExtendedTabbing.dataBase[n].playerID == loadEntry.playerID then
				loadEntry.showSlots = ExtendedTabbing.dataBase[n].showSlots
				for i = 1, 5 do
					loadEntry.slotID[i] = ExtendedTabbing.dataBase[n].slotID[i]
					if loadEntry.slotID[i] == nil then loadEntry.slotID[i] = ""; end
				end
				found = true
				dbgprint("loadPlayer : found in dataBase")
				break
			end
			n = n +1
		end
		if not found then 
			ExtendedTabbing:updateDataBase(loadEntry)
			dbgprint("loadPlayer : added to dataBase:")
			dbgprint_r(ExtendedTabbing.dataBase)
		end
		
		if localUser then
			for i=1,5 do
				if loadEntry.slotID[i] == nil then
					loadEntry.slotID[i] = ""
				end
				if loadEntry.slotID[i] ~= "" then
					local vehicle = ExtendedTabbing:getVehicleByID(loadEntry.slotID[i])
					if vehicle == nil then
						loadEntry.slotID[i] = ""
						ExtendedTabbing.vehiclesHaveChanged = true
					elseif found then
						ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET"..tostring(i))..vehicle:getName()
						if ExtendedTabbing.actionEvents[i] ~= nil then
							g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[i], ExtendedTabbing.actionEventText[i])
							g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[i], loadEntry.showSlots)
						end
					end
				end
			end
		end
		ExtendedTabbing.data[userId] = loadEntry
		
		dbgprint("loadPlayerData : loaded data:")
		dbgprint_r(ExtendedTabbing.data)
		dbgprint("loadPlayerData : loaded userdata:")
		dbgprint_r(ExtendedTabbing.data[userId])
	end
end

-- Speicherbereinigung, wenn Spieler das Spiel verlässt
function ExtendedTabbing:deletePlayer()
	if g_currentMission:getIsServer() then
		if self.userId == nil then
			dbgprint("deletePlayer : User ID is nil")
		else
			dbgprint("deletePlayer : Remove user "..tostring(self.userId))
			ExtendedTabbing.data[self.userId] = nil
			dbgprint("deletePlayer : data :")
			dbgprint_r(ExtendedTabbing.data)
		end
	else
		dbgprint("deletePlayer : leaving game")
	end
end

-- Initiale Übertragung der DB vom Server zum Client (Server-Seite)
function ExtendedTabbing:writeStream(streamId, connection)

	local userId = self.userId
	dbgprint("writeStream : starting for userId "..tostring(userId))
	
	if not connection.isServer then
		dbgprint("ExtendedTabbing :: writeStream : writing data for "..ExtendedTabbing.data[userId].playerName)
		streamWriteInt16(streamId, userId)
		streamWriteString(streamId, ExtendedTabbing.data[userId].playerID)
		streamWriteString(streamId, ExtendedTabbing.data[userId].playerName)
		streamWriteBool(streamId, ExtendedTabbing.data[userId].showSlots)
		for i = 1, 5 do
			if ExtendedTabbing.data[userId].slotID[i] == nil then
				ExtendedTabbing.data[userId].slotID[i] = ""
			end
			streamWriteString(streamId, ExtendedTabbing.data[userId].slotID[i])
		end
	end
end

-- Initiale Übertragung der DB vom Server zum Client (Client-Seite)
function ExtendedTabbing:readStream(streamId, connection)
	dbgprint("readStream : starting")
	if connection.isServer then
		local loadEntry = {}
		local loadedUserId = streamReadInt16(streamId)
		loadEntry.playerID = streamReadString(streamId)
		loadEntry.playerName = streamReadString(streamId)
		loadEntry.showSlots = streamReadBool(streamId)
		
		dbgprint("readStream : reading data for "..loadEntry.playerName)
		
		loadEntry.slotID = {"", "", "", "", ""}
		for i = 1, 5 do
			loadEntry.slotID[i] = streamReadString(streamId)
		end
		
		if loadedUserId == ExtendedTabbing.selfID then
			dbgprint("readStream : accepting data for "..loadEntry.playerName)
			ExtendedTabbing.data[ExtendedTabbing.selfID] = {}
			ExtendedTabbing.data[ExtendedTabbing.selfID].slotID = {"", "", "", "", ""}
			ExtendedTabbing.data[ExtendedTabbing.selfID].playerID = loadEntry.playerID
			ExtendedTabbing.data[ExtendedTabbing.selfID].playerName = loadEntry.playerName
			ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots = loadEntry.showSlots
			for i = 1, 5 do
				ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i] = loadEntry.slotID[i]
				if ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i] ~= "" then
					local vehicle = ExtendedTabbing:getVehicleByID(ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i])
					if vehicle == nil then
						ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i] = ""
						ExtendedTabbing.vehiclesHaveChanged = true
					else
						ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET"..tostring(i))..vehicle:getName()
					end
				end	
			end
		else
			dbgprint("readStream : ignoring data for "..loadEntry.playerName)
		end
	end
end

-- Laufende Übertragung vom Client zum Server (Client-Seite)
function ExtendedTabbing:writeUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		streamWriteBool(streamId, ExtendedTabbing.needsServerUpdate)
		if ExtendedTabbing.needsServerUpdate then
			dbgprint("writeUpdateStream : Starting")
			streamWriteString(streamId, ExtendedTabbing.data[ExtendedTabbing.selfID].playerID)
			streamWriteString(streamId, ExtendedTabbing.data[ExtendedTabbing.selfID].playerName)
			streamWriteBool(streamId, ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots)
			for i = 1, 5 do
				streamWriteString(streamId, ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i])
			end
			ExtendedTabbing.needsServerUpdate = false
			dbgprint("writeUpdateStream : Data transmitted")
		end
	end
end

-- Laufende Übertragung vom Client zum Server (Server-Seite)
function ExtendedTabbing:readUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		if streamReadBool(streamId) then
			local loadEntry = {}
			loadEntry.slotID={"", "", "", "", ""}

			dbgprint("readUpdateStream : Starting")
			
			loadEntry.playerID = streamReadString(streamId)
			loadEntry.playerName = streamReadString(streamId)
			loadEntry.showSlots = streamReadBool(streamId)
			for i = 1, 5 do
				loadEntry.slotID[i] = streamReadString(streamId)
			end
			dbgprint("readUpdateStream : Data transmitted")
			ExtendedTabbing:updateDataBase(loadEntry)	
		end
	end
end

-- Individuelle Informationen für den jeweiligen Spieler in die Datenbank schreiben
function ExtendedTabbing:updateDataBase(updateEntry)
	
	local dbSize = table.maxn(ExtendedTabbing.dataBase)
	local found = false 
	
	for i = 1, dbSize do
		if ExtendedTabbing.dataBase[i].playerID == updateEntry.playerID then
			ExtendedTabbing.dataBase[i].playerName = updateEntry.playerName
			ExtendedTabbing.dataBase[i].showSlots = updateEntry.showSlots
			ExtendedTabbing.dataBase[i].slotID = {"", "", "", "", ""}
			for slot=1,5 do
				ExtendedTabbing.dataBase[i].slotID[slot] = updateEntry.slotID[slot]
			end
			dbgprint("updateDataBase : database entry replaced : "..updateEntry.playerID)
			found = true
			break
		end
	end
	if not found then
		local newPos = dbSize+1
		--table.insert(ExtendedTabbing.dataBase, updateEntry)
		ExtendedTabbing.dataBase[newPos] = {}
		ExtendedTabbing.dataBase[newPos].playerID = updateEntry.playerID
		ExtendedTabbing.dataBase[newPos].playerName = updateEntry.playerName
		ExtendedTabbing.dataBase[newPos].showSlots = updateEntry.showSlots
		ExtendedTabbing.dataBase[newPos].slotID = {"", "", "", "", ""}
		for slot=1,5 do
			ExtendedTabbing.dataBase[newPos].slotID[slot] = updateEntry.slotID[slot]
		end
		dbgprint("updateDataBase : database entry inserted : "..updateEntry.playerID)
	end
end

---------------------
-- Hauptfunktionen --
---------------------

function ExtendedTabbing:toggleHelp()
	ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots = not ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots
	for slot=1,5 do
   		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots)
	end
	ExtendedTabbing.needsDBUpdate = true
end

function ExtendedTabbing:getSortedTables(rootNode)
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

function ExtendedTabbing:getPreviewTable()
	local previewTable = {}
	local previewIndexTable = {}
	local vehicleAnz = table.maxn(ExtendedTabbing.indexTable)
	local previewRange = 0
	local dummyNeeded = 0
	if (vehicleAnz == 2) or (vehicleAnz == 4) then dummyNeeded = 1; end

	if vehicleAnz > 1 then previewRange = 1; end
	if vehicleAnz > 3 then previewRange = 2; end
	
	for n = -previewRange+dummyNeeded,previewRange do
		local index = ExtendedTabbing.tabIndex + n
		if index < 1 then index = index + vehicleAnz; end
		if index > vehicleAnz then index = index - vehicleAnz; end
		previewTable[n] = ExtendedTabbing.indexTable[index]
		previewIndexTable[n] = index
	end
	return previewTable, previewIndexTable
end

function ExtendedTabbing:findNearestVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if ExtendedTabbing.isActive and actionName == "XTB_EXECTAB" then
		ExtendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)
		return
	end
	
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
	ExtendedTabbing.indexTable, ExtendedTabbing.vehicleTable, insideVehicle = ExtendedTabbing:getSortedTables(rootNode)
	
	if actionName == "XTB_FASTTAB" and insideVehicle then
		ExtendedTabbing.tabIndex = 2
	else
		ExtendedTabbing.tabIndex = 1
	end
	
	local vehicleAnz = table.maxn(ExtendedTabbing.indexTable)
	ExtendedTabbing.changingImpossible = (vehicleAnz <= 1)
	
	ExtendedTabbing.selectedDistance = ExtendedTabbing.indexTable[ExtendedTabbing.tabIndex]
	ExtendedTabbing.selectedVehicle = ExtendedTabbing.vehicleTable[ExtendedTabbing.selectedDistance]
	ExtendedTabbing.previewTable, ExtendedTabbing.previewIndexTable = ExtendedTabbing:getPreviewTable()
	
	ExtendedTabbing.isActive = true
end

function ExtendedTabbing:findNextVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if not ExtendedTabbing.isActive then 
		return
	end
	
	local iterator = 0
	if actionName == "XTB_PREV" then iterator = -1; end
	if actionName == "XTB_NEXT" then iterator =  1; end
		
 	ExtendedTabbing.tabIndex = ExtendedTabbing.tabIndex + iterator
	
	local tabMax = table.maxn(ExtendedTabbing.indexTable)
	if ExtendedTabbing.tabIndex > tabMax then
		ExtendedTabbing.tabIndex = 1
	elseif ExtendedTabbing.tabIndex < 1 then
		ExtendedTabbing.tabIndex = tabMax
	end
	
	ExtendedTabbing.selectedDistance = ExtendedTabbing.indexTable[ExtendedTabbing.tabIndex]
	ExtendedTabbing.selectedVehicle = ExtendedTabbing.vehicleTable[ExtendedTabbing.selectedDistance]
	ExtendedTabbing.previewTable, ExtendedTabbing.previewIndexTable = ExtendedTabbing:getPreviewTable()
end

function ExtendedTabbing:getVehicleByID(vehicleId)
	for _, vehicle in pairs(g_currentMission.vehicles) do
		local spec = vehicle.spec_ExtendedTabbingID
		if spec ~= nil and spec.ID == vehicleId then
			return vehicle
		end
	end
	return nil
end

function ExtendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)
	local slot = 0
	if actionName == "XTB_FAV1" then slot = 1; end
	if actionName == "XTB_FAV2" then slot = 2; end
	if actionName == "XTB_FAV3" then slot = 3; end
	if actionName == "XTB_FAV4" then slot = 4; end
	if actionName == "XTB_FAV5" then slot = 5; end
	
	if actionName == "XTB_EXECTAB" or actionName == "XTB_FASTTAB" then ExtendedTabbing.isActive = false; end
	
	-- slot-key pressed to tab into vehicle
	if not ExtendedTabbing.isActive and slot ~= 0 then
		local selectedId = ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[slot]
		ExtendedTabbing.selectedVehicle = ExtendedTabbing:getVehicleByID(selectedId)
		ExtendedTabbing.selectedDistance = 0
		if ExtendedTabbing.selectedVehicle == nil then ExtendedTabbing.updateSlots(); end
	end
	
	-- slot-key pressed to store vehicle into slot
	if ExtendedTabbing.isActive and slot ~= 0 then
		if ExtendedTabbing.selectedVehicle ~= nil then
			local spec = ExtendedTabbing.selectedVehicle.spec_ExtendedTabbingID
			ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[slot] = spec.ID
			ExtendedTabbing.actionEventText[slot] = g_i18n:getText("l10n_XTB_FAV_SET"..tostring(slot))..ExtendedTabbing.selectedVehicle:getName()
			g_currentMission:showBlinkingWarning(g_i18n:getText("l10n_XTB_SAVED")..tostring(slot).." ("..ExtendedTabbing.selectedVehicle:getName()..")", 2000)
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
    		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[slot] ~= nil and ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots)
    		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
			ExtendedTabbing.needsDBUpdate = true
		end
	end

	-- tab-key pressed für fastTab or tab-key pressed to end extended tabbing mode
	if not ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		local spec = ExtendedTabbing.selectedVehicle.spec_ExtendedTabbingID
		g_currentMission:requestToEnterVehicle(ExtendedTabbing:getVehicleByID(spec.ID))
		ExtendedTabbing.selectedVehicle = nil
		ExtendedTabbing.selectedDistance = 0
		ExtendedTabbing.previewTable = {}
		ExtendedTabbing.isActive = false
	end
end	

function ExtendedTabbing:updateSlots()
	if ExtendedTabbing.data[ExtendedTabbing.selfID] == nil then return; end
	local visible = ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots
	for slot=1,5 do
		local id = ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[slot]
		local vehicle = ExtendedTabbing:getVehicleByID(id)
		if vehicle ~= nil and vehicle.getIsEnterable ~= nil and (vehicle:getIsEnterable() or vehicle == g_currentMission.controlledVehicle) then
			ExtendedTabbing.actionEventText[slot] = g_i18n:getText("l10n_XTB_FAV_SET"..tostring(slot))..vehicle:getName()
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
		elseif vehicle ~= nil then
			local vehicleFarm = vehicle.ownerFarmId
			if vehicleFarm == nil then vehicleFarm = 0; end
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], g_i18n:getText("l10n_XTB_FAV"..tostring(slot).."_LOCKED")..tostring(vehicleFarm))
		else
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], g_i18n:getText("l10n_XTB_FAV"..tostring(slot).."_FREE"))
		end
   		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], visible)
   		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
	end
end
            
function ExtendedTabbing:update(dt)
	-- Show information if vehicles couldn't reassigned completely
	if g_currentMission.isMissionStarted and ExtendedTabbing.vehiclesHaveChanged and g_currentMission.hud ~= nil and g_dedicatedServerInfo == nil then
		dbgprint("update : show info message")
		local slot = {}
		for i=1,5 do
			local id = ExtendedTabbing.data[ExtendedTabbing.selfID].slotID[i]
			local vehicle = ExtendedTabbing:getVehicleByID(id)
			if vehicle ~= nil then slot[i] = vehicle:getName() else slot[i] = nil; end
			if slot[i] == nil or slot[i] == "" then slot[i] = "---"; end
		end
		g_currentMission.hud:showInGameMessage(g_i18n:getText("l10n_XTB_VEHICLELIST_HEADLINE"), string.format(g_i18n:getText("l10n_XTB_VEHICLELIST_CHANGED"), slot[1], slot[2], slot[3], slot[4], slot[5]), -1, nil, nil, nil)
		ExtendedTabbing.vehiclesHaveChanged = false
	end
	-- Update ActionEventTexts
	if g_currentMission.isMissionStarted and ExtendedTabbing.initSlotKeys and g_currentMission.hud ~= nil and g_dedicatedServerInfo == nil then
		ExtendedTabbing:updateSlots()
		ExtendedTabbing.initSlotKeys = false
	end
	-- Show info if assigned farm has changed
	if g_currentMission.isMissionStarted and ExtendedTabbing.farmID ~= g_currentMission.player.farmId and g_currentMission.hud ~= nil and g_dedicatedServerInfo == nil then
		dbgprint("update : farm changed from "..tostring(ExtendedTabbing.farmID).." to "..tostring(g_currentMission.player.farmId))
		ExtendedTabbing.farmID = g_currentMission.player.farmId
		ExtendedTabbing:updateSlots()
	end	
	-- Show tab-selection list
	if ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(1,1,1,1)
		dbgprint("onUpdate : previewTable")
		dbgprint_r(ExtendedTabbing.previewTable)
		for n = -2,2 do
			if n == 0 then setTextColor(1,1,1,1) else setTextColor(1,1,1,0.5) end
			local previewDistance = ExtendedTabbing.previewTable[n]
			local previewIndex = ExtendedTabbing.previewIndexTable[n]
			if previewDistance ~= nil then 
				local showLine = false
				local lastDistance = 0
				if n > -2 then lastDistance = Utils.getNoNil(ExtendedTabbing.previewTable[n-1], 0); end
				if previewDistance < lastDistance then showLine = true; end
				local previewVehicle = ExtendedTabbing.vehicleTable[previewDistance]
				local spec = previewVehicle.spec_ExtendedTabbingID
				local vehicleObject
				if spec ~= nil then vehicleObject = ExtendedTabbing:getVehicleByID(spec.ID); end
				local vehicleName
				if vehicleObject ~= nil then
					vehicleName = vehicleObject:getName()
					renderText(0.5, 0.7 + (0.05 * n), 0.03 - math.abs(n) * 0.007, string.format("%.0f",previewIndex).." - "..vehicleName.." ("..string.format("%.1f",previewDistance).." m)")
					if showLine then 
						setTextBold(true)
						setTextColor(0,0,1,1)
						renderText(0.5, 0.635 + (0.05 * n) + 0.05, 0.01, "____________________________________________________________________________________________________________")
						setTextBold(false)
					end
				end
			end
		end
		if ExtendedTabbing.changingImpossible then
			renderText(0.5, 0.65, 0.03, g_i18n:getText("l10n_XTB_NOVEHICLES"))
		end
	end
	-- Update dataBase
	if ExtendedTabbing.needsDBUpdate then
		if g_currentMission:getIsServer() then 
			ExtendedTabbing:updateDataBase(ExtendedTabbing.data[ExtendedTabbing.selfID])
		end
		ExtendedTabbing.needsServerUpdate = true
		ExtendedTabbing.needsDBUpdate = false
	end
end

-- Register mod to event management
addModEventListener(ExtendedTabbing);

-- Get unique User-Id on joining
Player.load = Utils.appendedFunction(Player.load, ExtendedTabbing.loadPlayer)

-- Free space on leaving
Player.delete = Utils.prependedFunction(Player.delete, ExtendedTabbing.deletePlayer)

-- Transfer information from server to client on joining
Player.readStream = Utils.appendedFunction(Player.readStream, ExtendedTabbing.readStream)
Player.writeStream = Utils.appendedFunction(Player.writeStream, ExtendedTabbing.writeStream)

-- Update information from client to server while playing
Player.readUpdateStream = Utils.appendedFunction(Player.readUpdateStream, ExtendedTabbing.readUpdateStream)
Player.writeUpdateStream = Utils.appendedFunction(Player.writeUpdateStream, ExtendedTabbing.writeUpdateStream)

-- Include database-information while saving gamedata
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ExtendedTabbing.saveDataBase)

-- Include specialization into enterable vehicles
if g_specializationManager:getSpecializationByName("ExtendedTabbingID") == nil then
  local specName = g_currentModName
  g_specializationManager:addSpecialization("ExtendedTabbingID", "ExtendedTabbingID", g_currentModDirectory.."extendedTabbingID.lua", nil)
  for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
    if SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations) then
      	g_vehicleTypeManager:addSpecialization(typeName, specName..".ExtendedTabbingID")
		dbgprint("ExtendedTabbingID registered for "..typeName)
    end
  end
end

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end
