generate_pose_animation = {}

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')
local handlePose = dofile('./handle-pose.lua')

generate_pose_animation.default_json = {
  points = {},
  pose_images = {},
  pose_guidance_scale = 3,
  selected_reference_image = "",
  reference_guidance_scale = 1.1,
  inpainting_images = { "No" },
  isometric = false,
  oblique_projection = false,
  view = "low top-down",
  direction = "south",
  reference_direction = "automatic",
  color_image = "No",
  init_images = { "No" },
  image_size = { width = 64, height = 64 },
  init_image_strength = 300,
  size_head_pose = 10,
  size_height_pose = 10,
  size_width_pose = 10,
  size_depth_pose = 10,
  scroll_preview = 0,
  x_pose = 0,
  y_pose = 0,
  fixed_head = "same_direction",
  model_name = "generate_pose_animation",
  output_method = "New layer",
  seed = "0",
  use_inpainting = false,
  show_skeleton_preview = false,
}

generate_pose_animation.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
    direction = { "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" },
    reference_direction = { "automatic", "north", "north-north-east", "north-east", "east-north-east", "east",
      "east-south-east",
      "south-east", "south-south-east", "south", "south-south-west", "south_west", "west-south-west", "west",
      "west-north_west", "north-west", "north-north-west" }
  },
  template_selected = "base",
  pose = {
    edit = false,
    handle_pose = handlePose
  },
  color_image = { options = { "Reference image", "Current image", "Color palette", "No" }, reference_image = "selected_reference_image" },
  documentation = "https://www.pixellab.ai/docs/tools/skeleton-animation",
  documentation_template_skeleton = "https://www.pixellab.ai/docs/tools/skeleton-animation",
  documentation_animation_to_animation = "https://www.pixellab.ai/docs/tools/skeleton-animation",
  tabs = {
    tabs = { { "Setup skeleton", "Generate" }, { "Template skeleton", "Animation to animation" } },
    active_tab = { "skeleton_setup", "template_skeleton" }
  },
  generate = {
    generation_setup = "Freeze 1 -> Generate 3 frames",
    number_of_freeze_frame = 1,
    number_of_generate_frame = 3
  },
  show_reference_over_display = false,
  selected_frames = {},
  selected_reference_frame = {}
}

generate_pose_animation.generate_from_frameNumber = nil

function generate_pose_animation.prepare_image(model, create_new_frames)
  mask.move_mask_to_top()
  handlePose.move_to_top()
  return prepareForGeneration.prepare_images_animation(model, create_new_frames, 4, "Generate - Pose Animation")
end

generate_pose_animation.current_json = createJson.deepcopy(generate_pose_animation.default_json)

function generate_pose_animation.check_size()
  -- (app.activeSprite.width == 128 and app.activeSprite.height == 128) or
  -- return ((app.activeSprite.width == 64 and app.activeSprite.height == 64) or (app.activeSprite.width == 32 and app.activeSprite.height == 32) or (app.activeSprite.width == 16 and app.activeSprite.height == 16)) == false
  return ((app.activeSprite.width == 128 and app.activeSprite.height == 128) or (app.activeSprite.width == 64 and app.activeSprite.height == 64) or (app.activeSprite.width == 32 and app.activeSprite.height == 32) or (app.activeSprite.width == 16 and app.activeSprite.height == 16)) ==
      false
end

function generate_pose_animation.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  elseif app.activeSprite.colorMode ~= ColorMode.RGB then
    return app.alert(
      "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
  elseif generate_pose_animation.check_size() then
    return app.alert("Canvas must be size 128x128, 64x64, 32x32 or 16x16")
  elseif model.current_json["selected_reference_image"] ~= "" and model.current_json["selected_reference_image"].width ~= app.activeSprite.width and model.current_json["selected_reference_image"].height ~= app.activeSprite.height then
    return app.alert("Reference image needs to be the same size as canvas")
  end

  model.current_json["image_size"]["width"] = app.activeSprite.width
  model.current_json["image_size"]["height"] = app.activeSprite.height

  local missing_skeleton = false
  local frame = app.activeFrame
  for i = 1, 4 do
    if frame ~= nil then
      model.current_json["points"][i] = get_points_from_frame(frame.frameNumber)
      frame = frame.next
    else
      model.current_json["points"][i] = {}
    end
    if #model.current_json["points"][i] == 0 then
      missing_skeleton = true
    end
  end

  if missing_skeleton then
    app.alert { title = "Missing pose/skeleton in your frames", text = "Missing pose/skeleton in your frames, its important to have them to control the output and its quality" }
  end

  local data_images = getImage.get_images_from_model_from_json(model.current_json)

  if data_images["selected_reference_image"] == "" or data_images["selected_reference_image"]:isEmpty() then
    -- if model.dialog_json["generate"]["generation_setup"] == "Custom" then
    --   return app.alert { title = "Missing reference image", text = "Missing reference image. Position yourself so that the frame your standing on has an image" }
    -- else
    return app.alert { title = "Missing reference image", text = "Missing reference image. Set the reference image you want to use an reference." }
    -- end
  end

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

  local prepare_for_json = getImage.get_images_bytes_from_json(model.current_json)

  local copy_data = createJson.deepcopy(model.current_json)
  local jsonData = createJSON.create(model, copy_data, default_current, prepare_for_json)

  if jsonData == nil then
    return
  end

  if model.current_json["output_method"] == "New frame" then
    model.generate_from_frameNumber = app.activeFrame.frameNumber
    for index = 1, 3 do
      if app.activeFrame.next ~= nil then
        app.activeFrame = app.activeFrame.next
      end
    end
  end

  local cels = generate_pose_animation.prepare_image(model, true)

  mask.move_mask_to_top()
  handlePose.move_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-pose-animation", cels, dlg_title, dlg_type)
end

function generate_pose_animation.onClose()
  handlePose.stop()
end

function generate_pose_animation.openDialog(model)
  if app.apiVersion < 26 then
    return app.alert { title = "Warning - Old Asprite version", text = "Your version of aseprite is too old to run this tool. Requires v1.3 or higher" }
  end
  generate_pose_animation.current_json = model.current_json
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

return generate_pose_animation
