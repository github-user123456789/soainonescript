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

-- COMMONMODULES --

local commons = {}
commons.Vector = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/Vector.lua
	Purpose: Vector functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local vector = {}

	function vector.Flatten(vector, normal)
		local dot = vector:Dot(normal.unit)
		return vector - (normal.unit) * dot
	end

	function vector.PlaneProject(point, nor)
		local ptpd = (nor.unit):Dot(point)
		return point - ((nor.unit) * ptpd), ptpd
	end

	function vector.Angle(from, to)
		local dot = (from.unit):Dot(to.unit)
		if dot >= 1 then
			return 0
		elseif dot <= -1 then
			return -math.pi
		end
		return math.acos(dot)
	end

	function vector.SignedAngle(from, to, up)
		local right = (up.unit):Cross(from).unit
		local dot = (from.unit):Dot(to.unit)
		local rdot = math.sign(right:Dot(to.unit))
		if rdot == 0 then
			rdot = 1
		end
		if dot >= 1 then
			return 0
		elseif dot <= -1 then
			return -math.pi * rdot
		end
		return math.acos(dot) * rdot
	end

	function vector.AddX(vector, x)
		return vector + Vector3.new(x, 0, 0)
	end

	function vector.AddY(vector, y)
		return vector + Vector3.new(0, y, 0)
	end

	function vector.AddZ(vector, z)
		return vector + Vector3.new(0, 0, z)
	end

	function vector.MulX(vector, x)
		return vector * Vector3.new(x, 1, 1)
	end

	function vector.MulY(vector, y)
		return vector * Vector3.new(1, y, 1)
	end

	function vector.MulZ(vector, z)
		return vector * Vector3.new(1, 1, z)
	end

	function vector.DivX(vector, x)
		return vector / Vector3.new(x, 1, 1)
	end

	function vector.DivY(vector, y)
		return vector / Vector3.new(1, y, 1)
	end

	function vector.DivZ(vector, z)
		return vector / Vector3.new(1, 1, z)
	end

	function vector.SetX(vector, x)
		return Vector3.new(x, vector.Y, vector.Z)
	end

	function vector.SetY(vector, y)
		return Vector3.new(vector.X, y, vector.Z)
	end

	function vector.SetZ(vector, z)
		return Vector3.new(vector.X, vector.Y, z)
	end

	return vector
end
commons.CFrame = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/CFrame.lua
	Purpose: CFrame functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local cframe = {}

	local vector = commons.Vector

	function cframe.FromToRotation(from, to)
		--Get our axis and angle
		local axis = from:Cross(to)
		local angle = vector.Angle(from, to)
		
		--Create matrix from axis and angle
		if angle <= -math.pi then
			return CFrame.fromAxisAngle(Vector3.new(0, 0, 1), math.pi)
		elseif axis.magnitude ~= 0 then
			return CFrame.fromAxisAngle(axis, angle)
		else
			return CFrame.new()
		end
	end

	return cframe
end
commons.CameraUtil = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/CameraUtil.lua
	Purpose: Camera utility functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local camera_util = {}
	--Camera frustum check
	local last_camera_res = nil
	local last_camera_fov = nil
	local cam_planes = nil
	function camera_util.CheckFrustum(point, rad)
		--Update camera planes if FOV or resolution changed
		local camera = workspace.CurrentCamera
		if cam_planes == nil or camera.ViewportSize ~= last_camera_res or camera.FieldOfView ~= last_camera_fov then
			--Get camera factors
			last_camera_res = camera.ViewportSize
			last_camera_fov = camera.FieldOfView
			
			local aspectRatio = last_camera_res.X / last_camera_res.Y
			local hFactor = math.tan(math.rad(last_camera_fov) / 2)
			local wFactor = aspectRatio * hFactor
			
			--Get planes
			cam_planes = {
				Vector3.new(hFactor, 0, 1).unit,
				Vector3.new(0, wFactor, 1).unit,
				Vector3.new(-hFactor, 0, 1).unit,
				Vector3.new(0, -wFactor, 1).unit,
			}
		end
		
		--Test against camera planes
		local cframe = camera.CFrame
		local local_pos = cframe:inverse() * point
		
		for _,v in pairs(cam_planes) do
			if v:Dot(local_pos) > rad then
				return false
			end
		end
		
		return true
	end

	return camera_util
end

commons.Collision = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/Collision.lua
	Purpose: Collision functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local collision_module = {}

	--Raycasting collision
	function collision_module.Raycast(wl, from, dir)
		local param = RaycastParams.new()
		param.FilterType = Enum.RaycastFilterType.Whitelist
		param.FilterDescendantsInstances = wl
		param.IgnoreWater = true
		local result = workspace:Raycast(from, dir, param)
		if result then
			return result.Instance, result.Position, result.Normal, result.Material
		else
			return nil, from + dir, nil, Enum.Material.Air
		end
	end

	--Sphere to box collision
	function collision_module.SqDistPointAABB(point, box)
		local sq_dist = 0
		
		--X axis check
		local v = point.X
		if v < box.min.X then
			sq_dist = sq_dist + (box.min.X - v) * (box.min.X - v)
		end
		if v > box.max.X then
			sq_dist = sq_dist + (v - box.max.X) * (v - box.max.X)
		end
		
		--Y axis check
		local v = point.Y
		if v < box.min.Y then
			sq_dist = sq_dist + (box.min.Y - v) * (box.min.Y - v)
		end
		if v > box.max.Y then
			sq_dist = sq_dist + (v - box.max.Y) * (v - box.max.Y)
		end
		
		--Z axis check
		local v = point.Z
		if v < box.min.Z then
			sq_dist = sq_dist + (box.min.Z - v) * (box.min.Z - v)
		end
		if v > box.max.Z then
			sq_dist = sq_dist + (v - box.max.Z) * (v - box.max.Z)
		end
		
		return sq_dist
	end

	function collision_module.TestSphereAABB(sphere, box)
		local sq_dist = collision_module.SqDistPointAABB(sphere.center, box)
		return sq_dist <= (sphere.radius ^ 2)
	end

	function collision_module.TestSphereRotatedBox(sphere, rotated_box)
		local sq_dist = collision_module.SqDistPointAABB(rotated_box.cframe:inverse() * sphere.center, {min = rotated_box.size / -2, max = rotated_box.size / 2})
		return sq_dist <= (sphere.radius ^ 2)
	end

	return collision_module
end

commons.GlobalReference = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/GlobalReference.lua
	Purpose: Global Reference class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local global_reference = {}

	local cur_ref_reg = {}

	--Common functions
	local function StringSplit(s, delimiter)
		local spl = {}
		for match in (s..delimiter):gmatch("(.-)"..delimiter) do
			table.insert(spl, match)
		end
		return spl
	end

	--Internal interface
	local function InitialReference(self)
		--Disconnect current reference connection
		if self.cur_p_con ~= nil then
			self.cur_p_con:Disconnect()
			self.cur_p_con = nil
		end
		
		--Find next current reference
		self.cur_p = self.parent
		for _,v in pairs(self.spl_dir) do
			local n = self.cur_p:FindFirstChild(v)
			if n ~= nil then
				self.cur_p = n
			else
				self.cur_p = nil
				break
			end
		end
		
		--Connect if reference was found
		if self.cur_p ~= nil then
			self.cur_p_con = self.cur_p:GetPropertyChangedSignal("Parent"):Connect(function()
				InitialReference(self)
			end)
		end
	end

	local function GetKey(parent, directory)
		return parent:GetFullName().."\\"..directory
	end

	local function Register(parent, directory)
		local key = GetKey(parent, directory)
		if cur_ref_reg[key] ~= nil then
			--Increment registration count
			cur_ref_reg[key].count = cur_ref_reg[key].count + 1
			return cur_ref_reg[key].instance, true
		else
			--Create new registry
			local self = setmetatable({}, {__index = global_reference})
			cur_ref_reg[key] = {instance = self, count = 1}
			return self, false
		end
	end

	local function Deregister(parent, directory)
		local key = GetKey(parent, directory)
		if cur_ref_reg[key] ~= nil then
			--Decrement registration count
			cur_ref_reg[key].count = cur_ref_reg[key].count - 1
			if cur_ref_reg[key].count <= 0 then
				--Destroy registry since there's no more references
				cur_ref_reg[key] = nil
				return false
			else
				--Registry hasn't been destroyed yet
				return true
			end
		else
			return true
		end
	end

	--Constructor and destructor
	function global_reference:New(parent, directory)
		--Check for same reference
		local self, alreg = Register(parent, directory)
		if alreg then
			return self
		end
		
		--Parse directory
		self.parent = parent
		self.directory = directory
		self.spl_dir = StringSplit(directory, "/")
		
		--Initial reference to given directory
		self.cur_p_con = nil
		InitialReference(self)
		
		return self
	end

	function global_reference:Destroy()
		--Deregister reference
		if Deregister(parent, directory) then
			return
		end
		
		--Disconnect current reference connection
		if self.cur_p_con ~= nil then
			self.cur_p_con:Disconnect()
			self.cur_p_con = nil
		end
	end

	--Global reference interface
	function global_reference:Get()
		if self.cur_p == nil then
			InitialReference(self)
		end
		return self.cur_p
	end

	return global_reference
end

commons.Switch = function()
	--[[
	= DigitalSwirl =
	Source: CommonModules/Switch.lua
	Purpose: Switch case implementation
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	return function(v, a, cases)
		if cases[v] ~= nil then
			return cases[v](unpack(a))
		end
	end
end

commons.PlayerReplicate = {}; commons.PlayerReplicate.Constants = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/PlayerReplicate/Constants.lua
	Purpose: Player Replication constants
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	return {
		packet_rate = 100 / 1000, --100ms
		packet_rate_limit = 200,
	}
end

commons.SpatialPartitioning = {}; commons.SpatialPartitioning.Part = function()
	--[[

	= DigitalSwirl =

	Source: CommonModules/SpatialPartitioning.lua
	Purpose: Spatial Partitioning part class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local part = {}

	--Constructor and destructor
	function part:New(cell_dim)
		--Initialize meta reference
		local self = setmetatable({}, {__index = part})
		
		--Initialize state
		self.cell_dim = cell_dim
		self.cells = {}
		self.prev_cframe = nil
		
		return self
	end

	function part:Destroy()
		--Clear cells table
		self.cells = nil
	end

	--Internal interface
	local function GetRegion(cf, size)
		--Get 8 points around the part
		size = size / 2
		local p0 = cf * Vector3.new( size.X,  size.Y,  size.Z)
		local p1 = cf * Vector3.new(-size.X,  size.Y,  size.Z)
		local p2 = cf * Vector3.new( size.X, -size.Y,  size.Z)
		local p3 = cf * Vector3.new(-size.X, -size.Y,  size.Z)
		local p4 = cf * Vector3.new( size.X,  size.Y, -size.Z)
		local p5 = cf * Vector3.new(-size.X,  size.Y, -size.Z)
		local p6 = cf * Vector3.new( size.X, -size.Y, -size.Z)
		local p7 = cf * Vector3.new(-size.X, -size.Y, -size.Z)
		
		--Get min and max of each axis
		local min_x = math.min(p0.X, p1.X, p2.X, p3.X, p4.X, p5.X, p6.X, p7.X)
		local min_y = math.min(p0.Y, p1.Y, p2.Y, p3.Y, p4.Y, p5.Y, p6.Y, p7.Y)
		local min_z = math.min(p0.Z, p1.Z, p2.Z, p3.Z, p4.Z, p5.Z, p6.Z, p7.Z)
		local max_x = math.max(p0.X, p1.X, p2.X, p3.X, p4.X, p5.X, p6.X, p7.X)
		local max_y = math.max(p0.Y, p1.Y, p2.Y, p3.Y, p4.Y, p5.Y, p6.Y, p7.Y)
		local max_z = math.max(p0.Z, p1.Z, p2.Z, p3.Z, p4.Z, p5.Z, p6.Z, p7.Z)
		
		--Return region
		return {
			min = Vector3.new(min_x, min_y, min_z),
			max = Vector3.new(max_x, max_y, max_z),
		}
	end

	local function ToCell(self, x)
		return math.floor(x / self.cell_dim)
	end

	--Part interface
	function part:Moved(cf)
		return cf ~= self.prev_cframe
	end

	function part:Update(cf, size)
		debug.profilebegin("part:Update")
		
		--Get new region and containing cells
		local region = GetRegion(cf, size)
		self.prev_cframe = cf
		
		local new_cells = {}
		for x = ToCell(self, region.min.X), ToCell(self, region.max.X) do
			for y = ToCell(self, region.min.Y), ToCell(self, region.max.Y) do
				for z = ToCell(self, region.min.Z), ToCell(self, region.max.Z) do
					new_cells[Vector3.new(x, y, z)] = true
				end
			end
		end
		
		--Compare against previous cells
		local cells_remove = {}
		local temp_map = {}
		for i, v in pairs(self.cells) do
			if not new_cells[v] then
				table.insert(cells_remove, v)
				self.cells[i] = nil
			else
				temp_map[v] = true
			end
		end
		
		local cells_set = {}
		for i,_ in pairs(new_cells) do
			if not temp_map[i] then
				table.insert(cells_set, i)
				table.insert(self.cells, i)
			end
		end
		
		debug.profileend()
		
		return cells_remove, cells_set
	end

	function part:GetCells()
		return self.cells
	end

	return part
end

commons.SpatialPartitioning.init = function()
	--[[
	= DigitalSwirl =
	Source: CommonModules/SpatialPartitioning.lua
	Purpose: Spatial Partitioning class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local spatial_partitioning = {}

	local run_service = game:GetService("RunService")

	local part_class = commons.SpatialPartitioning.Part()

	--Internal functions
	local function RemoveCell(self, vec, part)
		debug.profilebegin("spatial_partitioning:RemoveCell")
		
		if self.cells[vec] ~= nil then
			self.cells[vec][part] = nil
		end
		
		debug.profileend()
	end

	local function SetCell(self, vec, part)
		debug.profilebegin("spatial_partitioning:SetCell")
		
		if self.cells[vec] == nil then
			self.cells[vec] = {}
		end
		self.cells[vec][part] = true
		
		debug.profileend()
	end

	local function VectorHash(x, y, z)
		if typeof(x) == "Vector3" then
			y = x.Y
			z = x.Z
			x = x.X
		end
		return (x * 24832) + (y * 48128) + (z * 81935)
	end

	local function ToCell(self, x)
		return math.floor(x / self.cell_dim)
	end

	local function Update(self, part)
		debug.profilebegin("spatial_partitioning:Update")
		
		--Get cell updates
		local cell_remove, cell_set = self.parts[part]:Update(part.CFrame, part.Size)
		
		--Update cells
		for _,v in pairs(cell_remove) do
			RemoveCell(self, VectorHash(v), part)
		end
		for _,v in pairs(cell_set) do
			SetCell(self, VectorHash(v), part)
		end
		
		debug.profileend()
	end

	--Constructor and destructor
	function spatial_partitioning:New(cell_dim)
		--Initialize meta reference
		local self = setmetatable({}, {__index = spatial_partitioning})
		
		--Remember given properties
		self.cell_dim = cell_dim
		
		--Initialize state
		self.cells = {}
		self.parts = {}
		self.unanchored_parts = {}
		self.root_cons = {}
		
		--Handle physics updates
		self.physics_conn = run_service.Heartbeat:Connect(function()
			for i,_ in pairs(self.unanchored_parts) do
				if self.parts[i]:Moved(i.CFrame) then
					Update(self, i)
				end
			end
		end)
		
		return self
	end

	function spatial_partitioning:Destroy()
		--Disconnect connections
		if self.physics_conn ~= nil then
			self.physics_conn:Disconnect()
			self.physics_conn = nil
		end
		
		if self.root_cons ~= nil then
			for _,v in pairs(self.root_cons) do
				for _,k in pairs(v) do
					k:Disconnect()
				end
			end
			self.root_cons = nil
		end
		
		--Destroy parts
		if self.parts ~= nil then
			for _,v in pairs(self.parts) do
				v:Destroy()
			end
			self.parts = nil
		end
		
		--Clear cells table
		self.cells = nil
	end

	--Spatial partitioning interface
	function spatial_partitioning:Add(part)
		debug.profilebegin("spatial_partitioning:Add")
		
		if self.parts[part] == nil then
			--Create part class and get containing cells
			local new_part = part_class:New(self.cell_dim)
			local _, cell_set = new_part:Update(part.CFrame, part.Size)
			
			--Set cells
			for _,v in pairs(cell_set) do
				SetCell(self, VectorHash(v), part)
			end
			
			--Remember part class
			self.parts[part] = new_part
			
			--Attach update connections
			local update_func = function()
				Update(self, part)
			end
			local anchor_func = function()
				if part.Anchored then
					self.unanchored_parts[part] = nil
				else
					self.unanchored_parts[part] = true
				end
			end
			anchor_func()
			
			self.root_cons[part] = {
				part:GetPropertyChangedSignal("CFrame"):Connect(update_func),
				part:GetPropertyChangedSignal("Size"):Connect(update_func),
				part:GetPropertyChangedSignal("Anchored"):Connect(anchor_func),
			}
		end
		
		debug.profileend()
	end

	function spatial_partitioning:Remove(part)
		debug.profilebegin("spatial_partitioning:Remove")
		
		if self.parts[part] ~= nil then
			--Disconnect update
			if self.root_cons[part] ~= nil then
				for _,v in pairs(self.root_cons[part]) do
					v:Disconnect()
				end
				self.root_cons[part] = nil
			end
			
			--Remove containing cells
			local cell_remove = self.parts[part]:GetCells()
			for _,v in pairs(cell_remove) do
				RemoveCell(self, v, part)
			end
			
			--Destroy part class
			self.parts[part]:Destroy()
			self.parts[part] = nil
			self.unanchored_parts[part] = nil
		end
		
		debug.profileend()
	end

	function spatial_partitioning:GetPartsInRegion(region)
		debug.profilebegin("spatial_partitioning:GetPartsInRegion")
		
		if typeof(region) == "Region3" then
			region = {
				min = region.CFrame.p - region.Size / 2,
				max = region.CFrame.p + region.Size / 2,
			}
		end
		
		local res = {}
		local temp_map = {}
		
		for x = ToCell(self, region.min.X), ToCell(self, region.max.X) do
			for y = ToCell(self, region.min.Y), ToCell(self, region.max.Y) do
				for z = ToCell(self, region.min.Z), ToCell(self, region.max.Z) do
					local vec = VectorHash(x, y, z)
					if self.cells[vec] ~= nil then
						for i,_ in pairs(self.cells[vec]) do
							if not temp_map[i] then
								table.insert(res, i)
								temp_map[i] = true
							end
						end
					end
				end
			end
		end
		
		debug.profileend()
		
		return res
	end

	return spatial_partitioning
end

-- PLAYERCONTROL --

local pcontrol = {}
pcontrol.Constants = function()
	--[[

	= DigitalSwirl Client =

	Source: ControlScript/Constants.lua
	Purpose: Common game constants
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	return {
		--Game framerate
		framerate = 60,
		
		--Player states
		state = {
			idle = 0,
			walk = 1,
			skid = 2,
			spindash = 3,
			roll = 4,
			airborne = 5,
			homing = 6,
			bounce = 7,
			rail = 8,
			light_speed_dash = 9,
			air_kick = 10,
			ragdoll = 11,
			hurt = 12,
			dead = 13,
			drown = 14,
		},
	}
end
pcontrol.Music = function()
	--[[
	= DigitalSwirl Client =
	Source: ControlScript/Music.lua
	Purpose: Provides music playback
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local music_class = {}

	--Constructor and destructor
	function music_class:New(parent)
		--Initialize meta reference
		local self = setmetatable({}, {__index = music_class})
		
		--Create music object
		self.music = Instance.new("Sound")
		self.music.Name = "Music"
		self.music.Looped = true
		self.music.Parent = parent
		
		--Initialize music state
		self.music_id = "0"
		self.music_volume = 0
		
		return self
	end

	function music_class:Destroy()
		--Destroy music object
		if self.music ~= nil then
			self.music:Destroy()
			self.music = nil
		end
	end

	--Music interface
	function music_class:Update(id, volume, reset)
		--Update volume
		volume = tonumber(volume)
		if volume ~= nil and volume ~= self.music_volume then
			self.music.Volume = volume
			self.music_volume = volume
		end
		
		--Update id
		id = tostring(id)
		if id ~= self.music_id or reset then
			self.music:Stop()
			self.music.SoundId = "rbxassetid://"..id
			self.music_id = id
			self.music:Play()
		end
	end

	return music_class
end

pcontrol.ObjectCommon = function()
	--[[

	= DigitalSwirl Client =

	Source: ControlScript/ObjectCommon.lua
	Purpose: Common functions for game objects
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local object_common = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	--local common_modules = replicated_storage:WaitForChild("CommonModules")
	local common_modules = commons

	local vector = require(common_modules.Vector)
	local cframe = require(common_modules.CFrame)
	local collision = require(common_modules.Collision)
	local global_reference = require(common_modules.GlobalReference)

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

	--Common functions
	local function VelCancel(vel, normal)
		local dot = vel:Dot(normal.unit)
		if dot < 0 then
			return vel - (normal.unit) * dot
		end
		return vel
	end

	local function LocalVelCancel(self, vel, normal)
		return self:ToLocal(VelCancel(self:ToGlobal(vel), normal.unit))
	end

	--Common object to player collision
	function object_common.PushPlayerCylinder(root, player, power)
		--Get pos local to root
		local player_sphere = player:GetSphere()
		local loc_pos = root.CFrame:inverse() * player_sphere.center
		local loc_prj = vector.SetY(loc_pos, 0)
		
		if loc_prj.magnitude ~= 0 then
			--Check if we should clip out of the cylinder
			local tgt_clip = loc_prj.unit * Vector3.new(root.Size.X / 2, 0, root.Size.Z / 2)
			local clip = loc_prj.magnitude - (tgt_clip.magnitude + player_sphere.radius)
			
			if clip < 0 then
				--Attempt to clip out, but don't go through collision
				local root_rot = root.CFrame - root.Position
				local clip_world = root_rot * loc_prj.unit
				local from = player.pos
				local to = player.pos - clip_world * clip
				local hit, pos, _ = collision.Raycast({workspace.Terrain, collision_reference:Get()}, from, (to - from) + clip_world * player_sphere.radius)
				if hit == nil then
					player.pos = player.pos:Lerp(to, power)
				end
				
				--Kill velocity clipping into the object
				player.spd = player.spd:Lerp(LocalVelCancel(player, player.spd, clip_world), power)
			end
		end
	end

	return object_common
end

-- PCONTROL HUD

pcontrol.Hud = {}
pcontrol.Hud.ItemCard = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Hud/ItemCard.lua
	Purpose: HUD Item Cards for when you collect an item
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local item_card = {}

	--Item card sheet information
	local sheet_l = 3
	local sheet_t = 3
	local sheet_w = 167
	local sheet_h = 167
	local sheet_ix = 170
	local sheet_iy = 170

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Constructor and destructor
	function item_card:New(gui, x, sx, sy)
		--Initialize meta reference
		local self = setmetatable({}, {__index = item_card})
		
		--Initialize item card state
		self.x = x
		self.card_t = 0
		self.card_len = 2.375
		self.card_intrans = 0.375
		self.card_outtrans = 0.75
		
		--Create card
		self.card = Instance.new("ImageLabel")
		self.card.BackgroundTransparency = 1
		self.card.BorderSizePixel = 0
		self.card.AnchorPoint = Vector2.new(0.5, 0.5)
		self.card.Position = UDim2.new(0.5 + x, 0, 0.5, 0)
		self.card.Size = UDim2.new(0, 0, 0, 0)
		self.card.Image = "rbxassetid://5733228080"
		self.card.ImageRectOffset = Vector2.new(sheet_l + sheet_ix * sx, sheet_t + sheet_iy * sy)
		self.card.ImageRectSize = Vector2.new(sheet_w, sheet_h)
		self.card.Parent = gui
		
		return self
	end

	function item_card:Destroy()
		--Destroy card
		self.card:Destroy()
	end

	--Ring flash interface
	function item_card:Update(dt, shift_x)
		--Increment item card time
		self.card_t = self.card_t + dt
		if self.card_t >= self.card_len then
			return true
		end
		
		--Get next card size
		local dia
		if self.card_t < self.card_intrans then
			dia = self.card_t / self.card_intrans
		elseif self.card_t > (self.card_len - self.card_outtrans) then
			dia = (self.card_len - self.card_t) / self.card_outtrans
		else
			dia = 1
		end
		dia = math.sin(dia * math.rad(90)) * 0.95
		
		--Move card
		self.card.Position = UDim2.new(0.5 + self.x + shift_x, 0, 0.5, 0)
		self.card.Size = UDim2.new(dia, 0, dia, 0)
		return false
	end

	function item_card:GetX()
		return self.card.Position.X.Scale - 0.5
	end

	function item_card:ShiftLeft()
		self.x = self.x - 0.5
	end

	function item_card:ShiftRight()
		self.x = self.x + 0.5
	end

	return item_card
end

pcontrol.Hud.RingFlash = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Hud/RingFlash.lua
	Purpose: HUD Ring Flash for when you collect a ring
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local ring_flash = {}

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Constructor and destructor
	function ring_flash:New(gui)
		--Initialize meta reference
		local self = setmetatable({}, {__index = ring_flash})
		
		--Initialize ring flash state
		self.flash_t = 0
		self.flash_len = 0.4
		self.flash_from = 1.05
		self.flash_to = 1.8
		
		--Create flash
		self.flash = Instance.new("ImageLabel")
		self.flash.BackgroundTransparency = 1
		self.flash.BorderSizePixel = 0
		self.flash.AnchorPoint = Vector2.new(0.5, 0.5)
		self.flash.Position = UDim2.new(0.5, 0, 0.5, 0)
		self.flash.Size = UDim2.new(self.flash_from, 0, self.flash_from, 0)
		self.flash.Image = "rbxassetid://5781543083"
		self.flash.Parent = gui
		
		return self
	end

	function ring_flash:Destroy()
		--Destroy flash
		self.flash:Destroy()
	end

	--Ring flash interface
	function ring_flash:Update(dt)
		--Increment ring flash time
		self.flash_t = self.flash_t + dt
		if self.flash_t >= self.flash_len then
			return true
		end
		
		--Update flash
		local per = math.sqrt(self.flash_t / self.flash_len)
		local dia = lerp(self.flash_from, self.flash_to, per)
		self.flash.Size = UDim2.new(dia, 0, dia, 0)
		self.flash.ImageTransparency = per
		return false
	end

	return ring_flash
end

pcontrol.Hud.Text = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Hud/Text.lua
	Purpose: HUD Text for scores and timer
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local text = {}

	--Font and character information
	local font_image = "rbxassetid://5805079273"
	local font_width = 1024
	local font_height = 92
	local font_char_width = 78

	local char_width = 0.2
	local char_height = 0.26
	local char_off = 0.725

	local font_charmap = {
		['0'] =  0,
		['1'] =  1,
		['2'] =  2,
		['3'] =  3,
		['4'] =  4,
		['5'] =  5,
		['6'] =  6,
		['7'] =  7,
		['8'] =  8,
		['9'] =  9,
		['"'] = 10,
		[':'] = 11,
		['x'] = 12,
	}

	--Constructor and destructor
	function text:New(gui, position)
		--Initialize meta reference
		local self = setmetatable({}, {__index = text})
		
		--Create container
		self.container = Instance.new("Frame")
		self.container.BackgroundTransparency = 1
		self.container.BorderSizePixel = 0
		self.container.AnchorPoint = Vector2.new(1, 1)
		self.container.Position = position
		self.container.Size = UDim2.new(char_width, 0, char_height, 0)
		self.container.SizeConstraint = Enum.SizeConstraint.RelativeYY
		self.container.Parent = gui
		
		--Initialize text state
		self.colour = Color3.new(1, 1, 1)
		self.chars = {}
		
		return self
	end

	function text:Destroy()
		--Destroy container
		self.container:Destroy()
	end

	--Text interface
	function text:SetText(txt)
		debug.profilebegin("text:SetText")
		
		--Get new characters to type
		local new_chars = {}
		
		--Write new characters
		for i = 1, txt:len() do
			--Insert character
			local c = txt:sub(i, i)
			local map = font_charmap[c]
			table.insert(new_chars, Vector2.new(font_char_width * map, 0))
		end
		
		--Destroy or allocate new characters
		if #new_chars < #self.chars then
			for i = #new_chars + 1, #self.chars do
				self.chars[i]:Destroy()
				self.chars[i] = nil
			end
		elseif #new_chars > #self.chars then
			for i = #self.chars + 1, #new_chars do
				local new_char = Instance.new("ImageLabel")
				new_char.BackgroundTransparency = 1
				new_char.BorderSizePixel = 0
				new_char.Position = UDim2.new((1 - i) * char_off, 0, 0, 0)
				new_char.Size = UDim2.new(1, 0, 1, 0)
				new_char.Image = font_image
				new_char.ImageRectSize = Vector2.new(font_char_width, font_height)
				new_char.ImageColor3 = self.colour
				new_char.Parent = self.container
				self.chars[i] = new_char
			end
		end
		
		--Write characters
		for i = 1, #new_chars do
			local v = #new_chars - i + 1
			self.chars[i].ImageRectOffset = new_chars[v]
		end
		
		debug.profileend()
	end

	function text:SetColour(colour)
		--Update existing characters and set colour for next
		for _,v in pairs(self.container:GetChildren()) do
			v.ImageColor3 = colour
		end
		self.colour = colour
	end

	return text
end

pcontrol.Hud.init = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Hud.lua
	Purpose: Heads Up Display
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local hud_class = {}

	local assets = GLOBALASSETS
	local guis = assets.Guis

	local text = require(pcontrol.Hud.Text)
	local ring_flash = require(pcontrol.Hud.RingFlash)
	local item_card = require(pcontrol.Hud.ItemCard)

	--Constructor and destructor
	function hud_class:New(parent_gui)
		--Initialize meta reference
		local self = setmetatable({}, {__index = hud_class})
		
		--Create new Hud Gui
		self.gui = guis.HudGui:Clone()
		self.gui.Parent = parent_gui
		
		self.hud_left = self.gui:WaitForChild("Left")
		self.hud_frame = self.hud_left:WaitForChild("HudFrame")
		
		self.lives_frame = self.hud_frame:WaitForChild("LivesFrame")
		self.portrait_image = self.lives_frame:WaitForChild("Portrait")
		
		self.ring_icon = self.hud_frame:WaitForChild("RingIcon")
		
		--Create text objects
		self.score_text = text:New(self.hud_frame, UDim2.new(0.96, 0, 0.325, 0))
		--self.score_text:SetText('000000000')
		self.time_text = text:New(self.hud_frame, UDim2.new(0.8, 0, 0.66, 0))
		--self.time_text:SetText('00:00"00')
		self.ring_text = text:New(self.hud_frame, UDim2.new(0.525, 0, 0.995, 0))
		--self.ring_text:SetText('000')
		
		--Create item card frame
		self.item_card_frame = Instance.new("Frame")
		self.item_card_frame.BackgroundTransparency = 1
		self.item_card_frame.BorderSizePixel = 0
		self.item_card_frame.AnchorPoint = Vector2.new(0.5, 1)
		self.item_card_frame.Position = UDim2.new(0.5, 0, 0.9, 0)
		self.item_card_frame.Size = UDim2.new(0.2, 0, 0.2, 0)
		self.item_card_frame.SizeConstraint = Enum.SizeConstraint.RelativeYY
		self.item_card_frame.Parent = self.gui
		
		--Initialize Hud state
		self.ring_flashes = {}
		self.ring_blink = 0
		self.ring_blinkt = 0
		
		self.item_cards = {}
		self.item_card_x = 0
		self.item_card_shift = 0
		
		self.portrait = nil
		self.hurt_shake = 0
		
		return self
	end

	function hud_class:Destroy()
		--Destroy ring flashes
		if self.ring_flashes ~= nil then
			for _,v in pairs(self.ring_flashes) do
				v:Destroy()
			end
			self.ring_flashes = nil
		end
		
		--Destroy text objects
		if self.ring_text ~= nil then
			self.ring_text:Destroy()
			self.ring_text = nil
		end
		if self.time_text ~= nil then
			self.time_text:Destroy()
			self.time_text = nil
		end
		if self.score_text ~= nil then
			self.score_text:Destroy()
			self.score_text = nil
		end
		
		--Destroy Hud Gui
		if self.gui ~= nil then
			self.gui:Destroy()
		end
	end

	--Hud interface
	local function ZeroPad(str, length)
		return string.rep("0", length - str:len())..str
	end

	function hud_class:UpdateDisplay(dt, player)
		debug.profilebegin("hud_class:UpdateDisplay")
		
		--Update ring flashes
		for i, v in pairs(self.ring_flashes) do
			if v:Update(dt) then
				--Destroy ring flashes
				v:Destroy()
				self.ring_flashes[i] = nil
			end
		end
		
		--Update item cards
		local reset = true
		for i, v in pairs(self.item_cards) do
			if v:Update(dt, self.item_card_shift) then
				--Destroy item card
				v:Destroy()
				self.item_cards[i] = nil
				
				--Shift item cards left
				for _,j in pairs(self.item_cards) do
					j:ShiftLeft()
				end
				self.item_card_shift = self.item_card_shift + 0.5
				self.item_card_x = self.item_card_x - 0.5
			else
				reset = false
			end
		end
		
		if reset then
			self.item_card_x = 0
			self.item_card_shift = 0
		else
			self.item_card_shift = self.item_card_shift * 0.9
		end
		
		--Update Hud display
		--Hud
		if player.score ~= self.score then
			--Update score display
			self.score_text:SetText(ZeroPad(tostring(player.score), 9))
			self.score = player.score
		end
		
		--Time
		if player.time ~= self.time then
			--Get text to display
			local millis = ZeroPad(tostring(math.floor((player.time % 1) * 100)), 2)
			local seconds = ZeroPad(tostring(math.floor(player.time % 60)), 2)
			local minutes = ZeroPad(tostring(math.floor(player.time / 60)), 2)
			
			--Update time display
			self.time_text:SetText(minutes..':'..seconds..'"'..millis)
			self.time = player.time
		end
		
		--Rings
		if player.rings ~= self.rings then
			--If rings increased, create a ring flash
			if self.rings ~= nil and player.rings > self.rings then
				table.insert(self.ring_flashes, ring_flash:New(self.ring_icon))
			end
			
			--Update ring display
			self.ring_text:SetText(ZeroPad(tostring(player.rings), 3))
			self.rings = player.rings
		end
		
		--Item cards
		local sheet_coord = {
			["5Rings"] =        Vector2.new(0, 0),
			["10Rings"] =       Vector2.new(1, 0),
			["20Rings"] =       Vector2.new(2, 0),
			["1Up"] =           Vector2.new(0, 1),
			["Invincibility"] = Vector2.new(1, 1),
			["SpeedShoes"] =    Vector2.new(5, 0),
			["Shield"] =        Vector2.new(3, 0),
			["MagnetShield"] =  Vector2.new(4, 0),
		}
		
		if #player.item_cards > 0 then
			--If the player wants to display new item cards, create them
			for _,v in pairs(player.item_cards) do
				--Shift cards left
				for _,j in pairs(self.item_cards) do
					j:ShiftLeft()
				end
				for _,_ in pairs(self.item_cards) do
					self.item_card_shift = self.item_card_shift + 0.5
					break
				end
				
				--Insert new card
				local contents_coord = (sheet_coord[v] or Vector2.new(0, 0))
				table.insert(self.item_cards, item_card:New(self.item_card_frame, self.item_card_x, contents_coord.X, contents_coord.Y))
				self.item_card_x = self.item_card_x + 0.5
			end
			player.item_cards = {}
		end
		
		--Blink ring counter
		if self.rings == 0 then
			self.ring_blinkt = self.ring_blinkt + dt
			self.ring_blink = 1 - (math.cos(self.ring_blinkt * 3) / 2 + 0.5)
		else
			self.ring_blink = self.ring_blink * (0.9 ^ 60) ^ dt
			self.ring_blinkt = 0
		end
		self.ring_text:SetColour(Color3.new(1, 1, 1):Lerp(Color3.new(1, 0, 0), self.ring_blink))
		
		--Update portrait
		if player.portrait ~= self.portrait then
			--Update portrait display
			local portrait = player.portraits[player.portrait]
			self.portrait_image.Image = portrait.image
			self.portrait_image.Position = portrait.pos
			self.portrait_image.Size = portrait.size
			self.portrait = player.portrait
			
			--Shake display
			if player.portrait == "Hurt" then
				self.hurt_shake = 0.25
			end
		end
		
		--Shake HUD
		if self.hurt_shake > 0 then
			self.hurt_shake = self.hurt_shake - dt
			if self.hurt_shake < 0 then
				self.hud_left.Position = UDim2.new(0, 0, 0, 0)
			else
				self.hud_left.Position = UDim2.new(math.cos(self.hurt_shake * 50) * 0.003, 0, math.sin(self.hurt_shake * 32) * 0.003, 0)
			end
		end
		
		debug.profileend()
	end

	return hud_class
end

-- PCONTROL OBJECTS

pcontrol.Object = {}
pcontrol.Object.DashPanel = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/DashPanel.lua
	Purpose: Dash Panel object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local dash_panel = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("DashPanel")

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Disable dash panels for SEO v3
		if player.v3 then
			return
		end
		
		--Make sure player is grounded and perform debounce check
		if self.debounce == nil or self.debounce <= 0 then
			if player.flag.grounded == true then
				--Align player with dash panel and set speed and state
				player.pos = (self.root.CFrame * CFrame.new(0, self.root.Size.Y / -2, 0)).p
				player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
				player.spd = Vector3.new((self.power / 60) / player.p.scale, player.spd.Y, 0)
				player:ResetObjectState()
				player.dashpanel_timer = self.nocon_time * 60
				
				--Play touch sound
				self.touch_sound:Play()
				
				--Set debounce
				self.debounce = 6
				self.update = Update
			end
		end
	end

	--Constructor and destructor
	function dash_panel:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = dash_panel})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.nocon_time = self.object:WaitForChild("Nocon").Value
		self.power = self.object:WaitForChild("Power").Value
		
		--Create touch sound
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		return self
	end

	function dash_panel:Destroy()
		--Destroy sound
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
	end

	return dash_panel
end

pcontrol.Object.DashRamp = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/DashRamp.lua
	Purpose: Dash Ramp object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local dash_ramp = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("DashRamp")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = replicated_storage:WaitForChild("CommonModules")

	local vector = require(common_modules:WaitForChild("Vector"))
	local constants = require(script.Parent.Parent:WaitForChild("Constants"))

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Debounce check
		if self.debounce == nil or self.debounce <= 0 then
			--Align player with dash panel and set speed and state
			player.pos = self.root.CFrame.p
			player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
			player:ResetObjectState()
			if player.v3 ~= true then
				player.spd = Vector3.new((self.power / 60) / player.p.scale, (self.power / 60) / player.p.scale / 1.5, 0)
				player.dashpanel_timer = self.nocon_time * 60
			else
				player.spd = player:PosToSpd(player:ToLocal(vector.Flatten(player:ToGlobal(player.spd), self.root.CFrame.UpVector)) + (self.root.CFrame.UpVector * (self.power / 60) / player.p.scale / 1.5))
			end
			player.state = constants.state.airborne
			player:ExitBall()
			player.animation = "DashRamp"
			
			--Play touch sound
			self.touch_sound:Play()
			
			--Set debounce
			self.debounce = 12
			self.update = Update
		end
	end


	--Constructor and destructor
	function dash_ramp:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = dash_ramp})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.nocon_time = self.object:WaitForChild("Nocon").Value
		self.power = self.object:WaitForChild("Power").Value
		
		--Create touch sound
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		return self
	end

	function dash_ramp:Destroy()
		--Destroy sound
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
	end

	return dash_ramp
end

pcontrol.Object.DashRing = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/DashRing.lua
	Purpose: Dash Ring object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local dash_ring = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("DashRing")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = replicated_storage:WaitForChild("CommonModules")

	local cframe = require(common_modules:WaitForChild("CFrame"))
	local vector = require(common_modules:WaitForChild("Vector"))
	local constants = require(script.Parent.Parent:WaitForChild("Constants"))

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Disable dash panels for SEO v3
		if player.v3 then
			return
		end
		
		--Perform debounce check
		if self.debounce == nil or self.debounce <= 0 then
			--Move player to rainbow ring and set speed
			player:SetAngle(player:AngleFromRbx(self.root.CFrame - self.root.CFrame.p))
			player.pos = self.root.Position - (player:GetUp() * (player.p.height * player.p.scale))
			player.spd = Vector3.new((self.power / 60) / player.p.scale, 0, 0)
			
			--Set dash ring state and make airborne
			player.state = constants.state.airborne
			player.flag.grounded = false
			player:ExitBall()
			player:ResetObjectState()
			player.dashring_timer = self.nocon_time * 60
			player.animation = "DashRing"
			player.reset_anim = true
			
			--Play touch sound
			self.touch_sound:Play()
			
			--Set debounce
			self.debounce = 6
			self.update = Update
		end
	end

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce == nil then
			self.debounce = 0
		elseif self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		end
	end

	--Constructor and destructor
	function dash_ring:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = dash_ring})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.nocon_time = self.object:WaitForChild("Nocon").Value
		self.power = self.object:WaitForChild("Power").Value
		
		--Create touch sound
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		return self
	end

	function dash_ring:Destroy()
		--Destroy sound
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
	end

	return dash_ring
end

pcontrol.Object.HomingTest = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/HomingTest.lua
	Purpose: Homing Attack Test object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local homing_test = {}

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Perform debounce check
		if self.debounce == nil or self.debounce <= 0 then
			--Check if should interact
			if player.flag.grounded ~= true and player:BallActive() then
				--Bounce player
				player.pos = player.pos + self.root.Position - player:GetMiddle()
				player:ObjectBounce()
				
				--Set debounce
				self.debounce = 6
				self.update = Update
			end
		end
	end

	--Constructor and destructor
	function homing_test:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = homing_test})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		--Set other specifications
		self.homing_target = true
		
		return self
	end

	function homing_test:Destroy()
		
	end

	return homing_test
end

pcontrol.Object.ItemBox = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/ItemBox.lua
	Purpose: Item Box object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local item_box = {}

	local object_common = require(script.Parent.Parent:WaitForChild("ObjectCommon"))

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("ItemBox")

	--Object functions
	local function Draw(self, dt)
		--Destroy particle once lifetime is over
		if self.touch_particle ~= nil then
			self.touch_particle_life = self.touch_particle_life - dt
			if self.touch_particle_life <= 0 then
				self.touch_particle:Destroy()
				self.touch_particle = nil
				self.draw = nil
			end
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		if player.v3 then
			return
		end
		
		if not self.opened then
			if player:BallActive() or not (player.flag.grounded and self.grounded) then
				--Bounce player
				if not player.flag.grounded then
					player:ObjectBounce()
				end
				
				--Open item box
				self.homing_target = false
				self.opened = true
				
				--Hide item box and destroy animation
				for _,v in pairs(self.hide) do
					v.LocalTransparencyModifier = 1
				end
				if self.anim ~= nil then
					self.anim:Destroy()
					self.anim = nil
				end
				
				--Emit particles and play sound
				if self.touch_particle ~= nil then
					self.touch_particle:Emit(20)
				end
				self.touch_sound:Play()
				
				--Change object state
				self.draw = Draw
				
				--Give player item and score
				player:GiveItem(self.contents)
				player:GiveScore(200)
			else
				--Push out of item box
				object_common.PushPlayerCylinder(self.root, player, 0.375)
			end
		elseif self.grounded then
			--Push out of item box if in lower half
			local loc_pos = self.root.CFrame:inverse() * player.pos
			if loc_pos.Y < 0 then
				object_common.PushPlayerCylinder(self.root, player, 0.25)
			end
		end
	end

	--Constructor and destructor
	function item_box:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = item_box})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		if object:FindFirstChild("Ground") then
			self.grounded = object.Ground.Value
		else
			self.grounded = false
		end
		self.contents = object:WaitForChild("Contents").Value
		self.anim_controller = object:WaitForChild("AnimationController")
		
		--Create touch sound and particle
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		self.particle_attachment = Instance.new("Attachment", self.root)
		self.touch_particle = obj_assets:WaitForChild("TouchParticle"):clone()
		self.touch_particle.Parent = self.particle_attachment
		self.touch_particle_life = self.touch_particle.Lifetime.Max
		
		--Create and play animation
		self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
		self.anim:Play()
		
		--Get parts that should be hidden when box is opened
		self.hide = {
			object:WaitForChild("ItemBox"),
			object.ItemBox:WaitForChild("Ext"),
		}
		
		--Setup contents textures
		local sheet_coord = {
			["5Rings"] =        Vector2.new(0, 0),
			["10Rings"] =       Vector2.new(1, 0),
			["20Rings"] =       Vector2.new(2, 0),
			["1Up"] =           Vector2.new(0, 1),
			["Invincibility"] = Vector2.new(1, 1),
			["SpeedShoes"] =    Vector2.new(5, 0),
			["Shield"] =        Vector2.new(3, 0),
			["MagnetShield"] =  Vector2.new(4, 0),
		}
		local contents_coord = (sheet_coord[self.contents] or Vector2.new(0, 0)) * 2.34
		
		for _,v in pairs(object:WaitForChild("Content"):GetChildren()) do
			if v:IsA("Texture") then
				v.OffsetStudsU = contents_coord.X
				v.OffsetStudsV = contents_coord.Y
				table.insert(self.hide, v)
			end
		end
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		--Set other specifications
		self.homing_target = true
		
		--Set state
		self.opened = false
		
		return self
	end

	function item_box:Destroy()
		--Restore hidden parts if opened
		if self.opened then
			for _,v in pairs(self.hide) do
				v.LocalTransparencyModifier = 0
			end
		end
		
		--Destroy animation
		if self.anim ~= nil then
			self.anim:Destroy()
			self.anim = nil
		end
		
		--Destroy sound and particle
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
		if self.particle_attachment ~= nil then
			self.particle_attachment:Destroy()
			self.particle_attachment = nil
		end
	end

	return item_box
end

pcontrol.Object.RainbowRing = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/RainbowRing.lua
	Purpose: Rainbow Ring object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local rainbow_ring = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("RainbowRing")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = replicated_storage:WaitForChild("CommonModules")

	local cframe = require(common_modules:WaitForChild("CFrame"))
	local vector = require(common_modules:WaitForChild("Vector"))
	local constants = require(script.Parent.Parent:WaitForChild("Constants"))

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Disable dash panels for SEO v3
		if player.v3 then
			return
		end
		
		--Perform debounce check
		if self.debounce == nil or self.debounce <= 0 then
			--Move player to rainbow ring and set speed
			player:SetAngle(player:AngleFromRbx(self.og_cf - self.og_cf.p))
			player.pos = self.root.Position - (player:GetUp() * (player.p.height * player.p.scale))
			player.spd = Vector3.new((self.power / 60) / player.p.scale, 0, 0)
			
			--Set rainbow ring state and make airborne
			player.state = constants.state.airborne
			player.flag.grounded = false
			player:ExitBall()
			player:ResetObjectState()
			player.dashring_timer = self.nocon_time * 60
			player.animation = "RainbowRing"
			player.reset_anim = true
			
			--Play touch sound
			self.touch_sound:Play()
			
			--Set debounce
			self.debounce = 6
			self.update = Update
		end
	end

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce == nil then
			self.debounce = 0
		elseif self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		end
	end

	--Constructor and destructor
	function rainbow_ring:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = rainbow_ring})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.nocon_time = self.object:WaitForChild("Nocon").Value
		self.power = self.object:WaitForChild("Power").Value
		self.anim_controller = self.object:WaitForChild("AnimationController")
		
		--Remember original object position
		self.og_cf = self.root.CFrame
		
		--Create touch sound
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		
		--Create and play animation
		self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
		self.anim:Play()
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		return self
	end

	function rainbow_ring:Destroy()
		--Destroy animation
		if self.anim ~= nil then
			self.anim:Destroy()
			self.anim = nil
		end
		
		--Destroy sound
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
		
		--Restore object position
		if self.object ~= nil then
			self.object:SetPrimaryPartCFrame(self.og_cf)
		end
	end

	return rainbow_ring
