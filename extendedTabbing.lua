-- Extended Tabbing for LS 19
--
-- Author: Jason06 / Glowins Mod-Schmiede
-- Version: 1.0.1.0


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
ExtendedTabbing.isActive = false
ExtendedTabbing.needsServerUpdate = false
ExtendedTabbing.needsDBUpdate = false
ExtendedTabbing.vehiclesHaveChanged = false
ExtendedTabbing.selfID = 0

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
		g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
		local visible
		if ExtendedTabbing.data[ExtendedTabbing.selfID] == nil then 
			visible = true
		else
			visible = ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots
		end
   		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], visible)
   		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
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
	
	-- Load Database if MP-Server or SP
	if g_currentMission:getIsServer() then
		print("ExtendedTabbing :: loadMap : Gameserver: Loading DB")
		if  g_currentMission.missionInfo.savegameDirectory ~= nil then
			local dataBaseFile = g_currentMission.missionInfo.savegameDirectory .. "/extendedtabbing.xml"
			if fileExists(dataBaseFile) then
				local xmlFile = loadXMLFile("dataBase", dataBaseFile)
				local xmlPlayerKey = ""	
				
				local loadedEntry
				local xmlPlayerID
				local xmlPlayerName
				local xmlShowSlots
				local xmlSlot={}
				local xmlSlotName={}
				
				local pkey = 0
				while (true) do
					loadedEntry = {}	
					loadedEntry.playerID = ""
					loadedEntry.playerName = ""
					loadedEntry.showSlots = true
					loadedEntry.slot = {0, 0, 0, 0, 0}
					loadedEntry.slotName = {"", "", "", "", ""}
					
					xmlPlayerKey = string.format("ExtendedTabbing.player(%d)#", pkey)
					
					xmlPlayerID  	= xmlPlayerKey .. "playerID"
					xmlPlayerName 	= xmlPlayerKey .. "playerName"
					xmlShowSlots	= xmlPlayerKey .. "showSlots"
					for s=1,5 do
					    xmlSlot[s] = xmlPlayerKey .. "slot"..tostring(s)
					    xmlSlotName[s] = xmlPlayerKey .. "slot"..tostring(s).."name"
					end
					
					if not hasXMLProperty(xmlFile, xmlPlayerID) then break; end;
					
					loadedEntry.playerID 	= getXMLString(xmlFile, xmlPlayerID)
					loadedEntry.playerName 	= getXMLString(xmlFile, xmlPlayerName)
					
					if hasXMLProperty(xmlFile, xmlShowSlots) then 
						loadedEntry.showSlots = getXMLBool(xmlFile, xmlShowSlots)
					else	
						loadedEntry.showSlots = true
					end
					
					for s=1,5 do
					    if hasXMLProperty(xmlFile, xmlSlot[s]) then loadedEntry.slot[s] = getXMLInt(xmlFile, xmlSlot[s]); end
					    if hasXMLProperty(xmlFile, xmlSlotName[s]) then loadedEntry.slotName[s] = getXMLString(xmlFile, xmlSlotName[s]); end
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

	local dataBaseFile = missionInfo.savegameDirectory .. "/extendedtabbing.xml"
	local xmlFile = createXMLFile("dataBase", dataBaseFile, "ExtendedTabbing")
	
	if xmlFile == nil then 
		print("ExtendedTabbing :: saveDataBase : Error: Couldn't save dataBase")
		return false; 
	end;
	
	local xmlPlayerKey
	local xmlPlayerID
	local xmlPlayerName
	local xmlShowSlots
	local xmlSlot={}
	local xmlSlotName={}
	
	local pkey = 0
	for _, dbEntry in pairs(ExtendedTabbing.dataBase) do
		if dbEntry.slot ~= nil and dbEntry.playerID ~= nil and dbEntry.playerID ~= "" then
			xmlPlayerKey 	= string.format("ExtendedTabbing.player(%d)#",pkey)
			xmlPlayerID  	= xmlPlayerKey .. "playerID"
			xmlPlayerName = xmlPlayerKey .. "playerName"
			xmlShowSlots	= xmlPlayerKey .. "showSlots"
			setXMLString(xmlFile, xmlPlayerID, dbEntry.playerID)
			setXMLString(xmlFile, xmlPlayerName, dbEntry.playerName)
			setXMLBool(xmlFile, xmlShowSlots, dbEntry.showSlots)
			for s=1,5 do
				xmlSlot[s] = xmlPlayerKey.."slot"..tostring(s)
				xmlSlotName[s] = xmlPlayerKey.."slot"..tostring(s).."name"
				if dbEntry.slot[s] ~= nil then setXMLInt(xmlFile, xmlSlot[s], dbEntry.slot[s]); end
				if dbEntry.slotName[s] ~= nil then setXMLString(xmlFile, xmlSlotName[s], dbEntry.slotName[s]); end
			end
			print("ExtendedTabbing :: saveDataBase : saved entry for "..tostring(dbEntry.playerName))
		else
			print("ExtendedTabbing :: saveDataBase : nothing to save for "..tostring(dbEntry.playerName))
		end
		pkey = pkey + 1
	end
	saveXMLFile(xmlFile)
	delete(xmlFile)
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
		loadEntry.slot = {0, 0, 0, 0, 0}
		loadEntry.slotName = {"", "", "", "", ""}

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
					loadEntry.slot[i] = ExtendedTabbing.dataBase[n].slot[i]
					loadEntry.slotName[i] = ExtendedTabbing.dataBase[n].slotName[i]
					if loadEntry.slot[i] == nil then loadEntry.slot[i] = 0; end
					if loadEntry.slotName[i] == nil then loadEntry.slotName[i] = ""; end
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
				local vehicle = ExtendedTabbing:getVehicleById(loadEntry.slot[i])
				if vehicle == nil or loadEntry.slotName[i] ~= vehicle:getName() then
					loadEntry.slot[i] = 0
					loadEntry.slotName[i] = ""
					ExtendedTabbing.vehiclesHaveChanged = true
				elseif found then
					ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET")..loadEntry.slotName[i]
					if ExtendedTabbing.actionEvents[i] ~= nil then
						g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[i], ExtendedTabbing.actionEventText[i])
						g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[i], loadEntry.showSlots)
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
			streamWriteInt16(streamId, ExtendedTabbing.data[userId].slot[i])
			if ExtendedTabbing.data[userId].slotName[i] == nil then
				ExtendedTabbing.data[userId].slotName[i] = ""
			end
			streamWriteString(streamId, ExtendedTabbing.data[userId].slotName[i])
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
		
		loadEntry.slot = {0, 0, 0, 0, 0}
		loadEntry.slotName = {"", "", "", "", ""}
		for i = 1, 5 do
			loadEntry.slot[i] = streamReadInt16(streamId)
			loadEntry.slotName[i] = streamReadString(streamId)
		end
		
		if loadedUserId == ExtendedTabbing.selfID then
			dbgprint("readStream : accepting data for "..loadEntry.playerName)
			ExtendedTabbing.data[ExtendedTabbing.selfID] = {}
			ExtendedTabbing.data[ExtendedTabbing.selfID].slot = {0, 0, 0, 0, 0}
			ExtendedTabbing.data[ExtendedTabbing.selfID].slotName = {"", "", "", "", ""}
			ExtendedTabbing.data[ExtendedTabbing.selfID].playerID = loadEntry.playerID
			ExtendedTabbing.data[ExtendedTabbing.selfID].playerName = loadEntry.playerName
			ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots = loadEntry.showSlots
			for i = 1, 5 do
				ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i] = loadEntry.slot[i]
				ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[i] = loadEntry.slotName[i]
				local vehicle = ExtendedTabbing:getVehicleById(ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i])
				if vehicle == nil or ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[i] ~= vehicle:getName() then
					ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i] = 0
					ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[i] = ""
					ExtendedTabbing.vehiclesHaveChanged = true
				else
					ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET")..ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[i]
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
				streamWriteInt16(streamId, ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i])
				local vehicleName
				if ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i] == 0 or ExtendedTabbing:getVehicleById(ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i]) == nil then
					vehicleName = ""
				else
					vehicleName = ExtendedTabbing:getVehicleById(ExtendedTabbing.data[ExtendedTabbing.selfID].slot[i]):getName()
				end
				streamWriteString(streamId, vehicleName)
				ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[i] = vehicleName
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
			loadEntry.slot = {0, 0, 0, 0, 0}
			loadEntry.slotName={"", "", "", "", ""}

			dbgprint("readUpdateStream : Starting")
			
			loadEntry.playerID = streamReadString(streamId)
			loadEntry.playerName = streamReadString(streamId)
			loadEntry.showSlots = streamReadBool(streamId)
			for i = 1, 5 do
				loadEntry.slot[i] = streamReadInt16(streamId)
				loadEntry.slotName[i] = streamReadString(streamId)
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
			ExtendedTabbing.dataBase[i].slot = {0, 0, 0, 0, 0}
			ExtendedTabbing.dataBase[i].slotName = {"", "", "", "", ""}
			for slot=1,5 do
				ExtendedTabbing.dataBase[i].slot[slot] = updateEntry.slot[slot]
				ExtendedTabbing.dataBase[i].slotName[slot] = updateEntry.slotName[slot]
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
		ExtendedTabbing.dataBase[newPos].slot = {0, 0, 0, 0, 0}
		ExtendedTabbing.dataBase[newPos].slotName = {"", "", "", "", ""}
		for slot=1,5 do
			ExtendedTabbing.dataBase[newPos].slot[slot] = updateEntry.slot[slot]
			ExtendedTabbing.dataBase[newPos].slotName[slot] = updateEntry.slotName[slot]
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

