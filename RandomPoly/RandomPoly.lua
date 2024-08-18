local rpolyList
local poly_addon = ...

--------------------------------------------------------------------
-- Produced Marco Name [in player's macros]
--------------------------------------------------------------------

local PolymorphMacroName = "Poly"
local polyMacroSrc = "\n/click rpolyButton 1\n/click rpolyButton LeftButton 1"

local debugPoly = false
local unusablePolymorphTextColor = "|cffFF0000"

--------------------------------------------------------------------
-- Polymorph & Polymorph Variants List
--------------------------------------------------------------------

local rpolyVariants = {
--- Default Polymorph  --
	{118, "Sheep"},
--- Collectable Polymorph Variants --
	{61305, "Black Cat"},
	{277792, "Bumblebee"},
	{277787, "Direhorn"},
	{391622, "Duck"},
	{161354, "Monkey"},
	{227710, "Mosswool"},
	{28272, "Pig"},
	{161353, "Polar Bear Cub"},
	{126819, "Porcupine"},
	{61721, "Rabbit"},
	{28271, "Turtle"},
	}

--------------------------------------------------------------------
-- Used to check incoming spellIds, polymorph cast?
--------------------------------------------------------------------
function IsPolymorphVariantSpellId(spellId)
	for k in pairs(rpolyVariants) do
		-- Is spellId one of the polymorph variants? --
		if spellId == rpolyVariants[k][1] then
			return true
		end
	end
	
	return false
end

--------------------------------------------------------------------
-- UI in Options panel
--------------------------------------------------------------------

local rpolyOptionsPanel = CreateFrame("Frame")
rpolyOptionsPanel.name = "Random Poly [/poly]"
rpolyOptionsPanel.OnCommit = function() rpolyOptionsOkay(); end
rpolyOptionsPanel.OnDefault = function() end
rpolyOptionsPanel.OnRefresh = function() end
local rpolyCategory = Settings.RegisterCanvasLayoutCategory(rpolyOptionsPanel, "Random Poly [/poly]")
Settings.RegisterAddOnCategory(rpolyCategory)

-- Title --
local rpolyTitle = CreateFrame("Frame",nil, rpolyOptionsPanel)
rpolyTitle:SetPoint("TOPLEFT", 10, -10)
rpolyTitle:SetWidth(SettingsPanel.Container:GetWidth()-35)
rpolyTitle:SetHeight(1)
rpolyTitle.text = rpolyTitle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyTitle.text:SetPoint("TOPLEFT", rpolyTitle, 0, 0)
rpolyTitle.text:SetText("Random Poly")
rpolyTitle.text:SetFont("Fonts\\FRIZQT__.TTF", 18)

-- Thanks --
rpolyOptionsPanel.Thanks = rpolyOptionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyOptionsPanel.Thanks:SetPoint("BOTTOMRIGHT",-5,5)
rpolyOptionsPanel.Thanks:SetText("For the Mages who still Polymorph and collect the variants.\n Originally cloned from \"Random Hearthstone\" by JamienAU.  \n Tweaked into \"Random Hex\" then \"Random Poly\" by zecmo-Hakkar.    \nAnd thanks for the help, Khairis")
rpolyOptionsPanel.Thanks:SetFont("Fonts\\FRIZQT__.TTF", 9)
rpolyOptionsPanel.Thanks:SetJustifyH("RIGHT")

-- Description
local rpolyDesc = CreateFrame("Frame", nil, rpolyOptionsPanel)
rpolyDesc:SetPoint("TOPLEFT", 20, -40)
rpolyDesc:SetWidth(SettingsPanel.Container:GetWidth()-35)
rpolyDesc:SetHeight(1)
rpolyDesc.text = rpolyDesc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyDesc.text:SetPoint("TOPLEFT", rpolyDesc, 0, 0)
rpolyDesc.text:SetText("Add/remove Polymorph Variants from rotation [red text is missing/unusable by character]")
rpolyDesc.text:SetFont("Fonts\\FRIZQT__.TTF", 14)

-- Scroll Frame
local rpolyOptionsScroll = CreateFrame("ScrollFrame", nil, rpolyOptionsPanel, "UIPanelScrollFrameTemplate")
rpolyOptionsScroll:SetPoint("TOPLEFT", 5, -60)
rpolyOptionsScroll:SetPoint("BOTTOMRIGHT", -25, 100)

-- Divider
local rpolyDivider = rpolyOptionsScroll:CreateLine()
rpolyDivider:SetStartPoint("BOTTOMLEFT", 20, -10)
rpolyDivider:SetEndPoint("BOTTOMRIGHT", 0, -10)
rpolyDivider:SetColorTexture(0.25,0.25,0.25,1)
rpolyDivider:SetThickness(1.2)

-- Scroll Frame child
local rpolyScrollChild = CreateFrame("Frame")
rpolyOptionsScroll:SetScrollChild(rpolyScrollChild)
rpolyScrollChild:SetWidth(SettingsPanel.Container:GetWidth()-35)
rpolyScrollChild:SetHeight(1)

-- Checkbox for each Polymorph variant
local rpolyCheckButtons = {}
for i = 1, #rpolyVariants do
	local chkOffset = 0
	if i > 1 then
		local _,_,_,_,yOffSet = rpolyCheckButtons[i-1]:GetPoint()
		chkOffset = math.floor(yOffSet) + -26
	end
	rpolyCheckButtons[i] = CreateFrame("CheckButton", nil, rpolyScrollChild, "UICheckButtonTemplate")
	rpolyCheckButtons[i]:SetPoint("TOPLEFT", 15, chkOffset)
	rpolyCheckButtons[i]:SetSize(25,25)
	rpolyCheckButtons[i].ID = rpolyVariants[i][1]
	rpolyCheckButtons[i].Text:SetText("  " .. rpolyVariants[i][2])
	rpolyCheckButtons[i].Text:SetTextColor(1,1,1,1)
	rpolyCheckButtons[i].Text:SetFont("Fonts\\FRIZQT__.TTF", 13)
end

-- Select All button --
local rpolySelectAll = CreateFrame("Button", nil, rpolyOptionsPanel, "UIPanelButtonTemplate")
rpolySelectAll:SetPoint("BOTTOMLEFT", 20, 50)
rpolySelectAll:SetSize(100,25)
rpolySelectAll:SetText("Select all")
rpolySelectAll:SetScript("OnClick", function(self)
	for i = 1, #rpolyVariants do
		rpolyCheckButtons[i]:SetChecked(true)
	end
end)

-- Deselect All button --
local rpolyDeselectAll = CreateFrame("Button", nil, rpolyOptionsPanel, "UIPanelButtonTemplate")
rpolyDeselectAll:SetPoint("BOTTOMLEFT", 135, 50)
rpolyDeselectAll:SetSize(100,25)
rpolyDeselectAll:SetText("Deselect all")
rpolyDeselectAll:SetScript("OnClick", function(self)
	for i = 1, #rpolyVariants do
		rpolyCheckButtons[i]:SetChecked(false)
	end
end)

--------------------------------------------------------------------
-- Init/Awake AddonLoaded Msg Handling & Loading
--------------------------------------------------------------------
local rpolyListener = CreateFrame("Frame")
rpolyListener:RegisterEvent("ADDON_LOADED")
rpolyListener:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == poly_addon then
		if rpolyOptions == nil then
			-- Adds all polymorph variant IDs to savedvariables as enabled
			rpolyOptions = {}
			for i=1, #rpolyVariants do
				rpolyOptions[i] = {rpolyVariants[i][1], true}
			end
		else
			-- Deletes polymorph variant IDs that no longer exist in rpolyVariants list
			for i,v in pairs(rpolyOptions) do
				local chk = 0
				for l = 1, #rpolyVariants do
					if v[1] == rpolyVariants[l][1] then
						chk = 1
					end
				end
				if chk == 0 then 
					rpolyOptions[i] = nil
				end
			end

			-- Adds any missing polymorph variant IDs to savedvariables as enabled
			for i,v in pairs(rpolyVariants) do
				local chk = 0
				for l = 1, #rpolyOptions do
					if v[1] == rpolyOptions[l][1] then
						chk = 1
					end
				end
				if chk == 0 then
					table.insert(rpolyOptions, {v[1], true})
				end
			end
		end
		
		-- Loop through options and set checkbox state
		for i,v in pairs(rpolyOptions) do
			for l = 1, #rpolyOptions do
				if rpolyCheckButtons[l].ID == v[1] and v[2] == true then
					rpolyCheckButtons[l]:SetChecked(true)
				end
			end
		end

		self:UnregisterEvent("ADDON_LOADED")
	end
end)

