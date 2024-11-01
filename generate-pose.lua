generate_pose = {}

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_pose.default_json = {
  text_guidance_scale = 8,
  view_direction = false,
  view = "low top-down",
  direction = "none",
  view_direction_guidance_scale = 4,
  pixelart_style_guidance_scale = 4,
  image_size = { width = 128, height = 128 },
  no_background = false,
  no_background_guidance_scale = 4,
  init_image = "No",
  init_image_strength = 300,
  -- inpainting = "No",
  seed = "0",
  -- blur= 4,
  -- n_repaint= 4,
  pose_image = "",
  pose_image_size = { width = 512, height = 512 },
  pose_guidance_scale = 1,
  color_image = "No",
  model_name = "generate_pose"
}

generate_pose.dialog_json = {
  guidance = {
    view = { "high top-down", "low top-down", "side" },
    direction = { "none", "north", "east", "south", "west" },
  }
}

function generate_pose.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - Pose")
end

generate_pose.current_json = createJson.deepcopy(generate_pose.default_json)

function generate_pose.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif app.activeSprite.width * app.activeSprite.height > 200 * 200 then
    return app.alert("Canvas must be smaller or equal to 200x200 area")
  elseif app.activeSprite.width < 32 or app.activeSprite.height < 32 then
    return app.alert("Canvas width and height must be larger or equal to 32")
  end
  if app.activeSprite.width % 2 == 1 or app.activeSprite.height % 2 == 1 then
    return app.alert("Canvas height and width must be divisible by 2")
  end

  if app.fs.isFile(model.current_json["pose_image"]) == false then
    return app.alert("Pose must be selected or couldn't find path")
  end

  model.current_json["image_size"]["width"] = app.activeSprite.width
  model.current_json["image_size"]["height"] = app.activeSprite.height

  local prepare_for_json = getImage.get_images_bytes_from_json(model.current_json)

  local return_to_activeSprite = app.activeSprite

  app.open(model.current_json["pose_image"])
  local pose_im = Image(app.activeSprite)
  prepare_for_json["pose_image"] = pose_im.bytes
  model.current_json["pose_image_size"]["width"] = pose_im.width
  model.current_json["pose_image_size"]["height"] = pose_im.height
  app.command.CloseFile()

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create_with_size(model, copy_data, default_current, prepare_for_json)

  if jsonData == nil then
    return
  end
  app.activeSprite = return_to_activeSprite

  local cels = generate_pose.prepare_image(model, true)
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-general-pose", cels, dlg_title, dlg_type)
end

function generate_pose.onClose()
end

function generate_pose.openDialog()
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end

  local result = app.alert { title = "Open website",
    text = "Open website for creating pose. Export OpenPose (With hands)",
    buttons = { "Yes", "No" } }

  if result == 1 then
    -- Define the URL you want to open
    local url = "https://app.posemy.art/"

    -- Open the URL in the default web browser
    if os.execute("start " .. url) == nil then
      if os.execute("xdg-open " .. url) == nil then
        if os.execute("open " .. url) == nil then
          print("Failed to open the URL.")
        end
      end
    end
  end
end

return generate_pose