function ExtendedTabbing:findNearestVehicle(actionName, keyStatus, arg3, arg4, arg5)
	if ExtendedTabbing.isActive and actionName == "XTB_EXECTAB" then
		ExtendedTabbing:tabToSelectedVehicle(actionName, keyStatus, arg3, arg4, arg5)
		return
	end
	
	ExtendedTabbing.isActive = true
	
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
	
	ExtendedTabbing.selectedDistance = ExtendedTabbing.indexTable[ExtendedTabbing.tabIndex]
	ExtendedTabbing.selectedVehicle = ExtendedTabbing.vehicleTable[ExtendedTabbing.selectedDistance] 
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
end

function ExtendedTabbing:getVehicleById(vehicleId)
	for _, vehicle in pairs(g_currentMission.vehicles) do
		if vehicle.id == vehicleId then
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
		local selectedId = ExtendedTabbing.data[ExtendedTabbing.selfID].slot[slot]
		ExtendedTabbing.selectedVehicle = ExtendedTabbing:getVehicleById(selectedId)
		ExtendedTabbing.selectedDistance = 0
	end
	
	-- slot-key pressed to store vehicle into slot
	if ExtendedTabbing.isActive and slot ~= 0 then
		if ExtendedTabbing.selectedVehicle ~= nil then
			ExtendedTabbing.data[ExtendedTabbing.selfID].slot[slot] = ExtendedTabbing.selectedVehicle.id
			ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[slot] = ExtendedTabbing.selectedVehicle:getName()
			ExtendedTabbing.actionEventText[slot] = g_i18n:getText("l10n_XTB_FAV_SET")..ExtendedTabbing.selectedVehicle:getName()
			g_currentMission:showBlinkingWarning(g_i18n:getText("l10n_XTB_SAVED")..tostring(slot).." ("..ExtendedTabbing.selectedVehicle:getName()..")", 2000)
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
    		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.data[ExtendedTabbing.selfID].slot[slot] ~= nil and ExtendedTabbing.data[ExtendedTabbing.selfID].showSlots)
    		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_NORMAL)
			ExtendedTabbing.needsDBUpdate = true
		end
	end

	-- tab-key pressed für fastTab or tab-key pressed to end extended tabbing mode
	if not ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		g_currentMission:requestToEnterVehicle(ExtendedTabbing.selectedVehicle)
		ExtendedTabbing.selectedVehicle = nil
		ExtendedTabbing.selectedDistance = 0
		ExtendedTabbing.isActive = false
	end
