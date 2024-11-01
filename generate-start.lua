generate_start_images = {}

local getImage = dofile('./get-image.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_start_images.default_json = {
  negative_description = "",
  size = 20,
  text_guidance_scale = 8,
  color_image = "No",
  color_guidance_scale = 4,
  forced_colors = false,
  forced_symmetry = false,
  init_image = "No",
  init_image_strength = 300,
  -- inpainting = "No",
  view = "low top-down",
  direction = "south",
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  model_name = "generate_start"
}

generate_start_images.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
  },
  documentation = "https://www.pixellab.ai/docs/tools/generate-image-old"
}

generate_start_images.current_json = createJson.shallowcopy(generate_start_images.default_json)

function generate_start_images.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - Start image")
end

function generate_start_images.generate(model, default_current, dlg_title, dlg_type)
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

  local cels = generate_start_images.prepare_image(model, true)
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-start", cels, dlg_title, dlg_type)
end

function generate_start_images.onClose()
end

function generate_start_images.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
end

return generate_start_images
