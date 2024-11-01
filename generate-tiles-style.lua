generate_tiles_style = {}

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_tiles_style.default_json = {
  description = "forest",
  negative_description = "mixels. amateur",
  text_guidance_scale = 8,
  color_image = "No",
  init_image = "No",
  init_image_strength = 300,
  image_size = { width = 64, height = 64 },
  -- inpainting = "No",
  view = "high top-down",
  style_image = "No",
  style_image_size = { width = 64, height = 64 },
  style_guidance_scale = 1,
  inpainting_image = "",
  seed = "0",
  map_tile = true,
  force_colors = false,
  isometric = false,
  oblique_projection = false,
  map_zoom = "16x16",
  -- blur= 4,
  -- n_repaint= 4,
  use_selection = false,
  selection_origin = { 0, 0 },
  max_size = { 64, 64 },
  output_method = "New layer with changes",
  model_name = "generate_tiles_style"
}

generate_tiles_style.dialog_json = {
  guidance = {
    view = { "high top-down", "side" },
  },
  warning_custom_size = true,
  color_image = { options = { "Reference image", "Current image", "Color palette", "No" }, reference_image = "style_image" }
}

generate_tiles_style.current_json = createJson.shallowcopy(generate_tiles_style.default_json)

function generate_tiles_style.prepare_image(model, create_new_frames)
  if model.current_json["output_method"] == "New frame" then
    return prepareForGeneration.prepare_image(model, "Generate - Tiles Style")
  else
    return prepareForGeneration.prepare_same_image(model, "Generate - Tiles Style")
  end
end

function generate_tiles_style.check_size()
  -- (app.activeSprite.width == 128 and app.activeSprite.height == 128) or
  return (app.activeSprite.width == 64 and app.activeSprite.height == 64) == false
end

function generate_tiles_style.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif model.current_json["use_selection"] == false and generate_tiles_style.check_size() and model.current_json["max_size"][1] == 64 and model.current_json["max_size"][2] == 64 then
    return app.alert("Canvas must be equal to 64x64 if you don't use 'Paint in selection'")
  elseif model.current_json["use_selection"] and (app.activeSprite.selection.bounds.width == 0 or app.activeSprite.selection.bounds.height == 0) then
    return app.alert("You need to use the selection/marquee tool when using paint in selection")
  elseif (model.current_json["isometric"] or model.current_json["oblique_projection"]) and model.current_json["view"] ~= "high top-down" then
    return app.alert("Isometric and oblique projection must have view: 'high top down'")
  end

  if model.current_json["use_selection"] then
    local selection_rec = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
      app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
    if selection_rec.width % 2 == 1 then
      selection_rec.width = selection_rec.width - 1
    end
    if selection_rec.height % 2 == 1 then
      selection_rec.height = selection_rec.height - 1
    end
    app.activeSprite.selection:select(selection_rec)
  end

  local data_images = getImage.get_images_from_model_from_json(model.current_json)
  local prev_init_strength = model.current_json["init_image_strength"]
  local fake_init_image = false
  if (data_images["inpainting_image"] ~= nil and data_images["inpainting_image"] == "" or data_images["inpainting_image"]:isPlain(Color { r = 0, g = 0, b = 0, a = 255 })) then
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
  elseif model.current_json["init_image"] == "No" then
    model.current_json["init_image_strength"] = 1
    model.current_json["init_image"] = "Yes"
    fake_init_image = true
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

  if data_images["style_image"] ~= nil and data_images["style_image"] ~= "No" and data_images["style_image"] ~= "" then
    model.current_json["style_image_size"]["width"] = data_images["style_image"].width
    model.current_json["style_image_size"]["height"] = data_images["style_image"].height
  else
    model.current_json["style_image_size"]["width"] = model.current_json["image_size"]["width"]
    model.current_json["style_image_size"]["height"] = model.current_json["image_size"]["height"]
  end

  -- if model.current_json["style_image_size"]["width"] ~= model.current_json["image_size"]["width"] or model.current_json["style_image_size"]["height"] ~= model.current_json["image_size"]["height"] then
  --   return app.alert("Style image size doesn't match, make sure the size matches the generation size")
  -- end

  local copy_data = createJson.deepcopy(model.current_json)
  if model.current_json["style_image"] == "No" then
    copy_data["style_guidance_scale"] = 1
  end
  copy_data["map_zoom"] = tonumber(string.match(model.current_json["map_zoom"], "(%d+)x"))
  local jsonData = createJSON.create(model, copy_data, default_current, getImage.get_images_bytes_from_json(copy_data))

  if fake_init_image then
    model.current_json["init_image_strength"] = prev_init_strength
    model.current_json["init_image"] = "No"
  end

  if jsonData == nil then
    return
  end

  local cels = generate_tiles_style.prepare_image(model, true)
  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-tiles-style", cels, dlg_title, dlg_type)
end

local previous_origin = nil
local previous_bounds = nil
local listenerCode = nil
local event_sprite = nil
function generate_tiles_style.onClose(model)
  if event_sprite ~= nil then
    event_sprite.events:off(listenerCode)
  end
  event_sprite = nil
  listenerCode = nil
end

function generate_tiles_style.update_selection(ev)
  if ev.fromUndo then
    return
  end
  if generate_tiles_style.current_json["use_selection"] and (previous_origin == nil or previous_bounds == nil or previous_origin.x ~= app.activeSprite.selection.origin.x or previous_origin.y ~= app.activeSprite.selection.origin.y or
        app.activeSprite.selection.bounds.width ~= previous_bounds.width or app.activeSprite.selection.bounds.height ~= previous_bounds.height) then
    if app.activeSprite.selection.bounds.width ~= 0 and app.activeSprite.selection.bounds.height ~= 0 then
      if generate_tiles_style.current_json["max_size"][1] == 64 then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
          64, 64)
        app.activeSprite.selection:select(selection_rectangle)
        app.refresh()
      else
        local maxArea = generate_tiles_style.current_json["max_size"][1] *
            generate_tiles_style.current_json["max_size"][2]

        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
          app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)

        if app.activeSprite.selection.bounds.width < 64 then
          selection_rectangle.width = 64
        end
        if app.activeSprite.selection.bounds.height < 64 then
          selection_rectangle.height = 64
        end
        if selection_rectangle.height * selection_rectangle.width > maxArea then
          local ratio = selection_rectangle.width / selection_rectangle.height
          selection_rectangle.height = math.sqrt(maxArea / ratio)
          selection_rectangle.width = ratio * selection_rectangle.height
        end
        if selection_rectangle.height % 2 == 1 then
          selection_rectangle.height = selection_rectangle.height - 1
        end
        if selection_rectangle.width % 2 == 1 then
          selection_rectangle.width = selection_rectangle.width - 1
        end
        if selection_rectangle.height * selection_rectangle.width > 80 * 80 then
          show_warning("warning_custom_size", true)
        else
          show_warning("warning_custom_size", false)
        end

        app.activeSprite.selection:select(selection_rectangle)
        app.refresh()
      end

      previous_origin = app.activeSprite.selection.origin
      previous_bounds = app.activeSprite.selection.bounds
    end
  end
end

function generate_tiles_style.openDialog(model)
  generate_tiles_style.current_json = model.current_json
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if listenerCode == nil then
      event_sprite = app.activeSprite
      listenerCode = event_sprite.events:on('change', generate_tiles_style.update_selection)
    end
    if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
      app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
    end
  end
end

return generate_tiles_style