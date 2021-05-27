local track = require("modules/classes/track")

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

function trackSys:getStationTracks(station)
	local con = {}
	for _, t in pairs(self.tracks) do
		if t.hasStation.next == station.id then
			table.insert(con, t)
			if t.connectedID.first.next ~= -1 then
				table.insert(con, self.tracks[t.connectedID.first.next])
			end
			if t.connectedID.second.next ~= -1 then
				table.insert(con, self.tracks[t.connectedID.second.next])
			end
		elseif t.hasStation.last == station.id then
			table.insert(con, t)
			if t.connectedID.first.last ~= -1 then
				table.insert(con, self.tracks[t.connectedID.first.last])
			end
			if t.connectedID.second.last ~= -1 then
				table.insert(con, self.tracks[t.connectedID.second.last])
			end
		end
	end
	return con
end

function trackSys:generatePaths(tracks, station)
	for _, v in pairs(tracks) do
		if (v.hasStation.last ~= -1 and v.hasStation.last ~= station.id) then
			print("connected track " .. v.id .. " has station ")
			if v.connectedID.first.next ~= -1 then self:DFS(self.tracks[v.connectedID.first.next], v) end
			if v.connectedID.second.next ~= -1 then self:DFS(self.tracks[v.connectedID.second.next], v) end
		elseif (v.hasStation.next ~= station.id and v.hasStation.next ~= -1) then
			print("connected track " .. v.id .. " has station ")
			if v.connectedID.first.last ~= -1 then self:DFS(self.tracks[v.connectedID.first.last], v) end
			if v.connectedID.second.last ~= -1 then self:DFS(self.tracks[v.connectedID.second.last], v) end
		else
			if v.hasStation.last ~= -1 and v.hasStation.last == station.id then
				if v.connectedID.first.next ~= -1 then self:DFS(self.tracks[v.connectedID.first.next], v) end
				if v.connectedID.second.next ~= -1 then self:DFS(self.tracks[v.connectedID.second.next], v) end
			end
			if v.hasStation.next ~= -1 and v.hasStation.next == station.id then
				if v.connectedID.first.last ~= -1 then self:DFS(self.tracks[v.connectedID.first.last], v) end
				if v.connectedID.second.last ~= -1 then self:DFS(self.tracks[v.connectedID.second.last], v) end
			end
		end
	end
end

function trackSys:DFS(track, previous)
	print("called dfs from track id " .. track.id .. " previous " .. previous.id .. " stations: " ..track.hasStation.next.. " " .. track.hasStation.last)
	if previous.id == track.connectedID.first.next or previous.id == track.connectedID.second.next then
		if track.hasStation.next ~= -1 then
			print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next)
		elseif track.hasStation.last ~= -1 then
			print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last)
		else
			if track.connectedID.first.last ~= -1 then self:DFS(self.tracks[track.connectedID.first.last], track) end
			if track.connectedID.second.last ~= -1 then self:DFS(self.tracks[track.connectedID.second.last], track) end
		end
	end
	if previous.id == track.connectedID.first.last or previous.id == track.connectedID.second.last then
		if track.hasStation.last ~= -1 then
			print("found station on last of track " .. track.id .. "station id" .. track.hasStation.last)
		elseif track.hasStation.next ~= -1 then
			print("found station on next of track " .. track.id .. "station id" .. track.hasStation.next)
		else
			if track.connectedID.first.next ~= -1 then self:DFS(self.tracks[track.connectedID.first.next], track) end
			if track.connectedID.second.next ~= -1 then self:DFS(self.tracks[track.connectedID.second.next], track) end
		end
	end
end

function trackSys:requestTrainToStation(station)
	local connectedTracks = self:getStationTracks(station)
	for _, v in pairs(connectedTracks) do print(v.id) end
	self:generatePaths(connectedTracks, station)
end

return trackSys