end

pcontrol.Object.Ring = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/Ring.lua
	Purpose: Ring object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local ring = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("Ring")

	--Object functions
	local function Update(self, i)
		if self.collected then
			--Restore position once collect animation is over
			if self.draw == nil then
				self.object:SetPrimaryPartCFrame(self.og_cf)
				self.update = nil
			end
		elseif self.attract_player ~= nil then
			--Adjust speed
			local diff = self.attract_player:GetMiddle() - self.root.Position
			if diff.magnitude ~= 0 then
				local spd_accel = (self.spd * (0.925 + (self.attract_force * (1 - 0.925)))) + (diff.unit * 0.175 * self.attract_force)
				self.spd = spd_accel:Lerp(diff, self.attract_force)
			end
			
			--Increase attraction
			self.attract_force = math.min(self.attract_force + 0.005, 1)
			
			--Move
			self.object:SetPrimaryPartCFrame(self.root.CFrame + self.spd)
		end
	end

	local function Draw(self, dt)
		local done = true
		
		--Fade light
		if self.light.Brightness > 0 then
			self.light.Brightness = math.max(self.light.Brightness - (dt / 0.5), 0)
			done = false
		end
		
		--Destroy particle once lifetime is over
		if self.touch_particle ~= nil then
			self.touch_particle_life = self.touch_particle_life - dt
			if self.touch_particle_life <= 0 then
				self.touch_particle:Destroy()
				self.touch_particle = nil
			else
				done = false
			end
		end
		
		--Stop running once done
		if done then
			self.draw = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		if player.v3 then
			return
		end
		
		--Change object state
		self.draw = Draw
		self.touch_player = nil
		
		--Give player ring and collect
		player:GiveScore(10)
		player:GiveRings(1)
		self.collected = true
		
		--Hide ring and destroy animation
		self.ring.LocalTransparencyModifier = 1
		if self.anim ~= nil then
			self.anim:Destroy()
			self.anim = nil
		end
		
		--Particle and sound
		if self.touch_particle ~= nil then
			self.touch_particle:Emit(20)
		end
		self.touch_sound:Play()
	end

	--Constructor and destructor
	function ring:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = ring})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.ring = object:WaitForChild("Ring")
		self.light = self.ring:WaitForChild("PointLight")
		self.light_brightness = self.light.Brightness
		self.anim_controller = object:WaitForChild("AnimationController")
		
		--Remember ring object position
		self.og_cf = self.ring.CFrame
		
		--Create touch sound and particle
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		self.particle_attachment = Instance.new("Attachment", self.root)
		self.touch_particle = obj_assets:WaitForChild("TouchParticle"):clone()
		self.touch_particle.Parent = self.particle_attachment
		self.touch_particle_life = self.touch_particle.Lifetime.Max
		
		--Create and play animation
		self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
		self.anim:Play()
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		--Set state
		self.spd = Vector3.new()
		self.attract_force = 0
		self.attract_player = nil
		self.collected = false
		
		return self
	end

	function ring:Destroy()
		--Restore ring visibility and light
		if self.collected then
			self.ring.LocalTransparencyModifier = 0
			if self.light ~= nil then
				self.light.Brightness = self.light_brightness
			end
		end
		
		--Destroy animation
		if self.anim ~= nil then
			self.anim:Destroy()
			self.anim = nil
		end
		
		--Destroy sound and particles
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
		if self.particle_attachment ~= nil then
			self.particle_attachment:Destroy()
			self.particle_attachment = nil
		end
		
		--Restore ring position
		if self.update ~= nil then
			self.object:SetPrimaryPartCFrame(self.og_cf)
		end
	end

	function ring:Attract(player)
		self.attract_player = player
		self.update = Update
	end

	return ring
end

pcontrol.Object.Spiketrap = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/Spiketrap.lua
	Purpose: Spiketrap object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local spiketrap = {}

	--Object contact
	local function TouchPlayer(self, player)
		if player.v3 then
			return
		end
		
		--Damage player
		player:Damage(self.root.Position)
	end

	--Constructor and destructor
	function spiketrap:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = spiketrap})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		return self
	end

	function spiketrap:Destroy()
		
	end

	return spiketrap
end

pcontrol.Object.SpilledRing = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/SpilledRing.lua
	Purpose: Spilled Ring object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local spilled_ring = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local vector = require(common_modules.Vector)
	local collision = require(common_modules.Collision)
	local global_reference = require(common_modules.GlobalReference)

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("Ring")

	--Constants
	local drag = 0.98
	local gravity = Vector3.new(0, 0.025, 0)
	local tick_rate = 4
	local collect_time = 60 * 0.75
	local destroy_time = 60 * 10
	local flicker_time = 60 * 8

	--Object functions
	local function GetNextPos(self, inc)
		if inc.magnitude > 0.01 then
			--Get collision whitelist
			local wl = {workspace.Terrain, collision_reference:Get()}
			
			--Perform collision raycasts
			local clip_off = Vector3.new(0, -1.125, 0)
			
			local elips = inc.unit * 0.01
			local hit, pos, nor = collision.Raycast(wl, (self.root.Position + clip_off) - elips, inc + elips)
			if hit then
				--Bounce
				local perp_spd = self.spd:Dot(nor)
				local surf_spd = vector.PlaneProject(self.spd, nor)
				self.spd = (surf_spd * 0.9) + (nor * perp_spd * -0.925)
			end
			
			--[[
			local hit2, pos2 = collision.Raycast(wl, pos - clip_off, clip_off)
			if hit2 then
				return pos2 - clip_off
			end
			--]]
			
			return pos - clip_off
		end
		return self.root.Position
	end

	local function Update(self, i)
		--Update ring appropriately
		local sub_tick = i % tick_rate
		
		if sub_tick == 0 then
			--Drag and fall
			self.spd = self.spd * drag ^ tick_rate
			self.spd = self.spd - gravity * tick_rate
			
			--Get next position and sub speed
			local next_pos = GetNextPos(self, self.spd * tick_rate)
			self.sub_spd = (next_pos - self.root.Position) / tick_rate
		elseif self.sub_spd == nil then
			--Get ticks to simulate
			local sim_ticks = tick_rate - sub_tick
			
			--Drag and fall
			self.spd = self.spd * drag ^ sim_ticks
			self.spd = self.spd - gravity * sim_ticks
			
			--Get next position and sub speed
			local next_pos = GetNextPos(self, self.spd * sim_ticks)
			self.sub_spd = (next_pos - self.root.Position) / sim_ticks
		end
		
		--Move
		self.object:SetPrimaryPartCFrame(self.root.CFrame + self.sub_spd)
		
		--Destroy object after timer runs out
		self.time = self.time + 1
		if self.time >= destroy_time then
			local object = self.object
			self.object = nil
			object:Destroy()
		end
	end

	local function Draw(self, dt)
		if self.collected then
			local done = true
			
			--Fade light
			if self.light.Brightness > 0 then
				self.light.Brightness = math.max(self.light.Brightness - (dt / 0.5), 0)
				done = false
			end
			
			--Destroy particle once lifetime is over
			if self.touch_particle ~= nil then
				self.touch_particle_life = self.touch_particle_life - dt
				if self.touch_particle_life <= 0 then
					self.touch_particle:Destroy()
					self.touch_particle = nil
				else
					done = false
				end
			end
			
			--Destroy once done
			if done then
				local object = self.object
				self.object = nil
				object:Destroy()
			end
		else
			--Flicker
			if self.time >= flicker_time then
				self.ring.LocalTransparencyModifier = 1 - self.ring.LocalTransparencyModifier
			end
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		if player.v3 then
			return
		end
		
		if self.time >= collect_time then
			--Change object state
			self.update = nil
			self.touch_player = nil
			
			--Give player ring and collect
			player:GiveRings(1)
			self.collected = true
			
			--Hide ring and destroy animation
			self.ring.LocalTransparencyModifier = 1
			if self.anim ~= nil then
				self.anim:Destroy()
				self.anim = nil
			end
			
			--Particle and sound
			if self.touch_particle ~= nil then
				self.touch_particle:Emit(20)
			end
			self.touch_sound:Play()
		end
	end

	--Constructor and destructor
	function spilled_ring:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = spilled_ring})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.ring = object:WaitForChild("Ring")
		self.light = self.ring:WaitForChild("PointLight")
		self.light_brightness = self.light.Brightness
		self.anim_controller = object:WaitForChild("AnimationController")
		
		--Create touch sound and particle
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		self.particle_attachment = Instance.new("Attachment", self.root)
		self.touch_particle = obj_assets:WaitForChild("TouchParticle"):clone()
		self.touch_particle.Parent = self.particle_attachment
		self.touch_particle_life = self.touch_particle.Lifetime.Max
		
		--Create and play animation
		self.anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("Anim"))
		self.anim:Play()
		
		--Attach functions
		self.update = Update
		self.draw = Draw
		self.touch_player = TouchPlayer
		
		--Set state
		self.time = 0
		self.spd = self.root.Velocity / 60
		self.sub_spd = nil
		self.collected = false
		
		return self
	end

	function spilled_ring:Destroy()
		--Destroy object
		if self.object ~= nil then
			self.object:Destroy()
		end
	end

	return spilled_ring
end

pcontrol.Object.SpilledRing = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Object/Spring.lua
	Purpose: Spring object
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local spring = {}

	local assets = GLOBALASSETS
	local obj_assets = assets:WaitForChild("Spring")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local cframe = require(common_modules.CFrame)
	local vector = require(common_modules.Vector)
	local constants = require(pcontrol.Constants)

	local object_common = require(pcontrol.ObjectCommon)

	--Object functions
	local function Update(self, i)
		--Decrement debounce
		if self.debounce > 0 then
			self.debounce = math.max(self.debounce - 1, 0)
		else
			self.update = nil
		end
	end

	--Object contact
	local function TouchPlayer(self, player)
		--Perform debounce check
		if self.debounce == nil or self.debounce <= 0 then
			--Set player angle
			if player.v3 ~= true then
				if math.abs(self.root.CFrame.UpVector:Dot(player.gravity.unit)) < 0.95 then
					player:SetAngle(player:AngleFromRbx(CFrame.lookAt(Vector3.new(), self.root.CFrame.UpVector, -player.gravity.unit) * CFrame.Angles(math.pi / -2, 0, 0)))
				else
					player:SetAngle(cframe.FromToRotation(player:GetUp(), self.root.CFrame.UpVector) * player.ang)
				end
			end
			
			--Align player with spring and set speed
			player.pos = self.root.Position
			if player.v3 ~= true then
				player.spd = Vector3.new(0, (self.power / 60) / player.p.scale, 0)
			else
				player.spd = player:ToLocal(Vector3.new(0, (self.power / 60) / player.p.scale, 0))
			end
			
			--Set spring state and make airborne
			player.state = constants.state.airborne
			player.flag.grounded = false
			player:ExitBall()
			player:ResetObjectState()
			player.flag.air_kick = true
			if player.v3 ~= true then
				player.spring_timer = self.nocon_time * 60
				player.flag.scripted_spring = self.scripted
			end
			player.animation = "SpringStart"
			player.reset_anim = true
			
			--Play touch sound and animation
			self.touch_sound:Play()
			self.touch_anim:Play()
			
			--Set debounce
			self.debounce = 6
			self.update = Update
		end
	end

	--Constructor and destructor
	function spring:New(object)
		--Initialize meta reference
		local self = setmetatable({}, {__index = spring})
		
		--Use object information
		self.object = object
		self.root = object.PrimaryPart
		self.anim_controller = self.object:WaitForChild("AnimationController")
		self.nocon_time = self.object:WaitForChild("Nocon").Value
		self.power = self.object:WaitForChild("Power").Value
		
		if self.power < 0 then
			--Scripted
			self.power = self.power * -1
			self.scripted = true
		else
			--Not scripted
			self.scripted = false
		end
		
		--Create touch sound
		self.touch_sound = obj_assets:WaitForChild("TouchSound"):clone()
		self.touch_sound.Parent = self.root
		
		--Load touch animation
		self.touch_anim = self.anim_controller:LoadAnimation(obj_assets:WaitForChild("TouchAnim"))
		
		--Attach functions
		self.touch_player = TouchPlayer
		
		--Set other specifications
		self.homing_target = true
		
		return self
	end

	function spring:Destroy()
		--Destroy sound and animation
		if self.touch_sound ~= nil then
			self.touch_sound:Destroy()
			self.touch_sound = nil
		end
		if self.touch_anim ~= nil then
			self.touch_anim:Destroy()
			self.touch_anim = nil
		end
	end

	return spring
end

