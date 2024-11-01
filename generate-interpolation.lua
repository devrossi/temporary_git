generate_interpolation = {}

local spr = app.activeSprite

local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local prepareForGeneration = dofile('./prepare-for-generation.lua')
local createJson = dofile('./create-json.lua')

generate_interpolation.default_json = {
  action = "walk",
  negative_description = "",
  text_guidance_scale = 8,
  direction = "east",
  view = "low top-down",
  interpolation_from = "",
  interpolation_to = "",
  image_guidance_scale = 1,
  selected_reference_image = "",
  color_image = "Current image",
  seed = "0",
  model_name = "generate_interpolation",
  output_method = "New frame",
  use_selection = false,
  selection_origin = { 0, 0 },
  image_size = { width = 64, height = 64 },
  max_size = { 64, 64 },
}

generate_interpolation.dialog_json = {
  guidance = {
    name = "Character",
    view = { "high top-down", "low top-down", "side" },
    direction = { tier_1 = { "north", "east", "south", "west" }, tier_2 = { "north", "east", "south", "west", "south-east", "south-west", "north-east", "north-west" } },
  },
  documentation = "https://www.pixellab.ai/docs/tools/interpolation"
}

generate_interpolation.current_json = createJson.deepcopy(generate_interpolation.default_json)

function generate_interpolation.prepare_image(model, create_new_frames)
  return prepareForGeneration.prepare_images_animation(model, create_new_frames, 2, "Generate - Interpolation")
end

function generate_interpolation.generate(model, default_current, dlg_title, dlg_type)
  local request_history_data = createJson.deepcopy(model.current_json)
  if generatingImage then
    return app.alert("Already generating")
  end
  if app.activeSprite == nil then
    return app.alert("Must have an active canvas")
  end
  if model.current_json["use_selection"] then
    model.current_json["selection_origin"][1] = app.activeSprite.selection.origin.x
    model.current_json["selection_origin"][2] = app.activeSprite.selection.origin.y
  end

  if model.current_json["use_selection"] and (app.activeSprite.selection.bounds.width ~= 64 or app.activeSprite.selection.bounds.height ~= 64) then
    return app.alert("Selection width and height must be equal to 64")
  elseif model.current_json["use_selection"] == false and (app.activeSprite.width ~= 64 or app.activeSprite.height ~= 64) then
    return app.alert("Canvas width and height must be equal to 64")
  end

  local copy_data = createJson.deepcopy(model.current_json)
  -- model.current_json["selected_reference_image"] = selected_reference_image
  local jsonData = createJSON.create_with_size(model, copy_data, default_current,
    getImage.get_images_bytes_from_json(copy_data))

  if jsonData == nil then
    return
  end

  local cels = generate_interpolation.prepare_image(model, true)

  mask.move_mask_to_top()
  request_history.insert_request(copy_data.model_name, request_history_data)
  websocket.request(model, jsonData, _url .. "generate-interpolation", cels, dlg_title, dlg_type)
end

local previous_origin = nil
local previous_bounds = nil
local listenerCode = nil
local event_sprite = nil
function generate_interpolation.onClose(model)
  if event_sprite ~= nil then
    event_sprite.events:off(listenerCode)
  end
  listenerCode = nil
  event_sprite = nil
end

function generate_interpolation.update_selection(ev)
  if ev.fromUndo then
    return
  end
  if generate_interpolation.current_json["use_selection"] and (previous_origin == nil or previous_bounds == nil or previous_origin.x ~= app.activeSprite.selection.origin.x or previous_origin.y ~= app.activeSprite.selection.origin.y or
        app.activeSprite.selection.bounds.width ~= previous_bounds.width or app.activeSprite.selection.bounds.height ~= previous_bounds.height) then
    if app.activeSprite.selection.bounds.width ~= 0 and app.activeSprite.selection.bounds.height ~= 0 then
      local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
        generate_interpolation.current_json["max_size"][1], generate_interpolation.current_json["max_size"][2])

      app.activeSprite.selection:select(selection_rectangle)
      app.refresh()
    end
    previous_origin = app.activeSprite.selection.origin
    previous_bounds = app.activeSprite.selection.bounds
  end
end

function generate_interpolation.openDialog(model)
  generate_interpolation.current_json = model.current_json
  if app.activeSprite == nil then
    local sprite = Sprite(64, 64)
    app.activeSprite = sprite
    app.activeSprite:setPalette(Palette { fromResource = "DB32" })
    closeAllDialogs()
  end
  if app.activeSprite ~= nil then
    if listenerCode == nil then
      event_sprite = app.activeSprite
      listenerCode = event_sprite.events:on('change', generate_interpolation.update_selection)
    end
  end
end

return generate_interpolation
