local IGV = InventoryGridView
IGV.util = {}

local util = IGV.util
util.lam = LibAddonMenu2

local function AddColor(control)
    if not control.dataEntry then return end
    if control.dataEntry.data.slotIndex == nil then control.dataEntry.data.quality = 0 end

    local quality = control.dataEntry.data.quality
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)

    local alpha = 1
    if quality ~= nil and quality < IGV.settings.GetMinOutlineQuality() then
        alpha = 0
    end
    local bg = control:GetNamedChild("Bg")
    if bg ~= nil then
      bg:SetColor(r, g, b, 1)
    end
    local outline = control:GetNamedChild("Outline")
    if outline ~= nil then
      outline:SetColor(r, g, b, alpha)
    end
    local highlight = control:GetNamedChild("Highlight")
    if highlight ~= nil then
      highlight:SetColor(r, g, b, 0)
    end
end

--control = ZO_PlayerInventoryBackpack1Row1 etc.
local oldSetHidden
local function ReshapeSlot(control, isGrid, width, height)
    if control == nil then return end

    local ICON_MULT = 0.77
    local textureSet = IGV.settings.GetTextureSet()

    if control.isGrid ~= isGrid then
        control.isGrid = isGrid

        local bg = control:GetNamedChild("Bg")
        local highlight = control:GetNamedChild("Highlight")
        local outline = control:GetNamedChild("Outline")
        local new = control:GetNamedChild("Status")
        local button = control:GetNamedChild("Button")
        local name = control:GetNamedChild("Name")
        local sell = control:GetNamedChild("SellPrice")
        local traitInfo = control:GetNamedChild("TraitInfo")
        --local stat = control:GetNamedChild("StatValue")

        --make sure sell price label stays shown/hidden
        if sell then
            if not oldSetHidden then oldSetHidden = sell.SetHidden end

            sell.SetHidden = function(sell, shouldHide)
                if isGrid and shouldHide then
                    oldSetHidden(sell, shouldHide)
                elseif isGrid then
                    return
                else
                    oldSetHidden(sell, shouldHide)
                end
            end
            --show/hide sell price label
            sell:SetHidden(isGrid)
        end

        --create outline texture for control if missing
        if not outline then
            outline = WINDOW_MANAGER:CreateControl(control:GetName() .. "Outline", control, CT_TEXTURE)
            outline:SetAnchor(CENTER, control, CENTER)
        end
        outline:SetDimensions(height, height)

        if button then
            button:ClearAnchors()
            button:SetDimensions(height * ICON_MULT, height * ICON_MULT)
        end

        if new then new:ClearAnchors() end

        if isGrid and traitInfo ~= nil then
            util.debug("Trait info in grid")
            traitInfo:ClearAnchors()
            traitInfo:SetDimensions(25, 25)
            traitInfo:SetAnchor(TOPRIGHT, control, TOPRIGHT)
            traitInfo:SetDrawTier(DT_HIGH)
        elseif traitInfo ~= nil then
            util.debug("Trait info without grid")
            traitInfo:ClearAnchors()
            traitInfo:SetDimensions(32, 32)
            traitInfo:SetAnchor(RIGHT, sell, LEFT, -5)
        end

        control:SetDimensions(width, height)

        if isGrid == true and new ~= nil then
            util.debug("New item in grid")
            if button ~= nil then
                button:SetAnchor(CENTER, control, CENTER)
            end

            new:SetDimensions(25, 25)
            if button ~= nil then new:SetAnchor(TOPLEFT, button:GetNamedChild("Icon"), TOPLEFT, -5, -5) end
            new:SetDrawTier(DT_HIGH)

            --disable mouse events on status controls
            new:SetMouseEnabled(false)
            new:GetNamedChild("Texture"):SetMouseEnabled(false)

            if name then name:SetHidden(true) end
            --stat:SetHidden(true)

            if highlight ~= nil then
              highlight:SetTexture(textureSet.HOVER)
              highlight:SetTextureCoords(0, 1, 0, 1)
            end
            
            if bg ~= nil then
              bg:SetTexture(textureSet.BACKGROUND)
              bg:SetTextureCoords(0, 1, 0, 1)
            end

            if outline ~= nil then
              if IGV.settings.ShowQualityOutline() then
                  outline:SetTexture(textureSet.OUTLINE)
                  outline:SetHidden(false)
              else
                  outline:SetHidden(true)
              end
            end

            AddColor(control)
        else
            util.debug("Item without grid")
            local LIST_SLOT_BACKGROUND = "EsoUI/Art/Miscellaneous/listItem_backdrop.dds"
            local LIST_SLOT_HOVER = "EsoUI/Art/Miscellaneous/listitem_highlight.dds"

            if button then button:SetAnchor(CENTER, control, TOPLEFT, 70, 26) end

            if new then
                util.debug("But new item")
                new:SetDimensions(32, 32)
                new:SetAnchor(CENTER, control, TOPLEFT, 20, 27)

                --enable mouse events on status controls
                new:SetMouseEnabled(true)
                new:GetNamedChild("Texture"):SetMouseEnabled(true)
            end

            if name then name:SetHidden(false) end
            --if stat then stat:SetHidden(false) end
            outline:SetHidden(true)

            if highlight then
                highlight:SetTexture(LIST_SLOT_HOVER)
                highlight:SetColor(1, 1, 1, 0)
                highlight:SetTextureCoords(0, 1, 0, .625)
            end

            if bg then
                bg:SetTexture(LIST_SLOT_BACKGROUND)
                bg:SetTextureCoords(0, 1, 0, .8125)
                bg:SetColor(1, 1, 1, 1)
            end
        end
    end
