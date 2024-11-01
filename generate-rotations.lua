generate_rotations = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_rotations.default_json = {
  negative_description = "",
  inpainting_images = { "No" },
  rotation_images = {},
  always_visible_display_images_name = { "South", "East", "North", "West" },
  image_guidance_scale = 2,
  init_images = { "No" },
  init_image_strength = 300,
  view = "low top-down",
  text_guidance_scale = 8,
  color_image = "Current image",
  -- inpainting = "No",
  forced_symmetry = false,
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_rotations",
  output_method = "Modify current layer"
}

generate_rotations.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
  }
}

generate_rotations.current_json = createJson.deepcopy(generate_rotations.default_json)

function generate_rotations.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_images_animation(model, create_new_frames, 4, "Generate - Rotations")
end

function generate_rotations.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  end

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(model.current_json))

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

  local cels = generate_rotations.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-rotations", cels, dlg_title, dlg_type)
end

function generate_rotations.onClose()
end

function generate_rotations.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
      app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
    end
  end
end

return generate_rotations
