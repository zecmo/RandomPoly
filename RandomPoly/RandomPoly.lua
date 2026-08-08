local rpolyList
local poly_addon = ...

--------------------------------------------------------------------
-- Produced Marco Name [in player's macros]
--------------------------------------------------------------------

local PolymorphMacroName = "Poly"
local polyMacroSrc = "\n/click rpolyButton 1\n/click rpolyButton LeftButton 1"

local debugPoly = false

--------------------------------------------------------------------
-- Polymorph & Polymorph Variants List
--------------------------------------------------------------------

-- {spellId, name, faction} -- faction is set only on the two that are
-- locked to one side, and it's the data rather than a name comparison so
-- the count and the colouring can both read it (see IsPolyVariantImpossible)
local rpolyVariants = {
--- Default Polymorph  --
	{118, "Sheep"},
--- Collectable Polymorph Variants --
	{61305, "Black Cat"},
	{277792, "Bumblebee", "Alliance"},
	{277787, "Direhorn", "Horde"},
	{391622, "Duck"},
	{161354, "Monkey"},
	{460392, "Mosswool"},
	{28272, "Pig"},
	{161353, "Polar Bear Cub"},
	{126819, "Porcupine"},
	{61721, "Rabbit"},
	{28271, "Turtle"},
	}

--------------------------------------------------------------------
-- A variant locked to the other faction can never be collected on this
-- character, so it doesn't belong in the total you're working towards --
-- 11 is reachable, 12 never is, whichever side you're on.
--------------------------------------------------------------------
function IsPolyVariantImpossible(index)
	local faction = rpolyVariants[index][3]
	if not faction then return false end
	local playerFaction = UnitFactionGroup("player")
	-- Neutral (a pandaren who hasn't chosen) can still end up either side,
	-- so nothing is ruled out yet --
	if not playerFaction or playerFaction == "Neutral" then return false end
	return faction ~= playerFaction
end

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

-- Vertical rhythm for the header block. The description sits HEADER_GAP
-- under the title, and the list sits the same distance under the
-- description -- expressed as one constant so the two spacings can't drift
-- apart if the header ever moves.
local HEADER_Y = -10
local HEADER_GAP = -30
local DESC_Y = HEADER_Y + HEADER_GAP
local LIST_Y = DESC_Y + HEADER_GAP

-- Title --
local rpolyTitle = CreateFrame("Frame",nil, rpolyOptionsPanel)
rpolyTitle:SetPoint("TOPLEFT", 10, HEADER_Y)
rpolyTitle:SetWidth(SettingsPanel.Container:GetWidth()-35)
rpolyTitle:SetHeight(1)
rpolyTitle.text = rpolyTitle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyTitle.text:SetPoint("TOPLEFT", rpolyTitle, 0, 0)
rpolyTitle.text:SetText("Random Poly")
rpolyTitle.text:SetFont("Fonts\\FRIZQT__.TTF", 18)

-- Thanks --
rpolyOptionsPanel.Thanks = rpolyOptionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyOptionsPanel.Thanks:SetPoint("BOTTOMRIGHT",-20,14)
rpolyOptionsPanel.Thanks:SetText("For the Mages who still Polymorph and collect the variants. \nThanks for the help, Khairis!  \n zecmo - Runetotem    ")
rpolyOptionsPanel.Thanks:SetFont("Fonts\\FRIZQT__.TTF", 9)
rpolyOptionsPanel.Thanks:SetJustifyH("RIGHT")

-- Description
local rpolyDesc = CreateFrame("Frame", nil, rpolyOptionsPanel)
rpolyDesc:SetPoint("TOPLEFT", 20, DESC_Y)
rpolyDesc:SetWidth(SettingsPanel.Container:GetWidth()-35)
rpolyDesc:SetHeight(1)
rpolyDesc.text = rpolyDesc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpolyDesc.text:SetPoint("TOPLEFT", rpolyDesc, 0, 0)
rpolyDesc.text:SetText("Toggle which polymorph variants are active in the \"Poly\" macro\'s rotation.")
rpolyDesc.text:SetFont("Fonts\\FRIZQT__.TTF", 14)

--------------------------------------------------------------------
-- Collection progress [how many variants this character actually knows,
-- styled after Blizzard's own collection bars: a green fill with the
-- count centred on it. Filled in by ColorizePolymorphVariantText]
--------------------------------------------------------------------
local rpolyProgressBar = CreateFrame("StatusBar", nil, rpolyOptionsPanel)
rpolyProgressBar:SetSize(200, 10)
-- Anchored to the title frame rather than the panel, so it rides the header
-- wherever that moves. The title frame is a 1px line with its 18pt text
-- hanging below it, so the bar drops to sit level with that text --
rpolyProgressBar:SetPoint("RIGHT", rpolyTitle, "RIGHT", -5, -4)
rpolyProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
rpolyProgressBar:SetStatusBarColor(0.13, 0.63, 0.11)
rpolyProgressBar:SetMinMaxValues(0, #rpolyVariants)
rpolyProgressBar:SetValue(0)
local rpolyProgressBg = rpolyProgressBar:CreateTexture(nil, "BACKGROUND")
rpolyProgressBg:SetAllPoints()
rpolyProgressBg:SetColorTexture(0, 0, 0, 0.7)
-- Soft tooltip-edge border rather than the raw rectangle --
local rpolyProgressBorder = CreateFrame("Frame", nil, rpolyProgressBar, "BackdropTemplate")
rpolyProgressBorder:SetPoint("TOPLEFT", -5, 5)
rpolyProgressBorder:SetPoint("BOTTOMRIGHT", 5, -5)
rpolyProgressBorder:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14})
rpolyProgressBorder:SetBackdropBorderColor(1, 1, 1, 0.85)
local rpolyProgressText = rpolyProgressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
rpolyProgressText:SetPoint("CENTER")

-- Scroll Frame [sits the same distance below the description as the
-- description sits below the title -- see LIST_Y]
local rpolyOptionsScroll = CreateFrame("ScrollFrame", nil, rpolyOptionsPanel, "UIPanelScrollFrameTemplate")
rpolyOptionsScroll:SetPoint("TOPLEFT", 5, LIST_Y)
rpolyOptionsScroll:SetPoint("BOTTOMRIGHT", -10, 60)

-- No visible scrollbar: two columns fit without one, and an empty track
-- down the side is just clutter. The scroll frame itself stays, so the
-- wheel still works if the list ever outgrows the panel -- hence overriding
-- Show, since the template re-shows the bar whenever the range changes.
if rpolyOptionsScroll.ScrollBar then
	rpolyOptionsScroll.ScrollBar:Hide()
	rpolyOptionsScroll.ScrollBar.Show = function() end
end

-- Divider
local rpolyDivider = rpolyOptionsScroll:CreateLine()
rpolyDivider:SetStartPoint("BOTTOMLEFT", 20, -10)
rpolyDivider:SetEndPoint("BOTTOMRIGHT", 0, -10)
rpolyDivider:SetColorTexture(0.25,0.25,0.25,1)
rpolyDivider:SetThickness(1.2)

-- Scroll Frame child
local rpolyScrollChild = CreateFrame("Frame")
rpolyOptionsScroll:SetScrollChild(rpolyScrollChild)
-- Wider now that no scrollbar is eating the right-hand strip --
rpolyScrollChild:SetWidth(SettingsPanel.Container:GetWidth()-20)
rpolyScrollChild:SetHeight(1)

--------------------------------------------------------------------
-- One card per polymorph variant -- icon in a quickslot ring, name beside
-- it, the whole cell framed. Same look as Random Hex, Random Lure and
-- Random Toys, and the same idea behind it: the selected state is carried
-- by a gold border round the cell rather than a tick box, so nothing is
-- drawn over the icon.
--
-- These stay CheckButtons with .ID and .Text, because the rest of the file
-- (rpolyOptionsOkay, the saved-variable sync, Select/Deselect all) drives
-- them through exactly that interface.
--------------------------------------------------------------------
local COLS = 2
local GRID_WIDTH = rpolyScrollChild:GetWidth()
local COL_OFFSET = math.floor(GRID_WIDTH / COLS)
local ROW_WIDTH, ROW_HEIGHT, ROW_STEP, ICON_SIZE = COL_OFFSET - 20, 42, 44, 28
local DEFAULT_BORDER_COLOR = {0.3, 0.3, 0.3, 1}
local SELECTED_BORDER_COLOR = {1, 0.82, 0, 1}

local function UpdatePolyCellSelection(f)
	local selected = f:GetChecked() and true or false
	local color = selected and SELECTED_BORDER_COLOR or DEFAULT_BORDER_COLOR
	f.borderTop:SetColorTexture(unpack(color))
	f.borderBottom:SetColorTexture(unpack(color))
	f.borderLeft:SetColorTexture(unpack(color))
	f.borderRight:SetColorTexture(unpack(color))
	f.cellBg:SetColorTexture(1, 1, 1, selected and 0.14 or 0.06)
end

local function CreatePolyVariantCell(parent, spellId, index)
	local f = CreateFrame("CheckButton", nil, parent)
	f.ID = spellId
	f:SetSize(ROW_WIDTH, ROW_HEIGHT)
	-- Filled left to right, then down --
	local col = (index - 1) % COLS
	local row = math.floor((index - 1) / COLS)
	f:SetPoint("TOPLEFT", 15 + col * COL_OFFSET, -(row * ROW_STEP))

	f.cellBg = f:CreateTexture(nil, "BACKGROUND", nil, -2)
	f.cellBg:SetAllPoints(f)
	f.cellBg:SetColorTexture(1, 1, 1, 0.06)

	for _, spec in ipairs({
		{key = "borderTop",    p1 = "TOPLEFT",    p2 = "TOPRIGHT",    dim = "SetHeight"},
		{key = "borderBottom", p1 = "BOTTOMLEFT", p2 = "BOTTOMRIGHT", dim = "SetHeight"},
		{key = "borderLeft",   p1 = "TOPLEFT",    p2 = "BOTTOMLEFT",  dim = "SetWidth"},
		{key = "borderRight",  p1 = "TOPRIGHT",   p2 = "BOTTOMRIGHT", dim = "SetWidth"},
	}) do
		local tex = f:CreateTexture(nil, "BORDER")
		tex:SetColorTexture(unpack(DEFAULT_BORDER_COLOR))
		tex:SetPoint(spec.p1, 0, 0)
		tex:SetPoint(spec.p2, 0, 0)
		tex[spec.dim](tex, 1)
		f[spec.key] = tex
	end

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(ICON_SIZE, ICON_SIZE)
	f.icon:SetPoint("LEFT", 3, 0)

	-- Quickslot ring round the icon, dimmed so it doesn't outshine it --
	local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
	bg:SetTexture("Interface/Buttons/UI-EmptySlot-Disabled")
	bg:SetPoint("CENTER", f.icon, "CENTER")
	bg:SetSize(1.5 * ICON_SIZE, 1.5 * ICON_SIZE)
	bg:SetVertexColor(0.5, 0.5, 0.5)
	local edge = f:CreateTexture(nil, "OVERLAY", nil, -1)
	edge:SetTexture("Interface/Buttons/UI-Quickslot2")
	edge:SetSize(1.625 * ICON_SIZE, 1.625 * ICON_SIZE)
	edge:SetPoint("CENTER", f.icon, "CENTER", 0.25, -0.25)
	edge:SetVertexColor(0.5, 0.5, 0.5)
	local mask = f:CreateMaskTexture()
	mask:SetTexture("Interface/FrameGeneral/UIFrameIconMask")
	mask:SetAllPoints(f.icon)
	f.icon:AddMaskTexture(mask)

	f:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
	f:GetHighlightTexture():SetBlendMode("ADD")
	f:GetHighlightTexture():SetAllPoints(f.icon)

	-- Named .Text so the existing colorize/sync code keeps working --
	f.Text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.Text:SetPoint("LEFT", ICON_SIZE + 12, 0)
	f.Text:SetPoint("RIGHT", -2, 0)
	f.Text:SetJustifyH("LEFT")
	f.Text:SetFont("Fonts\\FRIZQT__.TTF", 13)

	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(self.ID)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT[self:GetChecked() and "IG_MAINMENU_OPTION_CHECKBOX_ON"
			or "IG_MAINMENU_OPTION_CHECKBOX_OFF"])
		UpdatePolyCellSelection(self)
	end)

	return f
