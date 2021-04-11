-- TabNext Warning for LS 19
--
-- Author: Martin Eller
-- Version: 0.9.4.4
-- Code review

ExtendedTabbing = {}

-- general data
ExtendedTabbing.tabIndex = 1
ExtendedTabbing.indexTable = {}
ExtendedTabbing.vehicleTable = {}
ExtendedTabbing.selectedVehicle = {}
ExtendedTabbing.isActive = false
ExtendedTabbing.needsUpdate = false
ExtendedTabbing.showSlots = true
ExtendedTabbing.vehiclesHaveChanged = false

ExtendedTabbing.actionEvents = {}

ExtendedTabbing.actionEventText = {}
ExtendedTabbing.actionEventText[1] = g_i18n:getText("l10n_XTB_FAV1_FREE")
ExtendedTabbing.actionEventText[2] = g_i18n:getText("l10n_XTB_FAV2_FREE")
ExtendedTabbing.actionEventText[3] = g_i18n:getText("l10n_XTB_FAV3_FREE")

-- local player data
ExtendedTabbing.data = {}
ExtendedTabbing.data.playerID = ""
ExtendedTabbing.data.playerName = ""
ExtendedTabbing.data.slot = {0, 0, 0}
ExtendedTabbing.data.slotName = {"", "", ""}

-- client player data (used for tranfer)
ExtendedTabbing.clientData = {}
ExtendedTabbing.clientData.playerID = ""
ExtendedTabbing.clientData.playerName = ""
ExtendedTabbing.clientData.slot = {0, 0, 0}
ExtendedTabbing.clientData.slotName = {"", "", ""}

-- all player data
ExtendedTabbing.dataBase = {}
ExtendedTabbing.dataBase.playerID = ""
ExtendedTabbing.dataBase.playerName = ""
ExtendedTabbing.dataBase.slot = {0, 0, 0}
ExtendedTabbing.dataBase.slotName = {"", "", ""}

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
	
		
	for slot=1,3 do
		_, ExtendedTabbing.actionEvents[slot] = g_inputBinding:registerActionEvent('XTB_FAV'..tostring(slot), self, ExtendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
		g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
   		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.showSlots)
   		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
	end
end

function ExtendedTabbing:loadMap(name)
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ExtendedTabbing.registerActionEvents);
	
	-- debug printing
	--print("ExtendedTabbing :: loadMap : started")
	
	-- Load Database if MP-Server or SP
	if g_currentMission:getIsServer() then
		print("ExtendedTabbing :: loadMap : Gameserver: Loading DB")
		if  g_currentMission.missionInfo.savegameDirectory ~= nil then
			local dataBaseFile = g_currentMission.missionInfo.savegameDirectory .. "/extendedtabbing.xml"
			if fileExists(dataBaseFile) then
				local xmlFile = loadXMLFile("dataBase", dataBaseFile)
				local xmlPlayerKey = ""				

				local loadedEntry = {}	
				loadedEntry.slot = {0, 0, 0}
				loadedEntry.slotName = {}
					
				ExtendedTabbing.dataBase = {}	

				local xmlPlayerID
				local xmlPlayerName
				local xmlSlot1
				local xmlSlot1Name
				local xmlSlot2
				local xmlSlot2Name
				local xmlSlot3
				local xmlSlot3Name
				
				local i = 0

				while (true) do
					xmlPlayerKey = string.format("ExtendedTabbing.player(%d)#", i)
					
					xmlPlayerID  	= xmlPlayerKey .. "playerID"
					xmlPlayerName 	= xmlPlayerKey .. "playerName"
					xmlSlot1		= xmlPlayerKey .. "slot1"
					xmlSlot2		= xmlPlayerKey .. "slot2"
					xmlSlot3		= xmlPlayerKey .. "slot3"
					xmlSlot1Name	= xmlPlayerKey .. "slot1name"
					xmlSlot2Name	= xmlPlayerKey .. "slot2name"
					xmlSlot3Name	= xmlPlayerKey .. "slot3name"

					if not hasXMLProperty(xmlFile, xmlPlayerID) then break; end;
					
					loadedEntry.playerID 	= getXMLString(xmlFile, xmlPlayerID)
					loadedEntry.playerName 	= getXMLString(xmlFile, xmlPlayerName)
					if hasXMLProperty(xmlFile, xmlSlot1) then loadedEntry.slot[1]	= getXMLInt(xmlFile, xmlSlot1); end
					if hasXMLProperty(xmlFile, xmlSlot1Name) then loadedEntry.slotName[1]	= getXMLString(xmlFile, xmlSlot1Name); end
					if hasXMLProperty(xmlFile, xmlSlot2) then loadedEntry.slot[2]	= getXMLInt(xmlFile, xmlSlot2); end
					if hasXMLProperty(xmlFile, xmlSlot2Name) then loadedEntry.slotName[2]	= getXMLString(xmlFile, xmlSlot2Name); end
					if hasXMLProperty(xmlFile, xmlSlot3) then loadedEntry.slot[3]	= getXMLInt(xmlFile, xmlSlot3); end
					if hasXMLProperty(xmlFile, xmlSlot3Name) then loadedEntry.slotName[3]	= getXMLString(xmlFile, xmlSlot3Name); end
					
					i = i + 1
					
					if ExtendedTabbing.dataBase.PlayerID == "" then
						ExtendedTabbing.dataBase = {}
					end
					table.insert(ExtendedTabbing.dataBase, loadedEntry)
					
				-- Debug printing
					--print("ExtendedTabbing :: loadMap : Step "..tostring(i)..": Database state:")
					--print_r(ExtendedTabbing.dataBase)
				end
			-- 	Debug printing
				print("ExtendedTabbing :: loadMap : Database loading finished")
			--	--
			else
				print("ExtendedTabbing :: loadMap : No database to load, starting with empty one")
				ExtendedTabbing.dataBase = {}
			end
		else
			print("ExtendedTabbing :: loadMap : Error: savegameDir not found")
			ExendedTabbing.dataBase = {}
		end
	else
		print("ExtendedTabbing :: loadMap : Just client, no database needed")
		ExtendedTabbing.dataBase = {}
	end
	
	-- debug printing
	--print("ExtendedTabbing :: loadMap : ended")
