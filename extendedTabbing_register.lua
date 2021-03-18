--
-- register
--
-- Martin Eller 
-- Version 0.0.1.2
--

if g_specializationManager:getSpecializationByName("extendedTabbing") == nil then

  g_specializationManager:addSpecialization("extendedTabbing", "extendedTabbing", g_currentModDirectory.."extendedTabbing.lua", true, nil)

  for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
    
    if    
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
    and  	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
    and  	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    and not	SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
    
	then
      g_vehicleTypeManager:addSpecialization(typeName, "extendedTabbing")
      print("Extended Tabbing registered for "..typeName)
    end
  end
end