--------------------------------------------------------------------
-- Assigned methods to the UI Panel's Confirm/Okay & Cancel [which Option UI updates where all changes are live with confirm, I'm not sure if the Cancel ever gets called. Perhaps in other use cases.
--------------------------------------------------------------------

function rpolyOptionsOkay()
	-- Class Check!
	local classFilename, classId = UnitClassBase("player")
	if classFilename ~= "MAGE" then
		return
	end

	for i = 1, #rpolyOptions do
		for _,v in pairs(rpolyOptions) do
			if rpolyCheckButtons[i].ID == v[1] then
				v[2] = rpolyCheckButtons[i]:GetChecked()
			end
		end
	end

	RefreshRandomPolymorphPool()
	SelectRandomPolymorphVariant()

	if #rpolyList == 0 then
		print("|cffFF0000RandomPoly Addon: No valid Polymorph Variants selected -|r Baa, baa!") end	
end

--------------------------------------------------------------------
-- Create an invisible button for our macro to click.
--  Button creation, named [rpolyButton]
--------------------------------------------------------------------
local rpolyBtn = CreateFrame("Button", "rpolyButton", nil,  "SecureActionButtonTemplate")

-- WoW client events we want to know about --
rpolyBtn:RegisterEvent("PLAYER_ENTERING_WORLD")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_START")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_STOP")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
rpolyBtn:RegisterEvent("PLAYER_LEAVE_COMBAT")
rpolyBtn:RegisterForClicks("LeftButtonDown", "LeftButtonUp" )
rpolyBtn:SetAttribute("type","spell")

