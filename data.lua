data:extend({
-- 組み立て機の定義
  {
    type = "assembling-machine",
    name = "black-box-assembler",
    icon = "__BlackBox__/graphics/icons/black-box-assembler.png",
    icon_size = 64,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    minable = {mining_time = 0.1, result = "black-box-assembler"},
    max_health = 300,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    alert_icon_shift = util.by_pixel(-3, -12),
    collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
    selection_box = {{-1, -1}, {1, 1}},
    animation = {
      filename = "__BlackBox__/graphics/entity/black-box-assembler/black-box-assembler.png",
      width = 108,
      height = 114,
      frame_count = 32,
      line_length = 8,
      animation_speed = 0.5,
      shift = util.by_pixel(0, 2),
      scale = 0.5
    },
    -- advanced-crafting を追加して組み立て機3のレシピに対応
    crafting_categories = {"crafting", "advanced-crafting", "crafting-with-fluid"},
    crafting_speed = 1,
    energy_source = {
      type = "void",
    },
    energy_usage = "150kW",
    ingredient_count = 4,
    module_specification = {
      module_slots = 2
    },
    allowed_effects = {"consumption", "speed", "productivity", "pollution"},
    fluid_boxes =
    {
      {
        production_type = "input",
        pipe_picture = assembler2pipepictures(),
        pipe_covers = pipecoverspictures(),
        base_area = 10,
        base_level = -1,
        pipe_connections = {{ type="input", position = {0, -2} }}
      },
      {
        production_type = "output",
        pipe_picture = assembler2pipepictures(),
        pipe_covers = pipecoverspictures(),
        base_area = 10,
        base_level = 1,
        pipe_connections = {{ type="output", position = {0, 2} }}
      },
  },
  -- 以降のアイテム、レシピ定義は変更なし
},
  -- アイテムの定義
  {
    type = "item",
    name = "black-box-assembler",
    icon = "__BlackBox__/graphics/icons/black-box-assembler.png",
    icon_size = 64,
    subgroup = "production-machine",
    order = "a[assembling-machine-1]",
    place_result = "black-box-assembler",
    stack_size = 50
  },
  -- レシピの定義
{
    type = "recipe",
    name = "black-box-crafting-recipe",
    enabled = true,
    ingredients = {
      {type="item", name="iron-plate", amount=10},
      {type="item", name="electronic-circuit", amount=5}
    },
    result = "black-box-assembler",
    energy_required = 0.1
  },
  -- 流体を必要とするレシピの定義
  {
    type = "recipe",
    name = "black-box-fluid-crafting-recipe",
    enabled = true,
    category = "chemistry", -- レシピのカテゴリを化学に変更
    subgroup = "fluid-recipes", -- サブグループを定義
    ingredients = {
      {type="fluid", name="crude-oil", amount=10},
      {type="item", name="iron-plate", amount=5}
    },
    results = {
      {type="fluid", name="petroleum-gas", amount=5},
      {type="fluid", name="steam", amount=100, temperature=165}
    },
    energy_required = 1,
    icons = {
      {
        icon = "__base__/graphics/icons/fluid/crude-oil.png",
        icon_size = 64
      }
    }
  },
})

