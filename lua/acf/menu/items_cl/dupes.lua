-- I wish AD2 exposed this globally.
-- Returns the information header and the remaining dupe string of an ad2 file without deserializing the dupe
local function getInfo(str)
	local last = str:find("\2")
	if not last then
		error("Attempt to read AD2 file with malformed info block!")
	end
	local info = {}
	local ss = str:sub(1, last - 1)
	for k, v in ss:gmatch("(.-)\1(.-)\1") do
		info[k] = v
	end

	if info.check ~= "\r\n\t\n" then
		if info.check == "\10\9\10" then
			error("Detected AD2 file corrupted in file transfer (newlines homogenized)(when using FTP, transfer AD2 files in image/binary mode, not ASCII/text mode)!")
		elseif info.check ~= nil then
			error("Detected AD2 file corrupted by newline replacements (copy/pasting the data in various editors can cause this!)")
		else
			error("Attempt to read AD2 file with malformed info block!")
		end
	end
	return info, str:sub(last+2)
end

-- Loads a dupe from the given path and sends it to the client
local function LoadDupe(name, path)
	local read = file.Read(path, "GAME")

	local success, dupe, info, moreinfo = AdvDupe2.Decode(read)
	if success then
		AdvDupe2.SendFile(name, read)
		AdvDupe2.LoadGhosts(dupe, info, moreinfo, name)
		AdvDupe2.Notify("Dupe Loaded: " .. name, NOTIFY_GENERIC)
	else
		AdvDupe2.Notify("File could not be decoded. ("..dupe..") Upload Canceled.", NOTIFY_ERROR)
	end
end

local function CreateMenu(Menu)
	Menu:AddTitle("#acf.menu.dupe.desc1")
	Menu:AddLabel("#acf.menu.dupe.desc2")

	local CurrentDupeName = nil
	local CurrentDupePath = nil

	local OpenDupeWindow = Menu:AddButton("Open Dupe Browser")
	function OpenDupeWindow:DoClickInternal()
		local DupePath = "addons/ACF-3/data_static/public_dupes"

		local _, DupePacks = file.Find(DupePath .. "/*", "GAME")
		local dupes = {}
		local dupe_infos = {}
		for _, DupePack in ipairs(DupePacks) do
			local PackPath = DupePath .. "/" .. DupePack
			local PackInfo = file.Read(PackPath .. "/info.json", "GAME")

			local PackDupeTable = {}
			if PackInfo then
				local Temp = util.JSONToTable(PackInfo)
				PackDupeTable = Temp and Temp.Dupes or {}
			end

			local Dupes, _ = file.Find(PackPath .. "/*.txt", "GAME")
			for _, Dupe in ipairs(Dupes) do
				local Name = string.StripExtension(Dupe)
				if PackDupeTable[Name] then
					PackDupeTable[Name].Name = nil -- We already know this
					for k, v in pairs(PackDupeTable[Name]) do
						dupe_infos[k] = dupe_infos[k] or {}
						dupe_infos[k][v] = true
					end
				end
				table.insert(dupes, {
					Name = Name,
					Path = PackPath .. "/" .. Name .. ".txt",
					Image = PackPath .. "/" .. Name .. ".jpg",
					Info = PackDupeTable[Name],
				})
			end
		end

		local DupeFrame = vgui.Create("DFrame")
		DupeFrame:SetTitle("ACF Community Dupe Browser")
		DupeFrame:SetSize(1200, 600)
		DupeFrame:Center()
		DupeFrame:MakePopup()
		DupeFrame:SetSizable(true)
		DupeFrame:SetDraggable(true)

		local InfoPanel = DupeFrame:Add("DPanel")
		InfoPanel:Dock(RIGHT)
		InfoPanel:SetWide(200)

		local FilterPanel = DupeFrame:Add("DPanel")
		FilterPanel:Dock(LEFT)
		FilterPanel:SetWide(200)

		-- Dupe Info stuff
		local DupeInfo = InfoPanel:Add("DCollapsibleCategory")
		DupeInfo:SetLabel("Dupe Information (From File)")
		DupeInfo:SetExpanded(true)
		DupeInfo:Dock(TOP)

		local DupeFileInfo = {}
		for _, name in ipairs({"Name", "Owner", "Date", "Time", "Size"}) do
			local Panel = DupeInfo:Add("DLabel")
			Panel:SetText("File: ")
			Panel:Dock(TOP)
			DupeFileInfo[name] = Panel
		end

		local DupeMetaData = InfoPanel:Add("DCollapsibleCategory")
		DupeMetaData:SetLabel("Dupe Information (From Creator)")
		DupeMetaData:SetExpanded(true)
		DupeMetaData:Dock(TOP)

		local DupeLoadButton = InfoPanel:Add("DButton")
		DupeLoadButton:SetText("Load Selected")
		DupeLoadButton:Dock(BOTTOM)
		DupeLoadButton.DoClick = function()
			if CurrentDupePath then
				DupeFrame:Close()
				spawnmenu.ActivateTool("advdupe2")
				LoadDupe(CurrentDupeName, CurrentDupePath)
			end
		end

		-- Dupe selection stuff
		local SelectPanel = DupeFrame:Add("DPanel")
		SelectPanel:Dock(FILL)

		local DupeSheet = SelectPanel:Add("DPropertySheet")
		DupeSheet:Dock(FILL)

		local SelectSubPanel = DupeSheet:AddSheet("All Dupes", vgui.Create("DPanel"), "icon16/shape_square.png").Panel
		SelectSubPanel:Dock(FILL)

		local DupeList = SelectSubPanel:Add("DPanelSelect")
		DupeList:Dock(FILL)

		for _, dupe in ipairs(dupes) do
			local Material = Material(dupe.Image)
			local Icon = vgui.Create("DImageButton")
			Icon:SetSize(256, 256)
			Icon:SetMaterial(Material)
			Icon:SetToolTip(dupe.Name)
			Icon.Data = dupe
			DupeList:AddPanel(Icon)
		end

		function DupeList:OnActivePanelChanged(_, New)
			local readFile = file.Open(New.Data.Path, "rb", "GAME")
			local readData = readFile:Read(readFile:Size())
			readFile:Close()

			local info, dupestring = getInfo(readData:sub(7))
			DupeFileInfo.Name:SetText("File: " .. (New.Data.Name or "Unknown"))
			DupeFileInfo.Owner:SetText("Owner: " .. (info.name or "Unknown"))
			DupeFileInfo.Date:SetText("Date: " .. (info.date or "Unknown"))
			DupeFileInfo.Time:SetText("Time: " .. (info.time or "Unknown"))
			DupeFileInfo.Size:SetText("Size: " .. string.NiceSize(tonumber(info.size or 0)))

			CurrentDupeName = New.Data.Name
			CurrentDupePath = New.Data.Path
		end

		-- Dupe filter stuff
		local DupeFilter = FilterPanel:Add("DCollapsibleCategory")
		DupeFilter:SetLabel("Dupe Filters")
		DupeFilter:SetExpanded(true)
		DupeFilter:Dock(TOP)

		local DupeFilterButton = FilterPanel:Add("DButton")
		DupeFilterButton:SetText("Apply Filters")
		DupeFilterButton:Dock(BOTTOM)
	end
end

ACF.AddMenuItem(3, "#acf.menu.dupe", "#acf.menu.dupe", "arrow_down", CreateMenu)