local polymorphWasCast = false
local polymorphCastId = 000000
-- Pass in an anonymous function which handles the events --
rpolyBtn:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	-- Capture any Polymorph Variant cast start --
	if event == "UNIT_SPELLCAST_START" and arg1 == "player" then
		if IsPolymorphVariantSpellId(arg3) then
			polymorphCastId = arg3
		end
	end

	if not InCombatLockdown() then
		-- Out of Combat --
		if event == "PLAYER_ENTERING_WORLD" then
			RefreshRandomPolymorphPool()
			SelectRandomPolymorphVariant()
			-- Unregister from event --
			rpolyBtn:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end

		if  event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_STOP" then
			if arg1 == "player" and IsPolymorphVariantSpellId(arg3) and polymorphCastId == arg3 then
				polymorphCastId = 000000
				SelectRandomPolymorphVariant()
			end
		end
	else
		-- In Combat --
		if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
			if IsPolymorphVariantSpellId(arg3) then				
				polymorphWasCast = true

				if debugPoly then
					print("== Polymorph used during combat") end
			end
		end
	end

	-- Always do whenever player leaves combat, regardless of lockdown
	if event == "PLAYER_LEAVE_COMBAT" then
		if debugPoly then
			print("== Player Leaves Combat...") end

		if polymorphWasCast then
			WaitThenSetRandomPolymorph()

			if debugPoly then
				print("=== And Polymorph was cast!!") end
		end		
	end
end)

--------------------------------------------------------------------
-- Convenient to have a method to call that executes after timer completes
--------------------------------------------------------------------
function WaitThenSetRandomPolymorph()
	local timeOut = 1
	C_Timer.After(timeOut, function()
		local ticker
		ticker = C_Timer.NewTicker(1, function()
			if InCombatLockdown() then
				WaitThenSetRandomPolymorph()
			else
				-- Now call polymorph selection --
				if polymorphWasCast then
					if debugPoly then
						print("==== Polymorph updated on post combat") end

					polymorphWasCast = false
					SelectRandomPolymorphVariant()
				end
			end

			-- Always cancel the ticker
  			ticker:Cancel()
	    end)
	end)
end

