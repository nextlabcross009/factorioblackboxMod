-- teleport.lua
-- このファイルの責務：
-- - プレイヤーのテレポート処理の実行
-- - カスタムサーフェスの生成と管理
local Gui = require("gui")
local Initialize = require("initialize")
local CreateEntity = require("createEntity")
local Blackbox = require("blackbox")

local Teleport = {}



local function findIrigutiEntities(surface)
    local boxes = surface.find_entities_filtered{name = "irigutiBox"}
    local ramps = surface.find_entities_filtered{name = "irigutiRamp"}
    -- 複数ある場合でも、最初のエンティティを返します。
    return boxes[1], ramps[1]
end

local function findDegutiEntities(surface)
    local boxes = surface.find_entities_filtered{name = "degutiBox"}
    local ramps = surface.find_entities_filtered{name = "degutiRamp"}
    -- 複数ある場合でも、最初のエンティティを返します。
    return boxes[1], ramps[1]
end

local function findSpecialCountBoxEntities(surface)
    local specialCountBox = surface.find_entities_filtered{name = "special-count-box"}
    -- 特別カウントボックスが複数ある場合でも、全てのエンティティを返します。
    return specialCountBox
end

function Teleport.create_custom_surface(player,event)
    local player_index = player.index
    local surface_name = "black-box-surface-" .. player_index
    local irigutiBox, degutiBox, irigutiRamp, degutiRamp, tSpecialCountBox, new_surface
    local black_box_entity_number = event.created_entity.unit_number

    player.print("サーフェス作成開始。")
    if game.surfaces[surface_name] then
        player.print("  game.surfaces[surface_name]はあるよ　：　 ".. tostring(game.surfaces[surface_name].name))
    end
    if not game.surfaces[surface_name] then
        -- サーフェス作成時の設定
        local map_gen_settings = {
            terrain_segmentation = "very-high",
            water = "none",
            autoplace_controls = {
                ["coal"] = { frequency = "none", size = "none" },
                ["stone"] = { frequency = "none", size = "none" },
                ["iron-ore"] = { frequency = "none", size = "none" },
                ["copper-ore"] = { frequency = "none", size = "none" },
                ["uranium-ore"] = { frequency = "none", size = "none" },
                ["crude-oil"] = { frequency = "none", size = "none" },
                ["trees"] = { frequency = "none", size = "none" },
                ["enemy-base"] = { frequency = "none", size = "none" },
            },
            width = 32,
            height = 32
        }
        player.print("  サーフェスを作成途中。")
        new_surface = game.create_surface(surface_name, map_gen_settings)
        new_surface.request_to_generate_chunks({x=0, y=0}, 1)
        new_surface.force_generate_chunk_requests()

        -- チェストの設置
        irigutiBox = CreateEntity.CreateEntitySurface(
            new_surface,player_index,"irigutiBox",
            {-15.5, 0},
            player.force,
            false,
            black_box_entity_number)

        degutiBox = CreateEntity.CreateEntitySurface(
            new_surface,player_index,"degutiBox",
            {15.5, 0},
            player.force,
            false,
            black_box_entity_number)


        -- ランプの設置
        irigutiRamp = CreateEntity.CreateEntitySurface(
            new_surface,player_index,"irigutiRamp",
            {irigutiBox.position.x,irigutiBox.position.y - 1},
            player.force,
            false,
            black_box_entity_number)

        degutiRamp = CreateEntity.CreateEntitySurface(
            new_surface,player_index,"degutiRamp",
            {degutiBox.position.x,
            degutiBox.position.y - 1},
            player.force,
            false,
            black_box_entity_number)

        -- special-count-boxの設置
        tSpecialCountBox = CreateEntity.CreateEntitySurface(
            new_surface,player_index,"special-count-box",
            {irigutiBox.position.x + 1, irigutiBox.position.y},
            player.force,
            false,
            black_box_entity_number)

        player.print("サーフェスを作成しました。")
    else
        new_surface = game.surfaces[surface_name]
        player.print("既存のサーフェスがありました: " .. tostring(new_surface.name))

        -- 既存のサーフェスでチェストとランプを取得
        irigutiBox, irigutiRamp = findIrigutiEntities(new_surface)
        degutiBox, degutiRamp = findDegutiEntities(new_surface)
        tSpecialCountBox = findSpecialCountBoxEntities(new_surface)
    end
    -- 新しいblack_Box_entityの作成
    local black_box_entity = {
        black_box_number = nil,  -- この値は後で設定されます
        setRecipe = nil,
        electricityConsumption = nil,
        assemblyPartsBox = nil,
        black_boxes_surface = new_surface,
        iriguti = {
            beforeBox = nil,  -- これらの値は後で設定されます
            afterBox = irigutiBox,
            beforeRamp = nil,
            afterRamp = irigutiRamp,
        },
        deguti = {
            beforeBox = nil,  -- これらの値は後で設定されます
            afterBox = degutiBox,
            beforeRamp = nil,
            afterRamp = degutiRamp,
        },
        specialCountBox = tSpecialCountBox,
    }

    -- ここでグローバル構造体に情報を格納
    return black_box_entity
