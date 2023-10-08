
local NODE_POSX = 1
local NODE_POSY = 2
local NODE_NEXT = 3
local NODE_PRNT = 4
local NODE_DATA = 5


local floor = math.floor


HashGrid = {}
HashGrid.__index = HashGrid


function createHashGridNode(x, y, data)
	return {x, y, false, false, data}
end	



function HashGrid:new(cell_size, max_radius)
	   
	cell_size = math.max(tonumber(cell_size) or 0, 0.1) 
	max_radius = math.min(tonumber(max_radius) or 0, cell_size)

	local self =
	{
		cell_size = cell_size,
		max_radius = max_radius,
		buckets = {}
	}
	setmetatable(self, HashGrid)
	return self
end


function HashGrid:add(node)

	if node[NODE_PRNT] then
		return
	end	

	local cell_size = self.cell_size
	local buckets = self.buckets

	local ix = floor(node[NODE_POSX] / cell_size)
	local iy = floor(node[NODE_POSY] / cell_size)
	
	local hashed = ix * 0x8da6b343 + iy * 0xd8163841
	local current = buckets[hashed]

	if not current then
		buckets[hashed] = node
	else     
		node[NODE_NEXT] = current
		buckets[hashed] = node
	end    

	node[NODE_PRNT] = self
end    


function HashGrid:remove(node)

	if node[NODE_PRNT] ~= self then
		return
	end	

	local cell_size = self.cell_size
	local buckets = self.buckets

	local node_x = node[NODE_POSX]
	local node_y = node[NODE_POSY]

	local ix = floor(node_x / cell_size)
	local iy = floor(node_y / cell_size)

	local hashed = ix * 0x8da6b343 + iy * 0xd8163841
	local current = buckets[hashed]
	local prev = nil

	while current do
		if current == node then
			if prev then
				prev[NODE_NEXT] = current[NODE_NEXT]
			else
				buckets[hashed] = current[NODE_NEXT]
			end
			
			break
		end	
		
		prev = current
		current = current[NODE_NEXT]
	end	
	
	node[NODE_NEXT] = false
	node[NODE_PRNT] = nil
end


function HashGrid:query(x, y, radius)

	local cell_size = self.cell_size
	local buckets = self.buckets
	local results = {}
	local count = 0

	local ax = floor( (x - cell_size) / cell_size)
	local ay = floor( (y - cell_size) / cell_size)
	local bx = floor( (x + cell_size) / cell_size)
	local by = floor( (y + cell_size) / cell_size)
	
	local radius = radius + self.max_radius
	local minx = x - radius
	local miny = y - radius
	local maxx = x + radius
	local maxy = y + radius


	for i = ax, bx do	
		for j = ay, by do
			local hashed = i * 0x8da6b343 + j * 0xd8163841
			local current = buckets[hashed]

			while current do

				local nx = current[NODE_POSX]
				local ny = current[NODE_POSY]

				if not (nx < minx or nx > maxx or ny < miny or ny > maxy) then
					count = count + 1	
					results[count] = current
				end	

				current = current[NODE_NEXT]
			end	
		end
	end	

	return results
end 


function getHashGridNodeData(node)
	return node[NODE_DATA]
end	

	


local hg = HashGrid:new(5, 2)
local finished = false

for i = -10, 10 do
	for j = -10, 10 do
		local ob = createObject(1946, i, j, 3.5)
		local node = createHashGridNode(i, j, ob)
		hg:add(node)

		if i == 10 and j == 10 then
			finished = true
		end	
	end	
end	


setTimer(
	function ()

		if not finished then
			return
		end	

		local player = localPlayer --getPlayerFromName("Injury")
		if not player then return end

		local x, y, z = getElementPosition(player)

		local a = getTickCount()
		local results = hg:query(x, y, 2.5)
		local b = getTickCount()
		
		outputChatBox(string.format("Result Count: %d  ms: %f", #results, (b - a)))

		a = os.clock()

		for i = 1, #results do

			local res = results[i]
			if not isElement(res[5]) and not finished then
				outputChatBox("Res is not element")
			end	

			destroyElement(res[5])
			hg:remove(results[i])
		end	
		b = os.clock()
		--outputChatBox(string.format("Ms remove results: %.5f", (b - a) * 1000))

	end,
	1500, 0
)