end

-- Grundlegende Informationen speichern: Relevant für MP-Server und SP, nicht notwendig für MP-Client
-- Ausführung bei jedem Speichervorgang
function ExtendedTabbing.saveDataBase(missionInfo)

--	debug printing
	print("ExtendedTabbing :: saveDataBase : starting")
	--print_r(ExtendedTabbing.dataBase)
--	--
	local dataBaseFile = missionInfo.savegameDirectory .. "/extendedtabbing.xml"
	local xmlFile = createXMLFile("dataBase", dataBaseFile, "ExtendedTabbing")
	
	if xmlFile == nil then 
		print("ExtendedTabbing :: saveDataBase : Error: Couldn't save dataBase")
		return false; 
	end;
	
	local i = 0
	for _, dbEntry in pairs(ExtendedTabbing.dataBase) do
		if dbEntry.slot ~= nil and (dbEntry.slot[1] ~= 0 or dbEntry.slot[2] ~= 0 or dbEntry.slot[3] ~= 0) then
			xmlPlayerKey 	= string.format("ExtendedTabbing.player(%d)#", i)
			xmlPlayerID  	= xmlPlayerKey .. "playerID"
			xmlPlayerName 	= xmlPlayerKey .. "playerName"
			xmlSlot1		= xmlPlayerKey .. "slot1"
			xmlSlot2		= xmlPlayerKey .. "slot2"
			xmlSlot3		= xmlPlayerKey .. "slot3"
			xmlSlot1Name	= xmlPlayerKey .. "slot1name"
			xmlSlot2Name	= xmlPlayerKey .. "slot2name"
			xmlSlot3Name	= xmlPlayerKey .. "slot3name"
			setXMLString(xmlFile, xmlPlayerID, dbEntry.playerID)
			setXMLString(xmlFile, xmlPlayerName, dbEntry.playerName)
			if dbEntry.slot[1] ~= nil then setXMLInt(xmlFile, xmlSlot1, dbEntry.slot[1]) end
			if dbEntry.slotName[1] ~= nil then setXMLString(xmlFile, xmlSlot1Name, dbEntry.slotName[1]); end
			if dbEntry.slot[2] ~= nil then setXMLInt(xmlFile, xmlSlot2, dbEntry.slot[2]) end
			if dbEntry.slotName[2] ~= nil then setXMLString(xmlFile, xmlSlot2Name, dbEntry.slotName[2]); end
			if dbEntry.slot[3] ~= nil then setXMLInt(xmlFile, xmlSlot3, dbEntry.slot[3]) end
			if dbEntry.slotName[3] ~= nil then setXMLString(xmlFile, xmlSlot3Name, dbEntry.slotName[3]); end
		-- 	Debug printing
			print("ExtendedTabbing :: saveDataBase : saved entry for "..tostring(dbEntry.playerName))
		--	--
		else
		--	Debug printing
			print("ExtendedTabbing :: saveDataBase : nothing to save for "..tostring(dbEntry.playerName))
		--	--
		end
		i = i + 1
	end
	saveXMLFile(xmlFile)
	delete(xmlFile)
