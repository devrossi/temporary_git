generate_tiles = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_tiles.default_json = {
  description = "grass",
  negative_description = "",
  reference_image = "Yes",
  view = "high top-down",
  text_guidance_scale = 8,
  color_image = "No",
  init_image = "No",
  init_image_strength = 300,
  tiling_position = "north-east",
  tiling_image = "",
  use_tiling = false,
  vertical_tiling = false,
  horizontal_tiling = false,
  inpainting_image = "",
  -- inpainting = "No",
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_tiles",
  use_selection = false,
  selection_origin = { 0, 0 },
  max_size = { 64, 64 },
  image_size = { width = 64, height = 64 },
  output_method = "Modify current layer"
}

generate_tiles.dialog_json = {
  guidance = {
    view = { "high top-down", "side" },
  },
  documentation = "https://www.pixellab.ai/docs/tools/map-tiles"
}

generate_tiles.current_json = createJson.deepcopy(generate_tiles.default_json)

function generate_tiles.prepare_image(model, create_new_frames)
  if model.current_json["output_method"] == "New frame" then
    return prepareForGeneration.prepare_image(model, "Generate - Tiles")
  else
    return prepareForGeneration.prepare_same_image(model, "Generate - Tiles")
  end
end

function generate_tiles.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif model.current_json["use_selection"] == false and model.current_json["max_size"][1] == 64 and (app.activeSprite.width ~= 64 or app.activeSprite.height ~= 64) then
    return app.alert("Canvas must be equal to 64x64 if you don't use 'Custom size' option or 'Paint in selection'")
  elseif (model.current_json["use_selection"] == false and model.current_json["max_size"][1] == 100 and app.activeSprite.width * app.activeSprite.height > 100 * 100) then
    return app.alert("Canvas area must be equal or less than 100x100 if you don't use 'Paint in selection' option")
  elseif (model.current_json["use_selection"] == false and model.current_json["max_size"][1] == 160 and app.activeSprite.width * app.activeSprite.height > 160 * 160) then
    return app.alert("Canvas area must be equal or less than 160x160 if you don't use 'Paint in selection' option")
  elseif (model.current_json["use_selection"] and app.activeSprite.selection.isEmpty) then
    return app.alert("You need to select/marquee an area when using the 'Paint in selection' option")
  end

  local data_images = getImage.get_images_from_model_from_json(model.current_json)
  if data_images["inpainting_image"]:isPlain(Color { r = 0, g = 0, b = 0, a = 255 }) then
    local result = app.alert { title = "Missing inpainting", text = "You need to draw in the inpaint layer to generate tiles", buttons = { "OK", "Help" } }

    if result == 2 then
      local url = "https://www.pixellab.ai/docs/guides/map-tiles"
      -- Open the URL in the default web browser
      if os.execute("start " .. url) == nil then
        if os.execute("xdg-open " .. url) == nil then
          if os.execute("open " .. url) == nil then
            print("Failed to open the URL.")
          end
        end
      end
    end
    return
  end

  if model.current_json["use_selection"] then
    model.current_json["selection_origin"][1] = app.activeSprite.selection.origin.x
    model.current_json["selection_origin"][2] = app.activeSprite.selection.origin.y
    if model.current_json["max_size"][1] == 64 then
      model.current_json["image_size"]["width"] = model.current_json["max_size"][1]
      model.current_json["image_size"]["height"] = model.current_json["max_size"][2]
    else
      model.current_json["image_size"]["width"] = app.activeSprite.selection.bounds.width
      model.current_json["image_size"]["height"] = app.activeSprite.selection.bounds.height
    end
  else
    model.current_json["image_size"]["width"] = app.activeSprite.width
    model.current_json["image_size"]["height"] = app.activeSprite.height
  end
  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create_with_size(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(model.current_json))

  if jsonData == nil then
    return
  end

  local cels = generate_tiles.prepare_image(model, true)

  mask.move_mask_to_top()

  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-tiles", cels, dlg_title, dlg_type)
end

local previous_origin = nil
local previous_bounds = nil
local listenerCode = nil
local event_sprite = nil
function generate_tiles.onClose(model)
  if event_sprite ~= nil then
    event_sprite.events:off(listenerCode)
  end
  listenerCode = nil
  event_sprite = nil
end

function generate_tiles.update_selection(ev)
  if ev.fromUndo then
    return
  end
  if generate_tiles.current_json["use_selection"] and (previous_origin == nil or previous_bounds == nil or previous_origin.x ~= app.activeSprite.selection.origin.x or previous_origin.y ~= app.activeSprite.selection.origin.y or
        app.activeSprite.selection.bounds.width ~= previous_bounds.width or app.activeSprite.selection.bounds.height ~= previous_bounds.height) then
    if app.activeSprite.selection.bounds.width ~= 0 and app.activeSprite.selection.bounds.height ~= 0 then
      if generate_tiles.current_json["max_size"][1] == 64 then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
          generate_tiles.current_json["max_size"][1], generate_tiles.current_json["max_size"][2])
        app.activeSprite.selection:select(selection_rectangle)
        app.refresh()
      else
        local maxArea = generate_tiles.current_json["max_size"][1] * generate_tiles.current_json["max_size"][2]

        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
          app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.width < 32 then
          selection_rectangle.width = 32
        end
        if app.activeSprite.selection.bounds.height < 32 then
          selection_rectangle.height = 32
        end
        if selection_rectangle.height * selection_rectangle.width > maxArea then
          local ratio = selection_rectangle.width / selection_rectangle.height
          selection_rectangle.height = math.sqrt(maxArea / ratio)
          selection_rectangle.width = ratio * selection_rectangle.height
        end

        app.activeSprite.selection:select(selection_rectangle)
        app.refresh()
      end

      previous_origin = app.activeSprite.selection.origin
      previous_bounds = app.activeSprite.selection.bounds
    end
  end
end

function generate_tiles.openDialog(model)
  generate_tiles.current_json = model.current_json
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end

  if app.activeSprite ~= nil then
    if listenerCode == nil then
      event_sprite = app.activeSprite
      listenerCode = event_sprite.events:on('change', generate_tiles.update_selection)
    end

    if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
      app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
    end
    -- mask.fill_layer(app.activeSprite, "Inpainting")
  end
end

return generate_tiles