data:extend({
  {
    type = "container",  -- エンティティのタイプをコンテナに設定します。
    name = "special-count-box",  -- エンティティの内部名です。これは他のプロトタイプと一意でなければなりません。
    icon = "__base__/graphics/icons/wooden-chest.png",  -- エンティティのアイコンのパスです。
    icon_size = 64,  -- アイコンのサイズをピクセルで指定します。Factorioの基準に従う必要があります。
    flags = {"placeable-neutral", "player-creation"},  -- エンティティのフラグを設定します。これはゲーム内でエンティティがプレイヤーによって設置されることを可能にします。
    max_health = 100,  -- エンティティの最大ヒットポイントを設定します。
    corpse = "small-remnants",  -- エンティティが破壊された時に残る残骸のタイプを設定します。
    open_sound = { filename = "__base__/sound/wooden-chest-open.ogg", volume=0.65 },  -- エンティティを開いた際のサウンドを設定します。
    close_sound = { filename = "__base__/sound/wooden-chest-close.ogg", volume = 0.7 },  -- エンティティを閉じた際のサウンドを設定します。
    vehicle_impact_sound =  { filename = "__base__/sound/car-wood-impact.ogg", volume = 0.65 },  -- 車両がエンティティに衝突した際のサウンドを設定します。
    picture = {  -- エンティティの画像を設定します。
      filename = "__base__/graphics/entity/wooden-chest/wooden-chest.png",  -- 画像ファイルのパスです。
      priority = "extra-high",  -- 描画の優先順位を設定します。
      width = 32,  -- 画像の幅をピクセルで設定します。
      height = 36,  -- 画像の高さをピクセルで設定します。元のエラーメッセージに基づいて修正されています。
      shift = {0.0, -0.14}  -- エンティティの画像を中心からどれだけずらすかを設定します。
    },
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    circuit_wire_connection_point = circuit_connector_definitions["chest"].points,  -- 電子回路ネットワークへの接続点を設定します。
    circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,  -- 電子回路のコネクタスプライトを設定します。
    circuit_wire_max_distance = default_circuit_wire_max_distance,  -- 回路ワイヤーが接続できる最大距離を設定します。
    inventory_size = 16  -- エンティティが持つインベントリのサイズを設定します。
  },
  
  {
    type = "item",
    name = "special-count-box",
    icon = "__base__/graphics/icons/wooden-chest.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "storage",
    order = "a[items]-a[special-count-box]",
    place_result = "special-count-box",
    stack_size = 50
  },
})

data:extend({
  -- 入口用チェスト（irigutiBox）
  {
    type = "container",
    name = "irigutiBox",
    icon = "__BlackBox__/graphics/icons/irigutiBox.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    max_health = 200,
    corpse = "small-remnants",
    open_sound = { filename = "__base__/sound/wooden-chest-open.ogg", volume=0.65 },
    close_sound = { filename = "__base__/sound/wooden-chest-close.ogg", volume = 0.7 },
    vehicle_impact_sound =  { filename = "__base__/sound/car-wood-impact.ogg", volume = 0.65 },
    picture = {
      filename = "__BlackBox__/graphics/entity/irigutiBox/irigutiBox.png",
      priority = "extra-high",
      width = 32,
      height = 36,
      shift = {0.0, -0.14}
    },
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
    circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
    circuit_wire_max_distance = default_circuit_wire_max_distance,
    inventory_size = 16
  },
  {
    type = "item",
    name = "irigutiBox",
    icon = "__BlackBox__/graphics/icons/irigutiBox.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "storage",
    order = "a[items]-a[irigutiBox]",
    place_result = "irigutiBox",
    stack_size = 50
  },
  -- 出口用チェスト（degutiBox）
  {
    type = "container",
    name = "degutiBox",
    icon = "__BlackBox__/graphics/icons/degutiBox.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    max_health = 200,
    corpse = "small-remnants",
    open_sound = { filename = "__base__/sound/wooden-chest-open.ogg", volume=0.65 },
    close_sound = { filename = "__base__/sound/wooden-chest-close.ogg", volume = 0.7 },
    vehicle_impact_sound =  { filename = "__base__/sound/car-wood-impact.ogg", volume = 0.65 },
    picture = {
      filename = "__BlackBox__/graphics/entity/degutiBox/degutiBox.png",
      priority = "extra-high",
      width = 32,
      height = 36,
      shift = {0.0, -0.14}
    },
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
    circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
    circuit_wire_max_distance = default_circuit_wire_max_distance,
    inventory_size = 16
  },
  {
    type = "item",
    name = "degutiBox",
    icon = "__BlackBox__/graphics/icons/degutiBox.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "storage",
    order = "a[items]-a[degutiBox]",
    place_result = "degutiBox",
    stack_size = 50
  }
})

