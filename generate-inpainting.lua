generate_inpainting = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_inpainting.default_json = {
  description = "Castle on a hill",
  negative_description = "amateur. ugly. artifacts",
  view_direction = false,
  reference_image = "Yes",
  view = "none",
  direction = "none",
  text_guidance_scale = 3,
  -- inpainting_guidance_scale = 1.5,
  color_image = "Current image",
  image_size = { width = 64, height = 64 },
  init_image = "No",
  init_image_strength = 500,
  inpainting_image = "",
  seed = "0",
  model_name = "generate_inpainting",
  use_selection = false,
  selection_origin = { 0, 0 },
  outline = "",
  shading = "",
  detail = "",
  transparent_background = true,
  isometric = false,
  oblique_projection = false,
  force_colors = false,
  output_method = "New layer"
}

generate_inpainting.dialog_json = {
  guidance = {
    view = { "none", "high top-down", "low top-down", "side" },
    direction = { "none", "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" },
    text_guidance_scale = { 15, 50 },
  },
  documentation = "https://www.pixellab.ai/docs/tools/inpaint"
}

generate_inpainting.current_json = createJson.deepcopy(generate_inpainting.default_json)

function generate_inpainting.prepare_image(model, create_new_frames)
  if model.current_json["output_method"] == "New frame" then
    return prepareForGeneration.prepare_image_reshape(model, create_new_frames, "Generate - Inpainting")
  else
    return prepareForGeneration.prepare_same_image(model, "Generate - Inpainting")
  end
end

function generate_inpainting.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif model.current_json["use_selection"] == false and app.activeSprite.width * app.activeSprite.height > 200 * 200 then
    return app.alert("Canvas must be smaller or equal to 200x200 area")
  elseif app.activeSprite.width < 16 or app.activeSprite.height < 16 then
    return app.alert("Canvas width and height must be larger or equal to 16")
  end
  if model.current_json["use_selection"] and app.activeSprite.selection.bounds.isEmpty then
    return app.alert("You have missed using the selection tool")
  end

  local data_images = getImage.get_images_from_model_from_json(model.current_json)
  if data_images["inpainting_image"]:isPlain(Color { r = 0, g = 0, b = 0, a = 255 }) then
    local result = app.alert { title = "Missing inpainting", text = "You need to draw in the inpaint layer to inpaint", buttons = { "OK", "Help" } }

    if result == 2 then
      local url = "https://www.pixellab.ai/docs/getting-started"
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

    if app.activeSprite.selection.bounds.isEmpty then
      model.current_json["image_size"]["width"] = 64
      model.current_json["image_size"]["height"] = 64
    else
      model.current_json["image_size"]["width"] = app.activeSprite.selection.bounds.width
      model.current_json["image_size"]["height"] = app.activeSprite.selection.bounds.height
    end
  else
    model.current_json["image_size"]["width"] = app.activeSprite.width
    model.current_json["image_size"]["height"] = app.activeSprite.height
  end

  local copy_data = createJson.deepcopy(model.current_json)
  copy_data["inpainting_guidance_scale"] = 3

  local jsonData = createJSON.create(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(model.current_json))

  if jsonData == nil then
    return
  end

  local cels = generate_inpainting.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-inpainting", cels, dlg_title, dlg_type)
end

local previous_origin = nil
local previous_bounds = nil
local listenerCode = nil
local event_sprite = nil
function generate_inpainting.onClose(model)
  if event_sprite ~= nil then
    event_sprite.events:off(listenerCode)
  end
  listenerCode = nil
  event_sprite = nil
end

function generate_inpainting.update_selection(ev)
  if ev.fromUndo then
    return
  end
  local maxArea = 140 * 140
  if _tier > 1 then
    maxArea = 200 * 200
  end

  if generate_inpainting.current_json["use_selection"] and (previous_origin == nil or previous_bounds == nil or previous_origin.x ~= app.activeSprite.selection.origin.x or previous_origin.y ~= app.activeSprite.selection.origin.y or
        app.activeSprite.selection.bounds.width ~= previous_bounds.width or app.activeSprite.selection.bounds.height ~= previous_bounds.height) then
    if app.activeSprite.selection.bounds.width ~= 0 and app.activeSprite.selection.bounds.height ~= 0 then
      local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
        app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
      if app.activeSprite.selection.bounds.width < 16 then
        selection_rectangle.width = 16
      end
      if app.activeSprite.selection.bounds.height < 16 then
        selection_rectangle.height = 16
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

function generate_inpainting.openDialog(model)
  generate_inpainting.current_json = model.current_json
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if listenerCode == nil then
      event_sprite = app.activeSprite
      listenerCode = event_sprite.events:on('change', generate_inpainting.update_selection)
    end

    if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
      app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
    end
    -- mask.fill_layer(app.activeSprite, "Inpainting")
  end
end

return generate_inpainting
