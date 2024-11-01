generate_resize = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_resize.default_json = {
  description = "human mage",
  negative_description = "",
  zoom = 2,
  fidelity = 0.8,
  oblique_projection = false,
  text_guidance_scale = 3,
  color_image = "No",
  resize_image = "",
  resize_image_strength = 400,
  -- init_image_strength = 300,
  image_size = { width = 64, height = 64 },
  -- inpainting = "No",
  view = "none",
  direction = "none",
  no_background = true,
  style_image = "No",
  style_guidance_scale = 5,
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_resize"
}

generate_resize.dialog_json = {
  guidance = {
    view = { "none", "high top-down", "low top-down", "side" },
    direction = { "none", "north", "east", "south", "west" },
  }
}

function generate_resize.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - resize image")
end

generate_resize.current_json = createJson.deepcopy(generate_resize.default_json)

function generate_resize.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif app.activeSprite.width < 64 or app.activeSprite.height < 64 or app.activeSprite.width > 128 or app.activeSprite.height > 128 then
    return app.alert("Canvas width and height must be between 64x64 and 128x128")
  end

  model.current_json["image_size"]["width"] = app.activeSprite.width
  model.current_json["image_size"]["height"] = app.activeSprite.height

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(model.current_json))

  if jsonData == nil then
    return
  end

  local cels = generate_general_images.prepare_image(model, true)
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-resize", cels, dlg_title, dlg_type)
end

function generate_resize.onClose()
end

function generate_resize.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
end

return generate_resize
