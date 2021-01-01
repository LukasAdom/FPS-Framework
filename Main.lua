

	-- Settings --
local Primary = "AK47"




	-- Services --
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")


	-- Variables --
local playerCamera = game.Workspace.Camera
local RS = game.ReplicatedStorage
local gunModels = RS.GunModels

local gunSettings = RS.GunSettings
local primarySettings = gunSettings:WaitForChild(Primary)

local primaryTypeAuto = primarySettings.Automatic.Value


	-- Blank Variables --
local weaponInHand
local primaryWeapon

local camPart
local altMag


	-- Debounce --
local dbAim = false


	-- RunService Variables --
local primaryAttachingRunS
local camAttachingRunS


	-- False Bools --
local primaryEquipped = false
local someGunEquipped = false

local walking = false
local aiming = false

local equipInProg = false
local reloadInProg = false

local primaryFirable = false
local firing = false


	-- Animations --
local AnimController

local IdleAnimation
local IdleAnimationTrack

local EquipAnimation
local EquipAnimationTrack

local ReloadAnimation
local ReloadAnimationTrack


	-- Ammo --
local primaryMagCapacity = primarySettings.MagCapacity.Value
local primaryAmmoInGun = primaryMagCapacity
local primaryMagsInBackpack = 1




	-- Key / Mouse  Binds --
UserInputService.InputBegan:Connect(function(input, gameProcessed) -- Bind Began
	if not gameProcessed then
		
			-- Weapon Binds
		
		if input.KeyCode == Enum.KeyCode.One then
			if not aiming and not reloadInProg then
				if primaryEquipped then
					primaryEquipped = false
					someGunEquipped = false
					primaryFirable = false
					unequip(Primary)
				else
					primaryEquipped = true
					someGunEquipped = true
					primaryFirable = true
					equip(Primary)
				end
			end
			
			-- Binds
			
		elseif input.KeyCode == Enum.KeyCode.R then
			if not reloadInProg then
				reload(Primary)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = true
			if someGunEquipped and not dbAim and not equipInProg then
				dbAim = true
				local goalPosition = {}
				goalPosition.Value = primarySettings.Positions.Aim.Value
				local tweenInfo = TweenInfo.new(.3)
				local tweenPosition = TweenService:Create(primarySettings.Positions.Position, tweenInfo, goalPosition)
				tweenPosition:Play()

				local goalFOV = {}
				goalFOV.FieldOfView = 45
				local tweenFOVInfo = TweenInfo.new(.2)
				local tweenFOV = TweenService:Create(playerCamera, tweenFOVInfo, goalFOV)
				tweenFOV:Play()
				wait(.3)
				dbAim = false
			elseif not dbAim and not equipInProg then
				local goalFOV = {}
				goalFOV.FieldOfView = 60
				local tweenFOVInfo = TweenInfo.new(.2)
				local tweenFOV = TweenService:Create(playerCamera, tweenFOVInfo, goalFOV)
				tweenFOV:Play()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = true
			if primaryFirable then
				fire(Primary)
			end
		end
	end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed) -- Bind Ended
	if not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local db = true
			
			aiming = false
			if someGunEquipped then
				local goalPosition = {}
				goalPosition.Value = primarySettings.Positions.Idle.Value
				local tweenInfo = TweenInfo.new(.3)
				local tweenPosition = TweenService:Create(primarySettings.Positions.Position, tweenInfo, goalPosition)
				tweenPosition:Play()

				local goalFOV = {}
				goalFOV.FieldOfView = 75
				local tweenFOVInfo = TweenInfo.new(.2)
				local tweenFOV = TweenService:Create(playerCamera, tweenFOVInfo, goalFOV)
				tweenFOV:Play()
			else
				local goalFOV = {}
				goalFOV.FieldOfView = 75
				local tweenFOVInfo = TweenInfo.new(.2)
				local tweenFOV = TweenService:Create(playerCamera, tweenFOVInfo, goalFOV)
				tweenFOV:Play()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = false
		end
	end
