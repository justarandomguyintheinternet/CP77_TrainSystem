local track = require("modules/classes/track")
local utils = require("modules/utils/utils")
local actOneData = {
	[7] = "next",
	[11] = "next",
	[4] = "last_second",
	[5] = "next"
} -- Hardcoded info on what tracks to disable for Act 1

trackSys = {}

function trackSys:new(ts)
	local o = {}

	o.ts = ts
	o.tracks = {}

	o.paths = {} -- Raw paths made of tracks, not useable
	o.pathsData = {} -- Tables with all points and meta info (See unpackPath function)
	o.arrivePath = {next = {}, last = {}} -- Arrive Path for both directions (If available)
	o.combinedData = {} -- Holds pairs of paths with arrivePaths

	self.__index = self
   	return setmetatable(o, self)
end

function trackSys:load()
	for _, file in pairs(dir("data/tracks")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local t = track:new()
            t:load("data/tracks/" .. file.name)
            self.tracks[t.id] = t
        end
    end

	self:handleActOne()
end

function trackSys:handleActOne() -- Remove certain tracks connections to limit the metro to the Act 1 area
	if not (Game.GetQuestsSystem():GetFact("q005_jackie_to_hospital") == 0 and Game.GetQuestsSystem():GetFact("q005_jackie_to_mama") == 0 and Game.GetQuestsSystem():GetFact("q005_jackie_stay_notell") == 0) then return end

	for id, t in pairs(self.tracks) do
		if actOneData[id] ~= nil then
			if actOneData[id] == "next" then
				t.connectedID.first.next = -1
				t.connectedID.second.next = -1
			elseif actOneData[id] == "last_second" then
				t.connectedID.second.last = -1
			end
		end
	end
end

function trackSys:getStationTrack(station) -- Get the track where this station sits on
	for _, t in pairs(self.tracks) do
		if t.hasStation.next == station.id then
			return t
		elseif t.hasStation.last == station.id then
			return t
		end
	end
end

function trackSys:generatePaths(track, station) -- Main function to fill the self.paths table with tables of all possible tracks to a new station
	self.paths = {}
	local path = {} -- Store the current path in here

	if (track.hasStation.last ~= -1 and track.hasStation.last ~= station.id) then -- Handle if there is another station on origin track
		table.insert(self.paths, {track}) -- Path of only the origin track
		table.insert(path, track)
		if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track, path) end -- Call recursive for both possible connected tracks, clear tmp field after each call has finished aka has found an end / station
		path = {}
		table.insert(path, track)
		if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track, path) end
	elseif (track.hasStation.next ~= station.id and track.hasStation.next ~= -1) then -- Same but for other direction
		table.insert(self.paths, {track})
		table.insert(path, track)
		if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track, path) end
		path = {}
		table.insert(path, track)
		if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track, path) end
	else -- Same but there is no other station on the same track, wont insert the single origin track as possible path
		path = {}
		table.insert(path, track)
		if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track, path) end
		path = {}
		table.insert(path, track)
		if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track, path) end

		path = {}
		table.insert(path, track)
		if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track, path) end
		path = {}
		table.insert(path, track)
		if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track, path) end
	end
end

function trackSys:DFS(track, previous, path) -- Recursive calling search function
	--print("DFS:", track.id, track.hasStation.next, track.hasStation.last)
	if previous.id == track.connectedID.first.next or previous.id == track.connectedID.second.next then -- If track is "backwards", "tip" of arrow is connected to previous, means the next track is at the beginning of this track
		table.insert(path, track) -- Add track to path
		--print("track id now: " .. track.id .. " is next of " .. previous.id)
		if track.hasStation.next ~= -1 then -- If station is found then break the recursive function
			--print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last .. "length of path: " .. #path)
			self:insertPath(path)
		elseif track.hasStation.last ~= -1 then
			--print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next .. "length of path: " .. #path)
			self:insertPath(path)
		else
			if track.connectedID.first.last ~= -1 then -- Call recursive func for all possible "last" ones
				self:DFS(self.tracks[track.connectedID.first.last], track, path)
			end
			if track.connectedID.second.last ~= -1 then
				self:DFS(self.tracks[track.connectedID.second.last], track, path)
			end
		end
		utils.removeItem(path, track) -- Remove from path to, important if called from the two calls above, to make sure the second call has a "past" path table without the path section from the call above
	end

	if previous.id == track.connectedID.first.last or previous.id == track.connectedID.second.last then -- Same but this track is in the "right" direction
		table.insert(path, track)
		--print("track id now: " .. track.id .. " is next of " .. previous.id)
		if track.hasStation.last ~= -1 then
			--print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last .. "length of path: " .. #path)
			self:insertPath(path)
		elseif track.hasStation.next ~= -1 then
			--print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next .. "length of path: " .. #path)
			self:insertPath(path)
		else
			if track.connectedID.first.next ~= -1 then
				self:DFS(self.tracks[track.connectedID.first.next], track, path)
			end
			if track.connectedID.second.next ~= -1 then
				self:DFS(self.tracks[track.connectedID.second.next], track, path)
			end
		end
		utils.removeItem(path, track)
	end