end	
            
function ExtendedTabbing:update(dt)
	if g_currentMission.isMissionStarted and ExtendedTabbing.vehiclesHaveChanged and g_currentMission.hud ~= nil and g_dedicatedServerInfo == nil then
		dbgprint("update : show info message")
		local slot1 = ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[1]
		if slot1 == nil or slot1 == "" then slot1 = "---"; end
		local slot2 = ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[2]
		if slot2 == nil or slot2 == "" then slot2 = "---"; end
		local slot3 = ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[3]
		if slot3 == nil or slot3 == "" then slot3 = "---"; end
		local slot4 = ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[4]
		if slot4 == nil or slot4 == "" then slot4 = "---"; end
		local slot5 = ExtendedTabbing.data[ExtendedTabbing.selfID].slotName[5]
		if slot5 == nil or slot5 == "" then slot5 = "---"; end
		g_currentMission.hud:showInGameMessage(g_i18n:getText("l10n_XTB_VEHICLELIST_HEADLINE"), string.format(g_i18n:getText("l10n_XTB_VEHICLELIST_CHANGED"), slot1, slot2, slot3, slot4, slot5), -1, nil, nil, nil)
		ExtendedTabbing.vehiclesHaveChanged = false
	end
	if ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, 0.7, 0.03, "--> "..ExtendedTabbing.selectedVehicle:getName().." ("..string.format("%.1f",ExtendedTabbing.selectedDistance).." m)")
	end
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

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end