--	debug printing
	print("ExtendedTabbing :: saveDataBase : ending")
--	--
	
end 

function ExtendedTabbing:loadPlayer(xmlFilename, playerStyle, creatorConnection, isOwner)
	if g_currentMission:getIsServer() then 
		local userId = self.userId
		local localUser = (g_currentMission.player == nil) -- On first load, Player isn't initiated
		local loadEntry = {}
		
	-- 	debug printing
		--print("ExtendedTabbing :: loadPlayer : loadUserId for UserId: "..tostring(userId))
	--	--
	
		local user = g_currentMission.userManager:getUserByUserId(userId)
		if user == nil then 
			print("ExtendedTabbing :: loadPlayer : Error: Server-Mode, but no user given. Aborting...")
			return false 
		end
		loadEntry.playerID = user.uniqueUserId
		loadEntry.playerName = user.nickname
		loadEntry.slot = {0, 0, 0}
		loadEntry.slotName = {}

	-- 	debug printing
		print("ExtendedTabbing :: loadPlayer : Player: "..tostring(loadEntry.playerName))
		--print("ExtendedTabbing :: loadPlayer : PlayerID: "..tostring(loadEntry.playerID))
	--	--

	-- Individuelle Informationen für den jeweiligen Spieler aus der DB abrufen oder anlegen
		local found = false
		for _, entry in pairs(ExtendedTabbing.dataBase) do
			if entry.playerID == loadEntry.playerID then
				found = true
				for i = 1, 3 do
					loadEntry.slot[i] = entry.slot[i]
					loadEntry.slotName[i] = entry.slotName[i]
				end
				break
			end
		end
		if not found then 
			table.insert(ExtendedTabbing.dataBase, loadEntry); 
	
		--	debug printing
			print("ExtendedTabbing :: loadPlayerData : added to dataBase:")
			--print_r(ExtendedTabbing.dataBase)
		--	--
		
		end
		
		if localUser then
			for i=1,3 do
				local vehicle = ExtendedTabbing:getVehicleById(loadEntry.slot[i])
				if vehicle == nil or loadEntry.slotName[i] ~= vehicle:getName() then
					loadEntry.slot[i] = 0
					ExtendedTabbing.vehiclesHaveChanged = true
				elseif found then
					ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET")..loadEntry.slotName[i]
					if ExtendedTabbing.actionEvents[i] ~= nil then
						g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[i], ExtendedTabbing.actionEventText[i])
					end
				end
			end
			ExtendedTabbing.data = loadEntry
		else
			ExtendedTabbing.clientData = loadEntry
		end
		
	--	debug printing
		--print("ExtendedTabbing :: loadPlayerData : loaded data:")
		--print_r(ExtendedTabbing.data)
		--print_r(ExtendedTabbing.clientData)
	--	--
	end
end


-- Initiale Übertragung der DB vom Server zum Client (Server-Seite)
function ExtendedTabbing:writeStream(streamId, connection)
-- 	debug printing
	--print("ExtendedTabbing :: writeStream : starting")
--	--
	if not connection.isServer then

	-- 	Debug printing
		--print("ExtendedTabbing :: writeStream : writing data for "..ExtendedTabbing.clientData.playerName)
	--	--

		streamWriteString(streamId, ExtendedTabbing.clientData.playerID)
		streamWriteString(streamId, ExtendedTabbing.clientData.playerName)
		
		for i = 1, 3 do
			streamWriteInt16(streamId, ExtendedTabbing.clientData.slot[i])
			if ExtendedTabbing.clientData.slotName[i] == nil then
				ExtendedTabbing.clientData.slotName[i] = ""
			end
			streamWriteString(streamId, ExtendedTabbing.clientData.slotName[i])
		end
	end
end

-- Inittiale Übertragung der DB vom Server zum Client (Client-Seite)
function ExtendedTabbing:readStream(streamId, connection)
-- 	debug printing
	--print("ExtendedTabbing :: readStream : starting")
