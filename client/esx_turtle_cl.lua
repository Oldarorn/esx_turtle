local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PID           			= 0
local GUI           			= {}
local turtleQTE       				= 0
ESX 			    			= nil
GUI.Time            			= 0
local turtle_meatQTE 				= 0
local myJob 					= nil
local PlayerData 				= {}
local GUI 						= {}
local HasAlreadyEnteredMarker   = false
local LastZone                  = nil
local isInZone                  = false
local CurrentAction             = nil
local CurrentActionMsg          = ''
local CurrentActionData         = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

AddEventHandler('esx_turtle:hasEnteredMarker', function(zone)

        ESX.UI.Menu.CloseAll()

        if zone == 'exitMarker' then
            CurrentAction     = zone
            CurrentActionMsg  = _U('exit_marker')
            CurrentActionData = {}
        end

        --turtle process
        if zone == 'TurtleFarm' then
            if myJob ~= "police" then
                CurrentAction     = 'turtle_harvest'
                CurrentActionMsg  = _U('press_collect_turtle')
                CurrentActionData = {}
            end
        end

        if zone == 'TurtleTreatment' then
            if myJob ~= "police" then
                if turtleQTE >= 10 then
                    CurrentAction     = 'turtle_treatment'
                    CurrentActionMsg  = _U('press_process_turtle')
                    CurrentActionData = {}
                end
            end
        end

        if zone == 'TurtleResell' then
            if myJob ~= "police" then
                if turtle_meatQTE >= 1 then
                    CurrentAction     = 'turtle_resell'
                    CurrentActionMsg  = _U('press_sell_turtle')
                    CurrentActionData = {}
                end
            end
        end
    end)

AddEventHandler('esx_turtle:hasExitedMarker', function(zone)

        CurrentAction = nil
        ESX.UI.Menu.CloseAll()

        TriggerServerEvent('esx_turtle:stopHarvestTurtle')
        TriggerServerEvent('esx_turtle:stopTransformTurtle')
        TriggerServerEvent('esx_turtle:stopSellTurtle')
end)

-- Render markers
Citizen.CreateThread(function()
    while true do

        Wait(0)

        local coords = GetEntityCoords(GetPlayerPed(-1))

        for k,v in pairs(Config.Zones) do
            if(GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < Config.DrawDistance) then
                DrawMarker(Config.MarkerType, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.ZoneSize.x, Config.ZoneSize.y, Config.ZoneSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
            end
        end

    end
end)


-- RETURN NUMBER OF ITEMS FROM SERVER
RegisterNetEvent('esx_turtle:ReturnInventory')
AddEventHandler('esx_turtle:ReturnInventory', function(turtleNbr, turtlepNbr, jobName, currentZone)
	turtleQTE       = turtleNbr
	turtle_meatQTE = turtlepNbr
	myJob         = jobName
	TriggerEvent('esx_turtle:hasEnteredMarker', currentZone)
end)

-- Activate menu when player is inside marker
Citizen.CreateThread(function()
    while true do

        Citizen.Wait(10)

        local coords      = GetEntityCoords(GetPlayerPed(-1))
        local isInMarker  = false
        local currentZone = nil

        for k,v in pairs(Config.Zones) do
            if(GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < Config.ZoneSize.x / 2) then
                isInMarker  = true
                currentZone = k
            end
        end

        if isInMarker and not HasAlreadyEnteredMarker then
            HasAlreadyEnteredMarker = true
            LastZone				= currentZone
            TriggerServerEvent('esx_turtle:GetUserInventory', currentZone)
        end

        if not isInMarker and HasAlreadyEnteredMarker then
            HasAlreadyEnteredMarker = false
            TriggerEvent('esx_turtle:hasExitedMarker', LastZone)
        end

        if isInMarker and isInZone then
            TriggerEvent('esx_turtle:hasEnteredMarker', 'exitMarker')
        end

    end
end)


-- Key Controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if CurrentAction ~= nil then
            SetTextComponentFormat('STRING')
            AddTextComponentString(CurrentActionMsg)
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustReleased(0, Keys['E']) then
                isInZone = true -- unless we set this boolean to false, we will always freeze the user
                if CurrentAction == 'exitMarker' then
                    isInZone = false -- do not freeze user
                    TriggerEvent('esx_turtle:freezePlayer', false)
                    TriggerEvent('esx_turtle:hasExitedMarker', lastZone)
                    Citizen.Wait(15000)
                    elseif CurrentAction == 'turtle_harvest' then
                        TriggerServerEvent('esx_turtle:startHarvestTurtle')
                    elseif CurrentAction == 'turtle_treatment' then
                        TriggerServerEvent('esx_turtle:startTransformTurtle')
                    elseif CurrentAction == 'turtle_resell' then
                        TriggerServerEvent('esx_turtle:startSellTurtle')
                else
                    isInZone = false
                end

                if isInZone then
                    TriggerEvent('esx_turtle:freezePlayer', true)
                end

                CurrentAction = nil
            end
        end
    end
end)

RegisterNetEvent('esx_turtle:freezePlayer')
AddEventHandler('esx_turtle:freezePlayer', function(freeze)
    FreezeEntityPosition(GetPlayerPed(-1), freeze)
end)