end

function util.ReshapeSlots()
    local scrollList = IGV.currentScrollList
    if not scrollList then return end
    local parent = scrollList.contents
    local numControls = parent:GetNumChildren()
    local gridIconSize = IGV.settings.GetGridIconSize()
    local IGVId = IGV.currentIGVId
    local isGrid = IGV.settings.IsGrid(IGVId)
    local isGridFlag = "false"
    if isGrid then
      isGridFlag = "true"
    end
    
    util.debug("Reshape slots on " .. (IGVId or "nil") .. " with flag isGrid ".. isGridFlag)

    local width, height

    if isGrid then
        width = gridIconSize
        height = gridIconSize
    else
        width = scrollList:GetWidth()
        height = scrollList.controlHeight
    end

    --CRAFT_BAG, QUICKSLOT, and BUY_BACK don't have the same child element pattern, have to start at 1 instead of 2
    if IGVId == 4 or IGVId == 5 or IGVId == 7 then
        for i = 1, numControls do
            ReshapeSlot(parent:GetChild(i), isGrid, width, height)
        end

        for i = 1, numControls do
            parent:GetChild(i).isGrid = isGrid
        end

        if scrollList.dataTypes[1] then
            for _, v in pairs(scrollList.dataTypes[1].pool["m_Free"]) do
                ReshapeSlot(v, isGrid, width, height)
            end
        end

        if scrollList.dataTypes[2] then
            for _, v in pairs(scrollList.dataTypes[2].pool["m_Free"]) do
                ReshapeSlot(v, isGrid, width, height)
            end
        end
    else
        for i = 2, numControls do
            ReshapeSlot(parent:GetChild(i), isGrid, width, height)
        end

        for i = 2, numControls do
            parent:GetChild(i).isGrid = isGrid
        end

        for _, v in pairs(scrollList.dataTypes[1].pool["m_Free"]) do
            ReshapeSlot(v, isGrid, width, height)
        end
    end
end

function util.debug(message)
    local settings = IGV.settings
    
    if not settings.IsDebug() then return end
    
    d("IGV: " .. message)
end