--	--
	if connection.isServer then
		ExtendedTabbing.data.playerID = streamReadString(streamId)
		ExtendedTabbing.data.playerName = streamReadString(streamId)
		
		-- 	Debug printing
			--print("ExtendedTabbing :: readStream : reading data for "..ExtendedTabbing.data.playerName)
		--	--
		
		for i = 1, 3 do
			ExtendedTabbing.data.slot[i] = streamReadInt16(streamId)
			local vehicleName = streamReadString(streamId)
			local vehicle = ExtendedTabbing:getVehicleById(ExtendedTabbing.data.slot[i])
			if vehicle == nil or vehicleName ~= vehicle:getName() then
				ExtendedTabbing.data.slot[i] = 0
				ExtendedTabbing.vehiclesHaveChanged = true
			else
				ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET")..vehicleName
			end	
		end
	end
end

function ExtendedTabbing:writeUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		streamWriteBool(streamId, ExtendedTabbing.needsUpdate)
		if ExtendedTabbing.needsUpdate then
		
		-- 	Debug printing
			--print("ExtendedTabbing :: writeUpdateStream : Starting")
		--	--

			streamWriteString(streamId, ExtendedTabbing.data.playerID)
			streamWriteString(streamId, ExtendedTabbing.data.playerName)
			for i = 1, 3 do
				streamWriteInt16(streamId, ExtendedTabbing.data.slot[i])
				local vehicleName
				if ExtendedTabbing.data.slot[i] == 0 or ExtendedTabbing:getVehicleById(ExtendedTabbing.data.slot[i]) == nil then
					vehicleName = ""
				else
					vehicleName = ExtendedTabbing:getVehicleById(ExtendedTabbing.data.slot[i]):getName()
				end
				streamWriteString(streamId, vehicleName)
			end
		--	Debug printing
			--print("ExtendedTabbing :: writeUpdateStream : Data transmitted")
		--	--
			ExtendedTabbing.needsUpdate = false
		end
	end
end

function ExtendedTabbing:readUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		if streamReadBool(streamId) then
			local loadEntry = {}
			loadEntry.slot = {}
			loadEntry.slotName={}
		
		-- 	Debug printing
			--print("ExtendedTabbing :: readUpdateStream : Starting")
		--	--

			loadEntry.playerID = streamReadString(streamId)
			loadEntry.playerName = streamReadString(streamId)
			for i = 1, 3 do
				loadEntry.slot[i] = streamReadInt16(streamId)
				loadEntry.slotName[i] = streamReadString(streamId)
			end
		--	Debug printing
			--print("ExtendedTabbing :: readUpdateStream : Data transmitted")
		--	--
			ExtendedTabbing:updateDataBase(loadEntry)	
		end
	end
end

-- Individuelle Informationen für den jeweiligen Spieler in die Datenbank schreiben: Nur für MP-Server und SP
function ExtendedTabbing:updateDataBase(updateEntry)
--	debug printing
	--print("ExtendedTabbing :: updateDataBase : updateEntry:")
	--print_r(updateEntry)
	--print("Local data:")
	--print_r(ExtendedTabbing.data)
	--print("Client data:")
	--print_r(ExtendedTabbing.clientData)
	--print("Old Database:")
	--print_r(ExtendedTabbing.dataBase)
--	--

	local playerAnz = table.maxn(ExtendedTabbing.dataBase)
	local dbEntry
	local dbDupFinder = {}
	local newDataBase = {}
	for i = 1, playerAnz do
		dbEntry = table.remove(ExtendedTabbing.dataBase)
		
		local dup = dbDupFinder[dbEntry.playerID]
		if dup == nil then 
			dup = false
		else
			dup = true
		end
		dbDupFinder[dbEntry.playerID] = dup
		
		--print("i = "..tostring(i)..": dbEntry:")
		--print_r(dbEntry)
		--print("DupFinder: "..tostring(dup))
		
		if dbEntry.playerID == updateEntry.playerID then
			dbEntry = updateEntry
		end
		if not dbDupFinder[dbEntry.playerID] then table.insert(newDataBase, dbEntry); end
	end
	ExtendedTabbing.dataBase = newDataBase
	-- debug printing
		--print("New Database:")
		--print_r(ExtendedTabbing.dataBase)
		--	--
end