end

function trackSys:calcDirs(path, station) -- Add a dir variable to all tracks in that path
	for key, track in pairs(path) do
		if key == 1 and #path == 1 then -- Only one track, aka Station on other end of station
			if station.id == track.hasStation.next then
				track.dir = "last"
			elseif station.id == track.hasStation.last then
				track.dir = "next"
			end
		else
			if key ~= #path then
				if path[key + 1].id == track.connectedID.first.next or path[key + 1].id == track.connectedID.second.next then -- If the next path is connected to the "next" end then this is in the "right" direction
					track.dir = "next"
				end
				if path[key + 1].id == track.connectedID.first.last or path[key + 1].id == track.connectedID.second.last then
					track.dir = "last"
				end
			else -- If last track use previous track to figure out dir
				if path[key - 1].id == track.connectedID.first.next or path[key - 1].id == track.connectedID.second.next then
					track.dir = "last"
				end
				if path[key - 1].id == track.connectedID.first.last or path[key - 1].id == track.connectedID.second.last then
					track.dir = "next"
				end
			end
		end
	end
end

function trackSys:setTrackDir(track) -- Changes a tracks points load/unload data to be according to its tracks dir
	for _, point in pairs(track.points) do
		if track.dir == "last" then
			point.dir = "last"
			--print(point, "is now" , point.dir)
		end
		if track.dir == "next" then
			point.dir = "next"
			--print(point, "is now" , point.dir)
		end
	end
end

