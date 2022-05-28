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

local assets = {}
assets.Guis = {}
assets.HudGui = Utils:Create({"Screen"})

pcontrol.Hud.init = function()
	--[[
	= Sonic Onset Adventure Client =
	Source: ControlScript/Hud.lua
	Purpose: Heads Up Display
	Author(s): Regan "CuckyDev/TheGreenDeveloper" Green
	--]]

	local hud_class = {}

	local assets = assets
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