end




function Teleport.teleport_player(player, ramp_name,event)
    local player_index = player.index
    local black_box_info = global.black_boxes[player_index]


    if not black_box_info or not black_box_info.black_Box_entities or #black_box_info.black_Box_entities == 0 then
        player.print("テレポート情報が見つかりません。")
        return
    end

    -- #TODO ここでblack_Box_entitiesから現在のエンティティを取得するロジックが必要 
    --    local current_entity_info = black_box_info.black_Box_entities[1] -- 仮に最初のエンティティを使用
    local current_entity_info = Blackbox.GetRelatedBlackBoxEntity(player_index,event) -- 仮に最初のエンティティを使用

    local destination_surface, destination_position

    if current_entity_info == nil then
        return
    end

    if ramp_name == "irigutiRamp" then
        if global.player_positions[player_index] ~= "after" then
            destination_surface = current_entity_info.black_boxes_surface
            destination_position = {x = current_entity_info.iriguti.afterBox.position.x, y = current_entity_info.iriguti.afterBox.position.y - 2}
            global.player_positions[player_index] = "after"
        else
            destination_surface = black_box_info.surface.return_surfaces
            destination_position = {x = current_entity_info.iriguti.beforeBox.position.x, y = current_entity_info.iriguti.beforeBox.position.y - 2}
            global.player_positions[player_index] = "before"
        end
    elseif ramp_name == "degutiRamp" then
        if global.player_positions[player_index] ~= "after" then
            destination_surface = current_entity_info.black_boxes_surface
            destination_position = {x = current_entity_info.deguti.afterBox.position.x, y = current_entity_info.deguti.afterBox.position.y - 2}
            global.player_positions[player_index] = "after"
        else
            destination_surface = black_box_info.surface.return_surfaces
            destination_position = {x = current_entity_info.deguti.beforeBox.position.x, y = current_entity_info.deguti.beforeBox.position.y - 2}
            global.player_positions[player_index] = "before"
        end
    end

    if player.character then
        player.teleport(destination_position, destination_surface)
    end
end





function Teleport.return_player(player)
    -- player_indexを使用して、プレイヤー固有の情報にアクセス
    local player_index = player.index
    
    -- global.black_boxesからプレイヤー固有のブラックボックス情報を取得
    if global.black_boxes and global.black_boxes[player_index] then
        local black_box_info = global.black_boxes[player_index]
        
        -- リターンポジションとリターンサーフェスを取得
        local return_position = black_box_info.surface.return_positions
        local return_surfaces = black_box_info.surface.return_surfaces
        
        -- プレイヤーを元のサーフェスにテレポート
        if player.character and return_surfaces and return_surfaces.valid then
            player.teleport(return_position, return_surfaces)
        end
    
    end
end


return Teleport