function trackSys:unpackPath(path, station) -- Take a path and generate a table with its total direction, target stationID and a table of all points to the targetID in the right order
	local data = {dir = path[1].dir, targetID = station.id, points = {}}
	-- for _, track in pairs(path) do
	-- 	print(track.dir)
	-- end

	if #path == 1 then -- Only one track aka station on that track
		if path[1].dir == "next" then
			data.targetID = path[1].hasStation.next
			self:setTrackDir(path[1])
			for _, p in pairs(path[1].points) do
				table.insert(data.points, p)
			end
		else
			data.targetID = path[1].hasStation.last
			self:setTrackDir(path[1])
			for i = #path[1].points, 1, -1 do
				table.insert(data.points, utils.reversePoint(path[1].points[i]))
			end
		end
	else
		for key, track in pairs(path) do
			if key == #path then
				if track.dir == "next" then -- If its the last track figure out the target stationID
					if track.hasStation.last ~= -1 then
						data.targetID = track.hasStation.last
					else
						data.targetID = track.hasStation.next
					end
				else
					if track.hasStation.next ~= -1 then
						data.targetID = track.hasStation.next
					else
						data.targetID = track.hasStation.last
					end
				end

				if not (track.dir == "next" and track.hasStation.last ~= -1) and not (track.dir == "last" and track.hasStation.next ~= -1) then -- Only add points if the station is not on the first point / at the "beginning" of the track
					if track.dir == "next" then
						self:setTrackDir(track)
						for _, p in pairs(track.points) do
							table.insert(data.points, p)
						end
					else
						self:setTrackDir(track)
						for i = #track.points, 1, -1 do
							table.insert(data.points, utils.reversePoint(track.points[i]))
						end
					end
				else
					if track.dir == "next" then -- Always add the one point the station is on tho, depending on direction last or first point
						table.insert(data.points, track.points[1])
					else
						table.insert(data.points, utils.reversePoint(track.points[#track.points]))
					end
				end
			elseif not (track.dir == "next" and track.hasStation.next ~= -1) and not (track.dir == "last" and track.hasStation.last ~= -1) then -- If its an "in between" track, if statement makes sure only points from the start track (with station on it) only get added if the path moves in the other direction from where the station is (If station is on next then only add the points if direction is last, not next)
				if track.dir == "next" then
					self:setTrackDir(track)
					for _, p in pairs(track.points) do
						table.insert(data.points, p)
					end
				else
					self:setTrackDir(track)
					for i = #track.points, 1, -1 do
						table.insert(data.points, utils.reversePoint(track.points[i]))
					end
				end
			elseif key == 1 then
				if (track.dir == "next" and track.hasStation.next ~= -1) then
					local point = track.points[#track.points]
					table.insert(data.points, point)
				elseif (track.dir == "last" and track.hasStation.last ~= -1) then
					table.insert(data.points, utils.reversePoint(track.points[1]))
					--print('WOULD ADD SINGLE STATION TRACK POINT LAST')
				end
			end
		end
	end

	-- print("Generated data to station " .. data.targetID .. " Direction is " .. data.dir .. " with num points: " .. #data.points)
	-- for _, p in pairs(data.points) do
	-- 	print(p.pos, GetSingleton('Quaternion'):ToEulerAngles(p.rot))
	-- end

	return data
end

function trackSys:getPathsDataDir() --Check if all paths from self.pathsData go in the same direction
	local nexts = 0
	local lasts = 0
	for _, p in pairs(self.pathsData) do
		if p.dir == "next" then
			nexts = nexts + 1
		else
			lasts = lasts + 1
		end
	end
	--print("lasts and nexts for arrive: ", lasts, nexts)
	if nexts == 0 or lasts == 0 then
		return false
	else
		return true
	end
end

function trackSys:generateArrivePaths(station) -- Uses the pathsData to create an arrival path from both directions, using the points load/unload triggers
	local nexts = {}
	local lasts = {}
	local shouldReversePoints = self:getPathsDataDir()

	for _, path in pairs(self.pathsData) do
		for key, point in pairs(path.points) do
			--print(key, point.dir, point.loadStation.next)
			if point.dir == "next" and point.loadStation.last then
				--print("found next at pos", point.pos)
				local gen = {}
				for i = key, 1, -1 do
					local point = path.points[i]
					if shouldReversePoints then
						point = utils.reversePoint(path.points[i])
					end
					table.insert(gen, point)
					--print(i)
				end
				if path.dir == "next" then
					table.insert(nexts, gen)
				else
					table.insert(lasts, gen)
				end
				--print(#gen)
			elseif point.dir == "last" and point.loadStation.next then
				--print("found last at pos", point.pos)
				local gen = {}
				for i = key, 1, -1 do
					local point = path.points[i]
					if shouldReversePoints then
						point = utils.reversePoint(path.points[i])
					end
					table.insert(gen, point)
					--print(i)
				end
				if path.dir == "next" then
					table.insert(nexts, gen)
				else
					table.insert(lasts, gen)
				end
				--print(#gen)
			end
		end
	end

	if #nexts ~= -1 then
		local longest = 0
		local optimalNext = nil
		for _, path in pairs(nexts) do
			if utils.distanceVector(path[1].pos, station.trainExit.pos) > longest then
				longest = utils.distanceVector(path[1].pos, station.trainExit.pos)
				optimalNext = path
			end
		end
		self.arrivePath.next = optimalNext
	end

	if #lasts ~= -1 then
		local longest = 0
		local optimalLast = nil
		for _, path in pairs(lasts) do
			if utils.distanceVector(path[1].pos, station.trainExit.pos) > longest then
				longest = utils.distanceVector(path[1].pos, station.trainExit.pos)
				optimalLast = path
			end
		end
		self.arrivePath.last = optimalLast
	end

	-- if self.arrivePath.next ~= nil then
	-- 	print("#optimalNext: " .. #self.arrivePath.next)
	-- end
	-- if self.arrivePath.last ~= nil then
	-- 	print("#optimalLast: " .. #self.arrivePath.last)
	-- end
	-- print("#nexts: " .. #nexts .. " #lasts: " .. #lasts)
end

function trackSys:insertPath(path) -- Add path so far as independent field to the self.paths, as deepcopy is broken inside the recursive function?!
	local todo = {}
	for k, t in pairs(path) do
		todo[k] = t
	end
	table.insert(self.paths, todo)
end

function trackSys:mainGeneratePathData(station) -- Main function to call to calculate all the paths and arrive paths for the given station and put them into one final table
	self.pathsData = {}
	self.combinedData = {}
	local connectedTrack = self:getStationTrack(station)
	self:generatePaths(connectedTrack, station)

	for _, path in pairs(self.paths) do
		self:calcDirs(path, station)
		local data = self:unpackPath(path, station)
		table.insert(self.pathsData, data)
		--print("Inserted new exitPath lenght ", #data.points)
	end

	self:generateArrivePaths(station)

	for _, path in pairs(self.pathsData) do -- Pack all data into one table
		if path.dir == "next" then
			local data = {exitPath = {}, arrivalPath = {}, dir = path.dir, targetID = path.targetID}
			data.exitPath = path.points
			data.arrivalPath = self.arrivePath.last
			if self.arrivePath.last == nil then
				data.arrivalPath = self.arrivePath.next
			end
			table.insert(self.combinedData, data)
			--print("Creating path with dir: ", data.dir, " targetID: ", data.targetID, " #exitpath: ", #data.exitPath, " #arrivalPath: ", #data.arrivalPath)
		elseif path.dir == "last" then
			local data = {exitPath = {}, arrivalPath = {}, dir = path.dir, targetID = path.targetID}
			data.exitPath = path.points
			data.arrivalPath = self.arrivePath.next
			if self.arrivePath.next == nil then
				data.arrivalPath = self.arrivePath.last
			end
			table.insert(self.combinedData, data)
			--print("Creating path with dir: ", data.dir, " targetID: ", data.targetID, " #exitpath: ", #data.exitPath, " #arrivalPath: ", #data.arrivalPath)
		end
	end

	return self.combinedData
end

return trackSys