generate_movement = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_movement.default_json = {
  action = "walk",
  negative_description = "",
  text_guidance_scale = 8,
  direction = "east",
  view = "low top-down",
  movement_images = {},
  image_guidance_scale = 1.4,
  init_images = { "No" },
  init_image_strength = 300,
  inpainting_images = { "No" },
  n_frames = 4,
  start_frame_index = 0,
  selected_reference_image = "",
  color_image = "Current image",
  seed = "0",
  model_name = "generate_movement",
  output_method = "New layer",
  use_selection = false,
  selection_origin = { 0, 0 },
  image_size = { width = 64, height = 64 },
  max_size = { 64, 64 },
}

generate_movement.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
    direction = { "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" },
  },
  color_image = { options = { "Reference image", "Current image", "Color palette", "No" }, reference_image = "selected_reference_image" },
  documentation = "https://www.pixellab.ai/docs/tools/animation"
}

generate_movement.current_json = createJson.deepcopy(generate_movement.default_json)

function generate_movement.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_images_animation(model, create_new_frames, 4, "Generate - Movement")
end

function generate_movement.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  end
  if model.current_json["use_selection"] then
    model.current_json["selection_origin"][1] = app.activeSprite.selection.origin.x
    model.current_json["selection_origin"][2] = app.activeSprite.selection.origin.y
  end

  if model.current_json["use_selection"] and (app.activeSprite.selection.bounds.width ~= 64 or app.activeSprite.selection.bounds.height ~= 64) then
    return app.alert("Selection width and height must be equal to 64")
  elseif model.current_json["use_selection"] == false and (app.activeSprite.width ~= 64 or app.activeSprite.height ~= 64) then
    return app.alert("Canvas width and height must be equal to 64")
  end
  local data_images = getImage.get_images_from_model_from_json(model.current_json)
  local no_inpaint = 0
  for index = 1, 4 do
    if data_images["inpainting_images"][index] ~= nil and data_images["inpainting_images"][index] ~= "" and data_images["inpainting_images"][index]:isPlain(Color { r = 0, g = 0, b = 0, a = 255 }) then
      no_inpaint = no_inpaint + 1
    end
  end
  if no_inpaint == 4 then
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


  local copy_data = createJson.deepcopy(model.current_json)
  -- model.current_json["selected_reference_image"] = selected_reference_image
  local jsonData = createJSON.create_with_size(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(copy_data))

  if jsonData == nil then
    return
  end

  if model.current_json["output_method"] == "New frame" then
    for index = 1, 3 do
      if app.activeFrame.next ~= nil then
        app.activeFrame = app.activeFrame.next
      end
    end
  end

  local cels = generate_movement.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-movement", cels, dlg_title, dlg_type)
end

local previous_origin = nil
local previous_bounds = nil
local listenerCode = nil
local event_sprite = nil
function generate_movement.onClose(model)
  if event_sprite ~= nil then
    event_sprite.events:off(listenerCode)
  end
  listenerCode = nil
  event_sprite = nil
end

function generate_movement.update_selection(ev)
  if ev.fromUndo then
    return
  end
  if generate_movement.current_json["use_selection"] and (previous_origin == nil or previous_bounds == nil or previous_origin.x ~= app.activeSprite.selection.origin.x or previous_origin.y ~= app.activeSprite.selection.origin.y or
        app.activeSprite.selection.bounds.width ~= previous_bounds.width or app.activeSprite.selection.bounds.height ~= previous_bounds.height) then
    if app.activeSprite.selection.bounds.width ~= 0 and app.activeSprite.selection.bounds.height ~= 0 then
      local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
        generate_movement.current_json["max_size"][1], generate_movement.current_json["max_size"][2])

      app.activeSprite.selection:select(selection_rectangle)
      app.refresh()
    end
    previous_origin = app.activeSprite.selection.origin
    previous_bounds = app.activeSprite.selection.bounds
  end
end

function generate_movement.openDialog(model)
  generate_movement.current_json = model.current_json
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if listenerCode == nil then
      event_sprite = app.activeSprite
      listenerCode = event_sprite.events:on('change', generate_movement.update_selection)
    end
    if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
      app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
    end
  end
end

return generate_movement
