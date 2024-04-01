-- sync.lua
-- - テレポート元とテレポート先のチェストの内容を同期させる
-- - プレイヤーが異なるサーフェス間を移動しても、特定のアイテムが常に追跡され、利用可能であることを保証する

local Sync = {}

function Sync.sync_chests()
    -- 各プレイヤーのブラックボックスに関する情報を基に同期処理を行います
    for player_index, player_info in pairs(global.black_boxes) do
        for _, black_box_info in pairs(player_info.black_Box_entities) do
            -- 入口チェストの同期
            local irigutiBefore = black_box_info.iriguti.beforeBox
            local irigutiAfter = black_box_info.iriguti.afterBox
            if irigutiBefore and irigutiAfter and irigutiBefore.valid and irigutiAfter.valid then
                -- テレポート後の入口チェストの内容をテレポート前の入口チェストにコピー
                local contentsAfter = irigutiAfter.get_inventory(defines.inventory.chest).get_contents()
                irigutiBefore.get_inventory(defines.inventory.chest).clear()
                for item, count in pairs(contentsAfter) do
                    irigutiBefore.get_inventory(defines.inventory.chest).insert({name = item, count = count})
                end
            end

            -- 出口チェストの同期
            local degutiBefore = black_box_info.deguti.beforeBox
            local degutiAfter = black_box_info.deguti.afterBox
            if degutiBefore and degutiAfter and degutiBefore.valid and degutiAfter.valid then
                -- テレポート後の出口チェストの内容をテレポート前の出口チェストにコピー
                local contentsAfter = degutiAfter.get_inventory(defines.inventory.chest).get_contents()
                degutiBefore.get_inventory(defines.inventory.chest).clear()
                for item, count in pairs(contentsAfter) do
                    degutiBefore.get_inventory(defines.inventory.chest).insert({name = item, count = count})
                end
            end
        end
    end
end
-- テレポート後の入口チェストの内容を特別カウントボックスにコピー
function Sync.sync_irigutiChest2specialchest()
    -- 各プレイヤーの全てのブラックボックスエンティティに対して処理を行います
    for player_index, player_info in pairs(global.black_boxes) do
        if player_info.black_Box_entities then
            for _, black_box_info in pairs(player_info.black_Box_entities) do
                local irigutiAfter = black_box_info.iriguti.afterBox
                local specialCountBox = black_box_info.specialCountBox
                if irigutiAfter and specialCountBox and irigutiAfter.valid and specialCountBox.valid then
                    -- テレポート後の入口チェストの内容を特別カウントボックスにコピー
                    local contentsAfter = irigutiAfter.get_inventory(defines.inventory.chest).get_contents()
                    irigutiAfter.get_inventory(defines.inventory.chest).clear()
                    for item, count in pairs(contentsAfter) do
                        specialCountBox.get_inventory(defines.inventory.chest).insert({name = item, count = count})
                    end
                end
            end
        end
    end
end



return Sync
