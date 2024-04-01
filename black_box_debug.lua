--Black_box_debug.lua

local Black_box_debug = {}

local addLabelList = {}

local debug_flow


function Black_box_debug.Init()
    addLabelList = addLabelList or {}
end
--初期アイテムの設定
function Black_box_debug.give_initial_items(player)
    -- Initial items to give to the player
    local initial_items = {
        ["black-box-assembler"] = 10,
        ["small-electric-pole"] = 100,
        ["transport-belt"] = 50,
        ["fast-transport-belt"] = 50,
        ["express-transport-belt"] = 50,
        ["iron-ore"] = 200
    }

    for item_name, item_count in pairs(initial_items) do
        player.insert({name = item_name, count = item_count})
    end
end

--1秒に１一度呼ばれる
function Black_box_debug.cycle(player)
    Black_box_debug.open_debug_custom_gui(player)

    if not addLabelList then
        return
    end

    -- リスト内の関数を実行
    for _, func in ipairs(addLabelList) do
        func()  -- 関数を呼び出し
    end

end
function Black_box_debug.SetGuiNum(setNumFunc)
    table.insert(addLabelList, setNumFunc)
end
local function tableToString(tbl, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)  -- インデントを生成
    local result = ""

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            result = result .. indent .. tostring(key) .. ":\n" .. tableToString(value, indentLevel + 1)  -- 再帰的に処理
        else
            result = result .. indent .. tostring(key) .. ": " .. tostring(value) .. "\n"
        end
    end

    return result
end
local function updateOrAddLabel(parent, name, value,en_open_table)
    local label_name = "label_" .. name
    local caption
    
    if type(value) == "table" then
        if next(value) == nil then
            caption = name .. " : {}"
        else
            if en_open_table then
                caption = name .. " : " .. tableToString(value)
            else
                caption = name .. " : " .. tostring(value.name or "table")
            end
        end
    elseif value == nil then
        caption = name .. " : NULL"
    else
        caption = name .. " : " .. tostring(value)
    end
    
    if parent[label_name] then
        parent[label_name].caption = caption
    else
        parent.add{type="label", name=label_name, caption=caption}
    end
end
--デバッグ用のGUIにラベルを追加en_open_tableはテーブルだった場合、中身を確認するか否か
function Black_box_debug.AddLabel(name, value,en_open_table)
    if not debug_flow then
        return
    end
    updateOrAddLabel(debug_flow, name, value,en_open_table)
end

--デバッグ用のGUIにラベルを追加en_open_tableはテーブルだった場合、中身を確認するか否か
function Black_box_debug.AddText(text)
    if not debug_flow then
        return
    end
    if not text then
        return
    end
    updateOrAddLabel(debug_flow,text,"",false)
end

local function debug_print_global_variables_to_gui(player_index, parent)
    local player = game.players[player_index]
    local black_box_info = global.black_boxes[player_index]

    updateOrAddLabel(parent, "Debug Print Call # :", global.debug_print_counter,false)
    -- 各変数をGUIに表示または更新
    updateOrAddLabel(parent, "global.is_counting :", global.is_counting,false)

    -- black_Box_entitiesの情報をGUIに表示または更新
    if black_box_info and black_box_info.black_Box_entities then
        for index, entity_info in ipairs(black_box_info.black_Box_entities) do
            updateOrAddLabel(parent, "Black_Box_Entity index#" .. index, "",false)
            updateOrAddLabel(parent, "  Number", entity_info.black_box_number,false)
            updateOrAddLabel(parent, "  Set Recipe", entity_info.setRecipe,false)
            updateOrAddLabel(parent, "  Electricity Consumption", entity_info.electricityConsumption,false)
            updateOrAddLabel(parent, "  AssemblyPartsBox", entity_info.assemblyPartsBox,false)
            updateOrAddLabel(parent, "  Black Boxes Surface", entity_info.black_boxes_surface,false)
            if entity_info.iriguti then
                updateOrAddLabel(parent, "  Iriguti Before Box", entity_info.iriguti.beforeBox,false)
                updateOrAddLabel(parent, "  Iriguti After Box", entity_info.iriguti.afterBox,false)
            end
            if entity_info.deguti then
                updateOrAddLabel(parent, "  Deguti Before Box", entity_info.deguti.beforeBox,false)
                updateOrAddLabel(parent, "  Deguti After Box", entity_info.deguti.afterBox,false)
            end
            if entity_info.specialCountBox then
                updateOrAddLabel(parent, "  Special Count Box", entity_info.specialCountBox,false)
            end
        end
    end
    if global.selected_recipe and global.selected_recipe[player_index] then
        updateOrAddLabel(parent, "  Selected Recipe", global.selected_recipe[player_index],false)
    end
end
function Black_box_debug.open_debug_custom_gui(player)
    global.debug_print_counter = (global.debug_print_counter) + 1

    if not player.gui.left.debug_custom_gui_frame then
        local debug_frame = player.gui.left.add{type="frame", name="debug_custom_gui_frame", caption="Debug Custom GUI"}
        debug_flow = debug_frame.add{type="flow", name="debug_flow", direction="vertical"}
        debug_print_global_variables_to_gui(player.index, debug_flow)
    else
        debug_flow = player.gui.left.debug_custom_gui_frame.debug_flow
        debug_print_global_variables_to_gui(player.index, debug_flow)
    end
    --player.print("Debug Custom GUIを更新または作成しました。")
end


return Black_box_debug
