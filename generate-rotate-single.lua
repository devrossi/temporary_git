generate_rotate_single = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_rotate_single.default_json = {
  from_view = "side",
  to_view = "side",
  from_direction = "south",
  to_direction = "east",
  oblique_projection = false,
  image_guidance_scale = 3,
  from_image = "",
  image_size = { width = 64, height = 64 },
  init_image = "No",
  init_image_strength = 300,
  inpainting_image = "No",
  use_inpainting = false,
  color_image = "Reference image",
  seed = "0",
  model_name = "generate_rotate_single",
  output_method = "New frame"
}

generate_rotate_single.dialog_json = {
  header_text = { "Canvas sizes 16x16, 32x32, 64x64 and 128x128 supported. Use smaller sizes when possible for optimal results." },
  guidance = {
    from_view = { "high top-down", "low top-down", "side" },
    to_view = { "high top-down", "low top-down", "side" },
    from_direction = { "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" },
    to_direction = { "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" },
  },
  color_image = { options = { "Reference image", "Current image", "Color palette", "No" }, reference_image = "from_image" },
  documentation = "https://www.pixellab.ai/docs/tools/rotate"
}

generate_rotate_single.current_json = createJson.deepcopy(generate_rotate_single.default_json)

function generate_rotate_single.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_images_animation(model, create_new_frames, 1, "Generate - Single rotation")
end

function generate_rotate_single.check_size()
  return ((app.activeSprite.width == 128 and app.activeSprite.height == 128) or (app.activeSprite.width == 64 and app.activeSprite.height == 64) or (app.activeSprite.width == 32 and app.activeSprite.height == 32) or (app.activeSprite.width == 16 and app.activeSprite.height == 16)) ==
      false
end

function generate_rotate_single.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif generate_rotate_single.check_size() then
    return app.alert("Canvas must be size 128x128, 64x64, 32x32 or 16x16")
  end

  model.current_json["image_size"]["width"] = app.activeSprite.width
  model.current_json["image_size"]["height"] = app.activeSprite.height

  if model.current_json["from_image"] ~= "" and (model.current_json["from_image"].width ~= model.current_json["image_size"]["width"] or model.current_json["from_image"].height ~= model.current_json["image_size"]["height"]) then
    return app.alert("Style image size doesn't match, make sure the size matches the generation size")
  end

  local copy_data = createJson.deepcopy(model.current_json)

  if copy_data["use_inpainting"] and copy_data["init_image"] == "No" then
    copy_data["init_image_strength"] = 1
    copy_data["init_image"] = "Yes"
  end

  local jsonData = createJSON.create(model, copy_data, default_current, getImage.get_images_bytes_from_json(copy_data))

  if jsonData == nil then
    return
  end

  local cels = generate_rotate_single.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-rotate-single", cels, dlg_title, dlg_type)
end

function generate_rotate_single.onClose()
end

function generate_rotate_single.openDialog(model)
  generate_rotate_single.current_json = model.current_json
  if app.activeSprite == nil then
    local size = 128
    local data =
        Dialog("Open sprite"):label { id = "info", text = "Open a canvas of size:                                                                " }
        :button { id = "result1", text = "128x128" }
        :button { id = "result2", text = "64x64" }
        :button { id = "result3", text = "32x32" }
        :button { id = "result4", text = "16x16" }
        :button { id = "cancel", text = "Cancel" }
        :show().data
    if data.result1 then
      size = 128
    elseif data.result2 then
      size = 64
    elseif data.result3 then
      size = 32
    elseif data.result4 then
      size = 16
    else
      return
    end

    local sprite = Sprite(size, size)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
    app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer', buttons = "OK" }
    mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
  end
end

return generate_rotate_single
