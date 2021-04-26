--
-- Glowins Modschmiede: Debug-Tool
-- V0.9.1

GMSDebug = {}
GMSDebug.modName = "Unknown Mod"
GMSDebug.state = false
GMSDebug.consoleCommands = false

function GMSDebug:init(modName, forceDbg)
	GMSDebug.modName = modName
	GMSDebug.state = (forceDbg == true)
end

function GMSDebug:enableConsoleCommands(doit)
	if not doit then return; end
	addConsoleCommand("gmsDebug", "Glowins Mod Smithery: Toggle Debug settings", "toggleDebug", GMSDebug)
	addConsoleCommand("gmsPrint", "Glowins Mod Smithery: Debug printing", "consolePrint", GMSDebug)
	GMSDebug:print("Debug Console Commands added")
end

function GMSDebug:print(text)
	if not GMSDebug.state then return; end
	print(modName.." :: "..text)
end

function GMSDebug:print_r(table)
	if not GMSDebug.state then return; end
	GMSDebug:print("BEGIN OF "..tostring(table).." =================")
	print_r(table)
	GMSDebug:print("END OF "..tostring(table).." =================")
end

function GMSDebug:toggleDebug()
	GMSDebug.state = not GMSDebug.modState
	print("GMSDebug: New state is "..tostringGMSDebug.state)
end


function GMSDebug:consolePrint(object)
	print(modName.." :: BEGIN of "..tostring(object).." =================")
	print_r(object)
	print(modName.." :: END of "..tostring(object).." =================")
end

--

function dbgprint(text)
	GMSDebug:print(text)
end

function dbgprint_r(table)
	GMSDebug:print_r(table)
end
