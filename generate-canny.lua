generate_canny = {}

local getImage = dofile('./get-image.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')
local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')

local cel_to_generate_into

generate_canny.default_json = {
  description                   = "Dog",
  text_guidance_scale           = 8,
  view_direction                = false,
  view                          = "side",
  direction                     = "south",
  view_direction_guidance_scale = 4,
  pixelart_style_guidance_scale = 4,
  image_size                    = { width = 64, height = 64 },
  no_background                 = false,
  no_background_guidance_scale  = 4,
  init_image                    = "No",
  init_image_strength           = 300,
  color_image                   = "No",
  canny_image                   = "",
  canny_guidance_scale          = 1,
  seed                          = "0",
  model_name                    = "generate_canny"
}

generate_canny.current_json = createJson.deepcopy(generate_canny.default_json)

generate_canny.dialog_json = {
  camera = {
    view = { "none", "high top-down", "low top-down", "side" },
    direction = { "none", "north", "east", "south", "west" },
  },
  documentation = "https://www.pixellab.ai/docs/tools/sketch"
}

local function get_canny_sprite()
  for i, sprite in ipairs(app.sprites) do
    if sprite.filename == "Sketch - Canny" then
      return sprite
    end
  end
  return nil
end

function generate_canny.prepare_image(model, create_new_frames)
  if app.activeSprite ~= nil and app.activeSprite.filename == "Sketch - Canny" then
    app.alert("Go to the canvas you want to generate into")
    return nil
  end
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - Sketch")
end

function generate_canny.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if cel_to_generate_into == nil or cel_to_generate_into[1] == nil then
    return app.alert(
      "Failed to find the cel you are attempting to generate into. Go to the canvas you want to generate into and select a cel")
  end
  if app.activeSprite.filename == "Sketch - Canny" then
    app.activeSprite = cel_to_generate_into[1].sprite
    app.activeFrame = cel_to_generate_into[1].frameNumber
  end

  if cel_to_generate_into[1] ~= nil and (cel_to_generate_into[1].image.width * cel_to_generate_into[1].image.height > 200 * 200) then
    return app.alert("Canvas generating from must be smaller or equal to 200x200 area")
  elseif cel_to_generate_into[1] ~= nil and cel_to_generate_into[1].image.width < 32 or cel_to_generate_into[1].image.height < 32 then
    return app.alert("Canvas width and height must be larger or equal to 32")
  end

  if cel_to_generate_into[1].image.width % 2 == 1 or cel_to_generate_into[1].image.height % 2 == 1 then
    return app.alert("Canvas height and width must be divisible by 2")
  end
  if generatingImage then
    return app.alert("Already generating")
  end

  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  end

  model.current_json["image_size"]["width"] = cel_to_generate_into[1].image.width
  model.current_json["image_size"]["height"] = cel_to_generate_into[1].image.height

  local data = getImage.get_images_bytes_from_json(model.current_json)

  local sketch_sprite = get_canny_sprite()
  if sketch_sprite == nil then
    return app.alert("Couldn't find sketch sprite, try closing tool then opening sketch again")
  end

  if cel_to_generate_into[1].image.width * cel_to_generate_into[1].image.height > 100 * 100 then
    if #data["canny_image"] / 4 ~= #cel_to_generate_into[1].image.bytes * 4 then
      result = app.alert { title = "Wrong size", text = "Size of sketch and image you are generating into does not match. Make sure the sketch is 4 times as large", buttons = { "Resize sketch", "Cancel" } }
      if result == 1 then
        sketch_sprite:resize(cel_to_generate_into[1].image.width * 4, cel_to_generate_into[1].image.height * 4)
        data = getImage.get_images_bytes_from_json(model.current_json)
      else

      end
    end
  else
    if #data["canny_image"] / 8 ~= #cel_to_generate_into[1].image.bytes * 8 then
      result = app.alert { title = "Wrong size", text = "Size of sketch and image you are generating into does not match. Make sure the sketch is 8 times as large", buttons = { "Resize sketch", "Cancel" } }
      if result == 1 then
        sketch_sprite:resize(cel_to_generate_into[1].image.width * 8, cel_to_generate_into[1].image.height * 8)
        data = getImage.get_images_bytes_from_json(model.current_json)
      else

      end
    end
  end


  -- model.current_json["canny_image"]
  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create_with_size(model, copy_data, default_current, data)

  if jsonData == nil then
    return
  end

  app.activeSprite = cel_to_generate_into[1].sprite
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-general-canny", cel_to_generate_into, dlg_title, dlg_type)
end

function generate_canny.onClose()
end

function generate_canny.openDialog(model)
  if app.activeSprite ~= nil and (app.activeSprite.width % 2 == 1 or app.activeSprite.height % 2 == 1) then
    return app.alert("Canvas height and width must be divisible by 2")
  end

  if app.activeSprite ~= nil and app.activeSprite.filename ~= "Sketch - Canny" then
    cel_to_generate_into = generate_canny.prepare_image(model, true, app.activeSprite)
  else
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    cel_to_generate_into = generate_canny.prepare_image(model, true, app.activeSprite)
  end

  if cel_to_generate_into[1] ~= nil and (cel_to_generate_into[1].image.width * cel_to_generate_into[1].image.height > 200 * 200) then
    return app.alert("Canvas must be smaller or equal to 200x200 area, go to your original canvas and change size")
  elseif cel_to_generate_into[1] ~= nil and (cel_to_generate_into[1].image.width < 32 or cel_to_generate_into[1].image.height < 32) then
    return app.alert("Canvas width and height must be larger or equal to 32")
  end

  if getImage.get_canny() == "" then
    local sprite
    if cel_to_generate_into[1].image.width * cel_to_generate_into[1].image.height > 100 * 100 then
      sprite = Sprite(cel_to_generate_into[1].image.width * 4, cel_to_generate_into[1].image.height * 4)
    else
      sprite = Sprite(cel_to_generate_into[1].image.width * 8, cel_to_generate_into[1].image.height * 8)
    end

    sprite.filename = "Sketch - Canny"
    app.activeSprite = sprite

    for it in app.activeImage:pixels() do
      it(app.pixelColor.rgba(0, 0, 0, 255))
    end
  else
    for i, sprite in ipairs(app.sprites) do
      if sprite.filename == "Sketch - Canny" then
        app.activeSprite = sprite
      end
    end
  end

  app.fgColor = Color { r = 255, g = 255, b = 255, a = 255 }
  app.activeTool = "pencil"
  app.activeBrush = Brush(1)
  app.alert("Draw in white with brush size 1. Click generate when ready.")
  app.refresh()
end

return generate_canny