end

local rpolyCheckButtons = {}
for i = 1, #rpolyVariants do
	rpolyCheckButtons[i] = CreatePolyVariantCell(rpolyScrollChild, rpolyVariants[i][1], i)
end
rpolyScrollChild:SetHeight(math.max(1, math.ceil(#rpolyVariants / COLS) * ROW_STEP))

-- Select All button --
local rpolySelectAll = CreateFrame("Button", nil, rpolyOptionsPanel, "UIPanelButtonTemplate")
rpolySelectAll:SetPoint("BOTTOMLEFT", 20, 15)
rpolySelectAll:SetSize(100,25)
rpolySelectAll:SetText("Select all")
rpolySelectAll:SetScript("OnClick", function(self)
	for i = 1, #rpolyVariants do
		-- Skips the other faction's variant, which is locked off --
		if rpolyCheckButtons[i]:IsEnabled() then
			rpolyCheckButtons[i]:SetChecked(true)
			UpdatePolyCellSelection(rpolyCheckButtons[i])
		end
	end
end)

-- Deselect All button --
local rpolyDeselectAll = CreateFrame("Button", nil, rpolyOptionsPanel, "UIPanelButtonTemplate")
rpolyDeselectAll:SetPoint("BOTTOMLEFT", 135, 15)
rpolyDeselectAll:SetSize(100,25)
rpolyDeselectAll:SetText("Deselect all")
rpolyDeselectAll:SetScript("OnClick", function(self)
	for i = 1, #rpolyVariants do
		rpolyCheckButtons[i]:SetChecked(false)
		UpdatePolyCellSelection(rpolyCheckButtons[i])
	end
end)

--------------------------------------------------------------------
-- Init/Awake AddonLoaded Msg Handling & Loading
--------------------------------------------------------------------
local rpolyListener = CreateFrame("Frame")
rpolyListener:RegisterEvent("ADDON_LOADED")
rpolyListener:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == poly_addon then
		-- Settings beyond the per-variant checkboxes. Empty by default, so
		-- anything unset reads as "on" (see PushCombatPolyOrder) --
		rpolySettings = rpolySettings or {}

		if rpolyOptions == nil then
			-- Adds all polymorph variant IDs to savedvariables as enabled
			rpolyOptions = {}
			for i=1, #rpolyVariants do
				rpolyOptions[i] = {rpolyVariants[i][1], true}
			end
		else
			-- Close up any hole a previous version left behind. Stale entries
			-- used to be dropped by assigning nil, which doesn't shorten the
			-- array -- it leaves a gap that every numeric loop below walks
			-- straight into. Gathered with pairs, since # can't be trusted on a
			-- table with a hole in it --
			local compacted = {}
			for _, entry in pairs(rpolyOptions) do
				if type(entry) == "table" then
					compacted[#compacted + 1] = entry
				end
			end
			rpolyOptions = compacted

			-- Deletes polymorph variant IDs that no longer exist in rpolyVariants
			-- list. table.remove, walking backwards, so the array stays
			-- contiguous -- changing a variant's spell ID is exactly what makes
			-- an entry stale, and that used to error out on the next load --
			for i = #rpolyOptions, 1, -1 do
				local chk = 0
				for l = 1, #rpolyVariants do
					if rpolyOptions[i][1] == rpolyVariants[l][1] then
						chk = 1
					end
				end
				if chk == 0 then
					table.remove(rpolyOptions, i)
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
		
		-- Loop through options and set checkbox state. Bounded by the number of
		-- CELLS, not options -- they should match, but indexing cells by an
		-- options count is how you get a nil cell if they ever don't --
		for i,v in pairs(rpolyOptions) do
			for l = 1, #rpolyCheckButtons do
				if rpolyCheckButtons[l].ID == v[1] and v[2] == true then
					rpolyCheckButtons[l]:SetChecked(true)
				end
			end
		end

		-- The cells carry their selected state in the border, not a tick
		-- box, so the restored state has to be painted on --
		for i = 1, #rpolyCheckButtons do
			UpdatePolyCellSelection(rpolyCheckButtons[i])
		end
		ColorizePolymorphVariantText()

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
end

--------------------------------------------------------------------
-- Create an invisible button for our macro to click.
--  Button creation, named [rpolyButton]
--------------------------------------------------------------------
-- SecureHandlerBaseTemplate as well, so the button can host its own
-- restricted environment and roll the variant during combat -- see the
-- snippet below --
local rpolyBtn = CreateFrame("Button", "rpolyButton", nil,  "SecureActionButtonTemplate,SecureHandlerBaseTemplate")

-- WoW client events we want to know about --
rpolyBtn:RegisterEvent("PLAYER_ENTERING_WORLD")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_START")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_STOP")
rpolyBtn:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
rpolyBtn:RegisterEvent("PLAYER_LEAVE_COMBAT")
rpolyBtn:RegisterEvent("PLAYER_REGEN_ENABLED")
rpolyBtn:RegisterForClicks("LeftButtonDown", "LeftButtonUp" )
rpolyBtn:SetAttribute("type","spell")

--------------------------------------------------------------------
-- Rolling a new variant DURING combat.
--
-- Lua can't touch the button's "spell" attribute in a lockdown, so the
-- variant used to be frozen for the whole fight -- and since Polymorph is
-- a combat spell, that meant every sheep in a fight was the same critter.
-- The old post-combat path rolled once the fight ended, which is the one
-- moment you're not casting it.
--
-- Code running INSIDE the restricted environment has no such limit, so the
-- roll moves there for the duration of a fight. Out of combat nothing
-- changes: Lua still owns the rotation, because it can rewrite the macro
-- and the sandbox cannot.
--
-- The snippet walks a plain comma-separated order that Lua shuffles and
-- pushes in beforehand (see PushCombatPolyOrder), so nothing clever has to
-- happen in there.
--
-- Known limit: EditMacro is unavailable in combat, so the macro's icon and
-- tooltip keep naming the variant from before the fight. Which critter it
-- says is wrong; that it's Polymorph, and its cooldown, stay right.
--------------------------------------------------------------------

-- Blizzard's Wrapped_Click only runs the post-body when the pre-body hands
-- back a message, so that is this one's whole job. Returning nil first
-- leaves the button name alone -- returning false there would swallow the
-- click entirely.
local RPOLY_COMBAT_PRE = [[ return nil, "rpoly" ]]

-- Runs AFTER the click has cast, so it sets up the NEXT press rather than
-- hijacking this one. Only on "LeftButton": the macro clicks this button
-- twice (see polyMacroSrc) and the other arrives as "1", so keying on the
-- name gives exactly one advance per press.
local RPOLY_COMBAT_POST = [[
	if button ~= "LeftButton" then return end
	if self:GetAttribute("rpolyCombatOff") then return end
	local combat = self:GetAttribute("state-rpolycombat")
	if combat ~= 1 and combat ~= "1" then return end
	local order = self:GetAttribute("rpolyOrder")
	if not order or order == "" then return end
	local count = select("#", strsplit(",", order))
	if count < 1 then return end
	local pos = (tonumber(self:GetAttribute("rpolyPos")) or 0) + 1
	if pos > count then pos = 1 end
	self:SetAttribute("rpolyPos", pos)
	local id = tonumber((select(pos, strsplit(",", order))))
	if id then self:SetAttribute("spell", id) end
]]

if SecureHandlerWrapScript and RegisterStateDriver then
	-- The restricted environment can't call InCombatLockdown, so a state
	-- driver tells it when it's allowed to take over --
	RegisterStateDriver(rpolyBtn, "rpolycombat", "[combat] 1; 0")
	SecureHandlerWrapScript(rpolyBtn, "OnClick", rpolyBtn, RPOLY_COMBAT_PRE, RPOLY_COMBAT_POST)
end

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

	-- Combat just ended. The snippet has been rolling the button on its own,
	-- so whatever it landed on is the truth now -- adopt it before anything
	-- else gets a say, then hand the button a fresh order for next time --
	if event == "PLAYER_REGEN_ENABLED" then
		if AdoptCombatPoly() then
			-- The rotation already moved on during the fight; letting the
			-- old post-combat path roll again would just burn a variant --
			polymorphWasCast = false
		end
		PushCombatPolyOrder()
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
-- Paints every cell: its icon, and whether this character has collected
-- the variant. Uncollected ones are desaturated and dimmed rather than
-- printed in red -- the same way an uncollected toy reads in Random Toys
-- and Random Lure, and it survives being read at a glance far better
-- than a colour code. Red is reserved for the one that's unreachable.
-- Also keeps the collection bar honest.
--------------------------------------------------------------------
function ColorizePolymorphVariantText()
	local known, collectable = 0, 0

	for k in pairs(rpolyVariants) do
		local spellId, variantName = rpolyVariants[k][1], rpolyVariants[k][2]
		local cell = rpolyCheckButtons[k]

		-- Faction-locked variants say so, so a greyed-out entry explains
		-- itself rather than looking like something you simply missed --
		local faction = rpolyVariants[k][3]
		local factionSuffix = faction and (" [" .. faction .. "]") or ""

		local spellInfo = C_Spell.GetSpellInfo(spellId)
		if spellInfo and spellInfo["originalIconID"] then
			cell.icon:SetTexture(spellInfo["originalIconID"])
		end

		local impossible = IsPolyVariantImpossible(k)
		local isKnown = IsSpellKnownOrOverridesKnown(spellId) and true or false
		if isKnown then known = known + 1 end
		if not impossible then collectable = collectable + 1 end

		cell.icon:SetDesaturated(not isKnown)
		cell.Text:SetText(variantName .. factionSuffix)
		if impossible then
			-- Wrong faction: not merely uncollected, but unreachable --
			cell.Text:SetTextColor(1, 0.25, 0.25)
		elseif isKnown then
			cell.Text:SetTextColor(1, 1, 1)
		else
			cell.Text:SetTextColor(0.5, 0.5, 0.5)
		end

		-- A variant you can never cast isn't a choice, so it stops being one:
		-- the cell is locked and forced off rather than left tickable into a
		-- rotation it could never contribute to. The tooltip still works --
		-- a disabled button keeps its hover -- so the reason stays readable --
		if impossible then
			if cell:GetChecked() then cell:SetChecked(false) end
			cell:Disable()
		else
			cell:Enable()
		end
		UpdatePolyCellSelection(cell)

		if debugPoly then
			print("=== " .. variantName .. (impossible and " : Wrong faction"
				or (isKnown and " : Usable!" or " : NOT Usable!!"))) end
	end

	-- Counted against what this character could actually collect, so the
	-- other faction's variant isn't held permanently against you --
	rpolyProgressBar:SetMinMaxValues(0, math.max(collectable, 1))
	rpolyProgressBar:SetValue(known)
	if known >= collectable then
		-- All collected reads as a single number in the uncommon green, the
		-- way Blizzard's own collection bars do --
		rpolyProgressText:SetText(tostring(collectable))
		rpolyProgressText:SetTextColor(0.12, 1.0, 0.0)
	else
		rpolyProgressText:SetText(known .. " / " .. collectable)
		rpolyProgressText:SetTextColor(1, 1, 1)
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

	-- Hand the button a fresh order to walk if a fight starts --
	PushCombatPolyOrder()
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
-- Hands the button the order it walks while combat is on.
--
-- Deliberately the FULL set of enabled, known variants rather than what's
-- left of the current pass: Polymorph gets cast a lot in one fight, and
-- being stuck with the two variants that happened to remain would show far
-- less variety than the pool actually holds. Shuffled here, so the sandbox
-- never has to make a judgement call, and the variant already loaded is
-- left out so the first roll of a fight can't repeat it.
--
-- Out of combat only -- SetAttribute is exactly what a lockdown forbids.
--------------------------------------------------------------------
function PushCombatPolyOrder()
	if InCombatLockdown() then return end

	-- The snippet reads this rather than being unwrapped, so "/poly combat"
	-- can switch in-combat rolling off without touching a secure handler --
	rpolyBtn:SetAttribute("rpolyCombatOff", rpolySettings and rpolySettings.combatRotation == false or nil)

	local current = tonumber(rpolyBtn:GetAttribute("spell"))
	local order = {}
	for i = 1, #rpolyOptions do
		local id = rpolyOptions[i][1]
		if rpolyOptions[i][2] == true and IsSpellKnownOrOverridesKnown(id) and id ~= current then
			table.insert(order, id)
		end
	end

	for i = #order, 2, -1 do
		local j = math.random(i)
		order[i], order[j] = order[j], order[i]
	end

	rpolyBtn:SetAttribute("rpolyOrder", table.concat(order, ","))
	rpolyBtn:SetAttribute("rpolyPos", 0)

	if debugPoly then
		print("==== Combat order pushed: " .. #order) end
end

--------------------------------------------------------------------
-- Combat is over: catch Lua up with whatever the snippet rolled to while
-- it couldn't. This is the moment the macro's icon stops naming a variant
-- you stopped casting several sheep ago. Returns true if it adopted
-- something, so the caller knows the rotation already moved on.
--------------------------------------------------------------------
function AdoptCombatPoly()
	if InCombatLockdown() then return false end

	local landed = tonumber(rpolyBtn:GetAttribute("spell"))
	-- prevPolyId is what Lua last chose, so anything else means the snippet
	-- moved it during the fight --
	if not landed or landed == prevPolyId then return false end

	local spellInfo = C_Spell.GetSpellInfo(landed)
	if not spellInfo then return false end

	UpdateRandomPolymorphMacro(spellInfo["name"] .. "(" .. PolymorphNameFromSpellId(landed) .. ")",
		spellInfo["originalIconID"])

	-- It's been cast, so take it out of the remaining pass rather than
	-- letting it come round again straight away --
	for i = 1, #rpolyList do
		if rpolyList[i] == landed then
			table.remove(rpolyList, i)
			break
		end
	end
	prevPolyId = landed

	if debugPoly then
		print("==== Adopted from combat: " .. PolymorphNameFromSpellId(landed)) end

	return true
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
	-- "/poly combat" turns in-combat rolling on/off. It's the one part that
	-- runs inside WoW's restricted environment, where a fault would be
	-- silent, so a switch that doesn't need a reload is worth having --
	local arg = (msg or ""):lower():match("^%s*(%S*)")
	if arg == "combat" then
		rpolySettings = rpolySettings or {}
		rpolySettings.combatRotation = (rpolySettings.combatRotation == false)
		PushCombatPolyOrder()
		print("|cff58C6FARandom Poly|r: rolling a new variant during combat is " ..
			(rpolySettings.combatRotation
				and "|cff40ff40on|r -- the macro icon still can't update until the fight ends."
				or "|cffff4040off|r -- a fight stays on whichever variant was loaded when it started."))
		return
	end

	Settings.OpenToCategory(rpolyCategory:GetID())
end