--------------------------------------------------------------------
-- Generate the list of valid Polymorph Variants
--------------------------------------------------------------------
function RefreshRandomPolymorphPool()
	-- Re-initialize
	rpolyList = {}

	for i=1, #rpolyOptions do
		if rpolyOptions[i][2] == true then
			if IsSpellKnownOrOverridesKnown(rpolyOptions[i][1]) then
				table.insert(rpolyList,rpolyOptions[i][1])
			end
		end
	end

	if debugPoly then
		print("==== Refreshing Pool: " .. #rpolyList) end

	ColorizePolymorphVariantText()
end

--------------------------------------------------------------------
-- White text for known/usable, Red text for unknown/unusable[faction]
--------------------------------------------------------------------
function ColorizePolymorphVariantText()
	-- Check for usable polymorph variants then colorize and [debug] print out all available polymorph variants --		
	for k in pairs(rpolyVariants) do

		-- Add a faction suffix for convenince --
		local factionSuffix = ""
		if rpolyVariants[k][2] == "Bumblebee" then
			factionSuffix = " [Alliance]" end
		if rpolyVariants[k][2] == "Direhorn" then
			factionSuffix = " [Horde]" end

		if IsSpellKnownOrOverridesKnown(rpolyVariants[k][1]) then
			if debugPoly then
				print("=== " .. rpolyVariants[k][2] .. " : Usable!") end
				-- Default white --
				rpolyCheckButtons[k].Text:SetText("  " .. rpolyVariants[k][2] .. factionSuffix)
		else
			if debugPoly then
				print("=== " .. rpolyVariants[k][2] .. " : NOT Usable!!") end
				-- Unknowns red --
				rpolyCheckButtons[k].Text:SetText("  " .. unusablePolymorphTextColor .. rpolyVariants[k][2] .. factionSuffix)
		end
	end
end

--------------------------------------------------------------------
-- Set random Polymorph Variant from a diminishing pool 
--------------------------------------------------------------------
function SelectRandomPolymorphVariant()
	if debugPoly then
		print("== remainingInPool_OnEnter: " .. #rpolyList) end

	-- Make sure the poolList is not empty 
	if #rpolyList == 0 then
		RefreshRandomPolymorphPool()
	end

	-- Still no valid entries?
	if #rpolyList == 0 then
		-- Default Polymorph --
		rpolyBtn:SetAttribute("spell", 118)
		UpdateRandomPolymorphMacro("Polymorph(Sheep)","136071")
		return
	end

	-- Get random index --
	local rnd = GetRandomPolymorphVariantIndex(#rpolyList)
	local randomPolymorphIndexSpellId = rpolyList[rnd]

	-- Get Spell Info with many return values --
	local spellInfo = C_Spell.GetSpellInfo(randomPolymorphIndexSpellId)

	-- Update button --
	rpolyBtn:SetAttribute("spell", spellInfo["spellID"])

	-- Build name and update macro --
	local polymorphVariantName = PolymorphNameFromSpellId(randomPolymorphIndexSpellId)
	local polymorphCompoundName = spellInfo["name"] .. "(" .. polymorphVariantName .. ")"
	UpdateRandomPolymorphMacro(polymorphCompoundName, spellInfo["originalIconID"])

	if debugPoly then
		print("=== Selected: " .. polymorphVariantName) end

	-- Once the polymorph variant data is loaded, remove the variant id from the pool --
	table.remove(rpolyList, rnd)	
end

function PolymorphNameFromSpellId(spellId)
	for i=1, #rpolyVariants do
		if rpolyVariants[i][1] == spellId then
			return rpolyVariants[i][2]
		end
	end

	return ""
end

--------------------------------------------------------------------
-- Gets random index without allowing the same polymorph variant twice in a row
--   which could happen on pool refresh
--------------------------------------------------------------------
local prevPolyId = -1
function GetRandomPolymorphVariantIndex(size)
	if size > 1 then
		local rando = math.random(1,size)
		if rpolyList[rando] == prevPolyId then
			if rando == 1 then
				rando = size
			else
				rando = rando - 1
			end
		end

		prevPolyId = rpolyList[rando]
		return rando
	end

	if size == 1 then
		prevPolyId = rpolyList[1]
		return 1
	end

	return 0		
end

--------------------------------------------------------------------
-- Update/Create the global macro
--------------------------------------------------------------------
function UpdateRandomPolymorphMacro(name,icon)
	if not InCombatLockdown() then
		local macroIndex = GetMacroIndexByName(PolymorphMacroName)
		if macroIndex > 0 then
			EditMacro(macroIndex, PolymorphMacroName, icon, "#showtooltip " .. name .. polyMacroSrc)
		else
			CreateMacro(PolymorphMacroName, icon, "#showtooltip " .. name .. polyMacroSrc, nil)
		end
	end
end

--------------------------------------------------------------------
-- Create slash commands
--------------------------------------------------------------------
SLASH_RandomPoly1 = "/poly"
function SlashCmdList.RandomPoly(msg, editbox)
	Settings.OpenToCategory(rpolyCategory:GetID())
end
