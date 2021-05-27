local track = require("modules/classes/track")
local utils = require("modules/utils/utils")

trackSys = {}

function trackSys:new(ts)
	local o = {}

	o.ts = ts
	o.tracks = {}

	self.paths = {}
	self.pathsData = {}

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
		if track.hasStation.last ~= -1 and track.hasStation.last == station.id then
			table.insert(path, track)
			if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track, path) end
			path = {}
			table.insert(path, track)
			if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track, path) end
		end
		if track.hasStation.next ~= -1 and track.hasStation.next == station.id then -- Handle both directions (last/next) and both possible connected tracks
			table.insert(path, track)
			if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track, path) end
			path = {}
			table.insert(path, track)
			if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track, path) end
		end
	end
end

function trackSys:DFS(track, previous, path) -- Recursive calling search function
	if previous.id == track.connectedID.first.next or previous.id == track.connectedID.second.next then -- If track is "backwards", "tip" of arrow is connected to previous, means the next track is at the beginning of this track
		table.insert(path, track) -- Add track to path
		if track.hasStation.next ~= -1 then -- If station is found then break the recursive function
			self:insertPath(path)
		elseif track.hasStation.last ~= -1 then
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

function trackSys:unpackPath(path, station) -- Take a path and generate a table with its total direction, target stationID and a table of all points to the targetID in the right order
	local data = {dir = path[1].dir, targetID = station.id, points = {}}

	if #path == 1 then -- Only one track aka station on that track
		if path[1].dir == "next" then
			data.targetID = path[1].hasStation.next
			for _, p in pairs(path[1].points) do
				table.insert(data.points, p)
			end
		else
			data.targetID = path[1].hasStation.last
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
						for _, p in pairs(track.points) do
							table.insert(data.points, p)
						end
					else
						for i = #track.points, 1, -1 do
							table.insert(data.points, utils.reversePoint(track.points[i]))
						end
					end
				else
					if track.dir == "next" then -- Always ad the one point the station is on tho, depending on direction last or first point
						table.insert(data.points, track.points[1])
					else
						table.insert(data.points, utils.reversePoint(track.points[#track.points]))
					end
				end
			elseif not (track.dir == "next" and track.hasStation.next ~= -1) and not (track.dir == "last" and track.hasStation.last ~= -1) then -- If its an "in between" track, if statement makes sure only points from the start track (with station on it) only get added if the path moves in the other direction from where the station is (If station is on next then only add the points if direction is last, not next)
				if track.dir == "next" then
					for _, p in pairs(track.points) do
						table.insert(data.points, p)
					end
				else
					for i = #track.points, 1, -1 do
						table.insert(data.points, utils.reversePoint(track.points[i]))
					end
				end
			end
		end
	end

	print("Generated data to station " .. data.targetID .. " Direction is " .. data.dir .. " with num points: " .. #data.points)
	for _, p in pairs(data.points) do
		print(p.pos, GetSingleton('Quaternion'):ToEulerAngles(p.rot))
	end

end

function trackSys:insertPath(path) -- Add path so far as independent field to the self.paths, as deepcopy is broken inside the recursive function?!
	local todo = {}
	for k, t in pairs(path) do
		todo[k] = t
	end
	table.insert(self.paths, todo)
end

function trackSys:requestTrainToStation(station)
	local connectedTrack = self:getStationTrack(station)
	self:generatePaths(connectedTrack, station)
	print(#self.paths)
	for k, path in pairs(self.paths) do
		self:calcDirs(path, station)
		self:unpackPath(path, station)
		print("PATH NR ".. k)
		for _, t in pairs(path) do
			print("- Track NR".. t.id .. " DIR: " .. t.dir)
		end
	end
end

return trackSys