generate_reshape = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_reshape.default_json = {
  reference_image = "",
  image_guidance_scale = 2,
  shape_image = "",
  shape_guidance_scale = 1.5,
  view = "low top-down",
  text_guidance_scale = 4,
  color_image = "Current image",
  init_images_amount = 1,
  init_images = { "No" },
  init_image_strength = 300,
  -- inpainting = "No",
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_reshape"
}

generate_reshape.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
  },
  documentation = "https://www.pixellab.ai/docs/tools/reshape"
}

generate_reshape.current_json = createJson.shallowcopy(generate_reshape.default_json)

function generate_reshape.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image_reshape(model, create_new_frames, "Generate - Reshape")
end

function generate_reshape.generate(model, default_current, dlg_title, dlg_type)
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

  local cels = generate_reshape.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-reshape", cels, dlg_title, dlg_type)
end

function generate_reshape.onClose()
end

function generate_reshape.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if mask.layer_exist(app.activeSprite, "PixelLab - Reshape", app.activeFrame) == false then
      app.alert { title = "Reshape - info", text = "Draw the new shape in black in the 'Reshape' layer", buttons = "OK" }
      mask.create_layer(app.activeSprite, "PixelLab - Reshape", app.activeFrame)
    end
    mask.fill_layer(app.activeSprite, "PixelLab - Reshape")
  end
end

return generate_reshape
