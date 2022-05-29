-- TODO: collision https://github.com/SonicOnset/DigitalSwirl-Client/blob/master/ControlScript/Player/Collision.lua
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

-- ASSETS --

local GLOBALASSETS = {}
GLOBALASSETS.Guis = Instance.new("Folder", script)
GLOBALASSETS.HudGui = Utils:Create({"ScreenGui", GLOBALASSETS.Guis}, {
	Name = "HudGui"
}); local HudGui = GLOBALASSETS.HudGui

Utils:Create({"Frame", HudGui}, {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Name = "Left"
}); Utils:Create({"Frame", HudGui.Left}, {
	Size = UDim2.new(.25, 0, .25, 0),
	Name = "HudFrame",
}); Utils:Create({"Frame", HudGui.Left.HudFrame}, {
	Size = UDim2.new(1, 0, .25, 0),
	Name = "LivesFrame",
}); Utils:Create({"ImageLabel", HudGui.Left.HudFrame.LivesFrame}, {
	Size = UDim2.new(.5, 0, .5, 0),
	Position = UDim2.new(0, 0, 1, 0),
	Name = "Portrait",
}); Utils:Create({"ImageLabel", HudGui.Left.HudFrame}, {
	Size = UDim2.new(.2, 0, .2, 0),
	Position = UDim2.new(0, 0, 1-.2, 0),
	Name = "RingIcon",
})

------------

local function require(func)
	return func()
end
