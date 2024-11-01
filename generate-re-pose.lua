generate_re_pose = {}

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_re_pose.default_json = {
  text_guidance_scale = 5,
  view = "low top-down",
  direction = "south",
  action = "run",
  -- init_image = "No",
  -- init_image_strength = 800,
  -- init_image_size = {width=512, height=512},
  pose_image = "",
  pose_image_size = { width = 512, height = 512 },
  pose_guidance_scale = 1,
  reference_image = "",
  image_guidance_scale = 5,
  reference_image_size = { width = 512, height = 512 },
  seed = "0",
  model_name = "generate_re_pose",
  color_image = "Current image",
  init_images_amount = 1,
  init_images = { "No" },
  init_image_strength = 300,
}

generate_re_pose.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
    direction = { "north", "east", "south", "west" },
  }
}

function generate_re_pose.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_image(create_new_frames, "Generate - Re-pose")
end

generate_re_pose.current_json = createJson.deepcopy(generate_re_pose.default_json)

function generate_re_pose.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif app.activeSprite.width ~= 64 or app.activeSprite.height ~= 64 then
    return app.alert("Canvas must be equal to 64x64")
  end
  if app.fs.isFile(model.current_json["pose_image"]) == false then
    return app.alert("Pose must be selected or couldn't find path")
  end

  model.current_json["reference_image_size"]["width"] = app.activeSprite.width
  model.current_json["reference_image_size"]["height"] = app.activeSprite.height
  -- model.current_json["init_image_size"]["width"] = app.activeSprite.width
  -- model.current_json["init_image_size"]["height"] = app.activeSprite.height

  local prepare_for_json = getImage.get_images_bytes_from_json(model.current_json)

  local return_to_activeSprite = app.activeSprite

  app.open(model.current_json["pose_image"])
  local re_pose_im = Image(app.activeSprite)
  prepare_for_json["pose_image"] = re_pose_im.bytes
  model.current_json["pose_image_size"]["width"] = re_pose_im.width
  model.current_json["pose_image_size"]["height"] = re_pose_im.height
  app.command.CloseFile()

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create(model, copy_data, default_current, prepare_for_json)

  if jsonData == nil then
    return
  end

  app.activeSprite = return_to_activeSprite

  local cels = generate_re_pose.prepare_image(model, true)
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-re-pose", cels, dlg_title, dlg_type)
end

function generate_re_pose.onClose()
end

function generate_re_pose.openDialog()
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

return generate_re_pose