end)

function equip(weapon)
	if weapon == Primary then
		equipInProg = true
		primaryWeapon = gunModels:FindFirstChild(Primary):Clone()
		camPart = primaryWeapon.camPart
		
		primaryWeapon.Parent = playerCamera

		weaponInHand = primaryWeapon
		
		AnimController = primaryWeapon.AnimationController
		IdleAnimation = gunSettings:FindFirstChild(Primary).Animations.Idle
		IdleAnimationTrack = AnimController:LoadAnimation(IdleAnimation)
		EquipAnimation = gunSettings:FindFirstChild(Primary).Animations.Equip
		EquipAnimationTrack = AnimController:LoadAnimation(EquipAnimation)
		
		IdleAnimationTrack:Play()
		
		
		wait(0.1)
		
		EquipAnimationTrack:Play()
		primaryWeapon.Main.equipSound:Play()
		
		primaryAttachingRunS = RunService.RenderStepped:Connect(function()
			if primaryEquipped then
				primaryWeapon:SetPrimaryPartCFrame(playerCamera.CFrame*CFrame.new(primarySettings.Positions.Position.Value))
			end
		end)
		
		wait(primarySettings.AnimationTimes.equipTime.Value)

		equipInProg = false
	end
end

function unequip(weapon)
	primaryFirable = false
	playerCamera.FieldOfView = 75
	AnimController = nil
	if weapon == Primary then
		primaryWeapon:Destroy()
		primaryAttachingRunS:Disconnect()
	end
end

function fire(weapon)
	if weapon == Primary then
		if primaryAmmoInGun > 0 and not reloadInProg then
			local function fireAnimation()
				local barrel = primaryWeapon.Main.barrel
				local fSound = primaryWeapon.Main.fireSound:Clone()

				primaryAmmoInGun = primaryAmmoInGun - 1

				fSound.Name = "fSound"
				fSound.Parent = primaryWeapon.Main.barrel
				fSound:Play()

				primaryWeapon.Main.barrel.muzzle.Transparency = NumberSequence.new(.35)
				primaryWeapon.Main.barrel.smoke.Enabled = true

				wait(0.025)

				primaryWeapon.Main.barrel.muzzle.Transparency = NumberSequence.new(1)
				primaryWeapon.Main.barrel.smoke.Enabled = false
			end
			fireAnimation()
			primaryFirable = false
			wait(60/primarySettings.RPM.Value)
			primaryFirable = true
			if firing and primaryTypeAuto then
				fire(Primary)
			end
		end
	end
end

function reload(weapon)
	if weapon == Primary then
		if primaryAmmoInGun < primaryMagCapacity then
			reloadInProg = true
			if primarySettings.reloadAltMag.Value then
				altMag = primaryWeapon.Mag:Clone()
				altMag.Parent = primaryWeapon
				altMag.Name = "AltMag"
			end
			
			AnimController = primaryWeapon.AnimationController
			ReloadAnimation = gunSettings:FindFirstChild(Primary).Animations.Reload
			ReloadAnimationTrack = AnimController:LoadAnimation(ReloadAnimation)

			ReloadAnimationTrack:Play()
			
			wait(primarySettings.AnimationTimes.reloadTime.Value)
			if primarySettings.reloadAltMag.Value then
				altMag:Destroy()
			end
			reloadInProg = false
			if primaryEquipped then
				primaryAmmoInGun = primaryMagCapacity
			end
		end
	end
end

camAttachingRunS = RunService.RenderStepped:Connect(function()
	if someGunEquipped then
		local gunRotX, gunRotY, gunRotZ = weaponInHand.rootPart.CFrame:ToEulerAnglesYXZ()
		local camRotX, camRotY, camRotZ = camPart.CFrame:ToEulerAnglesYXZ()
		local camCFrame = CFrame.Angles(0,  0,  camRotZ-gunRotZ)
		
		playerCamera.CFrame = playerCamera.CFrame * camCFrame
	end
end)
