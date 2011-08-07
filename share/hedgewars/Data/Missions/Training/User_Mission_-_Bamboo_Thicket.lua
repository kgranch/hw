
loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player = nil 
local enemy = nil
local firedShell = false
local turnNumber = 0

local hhs = {}
local numhhs = 0

function onGameInit()

	Seed = 0 
	TurnTime = 20000 
	CaseFreq = 0 
	MinesNum = 0 
	Explosives = 0 
	Map = "Bamboo" 
	Theme = "Bamboo"

	AddTeam(loc("Pathetic Resistance"), 14483456, "Simple", "Island", "Default")
	player = AddHog("Ikeda", 0, 10, "StrawHat")
			
	AddTeam(loc("Cybernetic Empire"), 	1175851, "Simple", "Island", "Default")
	enemy = AddHog(loc("Unit 835"), 1, 10, "cyborg")

	SetGearPosition(player,1166,1680)
	SetGearPosition(enemy,2848,1443)

end


function onGameStart()

	ShowMission(loc("Bamboo Thicket"), loc("User Challenge"), loc("Eliminate the enemy before the time runs out"), -amBazooka, 0)

	--WEAPON CRATE LIST. WCRATES: 1
	SpawnAmmoCrate(1915,1876,amBazooka)
	--UTILITY CRATE LIST. UCRATES: 2
	SpawnUtilityCrate(1986,1141,amBlowTorch)
	SpawnUtilityCrate(1427,1527,amParachute)

	AddAmmo(enemy, amGrenade, 100)
		
end

function onNewTurn()
	SetWind(100)
	turnNumber = turnNumber + 1
end

function onAmmoStoreInit()
	SetAmmo(amSkip, 9, 0, 0, 0)
	SetAmmo(amGirder, 4, 0, 0, 0)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amParachute, 0, 0, 0, 2)
	SetAmmo(amBazooka, 0, 0, 0, 2)
end


function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
	elseif GetGearType(gear) == gtShell then
		firedShell = true
	end

end

function onGearDelete(gear)

	if (gear == enemy) then
		
		ShowMission(loc("Bamboo Thicket"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
		
		if (turnNumber < 6) and (firedShell == false) then
			AddCaption(loc("Achievement Unlocked") .. ": " .. loc("Energetic Engineer"),0xffba00ff,capgrpMessage2)
		end

	elseif gear == player then
		ShowMission(loc("Bamboo Thicket"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
	end

end