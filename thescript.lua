
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
			sq_dist += (box.min.X - v) * (box.min.X - v)
		end
		if v > box.max.X then
			sq_dist += (v - box.max.X) * (v - box.max.X)
		end
		
		--Y axis check
		local v = point.Y
		if v < box.min.Y then
			sq_dist += (box.min.Y - v) * (box.min.Y - v)
		end
		if v > box.max.Y then
			sq_dist += (v - box.max.Y) * (v - box.max.Y)
		end
		
		--Z axis check
		local v = point.Z
		if v < box.min.Z then
			sq_dist += (box.min.Z - v) * (box.min.Z - v)
		end
		if v > box.max.Z then
			sq_dist += (v - box.max.Z) * (v - box.max.Z)
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
			cur_ref_reg[key].count += 1
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
			cur_ref_reg[key].count -= 1
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
		size /= 2
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
