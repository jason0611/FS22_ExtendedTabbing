--
-- register
--
-- Martin Eller 
-- Version 0.0.1.0
--

if g_specializationManager:getSpecializationByName("tabNext") == nil then

  g_specializationManager:addSpecialization("tabNext", "tabNext", g_currentModDirectory.."tabNext.lua", true, nil)

  for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
    
    if    
    		SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) 
    and  	SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
    and  	SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    and not
    (
    		SpecializationUtil.hasSpecialization(Locomotive, typeEntry.specializations)
    or		SpecializationUtil.hasSpecialization(ConveyorBelt, typeEntry.specializations)
    )
    
    then
      g_vehicleTypeManager:addSpecialization(typeName, "tabNext")
      print("TabNext registered for "..typeName)
    end
  end
end
