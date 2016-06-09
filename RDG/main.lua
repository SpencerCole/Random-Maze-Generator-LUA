function validate(data, array)
 local valid = {}
 for i = 1, #array do
  valid[array[i]] = true
 end
 if valid[data] then
  return true
 else
  return false
 end
end

local clock = os.clock
function sleep(n)
	local t0 = clock()
	while clock() - t0 <= n do end
end

-- Set Random Seed
math.randomseed(os.time())
-- Add More Randomness
math.random(); math.random(); math.random()

local RDG = {}
RDG.__index = RDG

function RDG:new(o)
	o = o or {}
	obj = o
	setmetatable(obj, self)
	obj.width = o.width or 10
	obj.height = o.height or 10
	obj.speed = o.speed or 0.1
	obj.show_steps = o.show_steps or false
	obj.raw = o.raw or false
	obj.mapping = {
		["oo"] = "  ",
		["lo"] = "| ",
		["ol"] = "``",
		["ll"] = "|`",
		["#"]  = " #",
		["@"]  = " @",
	}
	obj.previous_cells = {}
	obj.visited_cells = {}
	obj.current_cell = "1|1"
	obj.visited_cells[#obj.visited_cells+1] = obj.current_cell
	obj.previous_cells[#obj.previous_cells+1] = obj.current_cell
	obj.try_to_make_exit = false
	obj.has_exit = false
	self.__index = self
	--obj:generate()
	return obj
end


function RDG:generate()
	self.maze = {}
	-- Initial Maze Setup
	for i=1, self.height + 1, 1 do
		maze_row = {}
		for e=1, self.width + 1, 1 do
			if e <= self.width then
				-- Add Initial Cell '|`'
				cell = "ll"
			else
				-- Add Ending Columns Edges '| '
				cell = "lo"
			end
			if i > self.height then
				if e > self.width then
					-- Clearing Bottom Right Corner '  '
					cell = "oo"
				else
					-- Add Column Bottoms '``'
					cell = "ol"
				end
			end
			maze_row[#maze_row+1] = cell
		end
		self.maze[#self.maze+1] = maze_row
	end

	-- Make Maze Entrance
	-- TODO(spencercole) Randomize Entrance
	self.maze[1][1] = "lo"

	-- Fill in the maze
	while #self.previous_cells > 0 do
		neighbor = self:chooseNeighbor()
		if neighbor ~= nil then
			if not validate(self.current_cell, self.previous_cells) then
				self.previous_cells[#self.previous_cells+1] = self.current_cell
			end
			self.current_cell = neighbor
			if not validate(self.current_cell, self.visited_cells) then
				self.visited_cells[#self.visited_cells+1] = self.current_cell
			end
		else
			self.current_cell = table.remove(self.previous_cells)
		end
		if #self.visited_cells >= (self.width * self.height)/ 2 and not self.try_to_make_exit then
			self.try_to_make_exit = true
			self.has_exit = false
		end
		if not self.has_exit and self.try_to_make_exit then
			self:makeExit()
		end
		if self.show_steps then
			self:print()
			sleep(self.speed)
		end
	end
end

function RDG:stepGenerate()
	if not self.maze then
		self.maze = {}
		-- Initial Maze Setup
		for i=1, self.height + 1, 1 do
			maze_row = {}
			for e=1, self.width + 1, 1 do
				if e <= self.width then
					-- Add Initial Cell '|`'
					cell = "ll"
				else
					-- Add Ending Columns Edges '| '
					cell = "lo"
				end
				if i > self.height then
					if e > self.width then
						-- Clearing Bottom Right Corner '  '
						cell = "oo"
					else
						-- Add Column Bottoms '``'
						cell = "ol"
					end
				end
				maze_row[#maze_row+1] = cell
			end
			self.maze[#self.maze+1] = maze_row
		end

		-- Make Maze Entrance
		-- TODO(spencercole) Randomize Entrance
		self.maze[1][1] = "lo"
	end


	-- Fill in the maze
	if #self.previous_cells > 0 then
		neighbor = self:chooseNeighbor()
		if neighbor ~= nil then
			if not validate(self.current_cell, self.previous_cells) then
				self.previous_cells[#self.previous_cells+1] = self.current_cell
			end
			self.current_cell = neighbor
			if not validate(self.current_cell, self.visited_cells) then
				self.visited_cells[#self.visited_cells+1] = self.current_cell
			end
		else
			self.current_cell = table.remove(self.previous_cells)
		end
		if #self.visited_cells >= (self.width * self.height)/2 and not self.try_to_make_exit then
			self.try_to_make_exit = true
			self.has_exit = false
		end
		if not self.has_exit and self.try_to_make_exit then
			self:makeExit()
		end
	end
	return self.maze, self.current_cell, self.previous_cells
end


function RDG:getX()
	return tonumber(string.sub(self.current_cell, string.find(self.current_cell, '|') + 1))
end

function RDG:getY()
	return tonumber(string.sub(self.current_cell, 1, string.find(self.current_cell, '|') - 1))
end

function RDG:check(dir)
	return not validate(string.sub(dir, 1, string.find(dir, '+') - 1), self.visited_cells)
end


function RDG:chooseNeighbor()
	possible_cells = {}
	open_cell = nil

	x = self:getX()
	y = self:getY()

	up = (y - 1) .. "|" .. x .. "+up"
	dn = (y + 1) .. "|" .. x .. "+dn"
	lt = y .. "|" .. (x - 1) .. "+lt"
	rt = y .. "|" .. (x + 1) .. "+rt"

	if y - 1 > 0 then
		-- Up is available
		if self:check(up) then
			possible_cells[#possible_cells+1] = up
		end
	end
	if y < self.height then
		-- Down is available
		if self:check(dn) then
			possible_cells[#possible_cells+1] = dn
		end
	end
	if x - 1 > 0 then
		-- Left is available
		if self:check(lt) then
			possible_cells[#possible_cells+1] = lt
		end
	end
	if x < self.width then
		-- Right is available
		if self:check(rt) then
			possible_cells[#possible_cells+1] = rt
		end
	end

	if #possible_cells > 0 then
		choosen_cell = possible_cells[math.random(#possible_cells)]
		open_cell = string.sub(choosen_cell, 1, string.find(choosen_cell, '+') - 1)
		dir = string.sub(choosen_cell, string.find(choosen_cell, '+') + 1)
		self:removeWall(open_cell, dir)
	end

	return open_cell
end


function RDG:removeWall(cell, dir)
	y = tonumber(string.sub(cell, 1, string.find(cell, '|') - 1))
	x = tonumber(string.sub(cell, string.find(cell, '|') + 1))

	cur_y = self:getY()
	cur_x = self:getX()

	if dir == "up" then
		self.maze[cur_y][cur_x] = string.sub(self.maze[cur_y][cur_x], 1, 1) .. "o"
	end
	if dir == "dn" then
		self.maze[y][x] = string.sub(self.maze[y][x], 1, 1) .. "o"
	end
	if dir == "lt" then
		self.maze[cur_y][cur_x] = "o" .. string.sub(self.maze[cur_y][cur_x], 2, 2)
	end
	if dir == "rt" then
		self.maze[y][x] = "o" .. string.sub(self.maze[y][x], 2, 2)
	end
end


function RDG:makeExit()
	edge = nil

	cur_y = self:getY()
	cur_x = self:getX()

	if x - 1 == 0 then
		edge = "lt"
	elseif x + 1 == self.width + 1 then
		edge = "rt"
		cur_x = cur_x + 1
	elseif y + 1 == self.height + 1 then
		edge = "dn"
		cur_y = cur_y + 1
	end
	print(edge)
	if edge then
		self:removeWall(cur_y .. "|" .. cur_x, edge)
		self.has_exit = true
	end
end


function RDG:print()
	maze_display_str = ""
	for i=1, #self.maze, 1 do
		for e=1, #self.maze[i], 1 do
			on_cell = i .. "|" .. e
			if self.current_cell == on_cell and #self.previous_cells > 0 then
				maze_display_str = maze_display_str .. self.mapping['#']
			elseif validate(on_cell, self.previous_cells) then
				maze_display_str = maze_display_str .. self.mapping['@']
			else
				maze_display_str = maze_display_str .. self.mapping[self.maze[i][e]]
			end
		end
		maze_display_str = maze_display_str .. "\n"
	end
	io.write(maze_display_str)
end

--start_time = clock()
--randomGen = RDG:new()
--randomGen:print()
--end_time = clock()
--print(randomGen.width .. "X" .. randomGen.height,(end_time - start_time) .. "'s")

function love.load()
	-- Maze Object
	randomGen = RDG:new({["width"] = 20, ["height"] = 20})

	-- User window details
	local _, _, flags = love.window.getMode()
    width, height = love.window.getDesktopDimensions(flags.display)

    scale = 2

    -- Can we resize to fit the maze?
    if width >= randomGen.width * 10 * scale + (20 * scale) and height >=randomGen.height * 10 * scale + (20 * scale) then
		success = love.window.setMode(randomGen.width * 10 * scale + (20 * scale), randomGen.height * 10 * scale + (20 * scale))
	end
end

function love.draw()
	offset = 10 * scale
	if not done then
		maze, current_cell, previous_cells, done = randomGen:stepGenerate()
	end
	--draw left and top borders
	for i=1, #maze + 1, 1 do
		for e=1, #maze[1] + 1, 1 do
			if e == 1 or i == 1 then
				w = 12 * scale
				h = 12 * scale
				love.graphics.setColor(0, 100, 100)
				love.graphics.rectangle("fill", (e * 10 * scale) - w + offset - (10 * scale), (i * 10 * scale) - h + offset - (10 * scale), w, h)
			end
		end
	end

	-- draw maze
	for i=1, #maze, 1 do
		for e=1, #maze[i], 1 do
			on_cell = i .. "|" .. e
			cell = maze[i][e]
			if cell == "oo" then
				--x, y, w, h
				-- Draw 2 rectangles one tall one wide
				w = 12 * scale
				h = 9 * scale
				love.graphics.setColor(0, 100, 100)
				love.graphics.rectangle("fill", (e * 10 * scale) - w + offset, (i * 10 * scale) - h + offset, w, h)
				w = 9 * scale
				h = 12 * scale
			elseif cell == "lo" then
				w = 9 * scale
				h = 12 * scale
			elseif cell == "ol" then
				w = 12 * scale
				h = 9 * scale
			elseif cell == "ll" then
				w = 9 * scale
				h = 9 * scale
			end
			love.graphics.rectangle("fill", (e * 10 * scale) - w + offset, (i * 10 * scale) - h + offset, w, h)
		end
	end

	-- draw steps
	for i=1, #maze, 1 do
		for e=1, #maze[i], 1 do
			on_cell = i .. "|" .. e
			cell = maze[i][e]
			w = 5 * scale
			h = 5 * scale
			-- Draw current cell as Red
			if on_cell == current_cell and #previous_cells > 0 then
				love.graphics.setColor(255, 0, 0)
				love.graphics.rectangle("fill", (e * 10 * scale) - (w + w/2)  + offset, (i * 10 * scale) - (h + h/2) + offset, w, h)
			-- Draw previous cells as orange
			elseif validate(on_cell, previous_cells) then
				love.graphics.setColor(100, 100, 0)
				love.graphics.rectangle("fill", (e * 10 * scale) - (w + w/2)  + offset, (i * 10 * scale) - (h + h/2) + offset, w, h)
			end
		end
	end
end
