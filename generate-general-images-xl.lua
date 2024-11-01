generate_general_images_xl = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_general_images_xl.default_json = {
  description = "Castle on a hill",
  negative_description = "mixels. amateur. multiple. grainy background",
  guidance_scale = 8,
  view_direction = false,
  view = "none",
  direction = "none",
  image_size = { width = 128, height = 128 },
  no_background = false,
  init_image = "No",
  init_image_strength = 300,
  color_image = "No",
  -- inpainting = "No",
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_general_xl"
}

generate_general_images_xl.dialog_json = {
  guidance = {
    view = { "none", "high top-down", "low top-down", "side" },
    direction = { "none", "north", "east", "south", "west" },
    guidance_scale = { 10, 200 },
  },
  documentation = "https://www.pixellab.ai/docs/tools/generate-image"
}

function generate_general_images_xl.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - General image (new)")
end

generate_general_images_xl.current_json = createJson.deepcopy(generate_general_images_xl.default_json)

function generate_general_images_xl.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif app.activeSprite.width < 32 or app.activeSprite.height < 32 then
    return app.alert("Canvas width and height must be larger or equal to 32")
  elseif app.activeSprite.width * app.activeSprite.height > 200 * 200 then
    return app.alert("Canvas must be smaller or equal to 200x200 area")
  elseif app.activeSprite.width * app.activeSprite.height < 100 * 100 then
    return app.alert("Canvas must be larger or equal to 100x100 area")
  end
  if app.activeSprite.width % 2 == 1 or app.activeSprite.height % 2 == 1 then
    return app.alert("Canvas height and width must be divisible by 2")
  end

  model.current_json["image_size"]["width"] = app.activeSprite.width
  model.current_json["image_size"]["height"] = app.activeSprite.height

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(model.current_json), app.activeSprite.width, app.activeSprite.height)

  if jsonData == nil then
    return
  end

  local cels = generate_general_images_xl.prepare_image(model, true)
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-general-xl", cels, dlg_title, dlg_type)
end

function generate_general_images_xl.onClose()
end

function generate_general_images_xl.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(128, 128)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
end

return generate_general_images_xl