-- 入口ランプと出口ランプ
data:extend({
  {
      type = "lamp",
      name = "irigutiRamp",
      icon = "__BlackBox__/graphics/icons/irigutiRamp.png",
      icon_size = 64, icon_mipmaps = 4,
      max_health = 100,
      corpse = "lamp-remnants",
      collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
      selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
      vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
      energy_source = {
        type = "void",
      },
      energy_usage_per_tick = "5KW",
      light = {intensity = 0.9, size = 40, color = {r=0.1,g=0.5,b=1.0}},
      picture_off = {
          filename = "__BlackBox__/graphics/entity/irigutiRamp/lamp.png",
          priority = "high",
          width = 42,
          height = 36,
          frame_count = 1,
          axially_symmetrical = false,
          direction_count = 1,
          shift = {0, 0},
      },
      picture_on = {
          filename = "__BlackBox__/graphics/entity/irigutiRamp/lamp.png",
          priority = "high",
          width = 42,
          height = 36,
          frame_count = 1,
          axially_symmetrical = false,
          direction_count = 1,
          shift = {0, 0},
      },
  },
  {
      type = "lamp",
      name = "degutiRamp",
      icon = "__BlackBox__/graphics/icons/degutiRamp.png",
      icon_size = 64, icon_mipmaps = 4,
      max_health = 100,
      corpse = "lamp-remnants",
      collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
      selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
      vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
      energy_source = {
        type = "void",
      },
      energy_usage_per_tick = "5KW",
      light = {intensity = 0.9, size = 40, color = {r=1.0,g=0.5,b=0.1}},
      picture_off = {
          filename = "__BlackBox__/graphics/entity/degutiRamp/lamp.png",
          priority = "high",
          width = 42,
          height = 36,
          frame_count = 1,
          axially_symmetrical = false,
          direction_count = 1,
          shift = {0, 0},
      },
      picture_on = {
          filename = "__BlackBox__/graphics/entity/degutiRamp/lamp.png",
          priority = "high",
          width = 42,
          height = 36,
          frame_count = 1,
          axially_symmetrical = false,
          direction_count = 1,
          shift = {0, 0},
      },
  },
  -- irigutiRampのアイテム定義
  {
    type = "item",
    name = "irigutiRamp",
    icon = "__BlackBox__/graphics/icons/irigutiRamp.png",
    icon_size = 64,
    subgroup = "energy",
    order = "a[light]-a[small-lamp]",
    place_result = "irigutiRamp",
    stack_size = 50
  },
  -- degutiRampのアイテム定義
  {
    type = "item",
    name = "degutiRamp",
    icon = "__BlackBox__/graphics/icons/degutiRamp.png",
    icon_size = 64,
    subgroup = "energy",
    order = "a[light]-a[small-lamp]",
    place_result = "degutiRamp",
    stack_size = 50
  },
-- manufactured-parts-boxのエンティティ定義
{
  type = "logistic-container",
  name = "assemblyPartsBox",
  icon = "__BlackBox__/graphics/icons/assemblyPartsBox.png",
  icon_size = 64,
  flags = {"placeable-neutral", "placeable-player", "player-creation"},
  max_health = 150,
  corpse = "small-remnants",
  collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
  inventory_size = 200,
  logistic_mode = "requester",
  picture = {
    filename = "__BlackBox__/graphics/entity/assemblyPartsBox/assemblyPartsBox.png",
    priority = "extra-high",
    width = 34,
    height = 38,
    shift = {0.0, 0.0}
  },
  circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
  circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
  circuit_wire_max_distance = default_circuit_wire_max_distance
},

-- manufactured-parts-boxのアイテム定義
{
  type = "item",
  name = "assemblyPartsBox",
  icon = "__BlackBox__/graphics/icons/assemblyPartsBox.png",
  icon_size = 64,
  subgroup = "storage",
  order = "b[storage]-c[assemblyPartsBox]",
  place_result = "assemblyPartsBox",
  stack_size = 50
}

})