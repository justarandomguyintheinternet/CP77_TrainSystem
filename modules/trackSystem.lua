local track = require("modules/classes/track")
local utils = require("modules/utils/utils")

trackSys = {}

function trackSys:new(ts)
	local o = {}

	o.ts = ts
	o.tracks = {}

	self.tmpList = {}
	self.paths = {}

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

function trackSys:getStationTrack(station)
	for _, t in pairs(self.tracks) do
		if t.hasStation.next == station.id then
			return t
		elseif t.hasStation.last == station.id then
			return t
		end
	end
end

function trackSys:generatePaths(track, station)
	self.paths = {}
	local path = {}
	if (track.hasStation.last ~= -1 and track.hasStation.last ~= station.id) then
		print("connected track " .. track.id .. " has station ")
		table.insert(self.paths, {track})
		table.insert(path, track)
		if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track, path) end
		path = {}
		table.insert(path, track)
		if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track, path) end
	elseif (track.hasStation.next ~= station.id and track.hasStation.next ~= -1) then
		print("connected track " .. track.id .. " has station ")
		table.insert(self.paths, {track})
		table.insert(path, track)
		if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track, path) end
		path = {}
		table.insert(path, track)
		if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track, path) end
	else
		if track.hasStation.last ~= -1 and track.hasStation.last == station.id then
			table.insert(path, track)
			if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track, path) end
			path = {}
			table.insert(path, track)
			if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track, path) end
		end
		if track.hasStation.next ~= -1 and track.hasStation.next == station.id then
			table.insert(path, track)
			if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track, path) end
			path = {}
			table.insert(path, track)
			if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track, path) end
		end
	end
end

function trackSys:DFS(track, previous, path)
	if previous.id == track.connectedID.first.next or previous.id == track.connectedID.second.next then
		table.insert(path, track)
		print("track id now: " .. track.id .. " is last of " .. previous.id)
		if track.hasStation.next ~= -1 then
			print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next .. "length of path: " .. #path)
			self:insertPath(path)
		elseif track.hasStation.last ~= -1 then
			print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last .. "length of path: " .. #path)
			self:insertPath(path)
		else
			if track.connectedID.first.last ~= -1 then
				self:DFS(self.tracks[track.connectedID.first.last], track, path)
			end
			if track.connectedID.second.last ~= -1 then
				self:DFS(self.tracks[track.connectedID.second.last], track, path)
			end
		end
		utils.removeItem(path, track)
	end

	if previous.id == track.connectedID.first.last or previous.id == track.connectedID.second.last then
		table.insert(path, track)
		print("track id now: " .. track.id .. " is next of " .. previous.id)
		if track.hasStation.last ~= -1 then
			print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last .. "length of path: " .. #path)
			self:insertPath(path)
		elseif track.hasStation.next ~= -1 then
			print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next .. "length of path: " .. #path)
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

function trackSys:calcDirs(path, station)
	for key, track in pairs(path) do
		if key == 1 and #path == 1 then -- Only one track, aka Station on other end of station
			if station.id == track.hasStation.next then
				track.dir = "last"
			elseif station.id == track.hasStation.last then
				track.dir = "next"
			end
		else
			if key ~= #path then
				if path[key + 1].id == track.connectedID.first.next or path[key + 1].id == track.connectedID.second.next then
					track.dir = "next"
				end
				if path[key + 1].id == track.connectedID.first.last or path[key + 1].id == track.connectedID.second.last then
					track.dir = "last"
				end
			else
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

function trackSys:insertPath(path)
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
	for k, p in pairs(self.paths) do
		self:calcDirs(p, station)
		print("PATH NR ".. k)
		for _, t in pairs(p) do
			print("- Track NR".. t.id .. " DIR: " .. t.dir)
		end
	end
end

return trackSys