-- Hauptfunktionen --
function ExtendedTabbing:toggleHelp()
	ExtendedTabbing.showSlots = not ExtendedTabbing.showSlots
	for slot=1,3 do
   		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.showSlots)
	end
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
	
	ExtendedTabbing.selectedVehicle = ExtendedTabbing.vehicleTable[ExtendedTabbing.indexTable[ExtendedTabbing.tabIndex]] 
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
	
	local nextVehicle = ExtendedTabbing.vehicleTable[ExtendedTabbing.indexTable[ExtendedTabbing.tabIndex]]
	ExtendedTabbing.selectedVehicle = nextVehicle
end

--[[ Denkanstoß: Realisierung mit Hilfe von g_currentMission.enterables effizienter? ]]-- 

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
	
	if actionName == "XTB_EXECTAB" or actionName == "XTB_FASTTAB" then ExtendedTabbing.isActive = false; end
	
	-- slot-key pressed to tab into vehicle
	if not ExtendedTabbing.isActive and slot ~= 0 then
		local selectedId = ExtendedTabbing.data.slot[slot]
		ExtendedTabbing.selectedVehicle = ExtendedTabbing:getVehicleById(selectedId)
	end
	
	-- slot-key pressed to store vehicle into slot
	if ExtendedTabbing.isActive and slot ~= 0 then
		if ExtendedTabbing.selectedVehicle ~= nil then
			ExtendedTabbing.data.slot[slot] = ExtendedTabbing.selectedVehicle.id
			ExtendedTabbing.data.slotName[slot] = ExtendedTabbing.selectedVehicle:getName()
			--g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"), 2000)
			ExtendedTabbing.actionEventText[i] = g_i18n:getText("l10n_XTB_FAV_SET")..ExtendedTabbing.selectedVehicle:getName()
			g_currentMission:showBlinkingWarning(g_i18n:getText("l10n_XTB_SAVED")..tostring(slot).." ("..ExtendedTabbing.selectedVehicle:getName()..")", 2000)
			g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
    		g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.data.slot[slot] ~= nil)
    		g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_NORMAL)
			ExtendedTabbing.needsUpdate = true
		end
	end
	
	-- slot-key pressed: re-register actionEvent
	if slot ~= 0 then
		--Player:registerActionEvents()
		--_, ExtendedTabbing.actionEvents[slot] = g_inputBinding:registerActionEvent('XTB_FAV'..tostring(slot), self, ExtendedTabbing.tabToSelectedVehicle, false, true, false, true, nil)
		--Player:updateActionEvents()
	end
	
	-- tab-key pressed für fastTab or tab-key pressed to end extended tabbing mode
	if not ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		g_currentMission:requestToEnterVehicle(ExtendedTabbing.selectedVehicle)
		ExtendedTabbing.selectedVehicle = nil
		ExtendedTabbing.isActive = false
	end
end	
            
function ExtendedTabbing:update(dt)	
	if ExtendedTabbing.isActive and ExtendedTabbing.selectedVehicle ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, 0.7, 0.03, "--> "..ExtendedTabbing.selectedVehicle:getName())
	end
	if ExtendedTabbing.needsUpdate then
		if g_currentMission:getIsServer() then 
			ExtendedTabbing:updateDataBase(ExtendedTabbing.data)
			ExtendedTabbing.needsUpdate = false
		end
	end
end

function ExtendedTabbing:updatePlayerActionEvents()
	for slot=1,3 do
		g_inputBinding:setActionEventText(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.actionEventText[slot])
    	g_inputBinding:setActionEventTextVisibility(ExtendedTabbing.actionEvents[slot], ExtendedTabbing.data.slot[slot] ~= nil)
    	g_inputBinding:setActionEventTextPriority(ExtendedTabbing.actionEvents[slot], GS_PRIO_HIGH)
    	print("Update: "..ExtendedTabbing.actionEventText[slot])
    end
	-- _, ExtendedTabbing.actionEvents[1] = g_inputBinding:addActionEvent('XTB_FAV1', self, ExtendedTabbing.tabToSelectedVehicle, false, true, false, true, nil, true)
end

-- Register mod to event management
addModEventListener(ExtendedTabbing);

-- Load Database on start -- realized by "loadMap"
-- Mission00.load = Utils.appendedFunction(Mission00.load, ExtendedTabbing.loadDataBase)

-- Get unique User-Id on joining
Player.load = Utils.appendedFunction(Player.load, ExtendedTabbing.loadPlayer)

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