pcontrol.Object.init = function()
	--[[
	= DigitalSwirl Client =
	Source: ControlScript/Object.lua
	Purpose: Game Object manager
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local object_class = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local collision = require(common_modules.Collision)
	local spatial_partitioning = require(common_modules.SpatialPartitioning.init)

	--Object creation and destruction
	local function AddObject(self, v)
		if self.objects ~= nil then
			--Create new object class instance
			if self.class ~= nil and self.class[v.Name] then
				--Construct object
				local new = self.class[v.Name]:New(v)
				if new == nil then
					error("Failed to create class instance for object "..v.Name)
				end
				
				--Set general object information
				new.class = v.Name
				
				--Register object root
				local root = new.root
				if root ~= nil then
					if self.root_lut[root] == nil then
						self.root_lut[root] = new
						table.insert(self.roots, root)
						self.spatial_partitioning:Add(root)
					else
						self.root_lut[root] = new
					end
				end
				
				--Push object to object list
				self.objects[v] = new
			end
		end
	end

	local function DestroyObject(self, v)
		--Check if object is currently registered
		if self.objects ~= nil and self.objects[v] then
			--Deregister object root
			local root = self.objects[v].root
			if root ~= nil then
				self.root_lut[root] = nil
				for i, v in pairs(self.roots) do
					if v == root then
						self.roots[i] = nil
						break
					end
				end
				self.spatial_partitioning:Remove(root)
			end
			
			--Destroy object
			self.objects[v]:Destroy()
			self.objects[v] = nil
		end
	end

	--Object connection
	local ChildAddedFunction = nil --prototype
	local ChildRemovedFunction = nil --prototype

	local function ConnectFolder(self, p)
		--Recursively connect subfolders and initialize already existing objects
		for _, v in pairs(p:GetChildren()) do
			ChildAddedFunction(self, v)
		end
		
		--Connect for child creation and deletion
		table.insert(self.connections, p.ChildAdded:Connect(function(v)
			ChildAddedFunction(self, v)
		end))
		table.insert(self.connections, p.ChildRemoved:Connect(function(v)
			ChildRemovedFunction(self, v)
		end))
	end

	--Connection functions
	ChildAddedFunction = function(self, v)
		if v:IsA("Folder") or (v:IsA("Model") and v.PrimaryPart == nil) then
			ConnectFolder(self, v)
		elseif v:IsA("Model") then
			AddObject(self, v)
		end
	end

	ChildRemovedFunction = function(self, v)
		if v:IsA("Model") then
			DestroyObject(self, v)
		end
	end

	--Constructor and destructor
	function object_class:New()
		--Initialize meta reference
		local self = setmetatable({}, {__index = object_class})
		
		--Initialize object arrays
		self.objects = {}
		self.connections = {}
		
		--Initialize spatial partitioning
		self.spatial_partitioning = spatial_partitioning:New(16)
		self.root_lut = {}
		self.roots = {}
		
		--Load all object types
		self.class = {}
		--[[
		for _, v in pairs(script:GetChildren()) do
			if v:IsA("ModuleScript") then
				self.class[v.Name] = require(v)
			end
		end
		]]
		for k, v in pairs (pcontrol.Object) do
			if typeof(v) == "function" then
				self.class[k] = require(v)
			end
		end
		
		--Initial object connection
		ConnectFolder(self, workspace:WaitForChild("Level"):WaitForChild("Objects"))
		
		--Initialize state
		self.update_osc_time = 0
		
		return self
	end

	function object_class:Destroy()
		--Release classes
		self.class = nil
		
		--Destroy all objects
		if self.objects ~= nil then
			for _,v in pairs(self.objects) do
				v:Destroy()
			end
			self.objects = nil
		end
		
		--Destroy spatial partitioning
		if self.spatial_partitioning ~= nil then
			self.spatial_partitioning:Destroy()
			self.spatial_partitioning = nil
		end
		
		self.root_lut = nil
		self.roots = nil
		
		--Disconnect connections
		if self.connections ~= nil then
			for _, v in pairs(self.connections) do
				v:Disconnect()
			end
			self.connections = nil
		end
	end

	--Internal object interface
	function object_class:GetObjectsInRegion(region, cond)
		debug.profilebegin("object_class:GetObjectsInRegion")
		
		local objs = {}
		if self.root_lut ~= nil then
			--Perform Region3 check for roots
			local hit_roots = self.spatial_partitioning:GetPartsInRegion(region)
			
			--Get list of objects from hit roots
			for _,v in pairs(hit_roots) do
				local obj = self.root_lut[v]
				if obj ~= nil and (cond == nil or cond(obj)) then
					table.insert(objs, obj)
				end
			end
		end
		
		debug.profileend()
		return objs
	end

	--Object interface
	function object_class:Update()
		debug.profilebegin("object_class:Update")
		
		--Update all objects
		if self.objects ~= nil then
			local j = self.update_osc_time
			for i, v in pairs(self.objects) do
				if v.update ~= nil then
					--Update object
					v.update(v, j)
					j = j + 1
				end
			end
			self.update_osc_time = self.update_osc_time + 1
		end
		
		debug.profileend()
	end

	function object_class:Draw(dt)
		debug.profilebegin("object_class:Draw")
		
		--Draw all objects
		if self.objects ~= nil then
			for _,v in pairs(self.objects) do
				if v.draw ~= nil then
					--Draw object
					v.draw(v, dt)
				end
			end
		end
		
		debug.profileend()
	end

	function object_class:GetNearest(pos, max_dist, cond_init, cond_dist)
		debug.profilebegin("object_class:GetNearest")
		
		local nearest_obj = nil
		if self.objects ~= nil then
			--Get objects that are rougly within the given distance
			local check_region = Region3.new(
				pos - Vector3.new(max_dist, max_dist, max_dist),
				pos + Vector3.new(max_dist, max_dist, max_dist)
			)
			
			local objects = self:GetObjectsInRegion(check_region, function(v)
				return (cond_init == nil or cond_init(v)) and v.root ~= nil
			end)
			
			--Get nearest object out of the found objects
			local nearest_dis = math.huge
			for _,v in pairs(objects) do
				local dis = (v.root.Position - pos).magnitude
				if dis <= max_dist and dis <= nearest_dis and (cond_dist == nil or cond_dist(v)) then
					nearest_dis = dis
					nearest_obj = v
				end
			end
		end
		
		debug.profileend()
		return nearest_obj
	end

	function object_class:GetNearestDot(pos, dir, max_dist, max_dot, w1, w2, cond_init, cond_dist)
		debug.profilebegin("object_class:GetNearestDot")
		
		local obj = nil
		if self.objects ~= nil then
			--Get objects that are rougly within the given distance
			local check_region = Region3.new(
				pos - Vector3.new(max_dist, max_dist, max_dist),
				pos + Vector3.new(max_dist, max_dist, max_dist)
			)
			
			local objects = self:GetObjectsInRegion(check_region, function(v)
				return (cond_init == nil or cond_init(v)) and v.root ~= nil
			end)
			
			--Get list of targetable objects that meet the general requirements
			local obj_list = {}
			
			for _,v in pairs(objects) do
				local dif = (v.root.Position - pos)
				local dis = dif.magnitude
				local dot = dif.unit:Dot(dir)
				if dis <= max_dist and dot >= max_dot and (cond_dist == nil or cond_dist(v)) then
					table.insert(obj_list, {
						obj = v,
						dis = 1 - (dis / max_dist),
						dot = dot,
					})
				end
			end
			
			--Sort object list
			table.sort(obj_list, function(a, b)
				return ((a.dis * w1) + (a.dot * w2)) > ((b.dis * w1) + (b.dot * w2))
			end)
			
			--Return nearest object
			if obj_list[1] ~= nil then
				obj = obj_list[1].obj
			end
		end
		
		debug.profileend()
		return obj
	end

	--Object collision
	function object_class:TouchPlayer(player)
		debug.profilebegin("object_class:TouchPlayer")
		
		if self.objects ~= nil then
			--Get player sphere and region
			local player_sphere = player:GetSphere()
			local player_region = player:GetRegion()
			
			--Get list of objects to check
			local objects = self:GetObjectsInRegion(player_region, function(v)
				return (v.root ~= nil and v.touch_player ~= nil)
			end)
			
			--Check for collision with all objects
			for _,v in pairs(objects) do
				--Check if object collides
				if collision.TestSphereRotatedBox(player_sphere, {cframe = v.root.CFrame, size = v.root.Size}) then
					--Run object touch function
					v.touch_player(v, player)
				end
			end
		end
		
		debug.profileend()
	end

	return object_class
end

-- PLAYER CONTROLSCRIPT --

pcontrol.Player = {}
pcontrol.Player.Acceleration = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Acceleration.lua
	Purpose: Player acceleration functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_acceleration = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local vector = require(commons.Vector)

	local input = require(pcontrol.Player.Input.init)
	local sound = require(pcontrol.Player.Sound)
	local movement = require(script.Parent:WaitForChild("Movement"))

	--Ground movement interface
	function player_acceleration.GetAcceleration(self)
		--Get physics values
		local weight = self:GetWeight()
		local max_x_spd = self:GetMaxXSpeed()
		local run_accel = self:GetRunAccel() * (self.v3 and 1.5 or 1)
		local frict_mult = self.flag.grounded and self.frict_mult or 1
		
		--Get gravity force
		local acc = self:ToLocal(self.gravity * weight)
		
		--Get cross product between our moving velocity and floor normal
		local tnorm_cross_velocity = self.floor_normal:Cross(self:ToGlobal(self.spd))
		
		--Amplify gravity
		if self.dotp < 0.875 then
			if self.dotp >= 0.1 or math.abs(tnorm_cross_velocity.Y) <= 0.6 or self.spd.X < 1.16 then
				if self.dotp >= -0.4 or self.spd.X <= 1.16 then
					if self.dotp < -0.3 and self.spd.X > 1.16 then
						--acc = vector.AddY(acc, weight * -0.8)
					elseif self.dotp < -0.1 and self.spd.X > 1.16 then
						--acc = vector.AddY(acc, weight * -0.4)
					elseif self.dotp < 0.5 and math.abs(self.spd.X) < self.p.run_speed then
						acc = vector.MulX(acc, 4.225)
						acc = vector.MulZ(acc, 4.225)
					elseif self.dotp >= 0.7 or math.abs(self.spd.X) > self.p.run_speed then
						if self.dotp >= 0.87 or self.p.jog_speed <= math.abs(self.spd.X) then
							--acc = acc
						else
							acc = vector.MulZ(acc, 1.4)
						end
					else
						acc = vector.MulZ(acc, 2)
					end
				else
					--acc = vector.AddY(acc, weight * -5)
				end
			else
				acc = Vector3.new(0, -weight, 0)
			end
		else
			acc = Vector3.new(0, -weight, 0)
		end
		
		--Get analogue state
		local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
		
		--Air drag
		if self.v3 ~= true then
			--X air drag
			local spd_x = self.spd.X
			
			if has_control then
				if spd_x <= max_x_spd or self.dotp <= 0.96 then
					if spd_x > max_x_spd then
						acc = vector.AddX(acc, (spd_x - max_x_spd) * self.p.air_resist)
					elseif spd_x < 0 then
						acc = vector.AddX(acc, spd_x * self.p.air_resist)
					end
				else
					acc = vector.AddX(acc, (spd_x - max_x_spd) * (self.p.air_resist * 1.7))
				end
			else
				if spd_x > self.p.run_speed then
					acc = vector.AddX(acc, spd_x * self.p.air_resist)
				elseif spd_x > max_x_spd then
					acc = vector.AddX(acc, (spd_x - max_x_spd) * self.p.air_resist)
				elseif spd_x < 0 then
					acc = vector.AddX(acc, spd_x * self.p.air_resist)
				end
			end
			
			--Y and Z air drag
			self.spd = self.spd + self.spd * Vector3.new(0, self:GetAirResistY(), self.p.air_resist_z)
		else
			self.spd = vector.AddZ(self.spd, self.spd.Z * self.p.air_resist_z)
		end
		
		--Movement
		if has_control then
			--Get acceleration
			if self.spd.X >= max_x_spd then
				--Use lower acceleration if above max speed
				if self.spd.X < max_x_spd or self.dotp >= 0 then
					move_accel = run_accel * analogue_mag * 0.4
				else
					move_accel = run_accel * analogue_mag
				end
			else
				--Get acceleration, stopping at intervals based on analogue stick magnitude
				move_accel = 0
				
				if self.spd.X >= self.p.jog_speed then
					if self.spd.X >= self.p.run_speed then
						if self.spd.X >= self.p.rush_speed then
							move_accel = run_accel * analogue_mag
						elseif analogue_mag <= 0.9 then
							move_accel = run_accel * analogue_mag * 0.3
						else
							move_accel = run_accel * analogue_mag
						end
					elseif analogue_mag <= 0.7 then
						if self.spd.X < self.p.run_speed then
							move_accel = run_accel * analogue_mag
						end
					else
						move_accel = run_accel * analogue_mag
					end
				elseif analogue_mag <= 0.5 then
					if self.spd.X < (self.p.jog_speed + self.p.run_speed) * 0.5 then
						move_accel = run_accel * analogue_mag
					end
				else
					move_accel = run_accel * analogue_mag
				end
			end
			
			--Turning
			local diff_angle = math.abs(analogue_turn)
			local forward_speed = self.spd.X
			
			if math.abs(forward_speed) < 0.001 and diff_angle > math.rad(22.5) then
				move_accel = 0
				self:AdjustAngleYQ(analogue_turn)
			else
				if forward_speed < (self.p.jog_speed + self.p.run_speed) * 0.5 or diff_angle <= math.rad(22.5) then
					if forward_speed < self.p.jog_speed or diff_angle >= math.rad(22.5) then
						if forward_speed < self.p.dash_speed or not self.flag.grounded then
							if forward_speed >= self.p.jog_speed and forward_speed <= self.p.rush_speed and diff_angle > math.rad(45) then
								move_accel = move_accel * 0.8
							end
							self:AdjustAngleY(analogue_turn)
						else
							self:AdjustAngleYS(analogue_turn)
						end
					else
						self:AdjustAngleYS(analogue_turn)
					end
				else
					move_accel = self.p.slow_down * (self.v3 and 0 or 1) / frict_mult
					self:AdjustAngleY(analogue_turn)
				end
			end
		else
			--Decelerate
			move_accel = movement.GetDecel(self.spd.X + acc.X, self.p.slow_down * (self.v3 and 4 or 1))
		end
		
		--Apply movement acceleration
		if self.v3 then
			if self.spd.X * math.sign(move_accel) > (self.flag.underwater and 2 or 4) then
				move_accel = 0
			end
		end
		acc = vector.AddX(acc, move_accel * frict_mult)
		
		--Apply acceleration
		self.spd = self.spd + acc
	end

	function player_acceleration.GetAirAcceleration(self)
		--Get analogue state
		local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
		
		--Gravity
		local weight
		if (self.dashring_timer > 0) or (self.spring_timer > 0 and self.flag.scripted_spring == true) then
			weight = 0
		else
			weight = self:GetWeight()
		end
		
		self.spd = self.spd + self:ToLocal(self.gravity) * weight
		
		--Air drag
		if self.v3 ~= true then
			self.spd = self.spd + self.spd * Vector3.new(
				self.p.air_resist_air,
				self:GetAirResistY(),
				self.p.air_resist_z
			) / (1 + self.rail_trick)
		else
			self.spd = vector.AddZ(self.spd, self.spd.Z * self.p.air_resist_z)
		end
		
		--Use lighter gravity if A is held or doing a rail trick
		if (self.rail_trick > 0) or (self.jump_timer > 0 and self.flag.ball_aura and self.input.button.jump) then
			self.jump_timer = math.max(self.jump_timer - 1, 0)
			self.spd = vector.AddY(self.spd, self.p.jmp_addit * 0.8 * (1 + self.rail_trick / 2))
		end
		
		--Get our acceleration
		local accel
		if self.rail_trick > 0 then
			--Constant acceleration
			accel = self.p.air_accel * (1 + self.rail_trick / 2.5)
			self.last_turn = 0
		elseif not has_control then
			--No acceleration
			if self.v3 then
				accel = movement.GetDecel(self.spd.X, self.p.slow_down * 2)
			else
				accel = 0
			end
		else
			--Check if we should "skid"
			if (self.spd.X <= self.p.run_speed) or (math.abs(analogue_turn) <= math.rad(135)) then
				if math.abs(analogue_turn) <= math.rad(22.5) then
					if self.spd.Y >= 0 then
						accel = self.p.air_accel * analogue_mag
					else
						accel = self.p.air_accel * 2 * analogue_mag
					end
				else
					accel = 0
				end

				self:AdjustAngleY(analogue_turn)
			else
				--Air brake
				accel = self.p.air_break * analogue_mag
			end
		end
		
		--Accelerate
		if self.v3 and accel > 0 then
			accel = accel * 2
		end
		self.spd = vector.AddX(self.spd, accel)
	end

	return player_acceleration
end

pcontrol.Player.Animation = function()
	--[[

	= Sonic Onset Adventure Client =

	Source: ControlScript/Player/Animation.lua
	Purpose: Player animation functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local player_animation = {}

	local footstep_sounds = script.Parent:WaitForChild("FootstepSounds")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local constants = require(pcontrol.Constants)
	local collision = require(commons.Collision)
	local switch = require(commons.Switch)
	local rail = require(pcontrol.Player.Rail)
	local global_reference = require(common_modules:WaitForChild("GlobalReference"))

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	local function psign(x)
		return (x < 0) and -1 or 1
	end

	local function StringSplit(s, delimiter)
		local spl = {}
		for match in (s..delimiter):gmatch("(.-)"..delimiter) do
			table.insert(spl, match)
		end
		return spl
	end

	--Animation events
	local footstep_mats = {
		[Enum.Material.Plastic] = "Plastic",
		[Enum.Material.Wood] = "Wood",
		[Enum.Material.Slate] = "Stone",
		[Enum.Material.Concrete] = "Stone",
		[Enum.Material.CorrodedMetal] = "Metal",
		[Enum.Material.DiamondPlate] = "Metal",
		[Enum.Material.Foil] = "Metal",
		[Enum.Material.Grass] = "Grass",
		[Enum.Material.Ice] = "Metal",
		[Enum.Material.Marble] = "Stone",
		[Enum.Material.Granite] = "Stone",
		[Enum.Material.Brick] = "Stone",
		[Enum.Material.Pebble] = "Stone",
		[Enum.Material.Sand] = "Sand",
		[Enum.Material.Fabric] = "Dirt",
		[Enum.Material.SmoothPlastic] = "Plastic",
		[Enum.Material.Metal] = "Metal",
		[Enum.Material.WoodPlanks] = "Wood",
		[Enum.Material.Cobblestone] = "Stone",
		[Enum.Material.Air] = nil,
		[Enum.Material.Water] = "Water",
		[Enum.Material.Rock] = "Stone",
		[Enum.Material.Glacier] = "Metal",
		[Enum.Material.Snow] = "Snow",
		[Enum.Material.Sandstone] = "Stone",
		[Enum.Material.Mud] = "Dirt",
		[Enum.Material.Basalt] = "Stone",
		[Enum.Material.Ground] = "Dirt",
		[Enum.Material.CrackedLava] = "Stone",
		[Enum.Material.Neon] = "Metal",
		[Enum.Material.Glass] = "Metal",
		[Enum.Material.Asphalt] = "Stone",
		[Enum.Material.LeafyGrass] = "Grass",
		[Enum.Material.Salt] = "Stone",
		[Enum.Material.Limestone] = "Stone",
		[Enum.Material.Pavement] = "Stone",
		[Enum.Material.ForceField] = "Metal",
	}

	local facial_assets = {
		["Mouth"] = {
			["DefaultSmile"] = "rbxassetid://5961059446",
			["OpenSmile"] = "rbxassetid://5961060028",
			["AdventureSmile"] = "rbxassetid://5961059112",
			["AngrySmile"] = "rbxassetid://5961059315",
			["Frown"] = "rbxassetid://5961059731",
			["MouthOpen"] = "rbxassetid://5961059833",
			["MouthOpenConcern"] = "rbxassetid://5961059938",
		},
		["LEye"] = {
			["DefaultEyes"] = "rbxassetid://5961059553",
			["RedEyes"] = "rbxassetid://5961060113",
			["Wink"] = "rbxassetid://5961060175",
		},
		["REye"] = {
			["DefaultEyes"] = "rbxassetid://5961059553",
			["RedEyes"] = "rbxassetid://5961060113",
			["Wink"] = "rbxassetid://5961060175",
		},
	}

	local function AnimFootstep(self, anim, pos)
		if anim.WeightCurrent > 0.5 and self.hrp ~= nil then
			--Send a raycast down from the foot to find the floor material
			local up = self.hrp.CFrame.UpVector
			local hit, pos, nor, mat = collision.Raycast({workspace.Terrain, collision_reference:Get()}, (self.hrp.CFrame * pos) + up, up * -2)
			
			if hit ~= nil then
				--Get material
				local mapped_mat
				local mat_override = hit:FindFirstChild("Material")
				if mat_override and mat_override:IsA("StringValue") then
					mapped_mat = mat_override.Value
				else
					mapped_mat = footstep_mats[mat]
				end
				
				if mapped_mat ~= nil and self.footstep_sounds[mapped_mat] and #self.footstep_sounds[mapped_mat] > 0 then
					--Get random sound
					local f = self.footstep_sounds[mapped_mat]
					local snd = f[math.random(1, #f)]
					
					--Play sound
					snd.Volume = self.footstep_volumes[mapped_mat][snd.Name] * (0.55 + math.abs(anim.Speed) / 6.5)
					snd:Play()
				end
			end
		end
	end

	local function AttachEvents(self, anim)
		--Attach keyframe events
		local character = self.character
		if character ~= nil then
			--Footstep
			anim:GetMarkerReachedSignal("LStep"):Connect(function()
				AnimFootstep(self, anim, Vector3.new(-0.75, -self:GetCharacterYOff(), 0))
			end)
			anim:GetMarkerReachedSignal("RStep"):Connect(function()
				AnimFootstep(self, anim, Vector3.new(0.75, -self:GetCharacterYOff(), 0))
			end)
			
			--Facial
			local facial_parts = {
				["Mouth"] = self.mouth,
				["LEye"] = self.left_eye,
				["REye"] = self.right_eye,
			}
			
			for i, v in pairs(facial_parts) do
				for j, k in pairs(facial_assets[i]) do
					anim:GetMarkerReachedSignal(i.."-"..j):Connect(function()
						v.TextureID = k
					end)
				end
			end
		end
	end

	--Animation interface
	function player_animation.LoadAnimations(self)
		--Get facial parts
		self.mouth = self.character:WaitForChild("Mouth_Geo")
		self.left_eye = self.character:WaitForChild("LeftIris_Geo")
		self.right_eye = self.character:WaitForChild("RightIris_Geo")
		
		--Load animation tracks from animations folder
		self.animation_tracks = {}
		
		local animations = self.assets:WaitForChild("Animations")
		for _,v in pairs(animations:GetChildren()) do
			if v:IsA("Animation") then
				--Load new animation track and attach footsteps if a running animation
				local new_anim = self.hum:LoadAnimation(v)
				AttachEvents(self, new_anim)
				
				--Register animation
				self.animation_tracks[v.Name] = new_anim
			end
		end
		
		--Load footsteps
		self.footstep_sounds = {}
		self.footstep_volumes = {}
		
		for _,f in pairs(footstep_sounds:GetChildren()) do
			--Load footstep folders
			if f:IsA("Folder") then
				--Register folder
				self.footstep_sounds[f.Name] = {}
				self.footstep_volumes[f.Name] = {}
				
				--Load sounds
				for _,v in pairs(f:GetChildren()) do
					--Create new sound object and parent to sound source
					local new_snd = v:Clone()
					new_snd.Parent = self.sound_source or self.hrp
					
					--Register new sound
					table.insert(self.footstep_sounds[f.Name], new_snd)
					self.footstep_volumes[f.Name][v.Name] = v.Volume
				end
			end
		end
		
		--Get dynamic tilt joints
		self.tilt_neck = self.hrp:WaitForChild("Root"):WaitForChild("LowerTorso"):WaitForChild("UpperTorso"):WaitForChild("Neck")
		self.tilt_neck_cf = self.tilt_neck.CFrame
		self.tilt_torso = self.hrp:WaitForChild("Root"):WaitForChild("LowerTorso")
		self.tilt_torso_cf = self.tilt_torso.CFrame
	end

	function player_animation.UnloadAnimations(self)
		--Unload animations
		if self.animation_tracks ~= nil then
			for _,v in pairs(self.animation_tracks) do
				v:Destroy()
			end
			self.animation_tracks = nil
		end
		
		--Unload sounds
		if self.footstep_sounds ~= nil then
			for _,f in pairs(self.footstep_sounds) do
				for _,v in pairs(f) do
					v:Destroy()
				end
			end
			self.footstep_sounds = nil
		end
	end

	function player_animation.GetAnimationTrack(self)
		local track = nil
		local track_weight = 0
		
		for _,v in pairs(self.animations[self.animation].tracks) do
			if self.animation_tracks[v.name].WeightCurrent >= track_weight then
				track = self.animation_tracks[v.name]
				track_weight = track.WeightCurrent
			end
		end
		
		return track
	end

	function player_animation.GetAnimationRate(self)
		local track = player_animation.GetAnimationTrack(self)
		if track ~= nil and track.Length > 0 then
			return track.Speed / track.Length
		end
		return 0
	end

	function player_animation.Animate(self)
		if self.animation ~= nil then
			if self.animation == self.prev_animation then
				--Handle animation end changes
				if self.animations[self.animation].end_anim ~= nil then
					local track = player_animation.GetAnimationTrack(self)
					if track ~= nil and (track.IsPlaying == false or track.TimePosition >= track.Length) then
						self.animation = self.animations[self.animation].end_anim
					end
				end
				
				--Handle animation specific changes
				switch(self.animation, {}, {
					["Spring"] = function()
						if self.spd.Y < 0 then
							self.animation = "Fall"
						end
					end,
					["DashRing"] = function()
						if self.dashring_timer <= 0 then
							self.animation = "Fall"
						end
					end,
					["RainbowRing"] = function()
						if self.dashring_timer <= 0 then
							self.animation = "Fall"
						end
					end,
					["DashRamp"] = function()
						if self.dashpanel_timer <= 0 then
							self.animation = "Fall"
						end
					end,
				})
			end
			
			--Animation changes
			if self.animation ~= self.prev_animation or self.reset_anim then
				--Reset facial state
				self.mouth.TextureID = facial_assets["Mouth"]["DefaultSmile"]
				self.left_eye.TextureID = facial_assets["LEye"]["DefaultEyes"]
				self.right_eye.TextureID = facial_assets["REye"]["DefaultEyes"]
				
				--Stop previous animation
				if self.prev_animation ~= nil then
					for _,v in pairs(self.animations[self.prev_animation].tracks) do
						self.animation_tracks[v.name]:Stop()
					end
				end
				
				--Play new animation
				self.prev_animation = self.animation
				for _,v in pairs(self.animations[self.animation].tracks) do
					self.animation_tracks[v.name]:Play()
				end
			end
			
			--Handle animation speed
			if self.animations[self.animation].spd_b and self.animations[self.animation].spd_i then
				--Get speed to set
				local spd = self.animations[self.animation].spd_b + math.abs(self.anim_speed) * self.animations[self.animation].spd_i
				if not self.animations[self.animation].spd_a then
					spd = spd * psign(self.anim_speed)
				end
				
				--Set track speeds
				for _,v in pairs(self.animations[self.animation].tracks) do
					self.animation_tracks[v.name]:AdjustSpeed(spd)
				end
			end
			
			--Handle animation weights
			if #self.animations[self.animation].tracks > 1 then
				--Get track to play
				local playing_track = self.animations[self.prev_animation].tracks[1].name
				local playing_pos = 0
				
				for _,v in pairs(self.animations[self.prev_animation].tracks) do
					if v.pos >= playing_pos and self.anim_speed >= v.pos then
						playing_track = v.name
						playing_pos = v.pos
					end
				end
				
				--Adjust weights accordingly
				for _,v in pairs(self.animations[self.prev_animation].tracks) do
					if v.name == playing_track then
						self.animation_tracks[v.name]:AdjustWeight(1)
					else
						self.animation_tracks[v.name]:AdjustWeight(0.01)
					end
				end
			end
		end
		
		--[[
		--Reset animation state
		if self.animation ~= self.prev_animation or self.reset_anim then
			--Reset facial state
			self.mouth.TextureID = facial_assets["Mouth"]["DefaultSmile"]
			self.left_eye.TextureID = facial_assets["LEye"]["DefaultEyes"]
			self.right_eye.TextureID = facial_assets["REye"]["DefaultEyes"]
		end
		
		--Animation changes
		if self.animation == "Spring" then
			if self.spd.Y < 0 then
				self.animation = "Fall"
			end
		elseif self.animation == "DashRing" or self.animation == "RainbowRing" then
			if self.dashring_timer <= 0 then
				self.animation = "Fall"
			end
		elseif self.animation == "DashRamp" then
			if self.dashpanel_timer <= 0 then
				self.animation = "Fall"
			end
		elseif self.animation == "SpringStart" then
			local anim = self.animation_tracks[self.animation]
			if anim ~= nil then
				if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
					self.animation = "Spring"
				end
			end
		elseif string.sub(self.animation, 1, 5) == "Trick" then
			local anim = self.animation_tracks[self.animation]
			if anim ~= nil then
				if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
					self.animation = "Fall"
				end
			end
		elseif self.animation == "Land" then
			local anim = self.animation_tracks[self.animation]
			if anim ~= nil then
				if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
					self.animation = "Idle"
				end
			end
		elseif self.animation == "RailLand" then
			local anim = self.animation_tracks[self.animation]
			if anim ~= nil then
				if self.animation == self.prev_animation and (anim.IsPlaying == false or anim.TimePosition >= anim.Length) then
					self.animation = "Rail"
				end
			end
		end
		
		--Run animation
		if self.animation == "Run" then
			--Get animation weights
			local trans_length = 0.35
			local run_start = ((self.p.run_speed + self.p.dash_speed) / 2) - (trans_length / 2)
			local speed = (0.25 + math.abs(self.anim_speed) / 0.95) * psign(self.anim_speed)
			local weight = math.clamp((self.spd.X - run_start) / trans_length, 0.001, 0.999)
			
			if self.reset_anim == true or self.prev_animation ~= "Run" then
				--Stop previous animation
				if self.prev_animation then
					self.animation_tracks[self.prev_animation]:Stop()
				end
				self.prev_animation = self.animation
				
				--Play new animations
				self.animation_tracks["Jog2"]:Play()
				self.animation_tracks["Run"]:Play()
			end
			
			--Adjust animation speeds and weights
			self.animation_tracks["Jog2"]:AdjustSpeed(speed)
			self.animation_tracks["Jog2"]:AdjustWeight(1 - weight)
			self.animation_tracks["Run"]:AdjustSpeed(speed)
			self.animation_tracks["Run"]:AdjustWeight(weight)
		elseif self.animation_tracks[self.animation] then
			if self.reset_anim == true or self.animation ~= self.prev_animation then
				--Stop previous animation
				if self.prev_animation == "Run" then
					self.animation_tracks["Jog2"]:Stop()
					self.animation_tracks["Run"]:Stop()
				elseif self.prev_animation then
					self.animation_tracks[self.prev_animation]:Stop()
				end
				self.prev_animation = self.animation
				
				--Play new animation
				self.animation_tracks[self.animation]:Play()
			end
			
			--Update animation speed
			if self.animation == "Roll" or self.animation == "Spindash" then
				self.animation_tracks[self.animation]:AdjustSpeed(1.5 + math.abs(self.anim_speed) / 1.55)
			elseif self.animation == "Rail" or self.animation == "RailCrouch" then
				self.animation_tracks[self.animation]:AdjustSpeed(0.125 + math.abs(self.anim_speed) / 2)
			end
		end
		--]]
		
		--Clear animation reset flag now that it's been processed
		self.reset_anim = false
	end

	--Dynamic tilt
	local function TiltJoint(self, dt, joint, tilt)
		joint.CFrame = joint.CFrame:Lerp(tilt, (0.675 ^ 60) ^ dt)
	end

	function player_animation.DynTilt(self, dt)
		--Get how much player is trying to turn
		local turn = self.last_turn or 0
		if math.abs(turn) < math.rad(135) then
			turn = math.clamp(turn, math.rad(-80), math.rad(80))
		else
			turn = 0
		end
		self.anim_turn = self.anim_turn ~= nil and lerp(self.anim_turn, turn, (0.6275 ^ 60) ^ dt) or 0
		
		--Tilt head
		local tilt = math.clamp(self.anim_turn * -(1.125 + self.spd.X / 6), math.rad(-60), math.rad(60))
		TiltJoint(self, dt, self.tilt_neck, self.tilt_neck_cf *CFrame.Angles(0, -tilt, 0))
		
		--Tilt torso
		local tilt = math.clamp(self.anim_turn * (0.4 + self.spd.X / 4), math.rad(-30), math.rad(30))
		TiltJoint(self, dt, self.tilt_torso, self.tilt_torso_cf * CFrame.Angles(0, 0, tilt))
	end

	return player_animation
end

pcontrol.Player.Collision = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Collision.lua
	Purpose: Player collision functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_collision = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local constants = require(pcontrol.Constants)
	local vector = require(commons.Vector)
	local cframe = require(commons.CFrame)
	local collision = require(commons.Collision)
	local global_reference = require(commons.GlobalReference)

	local ragdoll = require(pcontrol.Player.Ragdoll)

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")
	local water_reference = global_reference:New(workspace, "Level/Water")

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Normal alignment
	local function GetAligned(self, normal)
		if self.state == constants.state.ragdoll then
			return self.ang
		end
		if self:GetUp():Dot(normal) < -0.999 then
			return CFrame.Angles(math.pi, 0, 0) * self.ang
		end
		local rot = cframe.FromToRotation(self:GetUp(), normal)
		return rot * self.ang
	end

	local function AlignNormal(self, normal)
		self:SetAngle(GetAligned(self, normal))
	end

	--Velocity cancel for walls
	local function VelCancel(vel, normal)
		local dot = vel:Dot(normal.unit)
		if dot < 0 then
			return vel - (normal.unit) * dot
		end
		return vel
	end

	local function LocalVelCancel(self, vel, normal)
		return self:ToLocal(VelCancel(self:ToGlobal(vel), normal.unit))
	end

	local function LocalFlatten(self, vector, normal)
		return self:ToLocal(vector.Flatten(self:ToGlobal(vector), normal.unit))
	end

	--Wall collision
	local function WallRay(self, wl, y, dir, vel)
		--Raycast
		local rdir = dir * self.p.rad * self.p.scale
		local from = self.pos + self:GetUp() * y
		local fdir = dir * (self.p.rad + vel) * self.p.scale
		local to = from + fdir
		
		local hit, pos, nor = collision.Raycast(wl, from, fdir)
		
		if hit then
			return (pos - rdir) - from, nor, pos
		end
		return nil, nil, nil
	end

	local function CheckWallAttach(self, dir, nor)
		local ddot = dir:Dot(nor)
		local sdot = self:ToGlobal(self.spd):Dot(nor)
		local udot = self:GetUp():Dot(nor)
		return (ddot < -0.35 and sdot < -1.16 and udot > 0.5)
	end

	local function WallAttach(self, wl, nor)
		local fup = self.p.height * self.p.scale
		local fdown = fup + (self.p.pos_error * self.p.scale)
		local hit, pos, hnor = collision.Raycast(wl, self.pos + self:GetUp() * fup, nor * -fdown)
		if hit then
			self.pos = pos
			self:SetAngle(GetAligned(self, hnor))
		end
	end

	local function WallHit(self, nor)
		self.spd = LocalVelCancel(self, self.spd, nor)
	end

	local function WallCollide(self, wl, y, dir, vel, fattach, battach)
		--Positive and negative wall collision
		local wf_pos, wf_nor, wf_tp = WallRay(self, wl, y, dir, math.max(vel, 0))
		local wb_pos, wb_nor, wb_tp = WallRay(self, wl, y, -dir, math.max(-vel, 0))
		
		--Clip with walls
		local move = true
		if wf_pos and wb_pos then
			self.pos = self.pos + (wf_pos + wb_pos) / 2
			local mid = wf_nor + wb_nor
			if mid.magnitude ~= 0 then
				wf_nor = mid.unit
			else
				wf_nor = nil
			end
			wb_nor = nil
			move = false
		elseif wf_pos then
			self.pos = self.pos + wf_pos
		elseif wb_pos then
			self.pos = self.pos + wb_pos
		end
		
		--Velocity cancelling
		if wf_nor then
			if fattach and CheckWallAttach(self, dir, wf_nor) then
				WallAttach(self, wl, wf_nor)
				move = false
			else
				WallHit(self, wf_nor)
			end
		end
		if wb_nor then
			if battach and CheckWallAttach(self, -dir, wb_nor) then
				WallAttach(self, wl, wb_nor)
				move = false
			else
				WallHit(self, wb_nor)
			end
		end
		return move
	end

	--Water collision
	local function PointInWater(pos)
		--Check for terrain water
		local voxel_pos = workspace.Terrain:WorldToCell(pos)
		local voxel_region = Region3.new(voxel_pos * 4, (voxel_pos + Vector3.new(1, 1, 1)) * 4)
		local material_map, occupancy_map = workspace.Terrain:ReadVoxels(voxel_region, 4)
		local voxel_material = material_map[1][1][1]
		if voxel_material == Enum.Material.Water then
			return true
		end
		
		--Check for part water
		local water = water_reference:Get()
		if water ~= nil then
			local near_water = workspace:FindPartsInRegion3WithWhiteList(voxel_region, water:GetChildren())
			
			for _, v in pairs(near_water) do
				local local_pos = v.CFrame:inverse() * pos
				if collision.SqDistPointAABB(local_pos, {min = v.Size / -2, max = v.Size / 2}) <= 0 then
					return true
				end
			end
		end
	end

	--Collision call
	function player_collision.Run(self)
		debug.profilebegin("player_collision.Run")
		
		--Remember previous state
		local prev_spd = self:ToGlobal(self.spd)
		
		--Get collision whitelist
		local wl = {workspace.Terrain, collision_reference:Get()}
		
		--Stick to moving floors
		if self.flag.grounded and self.floor ~= nil and self.floor_last ~= nil then
			local prev_world = self.floor_last * self.floor_off
			local new_world = self.floor.CFrame * self.floor_off
			local rt_rot = cframe.FromToRotation(prev_world.RightVector, new_world.RightVector)
			local up_rot = cframe.FromToRotation(prev_world.UpVector, new_world.UpVector)
			self.floor_move = new_world.p - prev_world.p
			self.pos = self.pos + self.floor_move
			self:SetAngle(rt_rot * self.ang)
		end
		
		for i = 1, 4 do
			--Remember previous position
			local prev_pos = self.pos
			local prev_mid = self:GetMiddle()
			
			--Wall collision heights
			local height_scale = (self.state == constants.state.roll) and 0.8 or 1
			local heights = {
				self.p.height * 0.85 * self.p.scale * height_scale,
				self.p.height * 1.25 * self.p.scale * height_scale,
				self.p.height * 1.95 * self.p.scale * height_scale,
			}
			
			--Wall collision and horizontal movement
			local xmove, zmove = true, true
			for i,v in pairs(heights) do
				if WallCollide(self, wl, v, self:GetLook(), self.spd.X, (self.flag.grounded or (self.spd.Y <= 0)) and (i == 1), false) == false then
					xmove = false
				end
				if WallCollide(self, wl, v, self:GetRight(), self.spd.Z, false, false) == false then
					zmove = false
				end
			end
			
			if xmove then
				self.pos = self.pos + self:GetLook() * self.spd.X * self.p.scale
			end
			if zmove then
				self.pos = self.pos + self:GetRight() * self.spd.Z * self.p.scale
			end
			
			--Ceiling collision
			local cup = self.p.height * self.p.scale
			local cdown = cup
			
			if self.spd.Y > 0 then
				cdown = cdown + self.spd.Y * self.p.scale --Moving upwards, extend raycast upwards
			elseif self.spd.Y < 0 then
				cup = cup + self.spd.Y * self.p.scale --Moving downwards, move raycast downwards
			end
			
			local from = self.pos + self:GetUp() * cup
			local dir = self:GetUp() * cdown
			local hit, pos, nor = collision.Raycast(wl, from, dir)
			
			if hit then
				if self.flag.grounded then
					--Set ceiling clip flag
					self.flag.ceiling_clip = nor:Dot(self.gravity.unit) > 0.9
				else
					--Clip and cancel velocity
					self.pos = pos - (self:GetUp() * (self.p.height * 2 * self.p.scale))
					self.spd = LocalVelCancel(self, self.spd, nor)
					self.flag.ceiling_clip = false
				end
			else
				--Clear ceiling clip flag
				self.flag.ceiling_clip = false
			end
			
			--Floor collision
			local pos_error
			if self.v3 then
				pos_error = self.flag.grounded and (0.01) or ((self.spd.Y > 0) and 0 or (self.p.pos_error * self.p.scale))
			else
				pos_error = self.flag.grounded and (self.p.pos_error * self.p.scale) or 0
			end
			local fup = self.p.height * self.p.scale
			local fdown = -(fup + pos_error)
			
			if self.spd.Y < 0 then
				fdown = fdown + self.spd.Y * self.p.scale --Moving downwards, extend raycast downwards
			elseif self.spd.Y > 0 then
				fup = fup + self.spd.Y * self.p.scale --Moving upwards, move raycast upwards
			end
			
			local from = self.pos + self:GetUp() * fup
			local dir = self:GetUp() * fdown
			local hit, pos, nor = collision.Raycast(wl, from, dir)
			
			--Do additional collision checks
			if hit then
				local drop = false
				
				if hit:FindFirstChild("NoFloor") then
					--Floor cannot be stood on under any conditions
					drop = true
				elseif self.flag.grounded then
					--Don't stay on the floor if we're going too slow on a steep floor
					if self:GetUp():Dot(nor) < 0.3 then
						drop = true
					elseif nor:Dot(-self.gravity.unit) < 0.4 then
						if ((self.spd.X ^ 2) + (self.spd.Z ^ 2)) < (1.16 ^ 2) then
							drop = true
						end
					end
				else
					--Don't collide with the floor if we won't land at a speed fast enough to stay on it
					local next_spd = vector.Flatten(self:ToGlobal(self.spd), nor)
					local next_ang = GetAligned(self, nor)
					local next_lspd = (next_ang:inverse() * next_spd) * Vector3.new(1, 0, 1)
					if nor:Dot(-self.gravity.unit) < 0.4 then
						if next_lspd.magnitude < 1.16 then
							drop = true
						end
					end
				end
				
				--Do simple collision
				if drop then
					self.spd = LocalVelCancel(self, self.spd, nor)
					self.pos = pos
					hit = nil
				end
			end
			
			--Do standard floor collision
			if hit then
				--Snap to ground
				self.pos = pos
				self.floor = hit
				
				--Align with ground
				if not (self.flag.grounded or self.v3) then
					self.spd = vector.Flatten(self:ToGlobal(self.spd), nor)
					
					self.flag.grounded = true
					AlignNormal(self, nor)
					
					self.spd = self:ToLocal(self.spd)
				else
					self.flag.grounded = true
					AlignNormal(self, nor)
				end
				
				--Kill any lingering vertical speed
				self.spd = vector.SetY(self.spd, 0)
			else
				--Move vertically and unground
				self.pos = self.pos + self:GetUp() * self.spd.Y * self.p.scale
				self.flag.grounded = false
				self.floor = nil
			end
			
			--Check if we clipped through something from our previous position to our new position
			local new_mid = self:GetMiddle()
			if new_mid ~= prev_mid then
				local new_add = (new_mid - prev_mid).unit * (self.p.rad * self.p.scale)
				local new_end = new_mid-- + new_add
				local hit, pos, nor = collision.Raycast(wl, prev_mid, (new_end - prev_mid))
				if hit then
					--Clip us out
					self.pos = self.pos + (pos - new_add) - new_mid
					self.spd = LocalVelCancel(self, self.spd * 0.8, nor)
				else
					break
				end
			else
				break
			end
		end
		
		--Check if we're submerged in water
		self.flag.underwater = PointInWater(self.pos + self:GetUp() * (self.p.height * self.p.scale))
		
		--Handle floor positioning
		if not self.v3 then
			if self.flag.grounded and self.floor ~= nil then
				self.floor_off = self.floor.CFrame:inverse() * (self.ang + self.pos)
				self.floor_last = self.floor.CFrame
				if self.floor_move == nil then
					self.floor_move = self.floor.Velocity / constants.framerate
				end
			else
				self.floor = nil
				self.floor_off = CFrame.new()
				self.floor_last = nil
				self:UseFloorMove()
			end
		else
			self.floor = nil
			self.floor_off = CFrame.new()
			self.floor_last = nil
			self.floor_move = nil
		end
		
		--Get final global speed
		self.gspd = self:ToGlobal(self.spd)
		
		--V3 ragdoll
		if self.v3 then
			ragdoll.Bounce(self, prev_spd, self.gspd)
		end
		
		debug.profileend()
	end

	return player_collision
end

pcontrol.Player.HomingAttack = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/HomingAttack.lua
	Purpose: Player Homing Attack functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_homing_attack = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local vector = require(commons.Vector)
	local cframe = require(commons.CFrame)
	local collision = require(commons.Collision)
	local global_reference = require(commons.GlobalReference)

	local acceleration = require(pcontrol.Player.Acceleration)

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

	--Homing attack object checks
	local function HomingCond_Init(self, v)
		--Check if object is homable
		return v.homing_target
	end

	local function HomingCond_Dist(self, v)
		--Check for upwards height difference
		local loc = (self.ang + self.pos):inverse() * v.root.Position
		if loc.Y > 20 * self.p.scale then
			return false
		end
		
		--Check if there's collision between us and the object
		local mypos = self:GetMiddle()
		local hit = collision.Raycast({workspace.Terrain, collision_reference:Get()}, mypos, v.root.Position - mypos)
		return hit == nil
	end

	local function GetHomingObject(self, object_instance)
		return object_instance:GetNearestDot(self.pos, self:GetLook(), 100 * self.p.scale, 0.3825, 1, 0.5,
			function(v)
				return HomingCond_Init(self, v)
			end,
			function(v)
				return HomingCond_Dist(self, v)
			end
		)
	end

	--Homing attack interface
	function player_homing_attack.CheckStartHoming(self, object_instance)
		--Check for homing object and return if it was found
		self.homing_obj = GetHomingObject(self, object_instance)
		return self.homing_obj ~= nil
	end

	function player_homing_attack.RunHoming(self, object_instance)
		if self.homing_obj ~= nil then
			--Align to gravity
			self:SetAngle(cframe.FromToRotation(self:GetUp(), -self.gravity.unit) * self.ang)
			
			--Update homing object
			local next_homing_obj = GetHomingObject(self, object_instance)
			if next_homing_obj ~= nil then
				self.homing_obj = next_homing_obj
			end
			
			--Get angle difference and turn
			local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
			local local_pos = world_cf:inverse() * self.homing_obj.root.Position
			local local_turnpos = local_pos * Vector3.new(1, 0, 1)
			local local_dir = local_turnpos.magnitude ~= 0 and local_turnpos.unit or Vector3.new(0, 0, -1)
			
			local max_turn = math.rad(11.25) --22.5 when super
			max_turn = max_turn * 1 + (self.homing_timer / 40)
			
			local turn = vector.SignedAngle(Vector3.new(0, 0, -1), local_dir, Vector3.new(0, 1, 0))
			self:Turn(math.clamp(turn, -max_turn, max_turn))
			
			--Get power
			local power = 5 --10 if super sonic
			if self.homing_timer > 180 then
				power = power * (0.7 + math.random() * 0.1) --Sputter power when we've been homing for 3 seconds
			end
			
			--Set speed
			local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
			local local_pos = world_cf:inverse() * self.homing_obj.root.Position
			
			if local_pos.magnitude ~= 0 then
				local local_spd = local_pos.unit
				local forward_mag = (local_spd * Vector3.new(1, 0, 1)).magnitude
				self.spd = Vector3.new(forward_mag * power, local_spd.Y * power, 0)
			end
			
			--Increment homing timer
			self.homing_timer = self.homing_timer + 1
			
			--Drop homing attack if we're gone by the object
			local pos_diff = self.homing_obj.root.Position - (self.pos + self:ToGlobal(self.spd) * self.p.scale)
			if pos_diff.magnitude ~= 0 then
				if pos_diff.unit:Dot(self:GetLook()) < 0 then
					return true
				end
			end
			return false
		else
			--Drag and do regular movement
			self.spd = vector.MulX(self.spd, 0.98)
			acceleration.GetAcceleration(self)
			
			--Increment homing timer
			self.homing_timer = self.homing_timer + 1
			return self.homing_timer >= 15
		end
	end

	return player_homing_attack
end

pcontrol.Player.LSD = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/LSD.lua
	Purpose: Player Light Speed Dash functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_lsd = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons
	
	local vector = require(commons.Vector)
	local cframe = require(commons.CFrame)
	local collision = require(commons.Collision)
	local global_reference = require(commons.GlobalReference)

	local collision_reference = global_reference:New(workspace, "Level/Map/Collision")

	--Light speed dash object checks
	local function LSD_Init(self, v)
		--Check if object is a ring
		return v.class == "Ring" and v.collected ~= true
	end

	local function LSD_Dist(self, v)
		--Check if there's collision between us and the object
		local mypos = self:GetMiddle()
		local hit = collision.Raycast({workspace.Terrain, collision_reference:Get()}, mypos, v.root.Position - mypos)
		return hit == nil
	end

	local function GetLSDObject(self, object_instance)
		local dis = (self.lsd_obj ~= nil) and 20 or 15
		local dot = -0.1
		return object_instance:GetNearestDot(self:GetMiddle(), self:GetLook(), 20, -0.1, 1, 0,
			function(v)
				return LSD_Init(self, v)
			end,
			function(v)
				return LSD_Dist(self, v)
			end
		)
	end

	local function ValidateStartLSD(self, object_instance)
		if self.lsd_obj ~= nil then
			--Get closest ring to target ring
			local look = self:GetLook()
			local dis = 20
			local near = object_instance:GetNearest(self.lsd_obj.root.Position, dis,
				function(v)
					return LSD_Init(self, v) and v ~= self.lsd_obj
				end,
				nil
			)
			if near == nil then
				return false
			end
			
			--Check if we can light dash these two rings
			local dir = near.root.Position - self.lsd_obj.root.Position
			if dir.magnitude == 0 then
				return false
			else
				dir = dir.unit
			end
			
			return math.abs(look:Dot(dir)) > 0.5
		else
			return false
		end
	end

	--Homing attack interface
	function player_lsd.CheckStartLSD(self, object_instance)
		--Check for homing object and return if it was found
		self.lsd_obj = GetLSDObject(self, object_instance)
		return ValidateStartLSD(self, object_instance)
	end

	function player_lsd.RunLSD(self, object_instance)
		--Align to gravity
		self.flag.grounded = false
		self:SetAngle(cframe.FromToRotation(self:GetUp(), -self.gravity.unit) * self.ang)
		
		--Get next object
		self.lsd_obj = GetLSDObject(self, object_instance)
		if self.lsd_obj == nil then
			if self.v3 == true then
				self.spd = Vector3.new()
			elseif self.spd.magnitude ~= 0 then
				self.spd = self.spd.unit * 5
			end
			return true
		end
		
		--Get angle difference and turn
		local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
		local local_pos = world_cf:inverse() * self.lsd_obj.root.Position
		local local_turnpos = local_pos * Vector3.new(1, 0, 1)
		local local_dir = local_turnpos.magnitude ~= 0 and local_turnpos.unit or Vector3.new(0, 0, -1)
		
		local max_turn = math.rad(33.75)
		
		local turn = vector.SignedAngle(Vector3.new(0, 0, -1), local_dir, Vector3.new(0, 1, 0))
		self:Turn(math.clamp(turn, -max_turn, max_turn))
		
		--Get dash power and speed
		local world_cf = self:ToWorldCFrame() + (self:GetUp() * (self.p.height * self.p.scale))
		local local_pos = world_cf:inverse() * self.lsd_obj.root.Position
		local power = math.clamp(local_pos.magnitude / self.p.scale, 2, 8)
		
		if local_pos.magnitude ~= 0 then
			self.spd = self:PosToSpd(local_pos.unit * power)
		end
		
		return false
	end

	return player_lsd
end

pcontrol.Player.Movement = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Movement.lua
	Purpose: Player movement functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_movement = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local vector = require(common_modules.Vector)
	local cframe = require(common_modules.CFrame)

	local input = require(pcontrol.Player.Input.init)

	--Acceleration functions
	function player_movement.GetDecel(spd, dec)
		if spd > 0 then
			return -math.min(spd, -dec)
		elseif spd < 0 then
			return math.min(-spd, -dec)
		end
		return 0
	end

	--Rotation / turning
	function player_movement.RotatedByGravity(self)
		local a1a = self:ToGlobal(self.spd)
		local dotp = (a1a.unit):Dot(self.gravity.unit)
		
		if a1a.magnitude <= self.p.jog_speed or dotp >= -0.86 then
			local a2a = self:ToLocal(self.gravity.unit)
			
			if a2a.Y <= 0 and a2a.y > -0.87 then
				--Get turn
				if a2a.X < 0 then
					a2a = vector.MulX(a2a, -1)
				end
				
				local turn = -math.atan2(a2a.Z, a2a.X)
				
				--Get max turn
				if a2a.Z < 0 then
					a2a = vector.MulZ(a2a, -1)
				end
				
				local max_turn
				if self.flag.ball_aura then
					max_turn = a2a.Z * math.rad(16.875)
				else
					max_turn = a2a.Z * math.rad(8.4375)
				end
				
				--Turn
				turn = math.clamp(turn, -max_turn, max_turn)
				return self:Turn(turn)
			end
		end
		return 0
	end

	function player_movement.RotatedByGravityS(self)
		local a1a = self:ToGlobal(self.spd)
		
		if a1a.magnitude > self.p.jog_Speed then
			local dotp = (a1a.unit):Dot(self.gravity.unit)
			
			if dotp > -0.86 then
				local a2a = self:ToLocal(self.gravity.unit)
				
				if a2a.Y > -0.87 then
					--Get turn
					if a2a.X < 0 then
						a2a = vector.MulX(a2a, -1)
					end
					
					local turn = -math.atan2(a2a.Z, a2a.X)
					
					--Get max turn
					if a2a.Z < 0 then
						a2a = vector.MulZ(a2a, -1)
					end
					
					local max_turn
					if self.flag.ball_aura then
						max_turn = math.abs((self.spd.X / self.p.jog_speed) * a2a.Z * math.rad(22.5))
					else
						max_turn = a2a.Z * math.rad(11.25)
					end
					
					--Turn
					turn = math.clamp(turn, -max_turn, max_turn)
					return self:Turn(turn)
				end
			end
		end
		return 0
	end

	function player_movement.GetRotation(self)
		--Get analogue state
		local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
		
		if has_control then
			--Turn
			if self.v3 then
				self:Turn(analogue_turn)
			else
				self:AdjustAngleY(analogue_turn)
			end
		end
	end

	function player_movement.AlignToGravity(self)
		if self.spd.magnitude < self.p.dash_speed then
			--Remember previous speed
			local prev_spd = self:ToGlobal(self.spd)
			
			--Get next angle
			local from = self:GetUp()
			local to = -self.gravity.unit
			local turn = vector.Angle(from, to)
			
			if turn ~= 0 then
				local max_turn = math.rad(11.25)
				local lim_turn = math.clamp(turn, -max_turn, max_turn)
				
				local next_ang = cframe.FromToRotation(from, to) * self.ang
				
				self:SetAngle(self.ang:Lerp(next_ang, lim_turn / turn))
			end
			
			--Keep using previous speed
			self.spd = self:ToLocal(prev_spd)
		end
	end

	--Acceleration / friction
	function player_movement.GetSkidSpeed(self)
		--Get physics values
		local weight = self:GetWeight()
		
		--Get gravity force
		local acc = self:ToLocal(self.gravity * weight)
		
		--Air drag
		if self.v3 ~= true then
			self.spd = self.spd + self.spd * Vector3.new(
				self.p.air_resist,
				self:GetAirResistY(),
				self.p.air_resist_z
			)
		else
			self.spd = self.spd + self.spd * Vector3.new(
				-1,
				0,
				self.p.air_resist_z
			)
		end
		
		--Friction
		local x_frict = self.p.run_break * self.frict_mult
		local z_frict = self.p.grd_frict_z * self.frict_mult
		local x_accel = player_movement.GetDecel(self.spd.X + acc.X, x_frict)
		local z_accel = player_movement.GetDecel(self.spd.Z + acc.Z, z_frict)
		
		--Apply acceleration
		acc = acc + Vector3.new(x_accel, 0, z_accel)
		self.spd = self.spd + acc
	end

	function player_movement.GetInertia(self)
		--Gravity
		local weight = self:GetWeight()
		local acc = self:ToLocal(self.gravity) * weight
		
		--Amplify gravity
		if self.flag.grounded and self.spd.X > self.p.run_speed and self.dotp < 0 then
			acc = vector.MulY(acc, -8)
		end
		
		--Air drag
		if self.flag.ball_aura and self.dotp < 0.98 then
			acc = vector.AddX(acc, self.spd.X * -0.0002)
		else
			acc = vector.AddX(acc, self.spd.X * self.p.air_resist)
		end
		acc = vector.AddY(acc, self.spd.Y * self.p.air_resist_y)
		acc = vector.AddZ(acc, self.spd.Z * self.p.air_resist_z)
		
		--Apply acceleration
		self.spd = self.spd + acc
	end

	return player_movement
end

pcontrol.Player.Ragdoll = function()
	--[[

	= Sonic Onset Adventure Client =

	Source: ControlScript/Player/Ragdoll.lua
	Purpose: Player ragdoll functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local player_ragdoll = {}

	local constants = require(pcontrol.Constants)

	local sound = require(pcontrol.Player.Sound)

	function player_ragdoll.Bounce(self, pspd, nspd)
		--Bounce
		local diff = nspd - pspd
		self.spd = self:ToLocal(nspd + diff * (0.5 + math.random() * 0.35))
		
		--Enter ragdoll if bounced hard
		if diff.magnitude > 6 and self.state ~= constants.state.ragdoll then
			--Enter ragdoll state
			self.do_ragdoll = true--self.state = constants.state.ragdoll
			self.ragdoll_time = 0
			sound.PlaySound(self, "Trip")
		end
		
		if diff.magnitude > 1 then
			--Angle speed
			local ang_force = self.spd.magnitude / 20
			self.ragdoll_ang_spd = CFrame.Angles((math.random() * 2 - 1) * ang_force, (math.random() * 2 - 1) * ang_force, (math.random() * 2 - 1) * ang_force)
		end
	end

	function player_ragdoll.Physics(self)
		--Gravity and air drag
		self.spd = self.spd + self:ToLocal(self.gravity) * self.p.weight
		self.spd = self.spd * 0.995
		
		--Rotate
		local gspd = self:ToGlobal(self.spd)
		self.flag.grounded = false
		self:SetAngle(self.ang * self.ragdoll_ang_spd)
		self.spd = self:ToLocal(gspd)
		
		--Check if we should stop
		if self.spd.magnitude < 1 then
			self.ragdoll_time = self.ragdoll_time + 1
			if self.ragdoll_time > 60 then
				sound.PlaySound(self, "GetUp")
				return true
			end
		else
			self.ragdoll_time = math.max(self.ragdoll_time - 1, 0)
		end
		return false
	end

	return player_ragdoll
end

pcontrol.Player.Rail = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Rail.lua
	Purpose: Player Rail Grinding functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_rail = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local input = require(pcontrol.Player.Input.init)
	local constants = require(pcontrol.Constants)
	local vector = require(commons.Vector)
	local collision = require(commons.Collision)
	local spatial_partitioning = require(commons.SpatialPartitioning.init)
	local sound = require(pcontrol.Sound)
	local global_reference = require(commons.GlobalReference)

	local rails_reference = global_reference:New(workspace, "Level/Rails")

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Rail connection
	local ChildAddedFunction = nil --prototype
	local ChildRemovedFunction = nil --prototype

	local function ConnectFolder(self, p)
		--Recursively connect subfolders and initialize already existing objects
		for _, v in pairs(p:GetChildren()) do
			ChildAddedFunction(self, v)
		end
		
		--Connect for child creation and deletion
		table.insert(self.rail_cons, p.ChildAdded:Connect(function(v)
			ChildAddedFunction(self, v)
		end))
		table.insert(self.rail_cons, p.ChildRemoved:Connect(function(v)
			ChildRemovedFunction(self, v)
		end))
	end

	--Connection functions
	ChildAddedFunction = function(self, v)
		if v:IsA("Folder") or v:IsA("Model") then
			ConnectFolder(self, v)
		elseif v:IsA("Part") then
			self.rail_spatial_partitioning:Add(v)
		end
	end

	ChildRemovedFunction = function(self, v)
		if v:IsA("Part") then
			self.rail_spatial_partitioning:Remove(v)
		end
	end

	--Rail interface
	function player_rail.Initialize(self)
		--Initialize spatial partitioning
		self.rail_cons = {}
		self.rail_spatial_partitioning = spatial_partitioning:New(16)
		ConnectFolder(self, workspace:WaitForChild("Level"):WaitForChild("Rails"))
	end

	function player_rail.Quit(self)
		--Destroy spatial partitioning
		if self.rail_spatial_partitioning ~= nil then
			self.rail_spatial_partitioning:Destroy()
			self.rail_spatial_partitioning = nil
		end
		
		--Disconnect connections
		if self.rail_cons ~= nil then
			for _, v in pairs(self.rail_cons) do
				v:Disconnect()
			end
			self.rail_cons = nil
		end
	end

	function player_rail.GetRailsInRegion(self, region)
		debug.profilebegin("player_rail.GetRailsInRegion")
		
		local hit_rails
		local rails = rails_reference:Get()
		if rails ~= nil then
			hit_rails = self.rail_spatial_partitioning:GetPartsInRegion(region)
		else
			hit_rails = {}
		end
		
		debug.profileend()
		return hit_rails
	end

	function player_rail.GetTouchingRail(self)
		debug.profilebegin("player_rail.GetTouchingRail")
		
		--Get player collision and get rails in region
		local radius = self.p.height * self.p.scale
		local center = self.pos + self:GetUp() * radius
		
		local sphere = {
			center = center,
			radius = radius,
		}
		
		local region = Region3.new(
			center - Vector3.new(radius, radius, radius),
			center + Vector3.new(radius, radius, radius)
		)
		
		local rails = player_rail.GetRailsInRegion(self, region)
		
		local hit = nil
		for _,v in pairs(rails) do
			--Check for collision
			if collision.TestSphereRotatedBox(sphere, {cframe = v.CFrame, size = v.Size}) then
				--Check if we should collide with this rail
				if self.flag.grounded then
					local up = v.CFrame.UpVector
					local top = v.Position + up * (v.Size.Y / 2)
					if (center - top):Dot(up) < 0 and not self.v3 then
						continue
					end
				end
				hit = v
				break
			end
		end
		
		debug.profileend()
		return hit
	end

	function player_rail.GetAngle(self)
		if self.rail ~= nil then
			return self:AngleFromRbx((self.rail.CFrame - self.rail.Position) * CFrame.Angles(0, (self.rail_dir >= 0) and 0 or math.pi, 0))
		end
		return self.ang
	end

	function player_rail.GetPosition(self)
		local local_pos = self.rail.CFrame:inverse() * self.pos
		return self.rail.CFrame * Vector3.new(0, self.rail.Size.Y / 2, local_pos.Z)
	end

	function player_rail.SetRail(self, rail)
		if rail ~= nil then
			--Get orientation to use
			local dir_dot = self:GetLook():Dot(rail.CFrame.LookVector)
			local spd_dot = self:ToGlobal(self.spd):Dot(rail.CFrame.LookVector)
			local rail_dir = (dir_dot ~= 0) and math.sign(dir_dot) or ((spd_dot ~= 0) and math.sign(spd_dot) or 1)
			
			if self.rail == nil then
				--Set player state
				self:ResetObjectState()
				self:Land()
				self.state = constants.state.rail
				
				--Set rail state
				self.rail = rail
				self.rail_dir = rail_dir
				self.rail_balance = 0
				self.rail_tgt_balance = 0
				self.rail_balance_fail = 0
				self.rail_off = Vector3.new()
				self.rail_trick = 0
				self.rail_snd = false
				self.rail_grace = nil
				self.rail_bonus_time = 0
				
				--Get angle and speed
				local prev_spd = self:ToGlobal(self.spd)
				self:SetAngle(player_rail.GetAngle(self))
				self.spd = self:ToLocal(prev_spd) * Vector3.new(1, 0, 0)
				
				--Set animation
				if math.abs(self.spd.X) < self.p.jog_speed and self:ToLocal(prev_spd).Y < -2 then
					self.animation = "RailLand"
				else
					self.animation = "Rail"
				end
				
				--Project position onto rail
				self.pos = player_rail.GetPosition(self)
			elseif self.rail ~= rail then
				--Set rail state
				local dot = math.clamp(self.rail.CFrame.RightVector:Dot(rail.CFrame.LookVector), -0.999, 0.999)
				self.rail = rail
				self.rail_dir = rail_dir
				local balance = math.asin(dot) * (self.spd.X / 10)
				self.rail_balance = math.clamp(self.rail_balance - balance * 1.625, math.rad(-80), math.rad(80))
				self.rail_tgt_balance = math.clamp(self.rail_tgt_balance + balance * 1.125, math.rad(-70), math.rad(70))
				
				--Get angle and project position
				self:SetAngle(player_rail.GetAngle(self))
				self.pos = player_rail.GetPosition(self)
			else
				return
			end
			
			--Use rail information
			if self.v3 ~= true and self.rail.Parent:FindFirstChild("Balance") then
				self.rail_do_balance = self.rail.Parent.Balance.Value
			else
				self.rail_do_balance = false
			end
		elseif self.rail ~= nil then
			--Release from rail state
			self.rail = nil
			self.rail_debounce = 10
			
			--Stop sound
			sound.StopSound(self, "Grind")
		end
	end

	function player_rail.CollideRails(self)
		debug.profilebegin("player_rail.CollideRails")
		
		if self.rail_debounce <= 0 then
			--Get touching rail and set player onto it if found
			local rail = player_rail.GetTouchingRail(self)
			if rail ~= nil then
				player_rail.SetRail(self, rail)
			end
		end
		
		debug.profileend()
		return self.state == constants.state.rail
	end

	function player_rail.GrindActive(self)
		return self.state == constants.state.rail and self.rail_off.magnitude < 0.5
	end

	function player_rail.CheckSwitch(self)
		if self.rail ~= nil and math.abs(self.input.stick_x) > 0.675 and self.spd.X ~= 0 then
			if self.v3 ~= true then
				--Get switch direction
				local dir = math.sign(self.input.stick_x) * math.sign(self.spd.X) * self.rail_dir
				
				--Get position along rail
				local local_pos = self.rail.CFrame:inverse() * self.pos
				local along_pos = self.rail.CFrame * (local_pos * Vector3.new(0, 0, 1))
				local switch_dir = self.rail.CFrame.RightVector * dir
				
				--Perform raycast
				local hit = collision.Raycast({rails_reference:Get()}, along_pos + switch_dir, switch_dir * 9)
				if hit ~= nil then
					--Switch to rail
					local prev_pos = self.pos
					player_rail.SetRail(self, hit)
					self.rail_grace = nil
					self.rail_off = prev_pos - self.pos
					
					--Give score bonus if at high speed
					if math.abs(self.spd.X) >= 8 then
						self:GiveScore(200)
					end
					return true
				end
			else
				self.spd = vector.SetZ(self.spd, self.input.stick_x * 8)
			end
		end
		return false
	end

	function player_rail.CheckTrick(self)
		if self.v3 ~= true and (self.spd.X * self.rail_dir) > 0 and self.rail ~= nil then
			--Get rail's trick value
			local trick = self.rail:FindFirstChild("Trick")
			if trick ~= nil then
				trick = trick.Value
			else
				return false
			end
			
			--Amplify trick based off speed
			trick = math.min((trick * math.abs(self.spd.X) / 15) - 0.5, 1)
			if trick < 0 then
				return false
			end
			
			--Give points bonus
			self:GiveScore(math.min(500 + math.floor(trick * 300) * 10, 3500))
			
			--Play trick animation and set state
			if trick > 0.675 then
				self.animation = "TrickRail1"
			elseif trick > 0.425 then
				self.animation = "TrickRail2"
			elseif trick > 0.1 then
				self.animation = "TrickRail3"
			else
				self.animation = "TrickRail4"
			end
			self.rail_trick = 0.35 + trick * 1.125
			
			--Jump off
			player_rail.SetRail(self, nil)
			self.rail_debounce = 30
			self.state = constants.state.airborne
			self.flag.air_kick = true
			if self.spd.X < 0 then
				self:Turn(math.pi)
				self.spd = self.spd * -1
			end
			self.spd = self.spd * (1 + self.rail_trick * 0.35)
			return true
		end
		return false
	end

	function player_rail.Movement(self)
		--Immediately quit if not on a rail
		if self.rail == nil then
			return true
		end
		
		--Get grinding state
		local crouch = self.input.button.roll
		
		--Gravity
		local weight
		if self.flag.underwater then
			weight = self.p.weight * 0.45
		else
			weight = self.p.weight
		end
		
		local gravity = (self:ToLocal(self.gravity) * weight).X
		
		--Amplify gravity
		if math.sign(gravity) == math.sign(self.spd.X) then
			--Have stronger gravity when gravity is working with us
			gravity = gravity * (1.125 + (math.abs(self.spd.X) / 8))
		elseif self.v3 == true then
			--No gravity working against you in SEO v3 mode
			gravity = Vector3.new()
		else
			--Have weaker gravity when gravity is working against us
			gravity = gravity * (0.5 / (1 + (math.abs(self.spd.X) / 3.5))) * (crouch and 0.75 or 1)
		end
		
		--Get drag factor
		local off = self.rail_balance - self.rail_tgt_balance
		self.rail_tgt_balance = self.rail_tgt_balance * 0.875
		
		local drag_factor
		if self.v3 == true then
			drag_factor = 0
		elseif self.rail_do_balance then
			drag_factor = 0.5 + (1 - math.cos(math.clamp(off, -math.pi / 2, math.pi / 2))) * 3.125
		else
			drag_factor = 0.95
		end
		
		--Apply gravity and drag
		self.spd = vector.AddX(self.spd, gravity)
		self.spd = vector.AddX(self.spd, self.spd.X * self.p.air_resist * (crouch and 0.675 or 0.875) * drag_factor)
		
		--Make sure player is at a minimum speed
		if self.spd.X == 0 then
			self.spd = vector.SetX(self.spd, self.p.jog_speed)
		elseif math.abs(self.dotp) > 0.95 then
			self.spd = vector.SetX(self.spd, math.max(math.abs(self.spd.X), self.p.jog_speed) * math.sign(self.spd.X))
		end
		
		--Give rail bonus at high speed
		if math.abs(self.spd.X) >= 8 then
			self.rail_bonus_time = self.rail_bonus_time + 1
			if self.rail_bonus_time >= 60 then
				self:GiveScore((self.spd.X < 0) and 1000 or 700)
				self.rail_bonus_time = 0
			end
		else
			self.rail_bonus_time = math.max(self.rail_bonus_time - 2, 0)
		end
		
		--Balancing
		local stick_x = self.input.stick_x * math.clamp(self.spd.X, -1, 1)
		if player_rail.GrindActive(self) and self.rail_do_balance then
			--Drag balance
			local drag_factor = lerp(math.cos(self.rail_tgt_balance), 1, 0.25)
			self.rail_balance = self.rail_balance * lerp(1, crouch and 0.9675 or 0.825, drag_factor)
			
			--Adjust balance using analogue stick
			local adjust_force
			if math.sign(self.rail_balance) == math.sign(stick_x) then
				adjust_force = math.cos(self.rail_balance) * 1.2125
			else
				adjust_force = 1.6125 + math.abs(self.rail_balance / 1.35)
			end
			adjust_force = adjust_force * crouch and 0.8975 or 1
			
			self.rail_balance = self.rail_balance + stick_x * adjust_force * math.rad(3.5 + math.abs(self.spd.X) / 2.825)
			if math.sign(stick_x) == math.sign(self.rail_tgt_balance) then
				local off = (self.rail_tgt_balance - self.rail_balance)
				self.rail_balance = self.rail_balance + off * math.abs(stick_x) * math.abs(math.sin(self.rail_tgt_balance)) * 0.15
			end
		else
			--Balancing disabled
			self.rail_balance = self.rail_balance * 0.825
		end
		
		--Move
		self.pos = self.pos + self:ToGlobal(self.spd) * self.p.scale
		self.rail_off = self.rail_off * 0.8
		
		--Balance failing
		if math.abs(self.rail_balance - self.rail_tgt_balance) >= math.rad(55) then
			self.rail_balance_fail = math.min(self.rail_balance_fail + 0.1, 1)
		else
			self.rail_balance_fail = math.max(self.rail_balance_fail - 0.04, 0)
		end
		
		--Run sound
		local new_snd = player_rail.GrindActive(self)
		if new_snd then
			if not self.rail_snd then
				sound.PlaySound(self, "GrindContact")
				sound.PlaySound(self, "Grind")
			end
			sound.SetSoundVolume(self, "Grind", math.sqrt(math.abs(self.spd.X) / 8))
		else
			if self.rail_snd then
				sound.StopSound(self, "GrindContact")
				sound.StopSound(self, "Grind")
			end
		end
		self.rail_snd = new_snd
		
		--Set animation
		if player_rail.GrindActive(self) then
			if self.animation ~= "RailLand" then
				if self.rail_balance_fail >= 0.3 then
					self.animation = "RailBalance"
				else
					self.animation = crouch and "RailCrouch" or "Rail"
					self.anim_speed = self.spd.X
				end
			end
		else
			local loc_off = self:AngleToRbx(self.ang):inverse() * self.rail_off
			if loc_off.X < 0 then
				self.animation = "RailSwitchLeft"
			elseif loc_off.X > 0 then
				self.animation = "RailSwitchRight"
			end
		end
		
		if self.rail_grace ~= nil then
			--Release from rail after grace period
			self.rail_grace = math.max(self.rail_grace - 1, 0)
			if self.rail_grace <= 0 then
				player_rail.SetRail(self, nil)
				return true
			end
		else
			--Handle keeping us on the rail (and subsequent rails)
			while true do
				--Project position onto rail
				self.pos = player_rail.GetPosition(self)
				self.ang = player_rail.GetAngle(self)
				
				--Check if we should go to next rail (or fly off with there being no rail to go to)
				local dir = self.rail_dir * math.sign(self.spd.X)
				local local_pos = self.rail.CFrame:inverse() * self.pos
				if self.spd.X ~= 0 and (local_pos.Z * -dir) > self.rail.Size.Z / 2 then
					--Do raycast
					local hit = collision.Raycast({rails_reference:Get()}, self.rail.Position, self.rail.CFrame.LookVector * ((self.rail.size.Z / 2) + 1) * dir)
					if hit == nil then
						self.rail_grace = 1 + math.floor(math.abs(self.spd.X) / 3.5)
						break
					else
						player_rail.SetRail(self, hit)
					end
				else
					break
				end
			end
		end
		return false
	end

	return player_rail
end

pcontrol.Input = {}; pcontrol.Input.TouchButton = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Input/TouchButton.lua
	Purpose: Mobile Touch Button class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local touch_button = {}

	local gui_service = game:GetService("GuiService")
	local uis = game:GetService("UserInputService")

	--Constants
	local pressed_col = Color3.new(0.75, 0.75, 0.75)
	local released_col = Color3.new(1, 1, 1)

	--Internal interface
	local function OnInputEnded(self)
		--Reset button
		self.button.ImageColor3 = released_col
		if not self.enabled then
			self.button.Active = false
		end
		
		--Reset input state
		self.pressed = false
		self.move_touch_input = nil
	end

	--Constructor and destructor
	function touch_button:New(parent_frame, pos, size)
		--Initialize meta reference
		local self = setmetatable({}, {__index = touch_button})
		
		--Create button
		self.button = Instance.new("ImageButton")
		self.button.Name = "Button"
		self.button.BackgroundTransparency = 1
		self.button.ImageTransparency = 1
		self.button.ImageColor3 = released_col
		self.button.Active = false
		self.button.Size = size
		self.button.Position = pos
		self.button.Parent = parent_frame
		
		--Initialize state
		self.pressed = false
		self.move_touch_input = nil
		self.enabled = false
		
		--Input connections
		self.input_connections = {
			self.button.InputBegan:Connect(function(input)
				--Make sure input is a valid state
				if self.enabled == false or self.move_touch_input ~= nil or input.UserInputType ~= Enum.UserInputType.Touch or input.UserInputState ~= Enum.UserInputState.Begin then
					return
				end
				
				--Start holding button
				self.move_touch_input = input
				self.button.ImageColor3 = pressed_col
				self.pressed = true
			end),
			uis.TouchEnded:Connect(function(input, processed)
				if input == self.move_touch_input then
					OnInputEnded(self)
				end
			end),
			gui_service.MenuOpened:Connect(function()
				if self.move_touch_input ~= nil then
					OnInputEnded(self)
				end
			end),
		}
		
		return self
	end

	function touch_button:Destroy()
		--Disconnect connections
		if self.input_connections ~= nil then
			for _,v in pairs(self.input_connections) do
				v:Disconnect()
			end
			self.input_connections = nil
		end
		
		--Destroy button
		if self.button ~= nil then
			self.button:Destroy()
			self.button = nil
		end
	end

	--Button interface
	function touch_button:Enable(id)
		if id ~= nil then
			if not self.enabled then
				self.button.ImageTransparency = 0
				self.button.Active = true
				self.enabled = true
			end
			if self.button.Image ~= id then
				self.button.Image = id
			end
		elseif self.enabled then
			self.button.ImageTransparency = 1
			self.enabled = false
		end
	end

	return touch_button
end

pcontrol.Player.Input.TouchThumbstick = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player/Input/TouchThumbstick.lua
	Purpose: Mobile Touch Thumbstick class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]


	local touch_thumbstick = {}

	local gui_service = game:GetService("GuiService")
	local uis = game:GetService("UserInputService")

	--Sheet
	local sheet_image = "rbxassetid://3505674311"
	local sheet_outer_off = Vector2.new(0, 0)
	local sheet_outer_size = Vector2.new(146, 146)
	local sheet_stick_off = Vector2.new(146, 0)
	local sheet_stick_size = Vector2.new(74, 74)

	--Constants
	local deadzone = 0.05

	--Internal interface
	local function OnInputEnded(self)
		--Reset stick positions
		self.frame.Position = self.orig_pos
		self.stick_image.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		--Reset input state
		self.move_vector = Vector2.new()
		self.move_touch_input = nil
	end

	local function DoMove(self, direction)
		--Get move vector
		local current_move_vector = direction / (self.frame.AbsoluteSize / 2)
		
		--Scaled Radial Dead Zone
		local input_axis_magnitude = current_move_vector.magnitude
		if input_axis_magnitude < deadzone then
			current_move_vector = Vector3.new()
		elseif input_axis_magnitude < 1 then
			current_move_vector = current_move_vector.unit * ((input_axis_magnitude - deadzone) / (1 - deadzone))
			current_move_vector = Vector2.new(current_move_vector.X, current_move_vector.Y)
		else
			current_move_vector = current_move_vector.unit
		end
		
		--Set final move vector
		self.move_vector = current_move_vector
	end

	local function MoveStick(self, pos)
		--Get stick position
		local relative_position = pos - (self.frame.AbsolutePosition + self.frame.AbsoluteSize / 2)
		local max_length = math.max(self.frame.AbsoluteSize.X, self.frame.AbsoluteSize.Y) / 2
		if relative_position.magnitude > max_length then
			relative_position = relative_position.unit * max_length
		end
		self.stick_image.Position = UDim2.new(0.5, relative_position.X, 0.5, relative_position.Y)
	end

	--Constructor and destructor
	function touch_thumbstick:New(parent_frame, pos, size)
		--Initialize meta reference
		local self = setmetatable({}, {__index = touch_thumbstick})
		
		--Remember given position
		self.orig_pos = pos
		self.orig_size = size
		
		--Create thumbstick container
		self.frame = Instance.new("Frame")
		self.frame.Name = "ThumbstickFrame"
		self.frame.Active = true
		self.frame.Visible = false
		self.frame.Size = size
		self.frame.Position = pos
		self.frame.BackgroundTransparency = 1
		self.frame.Parent = parent_frame
		
		--Create thumbstick outer image
		local outer_image = Instance.new("ImageLabel")
		outer_image.Name = "OuterImage"
		outer_image.Image = sheet_image
		outer_image.ImageRectOffset = sheet_outer_off
		outer_image.ImageRectSize = sheet_outer_size
		outer_image.BackgroundTransparency = 1
		outer_image.Size = UDim2.new(1, 0, 1, 0)
		outer_image.AnchorPoint = Vector2.new(0.5, 0.5)
		outer_image.Position = UDim2.new(0.5, 0, 0.5, 0)
		outer_image.Parent = self.frame
		
		self.stick_image = Instance.new("ImageLabel")
		self.stick_image.Name = "StickImage"
		self.stick_image.Image = sheet_image
		self.stick_image.ImageRectOffset = sheet_stick_off
		self.stick_image.ImageRectSize = sheet_stick_size
		self.stick_image.BackgroundTransparency = 1
		self.stick_image.Size = UDim2.new(0.5, 0, 0.5, 0)
		self.stick_image.AnchorPoint = Vector2.new(0.5, 0.5)
		self.stick_image.Position = UDim2.new(0.5, 0, 0.5, 0)
		self.stick_image.ZIndex = 2
		self.stick_image.Parent = self.frame
		
		--Initial state
		self.move_vector = Vector2.new()
		self.move_touch_input = nil
		self.enabled = false
		
		--Input connections
		self.input_connections = {
			self.frame.InputBegan:Connect(function(input)
				--Make sure input is a valid state
				if self.move_touch_input ~= nil or input.UserInputType ~= Enum.UserInputType.Touch or input.UserInputState ~= Enum.UserInputState.Begin then
					return
				end
				
				--Start capturing input and set thumbstick position
				self.move_touch_input = input
				self.frame.Position = UDim2.new(0, input.Position.X - self.frame.AbsoluteSize.X / 2, 0, input.Position.Y - self.frame.AbsoluteSize.Y / 2)
			end),
			uis.TouchMoved:Connect(function(input, processed)
				--Make sure this is the current move input
				if input == self.move_touch_input then
					--Move stick
					local input_pos = Vector2.new(input.Position.X, input.Position.Y)
					local direction = input_pos - (self.frame.AbsolutePosition + self.frame.AbsoluteSize / 2)
					DoMove(self, direction)
					MoveStick(self, input_pos)
				end
			end),
			uis.TouchEnded:Connect(function(input, processed)
				if input == self.move_touch_input then
					OnInputEnded(self)
				end
			end),
			gui_service.MenuOpened:Connect(function()
				if self.move_touch_input ~= nil then
					OnInputEnded(self)
				end
			end),
		}
		
		return self
	end

	function touch_thumbstick:Destroy()
		--Disconnect connections
		if self.input_connections ~= nil then
			for _,v in pairs(self.input_connections) do
				v:Disconnect()
			end
			self.input_connections = nil
		end
		
		--Destroy thumbstick frame
		if self.frame ~= nil then
			self.frame:Destroy()
			self.frame = nil
		end
	end

	--Thumbstick interface
	function touch_thumbstick:Enable(enabled)
		if self.enabled ~= enabled then
			self.frame.Visible = enabled
			self.enabled = enabled
		end
	end

	return touch_thumbstick
end

pcontrol.Player.Input.init = function()
	--[[

	= Sonic Onset Adventure Client =

	Source: ControlScript/Player/Input.lua
	Purpose: Player input functions
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local player_input = {}

	local player = game:GetService("Players").LocalPlayer
	local uis = game:GetService("UserInputService")
	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local vector = require(commons.Vector)
	local cframe = require(commons.CFrame)

	local touch_thumbstick = require(pcontrol.Player.Input.TouchThumbstick)
	local touch_button = require(pcontrol.Player.Input.TouchButton)

	--Constants
	local button_ids = {
		["Jump"] = "rbxassetid://5999555026",
		["HomingAttack"] = "rbxassetid://5999555026",
		["Spindash"] = "rbxassetid://5999556527",
		["Crouch"] = "rbxassetid://5999555839",
		["Roll"] = "rbxassetid://5999556527",
		["Bounce"] = "rbxassetid://5999555611",
		["LightSpeedDash"] = "rbxassetid://5999556218",
		["AirKick"] = "rbxassetid://5999555261",
	}


	--Input bindings
	local buttons = {
		"jump", "roll", "secondary_action", "tertiary_action", "dbg"
	}

	local keyboard_bind = {
		[Enum.KeyCode.Space] = "jump",
		[Enum.KeyCode.E] = "roll",
		[Enum.KeyCode.LeftShift] = "roll",
		[Enum.KeyCode.Q] = "secondary_action",
		[Enum.KeyCode.R] = "tertiary_action",
		[Enum.KeyCode.LeftAlt] = "dbg",
	}

	local gamepad_bind = {
		[Enum.KeyCode.ButtonA] = "jump",
		[Enum.KeyCode.ButtonB] = "roll",
		[Enum.KeyCode.ButtonX] = "roll",
		[Enum.KeyCode.ButtonY] = "secondary_action",
		[Enum.KeyCode.ButtonR1] = "tertiary_action",
	}

	--Internal interface
	local function GetInputForDevice(inputs, bind)
		local res = {}
		for _,v in pairs(inputs) do
			local bind = bind[v]
			if bind then
				res[bind] = true
			end
		end
		return res
	end

	local function MergeInputs(...)
		local res = {}
		for _, v in pairs({...}) do
			for i, j in pairs(v) do
				res[i] = j
			end
		end
		return res
	end

	--Input interface
	function player_input.Initialize(self)
		--Initialize input
		self.input = {
			--Analogue stick state
			stick_x = 0,
			stick_y = 0,
			stick_mag = 0,
			
			--Button state
			button = {},
			button_press = {},
			button_prev = {},
		}
		
		--Create mobile gui
		if uis.TouchEnabled then
			--Create containing ScreenGui
			self.touch_gui = Instance.new("ScreenGui")
			self.touch_gui.Name = "TouchGui"
			self.touch_gui.DisplayOrder = 5
			self.touch_gui.ResetOnSpawn = false
			self.touch_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			
			--Create left and right containers
			local touch_frame_left = Instance.new("Frame")
			touch_frame_left.Name = "FrameLeft"
			touch_frame_left.BackgroundTransparency = 1
			touch_frame_left.BorderSizePixel = 0
			touch_frame_left.Size = UDim2.new(1, 0, 1, 0)
			touch_frame_left.AnchorPoint = Vector2.new(0, 1)
			touch_frame_left.Position = UDim2.new(0, 0, 1, 0)
			touch_frame_left.Parent = self.touch_gui
			Instance.new("UIAspectRatioConstraint", touch_frame_left)
			
			local touch_frame_right = Instance.new("Frame")
			touch_frame_right.Name = "FrameRight"
			touch_frame_right.BackgroundTransparency = 1
			touch_frame_right.BorderSizePixel = 0
			touch_frame_right.Size = UDim2.new(1, 0, 1, 0)
			touch_frame_right.AnchorPoint = Vector2.new(1, 1)
			touch_frame_right.Position = UDim2.new(1, 0, 1, 0)
			touch_frame_right.Parent = self.touch_gui
			Instance.new("UIAspectRatioConstraint", touch_frame_right)
			
			--Get screen information
			local camera = workspace.CurrentCamera
			local min_axis = math.min(camera.ViewportSize.X, camera.ViewportSize.Y)
			local small_screen = min_axis <= 500
			
			--Create thumbstick
			local thumbstick_dim = small_screen and 90 or 120
			local thumbstick_size = UDim2.new(0, thumbstick_dim, 0, thumbstick_dim)
			local thumbstick_pos = UDim2.new(0, 50, 1, -40 - thumbstick_dim)
			self.touch_thumbstick = touch_thumbstick:New(touch_frame_left, thumbstick_pos, thumbstick_size)
			
			--Create jump button
			local jump_dim = small_screen and 90 or 120
			local jump_size = UDim2.new(0, jump_dim, 0, jump_dim)
			local jump_pos = UDim2.new(1, -50 - jump_dim, 1, -40 - jump_dim)
			self.touch_jump_button = touch_button:New(touch_frame_right, jump_pos, jump_size)
			
			--Create small buttons
			local small_dim = small_screen and 75 or 100
			local small_size = UDim2.new(0, small_dim, 0, small_dim)
			
			--Create roll button
			local roll_pos = UDim2.new(1, -50 - jump_dim - 15 - small_dim, 1, -40 - jump_dim + 15)
			self.touch_roll_button = touch_button:New(touch_frame_right, roll_pos, small_size)
			
			--Create secondary action button
			local secondary_pos = UDim2.new(1, -50 - jump_dim - small_dim + 10, 1, -40 - jump_dim - small_dim + 10)
			self.touch_secondary_button = touch_button:New(touch_frame_right, secondary_pos, small_size)
			
			--Create tertiary action button
			local tertiary_pos = UDim2.new(1, -50 - jump_dim + 10, 1, -40 - jump_dim - small_dim - 5)
			self.touch_tertiary_button = touch_button:New(touch_frame_right, tertiary_pos, small_size)
			
			--Parent touch gui
			self.touch_gui.Parent = player:WaitForChild("PlayerGui")
		end
	end

	function player_input.Quit(self)
		--Delete mobile gui and inputs
		if self.touch_tertiary_button ~= nil then
			self.touch_tertiary_button:Destroy()
			self.touch_tertiary_button = nil
		end
		if self.touch_secondary_button ~= nil then
			self.touch_secondary_button:Destroy()
			self.touch_secondary_button = nil
		end
		if self.touch_roll_button ~= nil then
			self.touch_roll_button:Destroy()
			self.touch_roll_button = nil
		end
		if self.touch_jump_button ~= nil then
			self.touch_jump_button:Destroy()
			self.touch_jump_button = nil
		end
		if self.touch_thumbstick ~= nil then
			self.touch_thumbstick:Destroy()
			self.touch_thumbstick = nil
		end
		if self.touch_gui ~= nil then
			self.touch_gui:Destroy()
			self.touch_gui = nil
		end
	end

	function player_input.Update(self)
		--Get input state
		local stick_x, stick_y = 0, 0
		if uis:GetFocusedTextBox() then
			--Don't process any input
			self.input.button = {}
			
			--Disable mobile inputs
			if self.touch_thumbstick ~= nil then
				self.touch_thumbstick:Enable(false)
			end
			if self.touch_jump_button ~= nil then
				self.touch_jump_button:Enable(nil)
			end
			if self.touch_roll_button ~= nil then
				self.touch_roll_button:Enable(nil)
			end
			if self.touch_secondary_button ~= nil then
				self.touch_secondary_button:Enable(nil)
			end
			if self.touch_tertiary_button ~= nil then
				self.touch_tertiary_button:Enable(nil)
			end
		else
			--Get input state
			local key_input_state = uis:GetKeysPressed()
			local gamepad_input_state = uis:GetGamepadState(Enum.UserInputType.Gamepad1)
			
			--Process key input
			local key_input = {}
			local w, a, s, d = false, false, false, false
			for _,v in pairs(key_input_state) do
				if v.UserInputState == Enum.UserInputState.Begin then
					if v.KeyCode == Enum.KeyCode.W then
						w = true
					elseif v.KeyCode == Enum.KeyCode.A then
						a = true
					elseif v.KeyCode == Enum.KeyCode.S then
						s = true
					elseif v.KeyCode == Enum.KeyCode.D then
						d = true
					end
					table.insert(key_input, v.KeyCode)
				end
			end
			
			stick_x = stick_x + (d and 1 or 0) - (a and 1 or 0)
			stick_y = stick_y + (s and 1 or 0) - (w and 1 or 0)
			
			--Process gamepad input
			local gamepad_input = {}
			for _,v in pairs(gamepad_input_state) do
				if v.KeyCode == Enum.KeyCode.Thumbstick1 then
					stick_x = stick_x + v.Position.X
					stick_y = stick_y - v.Position.Y
				elseif v.UserInputState == Enum.UserInputState.Begin then
					table.insert(gamepad_input, v.KeyCode)
				end
			end
			
			--Process button input
			self.input.button = MergeInputs(
				GetInputForDevice(key_input, keyboard_bind),
				GetInputForDevice(gamepad_input, gamepad_bind)
			)
			
			--Process mobile input
			if self.touch_thumbstick ~= nil then
				self.touch_thumbstick:Enable(true)
				stick_x = stick_x + self.touch_thumbstick.move_vector.X
				stick_y = stick_y + self.touch_thumbstick.move_vector.Y
			end
			
			if self.touch_jump_button ~= nil then
				if self.jump_action ~= nil then
					self.touch_jump_button:Enable(button_ids[self.jump_action])
				else
					self.touch_jump_button:Enable(nil)
				end
				self.input.button.jump = self.input.button.jump or self.touch_jump_button.pressed
			end
			
			if self.touch_roll_button ~= nil then
				if self.roll_action ~= nil then
					self.touch_roll_button:Enable(button_ids[self.roll_action])
				else
					self.touch_roll_button:Enable(nil)
				end
				self.input.button.roll = self.input.button.roll or self.touch_roll_button.pressed
			end
			
			if self.touch_secondary_button ~= nil then
				if self.secondary_action ~= nil then
					self.touch_secondary_button:Enable(button_ids[self.secondary_action])
				else
					self.touch_secondary_button:Enable(nil)
				end
				self.input.button.secondary_action = self.input.button.secondary_action or self.touch_secondary_button.pressed
			end
			
			if self.touch_tertiary_button ~= nil then
				if self.tertiary_action ~= nil then
					self.touch_tertiary_button:Enable(button_ids[self.tertiary_action])
				else
					self.touch_tertiary_button:Enable(nil)
				end
				self.input.button.tertiary_action = self.input.button.tertiary_action or self.touch_tertiary_button.pressed
			end
		end
		
		--Set stick state
		self.input.stick_mag = math.sqrt((stick_x ^ 2) + (stick_y ^ 2))
		if self.input.stick_mag > 0.15 then
			if self.input.stick_mag > 1 then
				self.input.stick_x = stick_x / self.input.stick_mag
				self.input.stick_y = stick_y / self.input.stick_mag
				self.input.stick_mag = 1
			else
				self.input.stick_x = stick_x
				self.input.stick_y = stick_y
			end
		else
			self.input.stick_x = 0
			self.input.stick_y = 0
			self.input.stick_mag = 0
		end
		
		--Get pressed buttons
		for _, v in pairs(buttons) do
			if self.input.button[v] == true then
				self.input.button_press[v] = self.input.button_prev[v] ~= true
				self.input.button_prev[v] = true
			else
				self.input.button[v] = false
				self.input.button_press[v] = false
				self.input.button_prev[v] = false
			end
		end
	end

	function player_input.HasControl(self)
		return true
	end

	function player_input.GetAnalogue_Turn(self)
		if player_input.HasControl(self) then
			if self.spring_timer > 0 or self.dashpanel_timer > 0 or self.dashring_timer > 0 then
				self.last_turn = 0
				return self.last_turn
			elseif self.input.stick_mag ~= 0 then
				--Get character vectors
				local tgt_up = Vector3.new(0, 1, 0)
				local look = self:GetLook()
				local up = self:GetUp()
				
				--Get camera angle, aligned to our target up vector
				local cam_look = vector.PlaneProject(workspace.CurrentCamera.CFrame.LookVector, tgt_up)
				if cam_look.magnitude ~= 0 then
					cam_look = cam_look.unit
				else
					cam_look = look
				end
				
				--Get move vector in world space, aligned to our target up vector
				local cam_move = CFrame.fromAxisAngle(tgt_up, math.atan2(-self.input.stick_x, -self.input.stick_y)) * cam_look
				
				--Update last up
				if self.last_up == nil or tgt_up:Dot(up) >= -0.999 then
					self.last_up = up
				end
				
				--Get final rotation and move vector
				local final_rotation = cframe.FromToRotation(tgt_up, self.last_up)
				
				local final_move = vector.PlaneProject(final_rotation * cam_move, up)
				if final_move.magnitude ~= 0 then
					final_move = final_move.unit
				else
					final_move = look
				end
				
				--Get turn amount
				self.last_turn = vector.SignedAngle(look, final_move, up)
				return self.last_turn
			end
		end
		
		self.last_turn = 0
		return self.last_turn
	end

	function player_input.GetAnalogue_Mag(self)
		if player_input.HasControl(self) then
			if self.spring_timer > 0 then
				return 0
			elseif self.dashpanel_timer > 0 or self.dashring_timer > 0 then
				return 1
			else
				return self.input.stick_mag
			end
		else
			return 0
		end
	end

	function player_input.GetAnalogue(self)
		local turn = player_input.GetAnalogue_Turn(self)
		local mag = player_input.GetAnalogue_Mag(self)
		return (player_input.HasControl(self) and mag ~= 0), turn, mag
	end

	return player_input
end

pcontrol.Player.Physics = {}
pcontrol.Player.Physics.SA1 = function()
	return {
		["Sonic"] = {
			60,
			2.0,
			16.0,
			16.0,
			3.0,
			0.60000002,
			1.66,
			3.0,
			0.23,
			0.46000001,
			1.39,
			2.3,
			3.7,
			5.0900002,
			0.075999998,
			0.050000001,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.2825,
			0.30000001,
			4.0,
			10.0,
			0.079999998,
			7.0,
			5.4000001
		},
		["Eggman"] = {
			60,
			3.0,
			16.0,
			16.0,
			3.0,
			1.0,
			1.66,
			3.0,
			0.23,
			0.46000001,
			1.39,
			2.3,
			3.7,
			5.0900002,
			0.075999998,
			0.059999999,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.33750001,
			0.30000001,
			8.5,
			18.0,
			0.079999998,
			7.0,
			5.3000002
		},
		["Tails"] = {
			60,
			1.5,
			16.0,
			16.0,
			2.0,
			0.60000002,
			1.66,
			3.0,
			0.23,
			0.49000001,
			1.39,
			2.8,
			3.7,
			5.0900002,
			0.075999998,
			0.059999999,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.33750001,
			0.30000001,
			3.5,
			9.0,
			0.079999998,
			6.0,
			4.5
		},
		["Knuckles"] = {
			60,
			2.0,
			16.0,
			16.0,
			2.5,
			0.60000002,
			1.66,
			3.0,
			0.23,
			0.46000001,
			1.39,
			3.0999999,
			3.7,
			5.0900002,
			0.075999998,
			0.050000001,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.33750001,
			0.30000001,
			4.0,
			11.4,
			0.079999998,
			9.0,
			5.6999998
		},
		["Tikal"] = {
			60,
			2.0,
			16.0,
			16.0,
			3.0,
			1.0,
			1.66,
			3.0,
			0.23,
			0.46000001,
			1.39,
			2.3,
			3.7,
			5.0900002,
			0.075999998,
			0.059999999,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.33750001,
			0.30000001,
			4.0,
			10.0,
			0.079999998,
			7.0,
			5.0
		},
		["Amy"] = {
			60,
			1.5,
			16.0,
			16.0,
			0.050000001,
			0.5,
			1.3,
			3.0,
			0.23,
			0.46000001,
			1.39,
			2.3,
			3.7,
			5.0900002,
			0.013,
			0.045000002,
			0.030999999,
			-0.059999999,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.33750001,
			0.30000001,
			3.5,
			10.0,
			0.039999999,
			7.0,
			5.0
		},
		["Gamma"] = {
			60,
			2.0,
			16.0,
			16.0,
			2.5,
			0.60000002,
			2.0,
			3.0,
			0.23,
			1.0,
			2.0,
			2.5,
			3.7,
			5.0900002,
			0.090000004,
			0.059999999,
			0.030999999,
			-0.059999999,
			-0.25,
			-0.17,
			-0.028000001,
			-0.0080000004,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.89999998,
			0.30000001,
			4.0,
			21.0,
			0.1,
			20.0,
			14.0
		},
		["Big"] = {
			60,
			2.0,
			5.0,
			8.0,
			1.0,
			0.2,
			2.0,
			3.0,
			0.23,
			0.31999999,
			1.39,
			2.3,
			3.7,
			5.0900002,
			0.1,
			0.079999998,
			0.030999999,
			-0.079999998,
			-0.18000001,
			-0.17,
			-0.028000001,
			-0.039999999,
			-0.0099999998,
			-0.40000001,
			-0.1,
			-0.60000002,
			-0.2,
			0.30000001,
			9.5,
			17.0,
			0.13500001,
			15.0,
			8.0
		}
	}
end

pcontrol.Player.Physics.SA2 = function()
	return {
		["Sonic"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["Shadow"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["Tails"] = {
			40, 1.5, 16.0, 16.0, 0.60000002, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 4.0, 0.075999998,
			0.048, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0099999998, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.33750001, 0.30000001, 3.5, 9.0, 0.079999998, 6.0, 4.5
		},
		["Eggman"] = {
			0, 3.0, 16.0, 16.0, 3.0, 1.0, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.059999999, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.33750001, 0.30000001, 8.5, 15.5, 0.079999998, 14.5, 10.0
		},
		["Knuckles"] = {
			60, 2.0, 16.0, 16.0, 2.5, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 3.0999999, 3.7, 5.0900002,
			0.075999998, 0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004,
			-0.0099999998, -0.40000001, -0.1, -0.60000002, -0.33750001, 0.30000001, 4.0, 11.4, 0.079999998, 9.0,
			5.6999998
		},
		["Rouge"] = {
			60, 2.0, 16.0, 16.0, 2.5, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 3.0999999, 3.7, 5.0900002,
			0.075999998, 0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004,
			-0.0099999998, -0.40000001, -0.1, -0.60000002, -0.33750001, 0.30000001, 4.0, 11.4, 0.079999998, 9.0,
			5.6999998
		},
		["MechTails"] = {
			16, 3.0, 16.0, 16.0, 1.0, 1.0, 2.5999999, 3.0, 0.23, 0.46000001, 1.39, 1.8, 2.0, 3.0, 0.19, 0.1,
			0.030999999, -0.1, -0.18000001, -0.17, -0.028000001, -0.014, -0.02, -0.40000001, -0.1, -0.60000002,
			-0.33750001, 0.30000001, 8.0, 21.0, 0.2, 20.0, 15.0
		},
		["MechEggman"] = {
			16, 3.0, 16.0, 16.0, 1.0, 1.0, 2.5999999, 3.0, 0.23, 0.46000001, 1.39, 1.8, 2.0, 3.0, 0.19, 0.1,
			0.030999999, -0.1, -0.18000001, -0.17, -0.028000001, -0.014, -0.02, -0.40000001, -0.1, -0.60000002,
			-0.33750001, 0.30000001, 8.0, 21.0, 0.2, 20.0, 15.0
		},
		["Amy"] = {
			60, 2.0, 16.0, 16.0, 1.3, 0.60000002, 1.3, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.048, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["SuperSonic"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["SuperShadow"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["B"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.1, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["MetalSonic"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 2.52, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.2, 0.050000001, -0.0099999998, -0.02, -0.029999999, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.40000001, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["ChaoWalker"] = {
			16, 3.0, 16.0, 16.0, 1.4, 1.0, 2.5999999, 3.0, 0.23, 0.46000001, 1.39, 1.8, 2.0, 3.0, 0.19, 0.2, 0.046,
			-0.1, -0.18000001, -0.17, -0.028000001, -0.014, -0.02, -0.40000001, -0.40000001, -0.60000002, -0.33750001,
			0.30000001, 8.0, 21.0, 0.2, 20.0, 15.0
		},
		["DarkChaoWalker"] = {
			16, 3.0, 16.0, 16.0, 0.69999999, 1.0, 2.5999999, 3.0, 0.23, 0.46000001, 1.39, 1.8, 2.0, 3.0, 0.19, 0.07,
			0.025, -0.1, -0.18000001, -0.17, -0.028000001, -0.014, -0.02, -0.40000001, -0.07, -0.60000002, -0.33750001,
			0.30000001, 8.0, 21.0, 0.2, 20.0, 15.0
		},
		["Tikal"] = {
			60, 2.0, 16.0, 16.0, 2.5, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 3.0999999, 3.7, 5.0900002,
			0.075999998, 0.059999999, 0.030999999, -0.059999999, -0.2, -0.17, -0.028000001, -0.0080000004,
			-0.0099999998, -0.40000001, -0.30000001, -0.60000002, -0.44999999, 0.30000001, 4.0, 11.4, 0.079999998, 9.0,
			5.6999998
		},
		["Chaos"] = {
			60, 2.0, 16.0, 16.0, 1.0, 0.60000002, 1.66, 3.0, 0.23, 0.46000001, 1.39, 3.0999999, 3.7, 5.0900002,
			0.075999998, 0.050000001, 0.030999999, -0.059999999, -0.18000001, -0.17, -0.028000001, -0.0080000004,
			-0.0099999998, -0.40000001, -0.090000004, -0.60000002, -0.33750001, 0.30000001, 4.0, 11.4, 0.079999998,
			9.0, 5.6999998
		},
		["SonicCopy1"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 2.52, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.2, 0.050000001, -0.0099999998, -0.02, -0.029999999, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.40000001, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
		["SonicCopy2"] = {
			60, 2.0, 16.0, 16.0, 3.0, 0.60000002, 2.52, 3.0, 0.23, 0.46000001, 1.39, 2.3, 3.7, 5.0900002, 0.075999998,
			0.2, 0.050000001, -0.0099999998, -0.02, -0.029999999, -0.028000001, -0.0080000004, -0.0099999998,
			-0.40000001, -0.40000001, -0.60000002, -0.2825, 0.30000001, 4.0, 10.0, 0.079999998, 7.0, 5.4000001
		},
	}
end

pcontrol.Player.Physics.SOA = function()
	return {
		["Sonic"] = {
			60,
			2.0,
			16.0,
			16.0,
			3.0,
			0.6,
			1.66,
			3.0,
			0.23,
			0.46,
			1.39,
			2.3,
			3.7,
			5.09,
			0.076,
			0.05,
			0.031,
			-0.06,
			-0.18,
			-0.17,
			-0.028,
			-0.008,
			-0.01,
			-0.4,
			-0.1,
			-0.6,
			-0.2825,
			0.3,
			3.0,
			5.0 * 2,
			0.08,
			7.0,
			5.4
		},
		["Emerl"] = {
			60,
			2.0,
			16.0,
			16.0,
			3.0,
			0.6,
			1.66,
			2.0,
			0.23,
			0.46,
			1.39,
			2.3,
			3.7,
			5.09,
			0.076,
			0.04,
			0.031,
			-0.06,
			-0.18,
			-0.17,
			-0.028,
			-0.008,
			-0.01,
			-0.4,
			-0.1,
			-0.6,
			-0.2825,
			0.3,
			3.0,
			5.0 * 2,
			0.08,
			7.0,
			5.4
		},
	}
end

-- ADD GLOBAL SOUNDS --
local gbsoundsig = Utils:Create({"Folder", GLOBALASSETS}, { -- globalsoundsiguess
	Name = "Sounds"
})

Utils:NewSound(gbsoundsig, 1, 1, 1).Name = "SpeedShoes"
Utils:NewSound(gbsoundsig, 1, 1, 1).Name = "Invincibility"
Utils:NewSound(gbsoundsig, 1, 1, 1).Name = "ExtraLife"
-----------------------

-- PLAYERDRAW --
pcontrol.PlayerDraw = {}
pcontrol.PlayerDraw.BallTrail = function()
	--[[
= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/BallTrail.lua
	Purpose: Player Draw Ball Trail class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_ball_trail = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local cframe = require(commons.CFrame)

	--Constructor and destructor
	function draw_ball_trail:New(holder, models)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_ball_trail})
		
		--Create model instance
		self.holder = holder
		
		self.ball_trail = models:WaitForChild("BallTrail"):clone()
		self.ball_trails = self.ball_trail:WaitForChild("Trail"):GetChildren()
		self.ball_trail.Parent = self.holder
		
		--Initialize state
		self.enabled = false
		self.hrp_cf = nil
		
		return self
	end

	function draw_ball_trail:Destroy()
		--Destroy model instance
		self.ball_trail:Destroy()
	end

	--Interface
	function draw_ball_trail:Enable()
		--Enable trails
		self.enabled = true
		for _,v in pairs(self.ball_trails) do
			v.Enabled = true
		end
	end

	function draw_ball_trail:Disable()
		--Disable trails
		self.enabled = false
		for _,v in pairs(self.ball_trails) do
			v.Enabled = false
		end
	end

	function draw_ball_trail:Draw(hrp_cf)
		if hrp_cf ~= self.hrp_cf then
			--Handle position tracking
			local prev_pos = self.hrp_cf and self.hrp_cf.p or hrp_cf.p
			local new_pos = hrp_cf.p
			
			local trail_cf
			if enabled then
				trail_cf = self.ball_trail.CFrame
			else
				trail_cf = hrp_cf
			end
			
			if new_pos ~= prev_pos then
				local look_dir = trail_cf.LookVector
				local diff_dir = (new_pos - prev_pos).unit
				if look_dir:Dot(diff_dir) < 0 then
					diff_dir = diff_dir * -1
				end
				local new_ang = cframe.FromToRotation(look_dir, diff_dir) * (trail_cf - trail_cf.p)
				trail_cf = new_ang + new_pos
			else
				trail_cf = (trail_cf - trail_cf.p) + new_pos
			end
			
			self.ball_trail.CFrame = trail_cf
			self.hrp_cf = hrp_cf
		end
	end

	function draw_ball_trail:LazyDraw(hrp_cf)
		self.hrp_cf = hrp_cf
	end

	return draw_ball_trail
end

pcontrol.PlayerDraw.Invincibility = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/Invincibility.lua
	Purpose: Player Draw Invincibility class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_invincibility = {}

	local assets = script.Parent.Parent:WaitForChild("Assets")
	local models = assets:WaitForChild("Models")

	--Constructor and destructor
	function draw_invincibility:New(holder)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_invincibility})
		
		--Create model instance
		self.holder = holder
		
		self.invincibility = models:WaitForChild("Invincibility"):clone()
		self.particles = self.invincibility:WaitForChild("RootPart"):WaitForChild("Invincibility"):GetChildren()
		self.invincibility.Parent = self.holder
		
		--Initialize state
		self.enabled = false
		self.hrp_cf = nil
		self.en_time = 0
		self.part_time = 0
		for _,v in pairs(self.particles) do
			self.part_time = math.max(self.part_time, v.Lifetime.Max)
		end
		
		return self
	end

	function draw_invincibility:Destroy()
		--Destroy model instance
		self.invincibility:Destroy()
	end

	--Interface
	function draw_invincibility:Enable()
		--Enable trails
		for _,v in pairs(self.particles) do
			v.Enabled = true
		end
		self.en_time = self.part_time
		self.enabled = true
	end

	function draw_invincibility:Disable()
		--Disable trails
		for _,v in pairs(self.particles) do
			v.Enabled = false
		end
		self.enabled = false
	end

	function draw_invincibility:Draw(dt, hrp_cf)
		if not self.enabled then
			self.en_time = self.en_time - dt
		end
		if self.en_time > 0 and hrp_cf ~= self.hrp_cf then
			--Set invincibility CFrame
			self.invincibility:SetPrimaryPartCFrame(hrp_cf)
			self.hrp_cf = hrp_cf
		end
	end

	function draw_invincibility:LazyDraw(dt, hrp_cf)
		if not self.enabled then
			self.en_time = self.en_time - dt
		end
		if self.en_time > 0 and hrp_cf ~= self.hrp_cf then
			--Set invincibility CFrame
			self.invincibility:SetPrimaryPartCFrame(hrp_cf)
			self.hrp_cf = hrp_cf
		end
	end

	return draw_invincibility
end

pcontrol.PlayerDraw.JumpBall = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/JumpBall.lua
	Purpose: Player Draw Jump Ball class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_jump_ball = {}

	--Constructor and destructor
	function draw_jump_ball:New(holder, models)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_jump_ball})
		
		--Create model instance
		self.holder = holder
		
		self.jump_ball = models:WaitForChild("JumpBall"):clone()
		self.jump_ball_smear = self.jump_ball:WaitForChild("Smear")
		
		--Initialize state
		self.spin = 0
		self.hrp_cf = nil
		
		return self
	end

	function draw_jump_ball:Destroy()
		--Destroy model instance
		self.jump_ball:Destroy()
	end

	--Interface
	function draw_jump_ball:Enable()
		--Set parent
		self.jump_ball.Parent = self.holder
	end

	function draw_jump_ball:Disable()
		--Set parent
		self.jump_ball.Parent = nil
	end

	function draw_jump_ball:Draw(dt, hrp_cf, spin)
		if hrp_cf ~= self.hrp_cf then
			--Modify jump ball smear transparency
			local smear = math.clamp((math.abs(spin) - 20) / 50, 0, 1)
			self.jump_ball_smear.Transparency = 1 - smear
			
			--Set jump ball CFrame
			self.spin = self.spin + spin * dt
			self.jump_ball:SetPrimaryPartCFrame(hrp_cf * CFrame.Angles(-self.spin, 0, 0))
			self.hrp_cf = hrp_cf
		end
	end

	function draw_jump_ball:LazyDraw(dt, hrp_cf, spin)
		if hrp_cf ~= self.hrp_cf then
			--Set jump ball CFrame
			self.jump_ball:SetPrimaryPartCFrame(hrp_cf)
			self.hrp_cf = hrp_cf
		end
	end

	return draw_jump_ball
end

pcontrol.PlayerDraw.MagnetShield = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/MagnetShield.lua
	Purpose: Player Draw Magnet Shield class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_magnet_shield = {}

	local assets = script.Parent.Parent:WaitForChild("Assets")
	local models = assets:WaitForChild("Models")

	--Constructor and destructor
	function draw_magnet_shield:New(holder)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_magnet_shield})
		
		--Create model instance
		self.holder = holder
		
		self.shield = models:WaitForChild("MagnetShield"):clone()
		
		self.shield1 = self.shield:WaitForChild("Shield1")
		self.shield1b = self.shield1:WaitForChild("Beams"):GetChildren()
		self.shield1c = {}
		for _,v in pairs (self.shield1:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield1c, v)
			end
		end
		
		self.shield2 = self.shield:WaitForChild("Shield2")
		self.shield2b = self.shield2:WaitForChild("Beams"):GetChildren()
		self.shield2c = {}
		for _,v in pairs (self.shield2:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield2c, v)
			end
		end
		
		self.shield3 = self.shield:WaitForChild("Shield3")
		self.shield3b = self.shield3:WaitForChild("Beams"):GetChildren()
		self.shield3c = {}
		for _,v in pairs (self.shield3:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield3c, v)
			end
		end
		
		--Initialize time
		self.time = 0
		self.rot = CFrame.new()
		
		return self
	end

	function draw_magnet_shield:Destroy()
		--Destroy model instance
		self.shield:Destroy()
	end

	--Interface
	function draw_magnet_shield:Enable()
		--Set parent
		self.shield.Parent = self.holder
	end

	function draw_magnet_shield:Disable()
		--Set parent
		self.shield.Parent = nil
	end

	local function GetTransparency(tim, off)
		return 1 - (math.clamp(math.cos((tim * 1.4) + (math.pi * 2 * off)), 0, 1) ^ 2.5)
	end

	function draw_magnet_shield:Draw(dt, hrp_cf)
		--Get shield transparencies
		self.time = self.time + dt
		
		local trans1 = GetTransparency(self.time, 0.000)
		local trans2 = GetTransparency(self.time, 0.333)
		local trans3 = GetTransparency(self.time, 0.666)
		
		--Apply shield transparencies
		for _,v in pairs(self.shield1c) do
			v.Transparency = trans1
		end
		for _,v in pairs(self.shield1b) do
			v.Enabled = trans1 < 0.75
		end
		
		for _,v in pairs(self.shield2c) do
			v.Transparency = trans2
		end
		for _,v in pairs(self.shield2b) do
			v.Enabled = trans2 < 0.75
		end
		
		for _,v in pairs(self.shield3c) do
			v.Transparency = trans3
		end
		for _,v in pairs(self.shield3b) do
			v.Enabled = trans3 < 0.75
		end
		
		--Set shield CFrame
		self.rot = self.rot * CFrame.Angles(dt * 0.16, dt * 0.21, dt * 0.19)
		self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p) * self.rot)
	end

	function draw_magnet_shield:LazyDraw(dt, hrp_cf)
		--Set shield CFrame
		self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p))
	end

	return draw_magnet_shield
end

pcontrol.PlayerDraw.Shield = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/Shield.lua
	Purpose: Player Draw Shield class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_shield = {}

	local assets = script.Parent.Parent:WaitForChild("Assets")
	local models = assets:WaitForChild("Models")

	--Constructor and destructor
	function draw_shield:New(holder)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_shield})
		
		--Create model instance
		self.holder = holder
		
		self.shield = models:WaitForChild("Shield"):clone()
		
		self.shield1 = self.shield:WaitForChild("Shield1")
		self.shield1c = {}
		for _,v in pairs (self.shield1:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield1c, v)
			end
		end
		
		self.shield2 = self.shield:WaitForChild("Shield2")
		self.shield2c = {}
		for _,v in pairs (self.shield2:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield2c, v)
			end
		end
		
		self.shield3 = self.shield:WaitForChild("Shield3")
		self.shield3c = {}
		for _,v in pairs (self.shield3:GetChildren()) do
			if v:IsA("Decal") then
				table.insert(self.shield3c, v)
			end
		end
		
		--Initialize time
		self.time = 0
		self.rot = CFrame.new()
		self.hrp_cf = nil
		
		return self
	end

	function draw_shield:Destroy()
		--Destroy model instance
		self.shield:Destroy()
	end

	--Interface
	function draw_shield:Enable()
		--Set parent
		self.shield.Parent = self.holder
	end

	function draw_shield:Disable()
		--Set parent
		self.shield.Parent = nil
	end

	local function GetTransparency(tim, off)
		return 1 - (math.clamp(math.cos((tim * 1.4) + (math.pi * 2 * off)), 0, 1) ^ 3)
	end

	function draw_shield:Draw(dt, hrp_cf)
		--Get shield transparencies
		self.time = self.time + dt
		
		local trans1 = GetTransparency(self.time, 0.000)
		local trans2 = GetTransparency(self.time, 0.333)
		local trans3 = GetTransparency(self.time, 0.666)
		
		--Apply shield transparencies
		for _,v in pairs(self.shield1c) do
			v.Transparency = trans1
		end
		
		for _,v in pairs(self.shield2c) do
			v.Transparency = trans2
		end
		
		for _,v in pairs(self.shield3c) do
			v.Transparency = trans3
		end
		
		--Set shield CFrame
		self.rot = self.rot * CFrame.Angles(dt * 0.16, dt * 0.21, dt * 0.19)
		self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p) * self.rot)
		self.hrp_cf = hrp_cf
	end

	function draw_shield:LazyDraw(dt, hrp_cf)
		if hrp_cf ~= self.hrp_cf then
			--Set shield CFrame
			self.shield:SetPrimaryPartCFrame(CFrame.new(hrp_cf.p))
			self.hrp_cf = hrp_cf
		end
	end

	return draw_shield
end

pcontrol.PlayerDraw.SpindashBall = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw/SpindashBall.lua
	Purpose: Player Draw Spindash Ball class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local draw_spindash_ball = {}

	--Constructor and destructor
	function draw_spindash_ball:New(holder, models)
		--Initialize meta reference
		local self = setmetatable({}, {__index = draw_spindash_ball})
		
		--Create model instance
		self.holder = holder
		
		self.spindash_ball = models:WaitForChild("SpindashBall"):clone()
		self.frames = {}
		for i = 1, 5 do
			self.frames[i] = self.spindash_ball:WaitForChild("Frame"..tostring(i))
		end
		
		--Initialize state
		self.spin = 0
		self.frame = 1
		self.hrp_cf = nil
		
		return self
	end

	function draw_spindash_ball:Destroy()
		--Destroy model instance
		self.spindash_ball:Destroy()
	end

	--Interface
	function draw_spindash_ball:Enable()
		--Set parent
		self.spindash_ball.Parent = self.holder
	end

	function draw_spindash_ball:Disable()
		--Set parent
		self.spindash_ball.Parent = nil
	end

	function draw_spindash_ball:Draw(dt, hrp_cf, spin)
		--Change shown spindash ball frame
		self.spin = self.spin + spin * dt
		
		local frame = 1 + math.floor(((self.spin / (math.pi * 2)) % 1) * 5)
		if frame ~= self.frame then
			if self.frames[self.frame] ~= nil then
				self.frames[self.frame].Transparency = 1
			end
			if self.frames[frame] ~= nil then
				self.frames[frame].Transparency = 0
			end
			self.frame = frame
		end
		
		if hrp_cf ~= self.hrp_cf then
			--Set spindash ball CFrame
			self.spindash_ball:SetPrimaryPartCFrame(hrp_cf)
			self.hrp_cf = hrp_cf
		end
	end

	function draw_spindash_ball:LazyDraw(dt, hrp_cf, spin)
		if hrp_cf ~= self.hrp_cf then
			--Set spindash ball CFrame
			self.spindash_ball:SetPrimaryPartCFrame(hrp_cf)
			self.hrp_cf = hrp_cf
		end
	end

	return draw_spindash_ball
end

function GetDefaultCharacterInfo()
	--self.p = info.physics
	--self.assets = info.assets
	--self.animations = info.animations
	--self.portraits = info.portraits
	
	--self.portrait_image.Image = portrait.image
	--self.portrait_image.Position = portrait.pos
	--self.portrait_image.Size = portrait.size
	return {
		p = require(pcontrol.Player.Physics.SOA),
		assets = GLOBALASSETS,
		animations = {},
		portraits = {
			[1] = {size = UDim2.new(.05, 0, .05, 0), pos = UDim2.new(0, 0, 1, 0), image = ""},
			[2] = {size = UDim2.new(.05, 0, .05, 0), pos = UDim2.new(0, 0, 1, 0), image = ""},
			[3] = {size = UDim2.new(.05, 0, .05, 0), pos = UDim2.new(0, 0, 1, 0), image = ""},
		},
	}
end
pcontrol.PlayerDraw.init = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/PlayerDraw.lua
	Purpose: Player Draw class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_draw = {}

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = replicated_storage:WaitForChild("CommonModules")

	local switch = require(common_modules:WaitForChild("Switch"))
	local camera_util = require(common_modules:WaitForChild("CameraUtil"))

	local jump_ball = require(pcontrol.PlayerDraw.JumpBall)
	local spindash_ball = require(pcontrol.PlayerDraw.SpindashBall)
	local ball_trail = require(pcontrol.PlayerDraw.BallTrail)
	local shield_model = require(pcontrol.PlayerDraw.Shield)
	local magnet_shield_model = require(pcontrol.PlayerDraw.MagnetShield)
	local invincibility = require(pcontrol.PlayerDraw.Invincibility)

	--Constants
	local draw_rad = 10

	--Constructor and destructor
	function player_draw:New(character)
		--Initialize meta reference
		local self = setmetatable({}, {__index = player_draw})
		
		--Load character's info
		local info
		if character ~= nil then
			self.character = character
			--info = require(self.character:WaitForChild("CharacterInfo"))
			info = GetDefaultCharacterInfo()
		else
			error("Player draw can't be created without character")
			return nil
		end
		
		--Find common character references
		self.hrp = self.character:WaitForChild("HumanoidRootPart")
		
		--Create model holder
		self.model_holder = Instance.new("Model")
		self.model_holder.Name = character.Name
		self.model_holder.Parent = workspace.CurrentCamera
		
		--Create model instances
		local models = info.assets:WaitForChild("Models")
		
		self.jump_ball = jump_ball:New(self.model_holder, models)
		self.spindash_ball = spindash_ball:New(self.model_holder, models)
		self.ball_trail = ball_trail:New(self.model_holder, models)
		
		self.shield_model = shield_model:New(self.model_holder)
		self.magnet_shield_model = magnet_shield_model:New(self.model_holder)
		self.invincibility = invincibility:New(self.model_holder)
		
		--Get parts to hide when in a ball
		self.parts = {}
		for _,v in pairs(self.character:GetChildren()) do
			if v:IsA("BasePart") then
				table.insert(self.parts, v)
			end
		end
		
		--Initialize draw state
		self.vis = 0
		self.cframe = self.hrp.CFrame
		self.ball = nil
		self.shield = nil
		self.invincible = false
		self.trail_active = false
		self.blinking = false
		
		return self
	end

	function player_draw:Destroy()
		--Destroy model instances
		if self.jump_ball ~= nil then
			self.jump_ball:Destroy()
			self.jump_ball = nil
		end
		if self.spindash_ball ~= nil then
			self.spindash_ball:Destroy()
			self.spindash_ball = nil
		end
		if self.ball_trail ~= nil then
			self.ball_trail:Destroy()
			self.ball_trail = nil
		end
		if self.shield_model ~= nil then
			self.shield_model:Destroy()
			self.shield_model = nil
		end
		if self.magnet_shield_model ~= nil then
			self.magnet_shield_model:Destroy()
			self.magnet_shield_model = nil
		end
		if self.invincibility ~= nil then
			self.invincibility:Destroy()
			self.invincibility = nil
		end
		
		--Destroy model holder
		if self.model_holder ~= nil then
			self.model_holder:Destroy()
			self.model_holder = nil
		end
	end

	--Player draw interface
	local function ApplyVisible(self, vis)
		if vis ~= self.last_vis then
			for _,v in pairs(self.parts) do
				v.LocalTransparencyModifier = vis
			end
			self.last_vis = vis
		end
	end

	function player_draw:Draw(dt, hrp_cf, ball, ball_spin, trail_active, shield, invincible, blinking)
		debug.profilebegin("player_draw:Draw")
		
		if self.hrp ~= nil then
			--Don't render player if not in frustum
			local not_cull = camera_util.CheckFrustum(hrp_cf.p, draw_rad)
			
			--Update character and model CFrame
			if hrp_cf ~= self.cframe then
				--Update character CFrame
				local prev_pos = self.cframe ~= nil and self.cframe.p or hrp_cf.p
				self.hrp.CFrame = hrp_cf
			end
			
			--Blink character
			local force_ball = nil
			if blinking then
				self.vis =  (self.ball ~= nil) and 1 or (1 - self.vis)
				ApplyVisible(self, self.vis)
				force_ball = self.vis < 0.5
			elseif blinking ~= self.blinking then
				self.vis = (self.ball ~= nil) and 1 or 0
				ApplyVisible(self, self.vis)
				force_ball = self.ball ~= nil
			end
			
			--Update ball
			if ball ~= self.ball or force_ball ~= nil then
				--Disable previous ball
				if self.ball ~= nil or force_ball == false then
					switch(self.ball, {}, {
						["JumpBall"] = function()
							self.jump_ball:Disable()
						end,
						["SpindashBall"] = function()
							self.spindash_ball:Disable()
						end,
					})
				end
				
				--Enable new ball
				if ball ~= nil or force_ball == true then
					if force_ball == nil then
						--Make character invisible
						ApplyVisible(self, 1)
						self.vis = 1
					end
					
					--Enable new ball
					switch(ball, {}, {
						["JumpBall"] = function()
							self.jump_ball:Enable()
						end,
						["SpindashBall"] = function()
							self.spindash_ball:Enable()
						end,
					})
				else
					if force_ball == nil then
						--Make character visible
						ApplyVisible(self, 0)
						self.vis = 0
					end
				end
			end
			
			if ball ~= nil then
				switch(ball, {}, {
					["JumpBall"] = function()
						if not_cull then
							self.jump_ball:Draw(dt, hrp_cf, ball_spin)
						else
							self.jump_ball:LazyDraw(dt, hrp_cf, ball_spin)
						end
					end,
					["SpindashBall"] = function()
						if not_cull then
							self.spindash_ball:Draw(dt, hrp_cf, ball_spin)
						else
							self.spindash_ball:LazyDraw(dt, hrp_cf, ball_spin)
						end
					end,
				})
			end
			
			--Update ball trail
			if trail_active ~= self.trail_active then
				if trail_active then
					self.ball_trail:Enable()
				else
					self.ball_trail:Disable()
				end
			end
			
			if not_cull then
				self.ball_trail:Draw(hrp_cf)
			else
				self.ball_trail:LazyDraw(hrp_cf)
			end
			
			--Update shield
			if shield ~= self.shield then
				--Disable previous shield
				if self.shield ~= nil then
					switch(self.shield, {}, {
						["Shield"] = function()
							self.shield_model:Disable()
						end,
						["MagnetShield"] = function()
							self.magnet_shield_model:Disable()
						end,
					})
				end
				
				--Enable new shield
				if shield ~= nil then
					switch(shield, {}, {
						["Shield"] = function()
							self.shield_model:Enable()
						end,
						["MagnetShield"] = function()
							self.magnet_shield_model:Enable()
						end,
					})
				end
			end
			
			if shield ~= nil then
				if not_cull then
					switch(shield, {}, {
						["Shield"] = function()
							self.shield_model:Draw(dt, hrp_cf)
						end,
						["MagnetShield"] = function()
							self.magnet_shield_model:Draw(dt, hrp_cf)
						end,
					})
				else
					switch(shield, {}, {
						["Shield"] = function()
							self.shield_model:LazyDraw(dt, hrp_cf)
						end,
						["MagnetShield"] = function()
							self.magnet_shield_model:LazyDraw(dt, hrp_cf)
						end,
					})
				end
			end
			
			--Update ball trail
			if invincible ~= self.invincible then
				if invincible then
					self.invincibility:Enable()
				else
					self.invincibility:Disable()
				end
			end
			
			if not_cull then
				self.invincibility:Draw(dt, hrp_cf)
			else
				self.invincibility:LazyDraw(dt, hrp_cf)
			end
			
			--Use given state
			self.cframe = hrp_cf
			self.ball = ball
			self.ball_spin = ball_spin
			self.invincible = invincible
			self.trail_active = trail_active
			self.shield = shield
			self.blinking = blinking
		end
		
		debug.profileend()
	end

	return player_draw
end

----------------

pcontrol.Player.init = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Player.lua
	Purpose: Player class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player = {}

	local assets = script.Parent:WaitForChild("Assets")
	local global_sounds = assets:WaitForChild("Sounds")
	local obj_assets = assets:WaitForChild("Objects")

	local spilled_ring = obj_assets:WaitForChild("SpilledRing")

	local speed_shoes_theme = global_sounds:WaitForChild("SpeedShoes")
	local speed_shoes_theme_id = string.sub(speed_shoes_theme.SoundId, 14)
	local speed_shoes_theme_volume = speed_shoes_theme.Volume

	local invincibility_theme = global_sounds:WaitForChild("Invincibility")
	local invincibility_theme_id = string.sub(invincibility_theme.SoundId, 14)
	local invincibility_theme_volume = invincibility_theme.Volume

	local extra_life_jingle = global_sounds:WaitForChild("ExtraLife")

	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons

	local switch = require(commons.Switch)
	local vector = require(commons.Vector)
	local cframe = require(commons.CFrame)
	local common_collision = require(commons.Collision)
	local global_reference = require(commons.GlobalReference)

	local player_draw = require(pcontrol.PlayerDraw.init)

	local constants = require(script.Parent:WaitForChild("Constants"))
	local input = require(script:WaitForChild("Input"))
	local acceleration = require(script:WaitForChild("Acceleration"))
	local movement = require(script:WaitForChild("Movement"))
	local collision = require(script:WaitForChild("Collision"))
	local rail = require(script:WaitForChild("Rail"))
	local homing_attack = require(script:WaitForChild("HomingAttack"))
	local lsd = require(script:WaitForChild("LSD"))
	local ragdoll = require(script:WaitForChild("Ragdoll"))
	local animation = require(script:WaitForChild("Animation"))
	local sound = require(script:WaitForChild("Sound"))

	local object_reference = global_reference:New(workspace, "Level/Objects")

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Constructor and destructor
	function player:New(character)
		--Initialize meta reference
		local self = setmetatable({}, {__index = player})
		
		--Load character's info
		local info
		if character ~= nil then
			self.character = character
			info = GetDefaultCharacterInfo()
		else
			error("Player can't be created without character")
			return nil
		end
		
		--Use character's info
		self.p = info.physics
		self.assets = info.assets
		self.animations = info.animations
		self.portraits = info.portraits
		
		--Find common character references
		self.hum = character:WaitForChild("Humanoid")
		self.hrp = character:WaitForChild("HumanoidRootPart")
		
		--Create player draw
		self.player_draw = player_draw:New(character)
		
		--Load animations and sounds
		sound.LoadSounds(self)
		animation.LoadAnimations(self)
		
		--Disable humanoid
		local enable = {
			[Enum.HumanoidStateType.None] = true,
			[Enum.HumanoidStateType.Dead] = true,
			[Enum.HumanoidStateType.Physics] = true,
		}
		for _,v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
			if enable[v] ~= true then
				self.hum:SetStateEnabled(v, false)
			end
		end
		self.hum:ChangeState(Enum.HumanoidStateType.Physics)
		
		--Use character's position and angle
		self.pos = self.hrp.Position - self.hrp.CFrame.UpVector * self:GetCharacterYOff()
		self.ang = self:AngleFromRbx(self.hrp.CFrame - self.hrp.CFrame.p)
		self.vis_ang = self.ang
		
		--Initialize player state
		self.state = constants.state.idle
		self.spd = Vector3.new()
		self.gspd = Vector3.new()
		self.flag = {
			grounded = true,
		}
		
		--Power-up state
		self.shield = nil
		self.speed_shoes_time = 0
		self.invincibility_time = 0
		
		self.invulnerability_time = 0
		
		--Meme state
		self.v3 = false
		
		--Physics state
		self.gravity = Vector3.new(0, -1, 0)
		
		--Collision state
		self.floor_normal = Vector3.new(0, 1, 0)
		self.dotp = 1
		
		self.floor = nil
		self.floor_off = CFrame.new()
		self.floor_last = nil
		self.floor_move = nil
		
		--Movement state
		self.frict_mult = 1
		
		self.jump_timer = 0
		self.spring_timer = 0
		self.dashpanel_timer = 0
		self.dashring_timer = 0
		self.rail_debounce = 0
		
		self.rail_trick = 0
		
		self.spindash_speed = 0
		
		self.jump_action = nil
		self.roll_action = nil
		self.secondary_action = nil
		self.tertiary_action = nil
		
		--Animation state
		self.animation = nil
		self.prev_animation = nil
		self.reset_anim = false
		self.anim_speed = 0
		
		--Game state
		self.score = 0
		self.time = 0
		self.rings = 0
		
		self.item_cards = {}
		
		self.portrait = "Idle"
		
		--Initialize sub-systems
		input.Initialize(self)
		rail.Initialize(self)
		
		--Effects
		--self.speed_trail = self.hrp:WaitForChild("SpeedTrail")
		self.rail_speed_trail = self.hrp:WaitForChild("RailSpeedTrail")
		self.air_kick_trails = {
			self.hrp:WaitForChild("KickBeam1"),
			self.hrp:WaitForChild("KickBeam2"),
		}
		
		local bottom = self.hrp:WaitForChild("Bottom")
		self.skid_effect = bottom:WaitForChild("Skid")
		self.rail_sparks = bottom:WaitForChild("Sparks")
		
		--Get level music id and volume
		local music_id = workspace:WaitForChild("Level"):WaitForChild("MusicId")
		local music_volume = workspace:WaitForChild("Level"):WaitForChild("MusicVolume")
		
		self.level_music_id = music_id.Value
		self.level_music_volume = music_volume.Value
		
		self.level_music_id_conn = music_id:GetPropertyChangedSignal("Value"):Connect(function()
			self.level_music_id = music_id.Value
		end)
		self.level_music_volume_conn = music_volume:GetPropertyChangedSignal("Value"):Connect(function()
			self.level_music_volume = music_volume.Value
		end)
		
		--Music state
		self.music_id = self.level_music_id
		self.music_volume = self.level_music_volume
		self.music_reset = false
		
		return self
	end

	function player:Destroy()
		--Disconnect level music events
		if self.level_music_id_conn ~= nil then
			self.level_music_id_conn:Disconnect()
			self.level_music_id_conn = nil
		end
		if self.level_music_volume_conn ~= nil then
			self.level_music_volume_conn:Disconnect()
			self.level_music_volume_conn = nil
		end
		
		--Quit sub-systems
		input.Quit(self)
		rail.Quit(self)
		
		--Destroy player draw
		if self.player_draw ~= nil then
			self.player_draw:Destroy()
			self.player_draw = nil
		end
		
		--Unload animations and sounds
		animation.UnloadAnimations(self)
		sound.UnloadSounds(self)
	end

	--Character functions
	function player:GetCharacterYOff()
		return self.hum.HipHeight + self.hrp.Size.Y / 2
	end

	--Physics setter
	local phys_dump_map = {
		"jump2_timer",
		"pos_error",
		"lim_h_spd",
		"lim_v_spd",
		"max_x_spd",
		"max_psh_spd",
		"jmp_y_spd",
		"nocon_speed",
		"slide_speed",
		"jog_speed",
		"run_speed",
		"rush_speed",
		"crash_speed",
		"dash_speed",
		"jmp_addit",
		"run_accel",
		"air_accel",
		"slow_down",
		"run_break",
		"air_break",
		"air_resist_air",
		"air_resist",
		"air_resist_y",
		"air_resist_z",
		"grd_frict",
		"grd_frict_z",
		"lim_frict",
		"rat_bound",
		"rad",
		"height",
		"weight",
		"eyes_height",
		"center_height",
	}

	local physics = script:WaitForChild("Physics")

	function player:SetPhysics(game, char)
		local game_mod = physics:FindFirstChild(game)
		if game_mod ~= nil and game_mod:IsA("ModuleScript") then
			local game_pack = require(game_mod)
			local char_phys = game_pack[char]
			
			if char_phys ~= nil then
				for i, v in pairs(char_phys) do
					local map = phys_dump_map[i]
					self.p[map] = v
				end
				self.p.height = self.p.height / 2
			end
		end
	end

	--Player space conversion
	function player:ToGlobal(vec)
		return self.ang * vec
	end

	function player:ToLocal(vec)
		return self.ang:inverse() * vec
	end

	function player:GetLook()
		return self.ang.RightVector
	end

	function player:GetRight()
		return -self.ang.LookVector
	end

	function player:GetUp()
		return self.ang.UpVector
	end

	function player:AngleFromRbx(ang)
		return ang * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.pi / 2)
	end

	function player:AngleToRbx(ang)
		return ang * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.pi / -2)
	end

	function player:ToWorldCFrame()
		return self:AngleToRbx(self.ang) + self.pos
	end

	function player:PosToSpd(vec)
		return Vector3.new(-vec.Z, vec.Y, vec.X)
	end

	function player:SpdToPos(vec)
		return Vector3.new(vec.Z, vec.Y, -vec.X)
	end

	--Player collision functions
	function player:GetMiddle()
		return self.pos + (self:GetUp() * (self.p.height * self.p.scale))
	end

	function player:GetSphereRadius()
		return ((self.p.height + self.p.rad) / 2) * self.p.scale
	end

	function player:GetSphere()
		return {
			center = self:GetMiddle(),
			radius = self:GetSphereRadius()
		}
	end

	function player:GetRegion()
		local mid = self:GetMiddle()
		local rad = self:GetSphereRadius()
		return Region3.new(
			mid - Vector3.new(rad, rad, rad),
			mid + Vector3.new(rad, rad, rad)
		)
	end

	--Player state functions
	function player:IsBlinking()
		return self.invulnerability_time > 0 and self.state ~= constants.state.hurt and self.state ~= constants.state.dead
	end

	function player:Damage(hurt_origin)
		--Do not take damage if invulnerable to damage
		if self.invulnerability_time > 0 or self.invincibility_time > 0 then
			return false
		end
		
		--Set state
		self:ResetObjectState()
		self:ExitBall()
		self.hurt_time = 1.5 * constants.framerate
		self.invulnerability_time = 2.75 * constants.framerate
		self.state = constants.state.hurt
		self.flag.grounded = false
		
		--Play hurt animation
		if math.abs(self.spd.X) >= self.p.dash_speed then
			self.animation = "Hurt2"
		else
			self.animation = "Hurt1"
		end
		
		--Set speed and rotation
		local diff = vector.PlaneProject(((hurt_origin ~= nil) and (hurt_origin - self:GetMiddle()) or (self:GetLook())), -self.gravity.unit)
		
		if diff.magnitude ~= 0 then
			local factor = math.abs(self:ToGlobal(self.spd):Dot(diff.unit)) / 5
			self:SetAngle(cframe.FromToRotation(self:GetLook(), diff.unit) * self.ang)
			self.spd = self:ToLocal((diff.unit * -1.125 * (1 + factor)) + (-self.gravity.unit * 1.675 * (1 + factor / 4)))
		else
			self.spd = self:ToLocal(-self.gravity.unit * 2.125)
		end
		
		--Damage
		if self.shield ~= nil then
			--Lose shield
			self.shield = nil
		else
			if self.rings > 0 then
				--Prepare to spill rings
				local lose_rings = math.min(self.rings, 20)
				local objects = object_reference:Get()
				local look = self:GetLook()
				local look_ang = math.atan2(look.X, look.Z)
				
				sound.PlaySound(self, "RingLoss")
				
				if lose_rings > 0 then
					--Spill first 10 rings in a taller arc
					local circle_rings = math.min(lose_rings, 10)
					local ang_inc = math.pi * 2 / circle_rings
					local ang = look_ang
					
					for i = 1, circle_rings do
						--Spill ring
						local ring = spilled_ring:Clone()
						ring:SetPrimaryPartCFrame(CFrame.new(self:GetMiddle()))
						ring.PrimaryPart.Velocity = Vector3.new(-math.sin(ang) * 30, 90, -math.cos(ang) * 30)
						ring.Parent = objects
						
						--Increment angle
						ang = ang + ang_inc
					end
				end
				
				if lose_rings > 10 then
					--Spill second 10 rings in a shorter arc
					local circle_rings = math.min(lose_rings - 10, 10)
					local ang_inc = math.pi * 2 / circle_rings
					local ang = look_ang
					
					for i = 1, circle_rings do
						--Spill ring
						local ring = spilled_ring:Clone()
						ring:SetPrimaryPartCFrame(CFrame.new(self:GetMiddle()))
						ring.PrimaryPart.Velocity = Vector3.new(-math.sin(ang) * 45, 60, -math.cos(ang) * 45)
						ring.Parent = objects
						
						--Increment angle
						ang = ang + ang_inc
					end
				end
				
				--Lose rings
				self.rings = math.max(self.rings - 150, 0)
			else
				--TODO: die
			end
		end
		
		return true
	end

	function player:ResetObjectState()
		self.flag.scripted_spring = false
		self.spring_timer = 0
		self.dashpanel_timer = 0
		self.dashring_timer = 0
		self.rail_trick = 0
		rail.SetRail(self, nil)
	end

	function player:EnterBall()
		self.flag.ball_aura = true
	end

	function player:ExitBall()
		sound.StopSound(self, "SpindashCharge")
		self.flag.air_kick = false
		self.flag.ball_aura = false
		self.flag.dash_aura = false
	end

	function player:Land()
		self:ExitBall()
		self.flag.bounce2 = false
	end

	function player:TrailActive()
		if self.flag.grounded then
			return self.flag.ball_aura and self.state ~= constants.state.spindash
		else
			return self.flag.dash_aura or self.state == constants.state.homing or self.state == constants.state.bounce
		end
	end

	function player:BallActive()
		return self.flag.ball_aura or self.state == constants.state.air_kick
	end

	function player:ObjectBounce()
		--Enter airborne state
		if self.state == constants.state.homing or self.state == constants.state.air_kick then
			self.flag.air_kick = true
		end
		if self:BallActive() then
			self:EnterBall()
			self.animation = "Roll"
			self.flag.dash_aura = false
		end
		self.state = constants.state.airborne
		self.flag.grounded = false
		
		--Set speed
		self.spd = Vector3.new(0, 3, 0)
		self.anim_speed = self.spd.magnitude
	end

	function player:UseFloorMove()
		if self.floor_move ~= nil then
			self.spd = self.spd + self:ToLocal(self.floor_move) / self.p.scale
			self.floor_move = nil
		end
	end

	function player:Scripted()
		return (self.flag.grounded and (false) or (self.spring_timer > 0 or self.dashring_timer > 0))
	end

	--Physics functions
	function player:GetWeight()
		return self.p.weight * (self.flag.underwater and 0.45 or 1)
	end

	function player:GetAirResistY()
		return self.p.air_resist_y * (self.flag.underwater and 1.5 or 1)
	end

	function player:GetMaxXSpeed()
		return self.p.max_x_spd * ((self.speed_shoes_time > 0) and 2 or 1)
	end

	function player:GetRunAccel()
		return self.p.run_accel * (self.underwater and 0.65 or 1) * ((self.speed_shoes_time > 0) and 2 or 1)
	end

	--Game functions
	function player:GiveScore(score)
		--Give score
		self.score = self.score + score
	end

	function player:GiveRings(rings)
		--Give ring and score bonus
		self.rings = self.rings + rings
	end

	function player:GiveItem(item)
		--Handle item
		switch(item, {}, {
			["5Rings"] = function()
				self:GiveScore(10 * 5)
				self:GiveRings(5)
			end,
			["10Rings"] = function()
				self:GiveScore(10 * 10)
				self:GiveRings(10)
			end,
			["20Rings"] = function()
				self:GiveScore(10 * 20)
				self:GiveRings(20)
			end,
			["1Up"] = function()
				extra_life_jingle:Play()
			end,
			["Invincibility"] = function()
				self.invincibility_time = 20 * constants.framerate
				self.music_id = invincibility_theme_id
				self.music_volume = invincibility_theme_volume
				self.music_reset = true
			end,
			["SpeedShoes"] = function()
				self.speed_shoes_time = 15 * constants.framerate
				self.music_id = speed_shoes_theme_id
				self.music_volume = speed_shoes_theme_volume
				self.music_reset = true
			end,
			["Shield"] = function()
				self.shield = "Shield"
			end,
			["MagnetShield"] = function()
				self.shield = "MagnetShield"
			end,
		})
		
		--Process item for hud item cards
		table.insert(self.item_cards, item)
	end

	--Other player global functions
	function player:SetAngle(ang)
		if self.flag.grounded and not self.v3 then
			--Set angle
			self.ang = ang
		else
			--Set angle, maintaining middle
			self.pos = self.pos + self:GetUp() * self.p.height * self.p.scale
			self.ang = ang
			self.pos = self.pos - self:GetUp() * self.p.height * self.p.scale
		end
		
		--Set other angle information
		self.dotp = -self:GetUp():Dot(self.gravity.unit)
		self.floor_normal = self:GetUp()
	end

	--Player turn functions
	function player:Turn(turn)
		if self.v3 and self.dotp < 0.95 then
			local fac = math.min(math.abs(self.spd.X) / self.p.max_x_spd, 1)
			turn = turn * fac
		end
		self.ang = self.ang * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), turn)
		return turn
	end

	function player:AdjustAngleY(turn)
		--Get analogue state
		local has_control,_,_ = input.GetAnalogue(self)
		
		--Remember previous global speed
		local prev_spd = self:ToGlobal(self.spd)
		
		--Get max turn
		local max_turn = math.abs(turn)
		
		if max_turn <= math.rad(45) then
			if max_turn <= math.rad(22.5) then
				max_turn = max_turn / 8
			else
				max_turn = max_turn / 4
			end
		else
			max_turn = math.rad(11.25)
		end
		
		--Turn
		if not self.v3 then
			turn = math.clamp(turn, -max_turn, max_turn)
		end
		turn = self:Turn(turn)
		
		--Handle inertia
		if self.v3 ~= true then
			if not self.flag.grounded then
				--90% inertia
				self.spd = self.spd * 0.1 + self:ToLocal(prev_spd) * 0.9
			else
				local inertia
				if has_control then
					if self.dotp <= 0.4 then
						inertia = 0.5
					else
						inertia = 0.01
					end
				else
					inertia = 0.95
				end
				
				if self.frict_mult < 1 then
					inertia = inertia * self.frict_mult
				end
				
				self.spd = self.spd * (1 - inertia) + self:ToLocal(prev_spd) * inertia
			end
		end
		
		return turn
	end

	function player:AdjustAngleYQ(turn)
		--Turn with full inertia
		local prev_spd = self:ToGlobal(self.spd)
		
		if not self.v3 then
			turn = math.clamp(turn, math.rad(-45), math.rad(45))
		end
		turn = self:Turn(turn)
		
		if self.v3 ~= true then
			self.spd = self:ToLocal(prev_spd)
		end
		
		return turn
	end

	function player:AdjustAngleYS(turn)
		--Remember previous global speed
		local prev_spd = self:ToGlobal(self.spd)
		
		--Get max turn
		local max_turn = math.rad(1.40625)
		if self.spd.X > self.p.dash_speed then
			max_turn = math.max(max_turn - (math.sqrt(((self.spd.X - self.p.dash_speed) * 0.0625)) * max_turn), 0)
		end
		
		--Turn
		if not self.v3 then
			turn = math.clamp(turn, -max_turn, max_turn)
		end
		turn = self:Turn(turn)
		
		--Handle inertia
		if self.v3 ~= true then
			local inertia
			if self.dotp <= 0.4 then
				inertia = 0.5
			else
				inertia = 0.01
			end
			
			self.spd = self.spd * (1 - inertia) + self:ToLocal(prev_spd) * inertia
		end
		
		return turn
	end

	--Moves
	local function GetWalkState(self)
		if math.abs(self.spd.X) > 0.01 then
			return constants.state.walk
		else
			return constants.state.idle
		end
	end

	local function CheckJump(self)
		--Check for jumping
		self.jump_action = "Jump"
		if self.input.button_press.jump then
			--Enter jump state
			if self.dotp > 0.9 or not self.v3 then
				self.spd = vector.SetY(self.spd, self.p.jmp_y_spd)
			end
			self:UseFloorMove()
			self.jump_timer = self.p.jump2_timer
			self.flag.grounded = false
			
			rail.SetRail(self, nil)
			
			self.state = constants.state.airborne
			self:EnterBall()
			
			--Play jump animation and sound
			self.animation = "Roll"
			self.anim_speed = self.spd.X
			sound.PlaySound(self, "Jump")
			return true
		end
		return false
	end

	local function CheckSpindash(self)
		--Check for spindashing
		self.roll_action = "Spindash"
		if self.input.button_press.roll then
			--Start spindashing
			self.state = constants.state.spindash
			self:EnterBall()
			self.spindash_speed = math.max(self.spd.X, 2)
			sound.PlaySound(self, "SpindashCharge")
			return true
		end
		return false
	end

	local function CheckUncurl(self)
		--Check for uncurling
		self.roll_action = "Roll"
		if self.input.button_press.roll and not self.flag.ceiling_clip then
			--Uncurl
			self.state = constants.state.walk
			self:ExitBall()
			return true
		end
		return false
	end

	local function CheckLightSpeedDash(self, object_instance)
		--Check for light speed dash
		self.secondary_action = "LightSpeedDash"
		if self.input.button_press.secondary_action and lsd.CheckStartLSD(self, object_instance) then
			--Start light speed dash
			self.animation = "LSD"
			self.state = constants.state.light_speed_dash
			self:ExitBall()
			self:ResetObjectState()
			return true
		end
		return false
	end

	local function CheckHomingAttack(self, object_instance)
		--Check for homing attack
		if self.flag.ball_aura then
			self.jump_action = "HomingAttack"
			if self.input.button_press.jump then
				if homing_attack.CheckStartHoming(self, object_instance) then
					--Homing attack
					self.animation = "Roll"
					self:EnterBall()
				else
					--Jump dash
					self.spd = vector.SetX(self.spd, 5)
					self.animation = "Fall"
					self:ExitBall()
					self.flag.dash_aura = true
					sound.PlaySound(self, "Dash")
				end
				
				--Enter homing attack state
				self.state = constants.state.homing
				self.homing_timer = 0
				sound.PlaySound(self, "Dash")
				return true
			end
		end
		return false
	end

	local function CheckBounce(self)
		--Check for bounce
		if self.flag.ball_aura then
			self.roll_action = "Bounce"
			if self.input.button_press.roll then
				--Bounce
				self.state = constants.state.bounce
				self.animation = "Roll"
				self.spd = vector.MulX(self.spd, 0.75)
				if self.flag.bounce2 == true then
					self.spd = vector.SetY(self.spd, -7)
				else
					self.spd = vector.SetY(self.spd, -5)
				end
				self.anim_speed = -self.spd.Y
				return true
			end
		end
		return false
	end

	local function CheckAirKick(self)
		--Check for air kick
		if self.flag.air_kick then
			self.tertiary_action = "AirKick"
			if self.input.button_press.tertiary_action then
				--Air kick
				self:GiveScore(200)
				self.state = constants.state.air_kick
				self:ExitBall()
				if input.GetAnalogue_Mag(self) <= 0 then
					self.animation = "AirKickUp"
					self.spd = Vector3.new(0.2, 2.65, 0)
					self.air_kick_timer = 60
				else
					self.animation = "AirKick"
					self.spd = Vector3.new(4.5, 1.425, 0)
					self.air_kick_timer = 120
				end
				return true
			end
		end
		return false
	end

	local function CheckSkid(self)
		local has_control, analogue_turn, _ = input.GetAnalogue(self)
		if has_control then
			return math.abs(analogue_turn) > math.rad(135)
		end
		return false
	end

	local function CheckStopSkid(self)
		if self.spd.X <= 0.01 then
			--We've stopped, stop skidding
			self.spd = vector.SetX(self.spd, 0)
			return true
		else
			--If holding forward, stop skidding
			local has_control, analogue_turn, _ = input.GetAnalogue(self)
			if has_control then
				return math.abs(analogue_turn) <= math.rad(135)
			end
			return false
		end
	end

	local function CheckStartWalk(self)
		local has_control, _, _ = input.GetAnalogue(self)
		if has_control or math.abs(self.spd.X) > self.p.slide_speed then
			self.state = constants.state.walk
			return true
		end
		return false
	end

	local function CheckStopWalk(self)
		local has_control, _, _ = input.GetAnalogue(self)
		if has_control or math.abs(self.spd.X) > 0.01 then
			return false
		end
		
		self.state = constants.state.idle
		return true
	end

	local function CheckMoves(self, object_instance)
		if self.do_ragdoll then
			self.state = constants.state.ragdoll
			self.do_ragdoll = false
			return true
		end
		
		return switch(self.state, {}, {
			[constants.state.idle] = function()
				return CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) or CheckStartWalk(self)
			end,
			[constants.state.walk] = function()
				if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) or CheckStopWalk(self) then
					return true
				else
					--Check if we should start skidding
					if self.spd.X > self.p.jog_speed and CheckSkid(self) then
						--Start skidding
						self.state = constants.state.skid
						sound.PlaySound(self, "Skid")
						return true
					end
				end
				return false
			end,
			[constants.state.skid] = function()
				if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckSpindash(self) then
					return true
				else
					--Check if we should stop skidding
					if CheckStopSkid(self) then
						--Stop skidding
						self.state = GetWalkState(self)
						return true
					end
				end
				return false
			end,
			[constants.state.roll] = function()
				if CheckLightSpeedDash(self, object_instance) or CheckJump(self) or CheckUncurl(self) then
					return true
				else
					if self.spd.X < self.p.run_speed then
						if self.flag.ceiling_clip then
							--Force us to keep rolling
							self.spd = vector.SetX(self.spd, self.p.run_speed)
						else
							--Uncurl if moving too slow
							self.state = GetWalkState(self)
							self:ExitBall()
							return true
						end
					end
				end
				return false
			end,
			[constants.state.spindash] = function()
				if CheckLightSpeedDash(self, object_instance) then
					return true
				else
					self.roll_action = "Spindash"
					if self.input.button.roll then
						--Increase spindash speed
						if self.spindash_speed < 10 or self.v3 == true then
							self.spindash_speed = self.spindash_speed + ((self.v3 == true) and 0.1 or 0.4)
						end
					else
						--Release spindash
						self.state = constants.state.roll
						self:EnterBall()
						self.spd = vector.SetX(self.spd, self.spindash_speed)
						sound.StopSound(self, "SpindashCharge")
						sound.PlaySound(self, "SpindashRelease")
						return true
					end
				end
				return false
			end,
			[constants.state.airborne] = function()
				return CheckLightSpeedDash(self, object_instance) or CheckHomingAttack(self, object_instance) or CheckBounce(self) or CheckAirKick(self)
			end,
			[constants.state.homing] = function()
				if self.homing_obj == nil then
					if CheckLightSpeedDash(self, object_instance) then
						return true
					end
				else
					self.jump_action = "Jump"
				end
				return false
			end,
			[constants.state.bounce] = function()
				self.roll_action = "Bounce"
				return CheckLightSpeedDash(self, object_instance) or CheckHomingAttack(self, object_instance)
			end,
			[constants.state.light_speed_dash] = function()
				self.secondary_action = "LightSpeedDash"
				return false
			end,
			[constants.state.air_kick] = function()
				return CheckLightSpeedDash(self, object_instance)
			end,
			[constants.state.rail] = function()
				self.jump_action = "Jump"
				self.roll_action = "Crouch"
				if self.input.button_press.jump then
					if rail.CheckSwitch(self) then
						--Rail switch jump
						sound.PlaySound(self, "Jump")
						return true
					elseif rail.CheckTrick(self) then
						--Trick jump
						sound.PlaySound(self, "Jump")
						return true
					else
						--Normal jump
						return CheckJump(self)
					end
				end
				return false
			end,
		}) or false
	end

	--Player update
	local admins = {
		[34801411] = true, --DigiPurgatory
		[53427446] = true, --TheGreenDeveloper
		[212784509] = true, --MrMacTtey3
		[1935825706] = true, --SOAPushBurner
	}

	function player:Update(object_instance)
		debug.profilebegin("player:Update")
		
		--Update input
		input.Update(self)
		
		--Debug input
		if admins[game:GetService("Players").LocalPlayer.UserId] then
			if self.input.button_press.dbg then
				self.gravity = -self.gravity
				self.flag.grounded = false
				self:SetAngle(self.ang * CFrame.Angles(math.pi, 0, 0))
				self.spd = self.spd * Vector3.new(1, -1, 0)
			end
		end
		
		--Handle power-ups
		self.invincibility_time = math.max(self.invincibility_time - 1, 0)
		self.speed_shoes_time = math.max(self.speed_shoes_time - 1, 0)
		
		if self.invincibility_time > 0 then
			self.music_id = string.sub(invincibility_theme.SoundId, 14)
			self.music_volume = invincibility_theme.Volume
		elseif self.speed_shoes_time > 0 then
			self.music_id = string.sub(speed_shoes_theme.SoundId, 14)
			self.music_volume = speed_shoes_theme.Volume
		else
			self.music_id = self.level_music_id
			self.music_volume = self.level_music_volume
		end
		
		--Shield idle abilities
		switch(self.shield, {}, {
			["Shield"] = function()
				
			end,
			["MagnetShield"] = function()
				--Get attracting rings
				local attract_range = 35
				local attract_region = Region3.new(self.pos - Vector3.new(attract_range, attract_range, attract_range), self.pos + Vector3.new(attract_range, attract_range, attract_range))
				local rings = object_instance:GetObjectsInRegion(attract_region, function(v)
					return v.class == "Ring" and v.collected ~= true and v.attract_player == nil
				end)
				
				--Attract rings
				for _,v in pairs(rings) do
					if (v.root.Position - self.pos).magnitude < attract_range then
						v:Attract(self)
					end
				end
				
				--Disappear when underwater
				if self.flag.underwater then
					self.shield = nil
				end
			end,
		})
		
		--Reset per frame state
		self.last_turn = 0
		
		--Handle player moves
		self.jump_action = nil
		self.roll_action = nil
		self.secondary_action = nil
		self.tertiary_action = nil
		
		if not self:Scripted() then
			CheckMoves(self, object_instance)
		end
		
		--Water drag
		if self.v3 ~= true and self.flag.underwater then
			if self.state == constants.state.roll then
				self.spd = vector.AddX(self.spd, self.spd.X * -0.06)
			else
				self.spd = vector.AddX(self.spd, self.spd.X * -0.03)
			end
		end
		
		--Handle timers
		if self.spring_timer > 0 then
			self.spring_timer = self.spring_timer - 1
			if self.spring_timer <= 0 then
				self.spring_timer = 0
				self.flag.scripted_spring = false
			end
		end
		
		if self.invulnerability_time > 0 and self:IsBlinking() then
			self.invulnerability_time = math.max(self.invulnerability_time - 1, 0)
		end
		
		if self.dashpanel_timer > 0 then
			self.dashpanel_timer = math.max(self.dashpanel_timer - 1, 0)
		end
		
		if self.dashring_timer > 0 then
			self.dashring_timer = math.max(self.dashring_timer - 1, 0)
		end
		
		if self.rail_debounce > 0 then
			self.rail_debounce = math.max(self.rail_debounce - 1, 0)
		end
		
		if self.rail_trick > 0 then
			self.rail_trick = math.max(self.rail_trick - 0.015, 0)
		end
		
		--Run character state
		switch(self.state, {}, {
			[constants.state.idle] = function()
				--Movement and collision
				movement.GetRotation(self)
				movement.RotatedByGravity(self)
				acceleration.GetAcceleration(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if not self.flag.grounded then
						--Ungrounded
						self.state = constants.state.airborne
						self.animation = "Fall"
					else
						--Set animation
						if self.animation ~= "Land" then
							self.animation = "Idle"
						end
					end
				end
			end,
			[constants.state.walk] = function()
				--Movement and collision
				acceleration.GetAcceleration(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if not self.flag.grounded then
						--Ungrounded
						self.state = constants.state.airborne
						self.animation = "Fall"
					else
						--Set animation
						self.animation = "Run"
						
						local slip_factor = math.sqrt(self.frict_mult)
						local acc_factor = math.min(math.abs(self.spd.X) / self.p.crash_speed, 1)
						self.anim_speed = lerp(self.spd.X / slip_factor + (1 - slip_factor) * 2, self.spd.X, acc_factor)
					end
				end
			end,
			[constants.state.skid] = function()
				--Movement and collision
				movement.GetSkidSpeed(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if not self.flag.grounded then
						--Ungrounded
						self.state = constants.state.airborne
						self.animation = "Fall"
					else
						--Set animation and check if should stop skidding
						self.animation = "Skid"
					end
				end
			end,
			[constants.state.spindash] = function()
				--Movement and collision
				movement.GetRotation(self)
				movement.GetSkidSpeed(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if not self.flag.grounded then
						--Ungrounded
						self.state = constants.state.airborne
						sound.StopSound(self, "SpindashCharge")
						
						--Set animation
						self.animation = "Roll"
						self.anim_speed = self.spd.magnitude
					else
						--Set animation
						self.animation = "Spindash"
						self.anim_speed = self.spindash_speed
					end
				end
			end,
			[constants.state.roll] = function()
				--Movement and collision
				movement.GetRotation(self)
				movement.GetInertia(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if not self.flag.grounded then
						--Ungrounded
						self.state = constants.state.airborne
					end
					
					--Set animation
					self.animation = "Roll"
					if self.flag.grounded then
						self.anim_speed = self.spd.X
					else
						self.anim_speed = self.spd.magnitude
					end
				end
			end,
			[constants.state.airborne] = function()
				--Movement
				acceleration.GetAirAcceleration(self)
				if self.spring_timer <= 0 and self.dashring_timer <= 0 then
					movement.AlignToGravity(self)
				end
				
				--Handle collision
				local fall_ysp = -self.spd.Y
				self.flag.grounded = false
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if self.flag.grounded then
						--Landed
						if math.abs(self.spd.X) < self.p.jog_speed then
							if fall_ysp > 2 then
								self.animation = "Land"
							else
								self.animation = "Idle"
							end
							self.spd = vector.SetX(self.spd, 0)
							self.state = constants.state.idle
						else
							self.state = GetWalkState(self)
						end
						self:Land()
						
						--Play land sound
						if fall_ysp > 0 then
							sound.SetSoundVolume(self, "Land", fall_ysp / 5)
							sound.PlaySound(self, "Land")
						end
					end
				end
			end,
			[constants.state.homing] = function()
				--Handle homing
				local stop_homing = homing_attack.RunHoming(self, object_instance)
				self.anim_speed = self.spd.X
				
				--Handle collision
				self.flag.grounded = false
				movement.AlignToGravity(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					--Check for homing attack to be cancelled
					if self.flag.grounded then
						--Land on the ground
						self.state = GetWalkState(self)
						self:Land()
					else
						--Stop homing attack if wall is hit or was told to stop
						if stop_homing or (self.homing_obj ~= nil and self.spd.magnitude < 2.5) then
							self.state = constants.state.airborne
							self:ExitBall()
							self.animation = "Fall"
						end
					end
				end
			end,
			[constants.state.bounce] = function()
				--Movement
				acceleration.GetAirAcceleration(self)
				
				--Handle collision
				self.flag.grounded = false
				movement.AlignToGravity(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					--Bounce off floor once we hit one
					if self.flag.grounded then
						--Unground and play sound
						self.state = constants.state.airborne
						sound.PlaySound(self, "Bounce")
						
						--Set upwards velocity
						self.jump_timer = 0
						if self.v3 ~= true or (math.random() < 0.5) then
							local fac = 1 + (math.abs(self.spd.X) / 16)
							if self.flag.bounce2 == true then
								self.spd = vector.SetY(self.spd, 3.575 * fac)
							else
								self.spd = vector.SetY(self.spd, 2.825 * fac)
								self.flag.bounce2 = true
							end
							self:UseFloorMove()
						end
					end
				end
			end,
			[constants.state.rail] = function()
				--Perform rail movement
				if rail.Movement(self) then
					--Become airborne in fall animation (came off rail)
					self.state = constants.state.airborne
					self.animation = "Fall"
				end
			end,
			[constants.state.light_speed_dash] = function()
				--Run light speed dash
				if lsd.RunLSD(self, object_instance) then
					--Stop light speed dash
					self.state = constants.state.airborne
					self.animation = "Fall"
				end
				
				--Handle collision
				self.flag.grounded = false
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					--Stop light speed dash if wall is hit
					if self.spd.magnitude < 1 then
						self.state = constants.state.airborne
						self.animation = "Fall"
					end
				end
			end,
			[constants.state.air_kick] = function()
				--Handle movement
				local has_control, analogue_turn, analogue_mag = input.GetAnalogue(self)
				self.spd = self.spd + self.spd * Vector3.new(self.p.air_resist_air * (0.285 - analogue_mag * 0.1), self:GetAirResistY(), self.p.air_resist_z)
				self.spd = self.spd + self:ToLocal(self.gravity) * self:GetWeight() * 0.4
				self:AdjustAngleYS(analogue_turn)
				
				--Handle collision
				local fall_ysp = -self.spd.Y
				self.flag.grounded = false
				movement.AlignToGravity(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if self.flag.grounded then
						--Landed
						self.state = GetWalkState(self)
						self:Land()
						
						--Play land sound
						if fall_ysp > 0 then
							sound.SetSoundVolume(self, "Land", fall_ysp / 5)
							sound.PlaySound(self, "Land")
						end
					else
						--Stop air kick after timer's run out or we've lost all our speed
						self.air_kick_timer = self.air_kick_timer - 1
						if self.air_kick_timer <= 0 or self.spd.magnitude < 0.35 then
							self.state = constants.state.airborne
							self.animation = "Fall"
						end
					end
				end
			end,
			[constants.state.ragdoll] = function()
				--Run ragdoll
				if ragdoll.Physics(self) then
					self.state = constants.state.airborne
					self.animation = "Fall"
					return
				end
				
				--Handle collision
				self.flag.grounded = false
				collision.Run(self)
			end,
			[constants.state.hurt] = function()
				--Handle movement
				movement.GetInertia(self)
				
				--Handle collision
				self.flag.grounded = false
				movement.AlignToGravity(self)
				collision.Run(self)
				
				if not rail.CollideRails(self) then
					if self.flag.grounded then
						--Land on the ground
						self.state = GetWalkState(self)
						self:Land()
						self.animation = "Land"
						self.spd = self.spd:Lerp(Vector3.new(), math.abs(self.dotp))
					elseif self.hurt_time > 0 then
						--Exit hurt state after cooldown
						self.hurt_time = math.max(self.hurt_time - 1, 0)
						if self.hurt_time <= 0 then
							self.state = constants.state.airborne
							self.animation = "Fall"
						end
					end
				end
			end,
			[constants.state.dead] = function()
				
			end,
			[constants.state.drown] = function()
				
			end,
		})
		
		--Get portrait to use
		if self.state == constants.state.hurt or self.state == constants.state.dead then
			self.portrait = "Hurt"
		else
			self.portrait = "Idle"
		end
		
		--Increment game time
		self.time = self.time + 1 / constants.framerate
		
		--TEMP: Die when below death barrier
		if self.pos.Y <= workspace.FallenPartsDestroyHeight then
			self.hum.Health = 0
		end
		if self.hum.Health <= 0 and not self.dead_debounce then
			self.dead_debounce = true
			replicated_storage:WaitForChild("LoadCharacter"):FireServer()
		end
		
		debug.profileend()
	end

	--Player draw
	function player:Draw(dt)
		debug.profilebegin("player:Draw")
		
		--Update animation and dynamic tilt
		animation.Animate(self)
		animation.DynTilt(self, dt)
		
		--Get character position
		local balance = self.state == constants.state.rail and self.rail_balance or 0
		local off = self.state == constants.state.rail and self.rail_off or Vector3.new()
		self.vis_ang = (self:AngleToRbx(self.ang) * CFrame.Angles(0, 0, -balance)):Lerp(self.vis_ang, (0.675 ^ 60) ^ dt)
		
		local hrp_cframe = (self.vis_ang + self.pos + off) + (self.vis_ang.UpVector * self:GetCharacterYOff())
		
		--Set Player Draw state
		local ball_form, ball_spin
		if self.animation == "Roll" then
			ball_form = "JumpBall"
			ball_spin = animation.GetAnimationRate(self) * math.pi * 2
		elseif self.animation == "Spindash" then
			ball_form = "SpindashBall"
			ball_spin = animation.GetAnimationRate(self) * math.pi * 2
		else
			ball_form = nil
			ball_spin = 0
		end
		
		self.player_draw:Draw(dt, hrp_cframe, ball_form, ball_spin, self:TrailActive(), self.shield, self.invincibility_time > 0, self:IsBlinking())
		
		--Update sound source
		sound.UpdateSource(self)
		
		--Speed trail
		--if math.abs(self.spd.X) >= (self.p.rush_speed + self.p.crash_speed) / 2 then
		--	self.speed_trail.Enabled = true
		--	self.speed_trail.TextureLength = math.abs(self.spd.X) * 0.875
		--else
		--	self.speed_trail.Enabled = false
		--end
		
		--Rail speed trail
		if rail.GrindActive(self) and math.abs(self.spd.X) >= self.p.crash_speed then
			self.rail_speed_trail.Enabled = true
		else
			self.rail_speed_trail.Enabled = false
		end
		
		--Air kick trails
		if self.animation == "AirKick" then
			for _,v in pairs(self.air_kick_trails) do
				v.Enabled = true
			end
		else
			for _,v in pairs(self.air_kick_trails) do
				v.Enabled = false
			end
		end
		
		--Skid trail
		if self.animation == "Skid" then
			self.skid_effect.Enabled = true
		else
			self.skid_effect.Enabled = false
		end
		
		--Rail sparks
		if rail.GrindActive(self) and math.abs(self.spd.X) >= self.p.run_speed then
			self.rail_sparks.Enabled = true
			self.rail_sparks.Rate = math.abs(self.spd.X) * 90
			self.rail_sparks.EmissionDirection = (self.spd.X >= 0) and Enum.NormalId.Back or Enum.NormalId.Front
		else
			self.rail_sparks.Enabled = false
		end
		
		debug.profileend()
	end

	return player
end

-- PLAYUER REPLICATE YAS --
pcontrol.PlayerReplicate = {}
pcontrol.PlayerReplicate.Peer = function()
	--[[
	= DigitalSwirl Client =
	Source: ControlScript/PlayerReplicate/Peer.lua
	Purpose: Player Replication Peer class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local peer_class = {}

	local players = game:GetService("Players")
	local replicated_storage = game:GetService("ReplicatedStorage")
	local common_modules = commons
	local playerreplicate_modules = commons.PlayerReplicate

	local constants = require(commons.PlayerReplicate.Constants)

	local player_draw = require(pcontrol.PlayerDraw.init)

	--Common functions
	local function lerp(x, y, z)
		return x + (y - x) * z
	end

	--Common peer functions
	local function InitPosition(self)
		if self.character ~= nil and self.hrp ~= nil then
			if self.cur_cf == nil or self.prev_cf == nil then
				self.prev_cf = self.hrp.CFrame
				self.cur_cf = self.hrp.CFrame
			end
		end
	end

	--Constructor and destructor
	function peer_class:New(peer)
		--Initialize meta reference
		local self = setmetatable({}, {__index = peer_class})
		
		--Get player to connect to
		self.player = players:FindFirstChild(peer)
		if self.player == nil then
			warn("Failed to find player")
			return nil
		end
		
		--Initialize peer position and other state stuff
		InitPosition(self)
		self.tick = nil
		self.rate = constants.packet_rate
		
		--Initialize render state
		self.ball = nil
		self.shield = nil
		self.invincible = false
		self.ball_spin = 0
		self.ball_draw_spin = 0
		self.trail_active = false
		
		return self
	end

	function peer_class:Destroy()
		--Destroy player draw
		if self.player_draw ~= nil then
			self.player_draw:Destroy()
			self.player_draw = nil
		end
	end

	--Peer interface
	function peer_class:SendData(data)
		debug.profilebegin("peer_class:SendData")
		
		--Process data
		if typeof(data.cframe) == "CFrame" then
			if data.character ~= self.character or data.tween == false then
				self.prev_cf = data.cframe
				self.cur_cf = data.cframe
			elseif data.tween == true then
				self.prev_cf = self.cur_cf
				self.cur_cf = data.cframe
			end
		else
			self.prev_cf = nil
			self.cur_cf = nil
		end
		
		if typeof(data.ball) == "string" then
			self.ball = data.ball
		else
			self.ball = nil
		end
		
		if typeof(data.ball_spin) == "number" then
			self.ball_spin = data.ball_spin
		else
			self.ball_spin = 0
		end
		
		if typeof(data.trail_active) == "boolean" then
			self.trail_active = data.trail_active
		else
			self.trail_active = false
		end
		
		if typeof(data.shield) == "string" then
			self.shield = data.shield
		else
			self.shield = nil
		end
		
		if typeof(data.invincible) == "boolean" then
			self.invincible = data.invincible
		else
			self.invincible = false
		end
		
		--Handle character and HumanoidRootPart updates
		if data.character ~= nil then
			if data.character ~= self.character or self.hrp == nil or self.hrp.Parent ~= self.character then
				--Update character and HumanoidRootPart
				self.character = data.character
				self.hrp = self.character:FindFirstChild("HumanoidRootPart")
				
				--Create new player draw
				if self.player_draw ~= nil then
					self.player_draw:Destroy()
				end
				self.player_draw = player_draw:New(self.character)
			end
		elseif self.character ~= nil then
			--Destroy player draw and release character and HumanoidRootPart
			if self.player_draw ~= nil then
				self.player_draw:Destroy()
				self.player_draw = nil
			end
			self.character = nil
			self.hrp = nil
		end
		
		--Initialize position if needed
		InitPosition(self)
		
		--Handle tick and rate calculation
		local now = tick()
		if self.tick ~= nil then
			local dt = now - self.tick
			self.rate = lerp(self.rate, dt, 0.25)
		end
		self.tick = now
		
		debug.profileend()
	end

	function peer_class:Update(dt)
		debug.profilebegin("peer_class:Update")
		
		if self.character ~= nil and self.hrp ~= nil and self.player_draw ~= nil then
			if self.prev_cf ~= nil and self.cur_cf ~= nil and self.tick ~= nil then
				--Calculate interpolated CFrame
				local now = tick()
				local interp = math.min((now - self.tick) / self.rate, 1)
				local cframe = self.prev_cf:Lerp(self.cur_cf, interp)
				
				--Draw player draw
				self.player_draw:Draw(dt, cframe, self.ball, self.ball_spin, self.trail_active, self.shield, self.invincible)
			end
		end
		
		debug.profileend()
	end

	return peer_class
end

pcontrol.PlayerReplicate.init = function()
	--[[
	= DigitalSwirl Client =
	Source: ControlScript/PlayerReplicate.lua
	Purpose: Player Replication class
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local player_replicate_class = {}

	local players = game:GetService("Players")
	local player = players.LocalPlayer
	local replicated_storage = game:GetService("ReplicatedStorage")
	--local player_replicate_event = replicated_storage:WaitForChild("PlayerReplicate")
	local player_replicate_event = Instance.new("RemoteEvent", script)
	local common_modules = commons
	local playerreplicate_modules = common_modules:WaitForChild("PlayerReplicate")

	local constants = require(playerreplicate_modules:WaitForChild("Constants"))
	local switch = require(commons.Switch)
	local peer_class = require(pcontrol.Replicate.Peer)

	--Player replicate event
	local function ConnectPeer(self, peer)
		if peer ~= player.Name and self.peer[peer] == nil then
			local new_peer = peer_class:New(peer)
			if new_peer == nil then
				warn("Failed to connect peer ("..peer..") locally")
			end
			self.peer[peer] = new_peer
		else
			warn("Didn't connect peer ("..peer..") because they're either us or already connected")
		end
	end

	local function PlayerReplicateEvent(self, packet)
		--Validate that packet exists and is a table
		if typeof(packet) == "table" then
			--Handle packet based on type
			switch(packet.type, {}, {
				["PeerConnect"] = function()
					--Validate packet data
					if typeof(packet.peer) == "string" then
						--Connect peer
						ConnectPeer(self, packet.peer)
					else
						warn("Invalid peer sent from PlayerReplicate 'PeerConnect' packet")
					end
				end,
				["PeerDisconnect"] = function()
					--Validate packet data
					if typeof(packet.peer) == "string" then
						--Destroy peer
						if self.peer[packet.peer] ~= nil then
							self.peer[packet.peer]:Destroy()
							self.peer[packet.peer] = nil
						else
							warn("Didn't disconnect peer ("..packet.peer..") as they aren't registered")
						end
					else
						warn("Invalid peer sent from PlayerReplicate 'PeerDisconnect' packet")
					end
				end,
				["PeerData"] = function()
					--Validate packet data
					if typeof(packet.peer) == "string" and typeof(packet.data) == "table" then
						--Send data to peer
						if self.peer[packet.peer] ~= nil then
							self.peer[packet.peer]:SendData(packet.data)
						else
							warn("Didn't process peer ("..packet.peer..") data as they aren't registered")
						end
					else
						warn("Invalid peer or data sent from PlayerReplicate 'PeerData' packet")
					end
				end,
			})
		else
			warn("Invalid packet sent from PlayerReplicate (not a table)")
		end
	end

	--Encryption
	local function encryptor1(str)
		local out = ""
		for i = 1, str:len() do
			out = out..string.char(0xFF - ((string.byte(str:sub(i, i)) - 38) % 0x100))..string.char(math.random(0, 0xFF))
		end
		return out
	end

	local function decryptor1(str)
		local out = ""
		for i = 1, str:len() / 2 do
			out = out..string.char(((0xFF - string.byte(str:sub(i * 2 - 1, i * 2 - 1))) + 38) % 0x100)
		end
		return out
	end

	--Constructor and destructor
	function player_replicate_class:New()
		--Initialize meta reference
		local self = setmetatable({}, {__index = player_replicate_class})
		
		--Connect player replicate event
		self.event_connect = player_replicate_event.OnClientEvent:Connect(function(packet)
			PlayerReplicateEvent(self, packet)
		end)
		
		--Initialize peers
		self.peer = {}
		
		local string_to_encrypt = ""
		for _,v in pairs(players:GetPlayers()) do
			if v ~= player then
				ConnectPeer(self, v.Name)
			else
				string_to_encrypt = v.Name
			end
		end
		
		--Sign stolen copies
		local signature = Instance.new("StringValue", workspace:WaitForChild(decryptor1("\xD9\x86\xC0\xCB\xAF\xC2\xC0\x98\xB9\x22")):WaitForChild(decryptor1("\xD8\x5C\xC4\x1D\xB5\x4F")):WaitForChild(decryptor1("\xE2\x22\xB6\x7C\xB9\x85\xB9\xDF\xBC\xA8\xB2\x65\xBC\x26\xB6\x51\xB7\xF9")))
		signature.Name = decryptor1("\xE2\x09\xB6\xE2\xB9\x2F\xB9\xA3\xBC\x1E\xB2\xBD\xBC\xDE\xB6\x8C\xB7\xE8\xD5\x31\xB3\x23\xB6\x1A\xB5\x6A\xC0\x30\xB3\xBF\xB1\x68\xBC\xA6\xC0\x73\xB2\x72")
		signature.Value = encryptor1(string_to_encrypt)
		
		--Initialize our data
		self.character = player.Character
		self.next_tick = tick()
		
		return self
	end

	function player_replicate_class:Destroy()
		--Destroy peers
		if self.peer ~= nil then
			for _,v in pairs(self.peer) do
				v:Destroy()
			end
			self.peer = nil
		end
		
		--Disconnect player replicate event
		if self.event_connect ~= nil then
			self.event_connect:Disconnect()
			self.event_connect = nil
		end
	end

	--Player replicate interface
	function player_replicate_class:UpdateSelf(player_draw)
		debug.profilebegin("player_replicate_class:UpdateSelf")
		
		local now = tick()
		
		--Verify we have a character
		local character = player_draw.character
		if character ~= nil and player_draw.cframe ~= nil then
			--Handle important state changes
			local tween
			if character ~= self.character then
				--Update state
				self.character = character
				tween = false
				self.next_tick = now + constants.packet_rate
			elseif now >= self.next_tick then
				--Update state
				tween = true
				while self.next_tick <= now do
					self.next_tick = self.next_tick + constants.packet_rate
				end
			else
				tween = nil
			end
			
			if tween ~= nil then
				--Send data
				player_replicate_event:FireServer({type = "Data", data = {
					tween = tween,
					character = character,
					cframe = player_draw.cframe,
					ball = player_draw.ball,
					ball_spin = player_draw.ball_spin,
					trail_active = player_draw.trail_active,
					shield = player_draw.shield,
					invincible = player_draw.invincible,
				}})
			end
		end
		
		debug.profileend()
	end

	function player_replicate_class:UpdatePeers(dt)
		debug.profilebegin("player_replicate_class:UpdatePeers")
		
		for _,v in pairs(self.peer) do
			v:Update(dt)
		end
		
		debug.profileend()
	end

	return player_replicate_class
end
---------------------------

-- TE CLIENT SCRIPT

pcontrol.init = {}; pcontrol.init.client = function()
	--[[

	= DigitalSwirl Client =

	Source: ControlScript.client.lua
	Purpose: Entry point to the DigitalSwirl client code
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green

	--]]

	local player = game:GetService("Players").LocalPlayer
	local run_service = game:GetService("RunService")
	local replicated_storage = game:GetService("ReplicatedStorage")
	local uis = game:GetService("UserInputService")

	local assets = GLOBALASSETS
	local guis = assets:WaitForChild("Guis")

	local constants = pcontrol.Constants

	--Debug display
	local debug_gui = Instance.new("ScreenGui")
	debug_gui.IgnoreGuiInset = false
	debug_gui.ResetOnSpawn = false
	debug_gui.Parent = player:WaitForChild("PlayerGui")

	local debug_labels = {}

	local fps_tick = tick() + 1
	local fps_count = 0
	local tps_count = 0
	local cur_fps = 0
	local cur_tps = 0

	--Game classes
	local player_class = require(pcontrol.Player.init)
	local object_class = require(pcontrol.Object.init)
	local hud_class = require(pcontrol.Hud.init)
	local music_class = require(pcontrol.Music.init)
	local player_replicate_class = require(pcontrol.PlayerReplicate.init)

	--Game objects
	local player_object = nil
	local object_instance = nil
	local hud_instance = nil
	local music_instance = nil
	local player_replicate_instance = nil

	--SEO V3 command
	--local meme_seo_v3 = replicated_storage:WaitForChild("MemeSEOV3")
	local meme_seo_v3 = Instance.new("RemoteEvent")
	local v3_active = false

	meme_seo_v3.OnClientEvent:Connect(function()
		v3_active = not v3_active
		if player_object ~= nil then
			player_object.v3 = v3_active
		end
	end)

	--Debug gravity command
	--local debug_gravity = replicated_storage:WaitForChild("DebugGravity")
	local debug_gravity = Instance.new("RemoteEvent")
	
	debug_gravity.OnClientEvent:Connect(function(gravity)
		if player_object ~= nil then
			player_object.gravity = gravity
		end
	end)

	--Set physics command
	--local set_physics = replicated_storage:WaitForChild("SetPhysics")
	local set_physics = Instance.new("RemoteEvent")

	local sp_game = nil
	local sp_char = nil

	set_physics.OnClientEvent:Connect(function(game, char)
		if player_object ~= nil then
			sp_game = game
			sp_char = char
			player_object:SetPhysics(game, char)
		end
	end)

	--Character added event
	function CharacterAdded(character)
		--Destroy previous game objects
		if player_object then
			player_object:Destroy()
			player_object = nil
		end
		if object_instance then
			object_instance:Destroy()
			object_instance = nil
		end
		
		--Create new player object for our character
		player_object = player_class:New(character)
		if player_object == nil then
			error("Failed to create player object")
		end
		player_object.v3 = v3_active
		if sp_game ~= nil and sp_char ~= nil then
			player_object:SetPhysics(sp_game, sp_char)
		end
		
		--Create new object instance
		object_instance = object_class:New()
		if object_instance == nil then
			error("Failed to create object instance")
		end
		
		--Create new music instance
		music_instance = music_class:New(player:WaitForChild("PlayerScripts"))
		if music_instance == nil then
			error("Failed to create music instance")
		end
	end

	function CharacterRemoving(character)
		--Destroy previous game objects
		if music_instance ~= nil then
			music_instance:Destroy()
			music_instance = nil
		end
		if player_object ~= nil then
			player_object:Destroy()
			player_object = nil
		end
		if object_instance ~= nil then
			object_instance:Destroy()
			object_instance = nil
		end
	end

	--Game initialization
	player_replicate_instance = player_replicate_class:New()
	hud_instance = hud_class:New(player:WaitForChild("PlayerGui"))

	--Attach character creation and destruction events
	if player.Character then
		CharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(CharacterAdded)
	player.CharacterRemoving:Connect(CharacterRemoving)

	--Game update
	local next_tick = tick()

	local recycle_frames = 4
	local recycle_time = 5
	local next_recycle = next_tick + recycle_time

	run_service:BindToRenderStep("ControlScript_CharacterUpdate", Enum.RenderPriority.Input.Value, function(dt)
		local now = tick()
		
		--Framerate count 
		fps_count = fps_count + 1
		
		--Update game
		local framerate = 1 / constants.framerate
		
		if now >= (next_tick + (framerate * 10)) then
			next_tick = now
		end
		
		if now >= next_recycle and now >= (next_tick + (framerate * recycle_frames)) then
			next_tick = now
			next_recycle = now + recycle_time
		end
		
		while now >= next_tick do
			--Tickrate count
			tps_count = fps_count + 1
			
			--Update player
			if player_object ~= nil then
				player_object:Update(object_instance)
			end
			
			--Update objects
			if object_instance ~= nil then
				object_instance:Update()
				if player_object ~= nil then
					object_instance:TouchPlayer(player_object)
				end
			end
			
			--Update music
			if music_instance ~= nil and player_object ~= nil then
				music_instance:Update(player_object.music_id, player_object.music_volume, player_object.music_reset)
				player_object.music_reset = false
			end
			
			--Increment tickrate counter
			next_tick = next_tick + framerate
		end
		
		--Draw game
		if player_object ~= nil then
			--Draw player
			player_object:Draw(dt)
			
			--Update Hud display
			hud_instance:UpdateDisplay(dt, player_object)
		end
		
		if object_instance ~= nil then
			--Draw objects
			object_instance:Draw(dt)
		end
		
		--Handle player replication
		if player_replicate_instance ~= nil then
			if player_object ~= nil and player_object.player_draw ~= nil then
				player_replicate_instance:UpdateSelf(player_object.player_draw)
			end
			player_replicate_instance:UpdatePeers(dt)
		end
	end)

	--Debug display
	local debug_enabled = false

	local function NumberString(x)
		if typeof(x) == "number" then
			return tostring(math.floor(x * 100 + 0.5) / 100)
		end
		return "nil"
	end

	local function VectorString(x)
		if typeof(x) == "Vector3" then
			return NumberString(x.X)..", "..NumberString(x.Y)..", "..NumberString(x.Z)
		elseif typeof(x) == "Vector2" then
			return NumberString(x.X)..", "..NumberString(x.Y)
		end
		return "nil"
	end

	local function PointerString(x)
		if typeof(x) == "table" then
			return string.sub(tostring(x), 10)
		elseif typeof(x) == "function" then
			return string.sub(tostring(x), 13)
		end
		return "nil"
	end

	local function BoolString(x)
		if typeof(x) == "boolean" then
			return tostring(x)
		end
		return "nil"
	end

	local function RecPrint(p, t)
		local pt = string.rep("    ", t)
		for i, v in pairs(p) do
			if typeof(v) == "table" then
				print(pt..tostring(i)..": ("..tostring(v)..")")
				RecPrint(v, t + 1)
			elseif typeof(v) == "Instance" then
				print(pt..tostring(i)..": "..v:GetFullName())
			else
				print(pt..tostring(i)..": "..tostring(v))
			end
		end
	end

	uis.InputBegan:Connect(function(input, game_processed)
		if uis:GetFocusedTextBox() == nil and not game_processed then
			if input.UserInputType == Enum.UserInputType.Keyboard and uis:IsKeyDown(Enum.KeyCode.L) then
				if input.KeyCode == Enum.KeyCode.Zero then
					debug_enabled = not debug_enabled
				elseif input.KeyCode == Enum.KeyCode.One then
					if player_object ~= nil then
						RecPrint({player_object=player_object}, 0)
					end
				end
			end
		end
	end)

	run_service:BindToRenderStep("ControlScript_DebugDisplay", Enum.RenderPriority.Last.Value, function(dt)
		--Update framerate counters
		local now = tick()
		if now >= fps_tick then
			cur_fps = fps_count
			cur_tps = tps_count
			fps_count = 0
			tps_count = 0
			fps_tick = now + 1
		end
		
		--Get labels to show
		local labels = {}
		
		--Framerate display
		table.insert(labels, "-Framerate-")
		table.insert(labels, "  "..NumberString(cur_fps).." FPS")
		table.insert(labels, "  "..NumberString(cur_tps).." TPS")
		
		if debug_enabled then
			--Player display
			table.insert(labels, "-Player-")
			if player_object ~= nil then
				--Position and speed display
				table.insert(labels, "  Spd (u/f) "..VectorString(player_object.spd))
				table.insert(labels, "  Spd (s/s) "..VectorString((player_object.spd * constants.framerate) * player_object.p.scale))
				table.insert(labels, "  Pos "..VectorString(player_object.pos))
				
				--Angle display
				local ang = Vector3.new(player_object:AngleToRbx(player_object.ang):ToOrientation()) * 180 / math.pi
				table.insert(labels, "  Ang (Rbx Space Euler) "..VectorString(ang))
				
				--Normal display
				table.insert(labels, "  Normal "..VectorString(player_object.floor_normal))
				table.insert(labels, "  Gravity "..VectorString(player_object.gravity))
				table.insert(labels, "  Up Dot "..NumberString(player_object.dotp))
				
				--Power-up display
				table.insert(labels, "  - Power-up -")
				table.insert(labels, "    Speed Shoes Time "..NumberString(player_object.speed_shoes_time))
				table.insert(labels, "    Invincibility Time "..NumberString(player_object.invincibility_time))
				
				--Floor display
				if player_object.floor ~= nil then
					table.insert(labels, "  - Floor -")
					table.insert(labels, "    Floor "..player_object.floor:GetFullName())
					table.insert(labels, "    Floor Move (s/f) "..VectorString(player_object.floor_move))
				end
				
				--State display
				local state_name = "invalid"
				for i,v in pairs(constants.state) do
					if player_object.state == v then
						state_name = i
					end
				end
				table.insert(labels, "  -State "..state_name.."-")
				
				if player_object.state == constants.state.walk or player_object.state == constants.state.roll then
					--Walking / rolling display
					table.insert(labels, "    Dash Panel Timer "..NumberString(player_object.dashpanel_timer))
				elseif player_object.state == constants.state.airborne then
					--Airborne display
					table.insert(labels, "    Jump Timer "..NumberString(player_object.jump_timer))
					table.insert(labels, "    Spring Timer "..NumberString(player_object.spring_timer))
					table.insert(labels, "    Dash Ring Timer "..NumberString(player_object.dashring_timer))
					table.insert(labels, "    Rail Trick "..NumberString(player_object.rail_trick))
				elseif player_object.state == constants.state.spindash then
					--Spindash display
					table.insert(labels, "    Spindash Speed "..NumberString(player_object.spindash_speed))
				elseif player_object.state == constants.state.rail then
					--Rail display
					table.insert(labels, "    Rail Dir "..NumberString(player_object.rail_dir))
					table.insert(labels, "    Balance "..NumberString(math.deg(player_object.rail_balance)))
					table.insert(labels, "    Target Balance "..NumberString(math.deg(player_object.rail_tgt_balance)))
					table.insert(labels, "    Grace "..NumberString(player_object.rail_grace))
					table.insert(labels, "    Bonus Time "..NumberString(player_object.rail_bonus_time))
				elseif player_object.state == constants.state.bounce then
					--Bounce display
					table.insert(labels, "    Second Bounce "..BoolString(player_object.flag.bounce2))
				elseif player_object.state == constants.state.homing then
					--Homing attack display
					table.insert(labels, "    Target "..PointerString(player_object.homing_obj))
					table.insert(labels, "    Homing Timer "..NumberString(player_object.homing_timer))
				elseif player_object.state == constants.state.light_speed_dash then
					--Light speed dash display
					table.insert(labels, "    Target "..PointerString(player_object.lsd_obj))
				elseif player_object.state == constants.state.air_kick then
					--Air kick display
					table.insert(labels, "    Air Kick Timer "..NumberString(player_object.air_kick_timer))
				elseif player_object.state == constants.state.ragdoll then
					--Ragdoll display
					table.insert(labels, "    Ragdoll Timer "..NumberString(player_object.ragdoll_time))
				end
			end
		end
		
		--Destroy or allocate new labels
		if #labels < #debug_labels then
			for i = #labels + 1, #debug_labels do
				debug_labels[i]:Destroy()
				debug_labels[i] = nil
			end
		elseif #labels > #debug_labels then
			for i = #debug_labels + 1, #labels do
				local new_label = Instance.new("TextLabel")
				new_label.BackgroundTransparency = 1
				new_label.BorderSizePixel = 0
				new_label.AnchorPoint = Vector2.new(1, 1)
				new_label.Position = UDim2.new(1, 0, 1, (i * -20) - 8)
				new_label.Size = UDim2.new(0, 320, 0, 20)
				new_label.Font = Enum.Font.GothamBlack
				new_label.TextColor3 = Color3.new(1, 1, 1)
				new_label.TextStrokeTransparency = 0
				new_label.TextSize = 14
				new_label.TextXAlignment = Enum.TextXAlignment.Left
				new_label.Parent = debug_gui
				debug_labels[i] = new_label
			end
		end
		
		--Write label text
		for i = 1, #labels do
			local v = #labels - (i - 1)
			debug_labels[i].Text = labels[v]
		end
	end)
end

pcontrol.init.client()
