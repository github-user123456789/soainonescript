-- :im bad at this: --
local owner = owner
----------------------
-- Services
local TweenS = game:service("TweenService")
local HTTP = game:service("HttpService")
-------------
-- UTILS --
local Utils = {}
function Utils:Create(InstData, Props)
	local Obj = Instance.new(InstData[1], InstData[2])
	for k, v in pairs (Props) do
		Obj[k] = v
	end; return Obj
end
function Utils:CNR(cf) -- CFrameNoRotate
	return CFrame.new(cf.x,cf.y,cf.z)
end
-- LEGACY FUNCTIONS WITH ADDED FEATURES
function Utils:ezweld(p, a, b, cf, c1)
	local weld = Instance.new("Weld",p)
	weld.Part0 = a
	weld.Part1 = b
	weld.C0 = cf
	if c1 then weld.C1 = c1 end
    return weld
end
function Utils:NewSound(p, id, pit, vol, loop, autoplay)
	local Sound = Instance.new("Sound",p)
    Sound.Pitch = pit
    Sound.Volume = vol
    Sound.SoundId = "rbxassetid://" ..id
    Sound.Looped = loop
	if autoplay then
    	Sound:Play()
	end
    return Sound
end
-----------

--local commonmodules = {}
local function importgit(url)
	print("Running: " ..url)
	local func = loadstring(HTTP:GetAsync(url))
	-- sandbox it to make stuff like bit work
	local sb = getfenv(func)
	sb.sandbox = {}
	
	-- return what the function returns
	return func()
end; local function loadcode(url, name, folder)
	return Utils:Create({"StringValue", folder}, {
		Name = name,
		Value = HTTP:GetAsync(url),
	})
end

-- custom loadstring stuff

local importcustom = Utils:Create({"Folder", owner.PlayerGui}, {
	Name = "ImportCustom"
}); loadcode("https://raw.githubusercontent.com/github-user123456789/fioneandyueliang/main/yueliang.lua", "Yueliang", importcustom)
	loadcode("https://raw.githubusercontent.com/github-user123456789/fioneandyueliang/main/fione.lua", "FiOne", importcustom)

-- make da stuff

-- COMMONMODULES --
local commons = Utils:Create({"Folder", owner.PlayerGui}, {
	Name = "CommonModules"
});

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/Vector.lua", "Vector", commons)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/CFrame.lua", "CFrame", commons)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/CameraUtil.lua", "CameraUtil", commons)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/Collision.lua", "Collision", commons)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/GlobalReference.lua", "GlobalReference", commons)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/Switch.lua", "Switch", commons)

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/PlayerReplicate/Constants.lua", "Constants", Utils:Create({"Folder", commons}, {Name = "PlayerReplicate"}))

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/SpatialPartitioning/Part.lua", "Part", Utils:Create({"Folder", commons}, {Name = "SpatialPartitioning"}))
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/CommonModules/SpatialPartitioning/init.lua", "init", commons.SpatialPartitioning)

-- CONTROLSCRIPT --

local pcontrol = Utils:Create({"Folder", owner.PlayerGui}, {
	Name = "ControlScript"
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Constants.lua", "Constants", pcontrol)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Music.lua", "Music", pcontrol)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/ObjectCommon.lua", "ObjectCommon", pcontrol)

local hud = Utils:Create({"Folder", pcontrol}, {
	Name = "Hud",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Hud/ItemCard.lua", "ItemCard", hud)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Hud/RingFlash.lua", "RingFlash", hud)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Hud/Text.lua", "Text", hud)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Hud/init.lua", "init", hud)

local object = Utils:Create({"Folder", pcontrol}, {
	Name = "Object",
})

-- TODO (NOTE): if proper object support is added, code from "thescript" (old localscript) will have to be copied and used on the github

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/DashPanel.lua", "DashPanel", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/DashRamp.lua", "DashRamp", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/DashRing.lua", "DashRing", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/HomingTest.lua", "HomingTest", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/ItemBox.lua", "ItemBox", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/RainbowRing.lua", "RainbowRing", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/Ring.lua", "Ring", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/Spiketrap.lua", "Spiketrap", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/SpilledRing.lua", "SpilledRing", object)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/Spring.lua", "Spring", object)

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Object/init.lua", "init", object)

local player = Utils:Create({"Folder", pcontrol}, {
	Name = "Player",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Acceleration.lua", "Acceleration", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Animation.lua", "Animation", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Collision.lua", "Collision", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/HomingAttack.lua", "HomingAttack", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/LSD.lua", "LSD", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Movement.lua", "Movement", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Ragdoll.lua", "Ragdoll", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Rail.lua", "Rail", player)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Sound.lua", "Sound", player)

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/init.lua", "init", player)

local physics = Utils:Create({"Folder", player}, {
	Name = "Physics",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Physics/SA1.lua", "SA1", physics)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Physics/SA2.lua", "SA2", physics)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Physics/SOA.lua", "SOA", physics)

local input = Utils:Create({"Folder", player}, {
	Name = "Input",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Input/TouchButton.lua", "TouchButton", input)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Input/TouchThumbstick.lua", "TouchThumbstick", input)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/Player/Input/init.lua", "init", input)

------------

local prep = Utils:Create({"Folder", pcontrol}, {
	Name = "PlayerReplicate",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerReplicate/Peer.lua", "Peer", prep)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerReplicate/init.lua", "init", prep)

-- playerdraw --

local pdraw = Utils:Create({"Folder", pcontrol}, {
	Name = "PlayerDraw",
})

loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/BallTrail.lua", "BallTrail", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/Invincibility.lua", "Invincibility", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/JumpBall.lua", "JumpBall", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/MagnetShield.lua", "MagnetShield", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/Shield.lua", "Shield", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/SpindashBall.lua", "SpindashBall", pdraw)
loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/PlayerDraw/init.lua", "init", pdraw)

-- clientscript--

local init = Utils:Create({"Folder", pcontrol}, {
	Name = "init"
}); loadcode("https://github.com/github-user123456789/DigitalSwirl-Client-Importable/raw/master/ControlScript/init.client.lua", "client", init)

----------------

-- The whole script as a local --

NLS(HTTP:GetAsync("https://raw.githubusercontent.com/github-user123456789/soainonescript/main/thescriptforvsb.lua"), owner.PlayerGui)
