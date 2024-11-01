local generate_start_images = dofile('./generate-start.lua')
local generate_style = dofile('./generate-style.lua')
local generate_style_old = dofile('./generate-style-old.lua')
local generate_character = dofile('./generate-character.lua')
local generate_character_old = dofile('./generate-character-old.lua')
local generate_general_images = dofile('./generate-general-images.lua')
local generate_general_images_xl = dofile('./generate-general-images-xl.lua')
local generate_movement = dofile('./generate-movement.lua')
local generate_reshape = dofile('./generate-reshape.lua')
local generate_rotations = dofile('./generate-rotations.lua')
local generate_interpolation = dofile('./generate-interpolation.lua')
local generate_pose = dofile('./generate-pose.lua')
local generate_re_pose = dofile('./generate-re-pose.lua')
local generate_canny = dofile('./generate-canny.lua')
local generate_inpainting = dofile('./generate-inpainting.lua')
local generate_inpainting_map = dofile('./generate-inpainting-map.lua')
local generate_tiles = dofile('generate-tiles.lua')
local generate_resize = dofile('generate-resize.lua')
local generate_rotate_single = dofile('generate-rotate-single.lua')
local generate_tiles_style = dofile('generate-tiles-style.lua')
local generate_pose_animation = dofile('generate-pose-animation.lua')
local createJson = dofile('./create-json.lua')
local update_plugin = dofile('./update-plugin.lua')
local displayImagesInDialog = dofile('./display-images-in-dialog.lua')
local dialogSettingsAdvanced = dofile('./dialog-settings-advanced.lua')
local dialogSettings = dofile('./dialog-settings.lua')

local json = dofile('./json.lua')
local mask = dofile('./mask.lua')
local current_default_json

current_model = {}

if app.apiVersion < 26 then
  app.alert(
    "You seem to have an old version of aseprite. PixelLab requires at minimum version 1.3 to use all tools and functionalitíes")
end

function isWindows()
  return package.config:sub(1, 1) == '\\'
end

function scriptPath()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*[/\\])") or "./"
end

_path = scriptPath()
-- _url = "http://localhost:8000/"
_url = "http://api.pixellab.ai/"

local file = io.open(_path .. "package.json", "r")
local packageJson = file:read("*all")
separator = package.config:sub(1, 1)
io.close(file)

_secret = json.decode(packageJson)["secret"]
_version = json.decode(packageJson)["version"]
_tier = json.decode(packageJson)["tier"]
_show_advanced_settings = false
_updated = false

local dlgAdvancedSettings
local dlgSettings
local dlgDeprecatedTools
local dlgTools
local screenWidth
local screenHeight

local fullscreen
local dlgToolsPosition
local dlgDeprecatedToolsPosition
local dlgSettingsPosition
local dlgAdvancedSettingsPosition
dlgLoadingPosition = nil

local always_open

local timer

local show_openTools = false

local function UpdateDialog()
  timer = Timer {
    interval = 2.0,
    ontick = function()
      if app.activeSprite ~= nil and app.activeSprite.selection.isEmpty or (current_model ~= nil and current_model.current_json ~= nil and current_model.current_json["use_selection"]) then
        if dlgAdvancedSettings ~= nil then
          dlgAdvancedSettings:repaint()
        end
        if dlgSettings ~= nil then
          dlgSettings:repaint()
        end
      end
    end }
  timer:start()
end

function getOpenDialog()
  if dlgAdvancedSettings ~= nil and _show_advanced_settings then
    return dlgAdvancedSettings
  end
  if dlgSettings ~= nil then
    return dlgSettings
  end
  return nil
end

function closeAllDialogs()
  if dlgAdvancedSettings ~= nil then
    dlgAdvancedSettings:close()
  end
  if dlgSettings ~= nil then
    dlgSettings:close()
  end
  if dlgTools ~= nil then
    dlgTools:close()
  end
  if dlgDeprecatedTools ~= nil then
    dlgDeprecatedTools:close()
  end
end

function GetDialogPosition(dlg)
  return { dlg.bounds.origin.x, dlg.bounds.origin.y }
end

local function GetDialogBounds(position, dlg)
  if fullscreen then
    if position[1] < 0 then
      position[1] = 0
    elseif position[1] + dlg.bounds.width > screenWidth then
      position[1] = screenWidth - dlg.bounds.width
    end
    if position[2] < 0 then
      position[2] = 0
    elseif position[2] + dlg.bounds.height > screenHeight then
      position[2] = screenHeight - dlg.bounds.height
    end
  end

  return Rectangle(position[1], position[2], dlg.bounds.width, dlg.bounds.height)
end

function SetDialogBounds(dlg, position)
  if dlg ~= nil and position ~= nil then
    screenWidth = dlg.bounds.origin.x * 2 + dlg.bounds.width
    screenHeight = dlg.bounds.origin.y * 2 + dlg.bounds.height
    dlg.bounds = GetDialogBounds(position, dlg)
    dlg:repaint()
  end
end

function showAdvancedSettings(model, name)
  if model.default_json["model_name"] == "generate_pose_animation" then
    showAdvancedSettingsSkeleton(model, name)
    return
  end

  current_model = model

  dlgAdvancedSettings = Dialog { title = name, onclose = function()
    dlgAdvancedSettingsPosition = GetDialogPosition(dlgAdvancedSettings)
    model.onClose(model)
  end }
  if model.default_json["model_name"] == "generate_tiles" then
    dlgAdvancedSettings:label { text = "Trained to create 16x16 tiles" }
  end
  if model.dialog_json["header_text"] ~= nil then
    for _, h_text in ipairs(model.dialog_json["header_text"]) do
      dlgAdvancedSettings:separator { text = h_text }
    end
  end
  if model.default_json["use_selection"] ~= nil then
    model.openDialog(model)
  end

  displayImagesInDialog.displayAllWaysVisibleImagesInDialog(dlgAdvancedSettings, model)
  imageAdvancedDialog(dlgAdvancedSettings, model, current_default_json, name)
  characterAdvancedDialog(dlgAdvancedSettings, model, current_default_json, name)
  actionAdvancedDialog(dlgAdvancedSettings, model, current_default_json)
  if model.dialog_json["camera"] ~= nil then
    cameraAdvancedDialog(dlgAdvancedSettings, model, current_default_json)
  end
  initImageAdvancedDialog(dlgAdvancedSettings, model, name)
  colorAdvancedDialog(dlgAdvancedSettings, model)
  generalAdvancedDialog(dlgAdvancedSettings, model)
  dlgAdvancedSettings:newrow {}
  dlgAdvancedSettings:check { id = 'advanced_options', text = 'Advanced Options', selected = _show_advanced_settings, onclick = function()
    _show_advanced_settings = dlgAdvancedSettings.data.advanced_options
    closeAllDialogs()
    openSettingsDialog(model, name, true)
  end }
  show_warning_text(model, dlgAdvancedSettings)

  if model.default_json.model_name ~= request_history.current_model_name then
    request_history.instantiate_request_history_list(model.default_json.model_name)
  end
  dlgAdvancedSettings:file {
    id = "get_history_request",
    label = "Load previous settings:",
    title = "Select history",
    load = true,
    save = false,
    filename = _path .. "request_history" .. separator .. model.default_json.model_name .. separator,
    filetypes = { "json", "png" },
    onchange = function()
      request_history.transfer_over(
        request_history.load_request_from_filename(dlgAdvancedSettings.data.get_history_request),
        model.current_json)
      dlgAdvancedSettings:close()
      showAdvancedSettings(model, name)
    end
  }
  dlgAdvancedSettings:button { id = 'generate', text = 'Generate', onclick = function()
    model.generate(model, current_default_json, name,
      "Advanced")
  end }
      :button { id = 'reset', text = 'Reset', onclick = function()
        model.current_json = createJson.deepcopy(model.default_json)
        closeAllDialogs()
        showAdvancedSettings(model, name)
      end }
      :button { id = 'cancel', text = 'Cancel', onclick = function()
        closeAllDialogs()
        openToolsDialog()
      end }
      :show {
        wait = false,
        autoscrollbars = true,
      }
  -- UpdateDialog(dlgAdvancedSettings)
  SetDialogBounds(dlgAdvancedSettings, dlgAdvancedSettingsPosition)
end

function openSettingsDialog(model, name, open_previous)
  if model.default_json["model_name"] == "generate_pose_animation" then
    openSettingsDialogSkeleton(model, name, open_previous)
    return
  end

  current_model = model
  if open_previous == nil or model.default_json["use_selection"] ~= nil then
    model.openDialog(model)
  end
  if _show_advanced_settings then
    closeAllDialogs()
    showAdvancedSettings(model, name)
    return
  end
  dlgSettings = Dialog { title = name, onclose = function()
    dlgSettingsPosition = GetDialogPosition(dlgSettings)
    model.onClose(model)
  end }
  if model.default_json["model_name"] == "generate_tiles" then
    dlgSettings:label { text = "Trained to create 16x16 tiles" }
  end
  if model.dialog_json["header_text"] ~= nil then
    for _, h_text in ipairs(model.dialog_json["header_text"]) do
      dlgSettings:separator { text = h_text }
    end
  end

  displayImagesInDialog.displayAllWaysVisibleImagesInDialog(dlgSettings, model, current_default_json)
  characterDialog(dlgSettings, model, current_default_json, name)
  actionDialog(dlgSettings, model, current_default_json)
  if model.dialog_json["camera"] ~= nil then
    cameraDialog(dlgSettings, model, current_default_json)
  end
  initImageDialog(dlgSettings, model, name)
  colorDialog(dlgSettings, model)
  generalDialog(dlgSettings, model)
  dlgSettings:newrow {}
  dlgSettings:check { id = "advanced_options", text = "Advanced options", selected = _show_advanced_settings, onclick = function()
    _show_advanced_settings = dlgSettings.data.advanced_options
    closeAllDialogs()
    showAdvancedSettings(model, name)
  end }
  -- :button{ id = 'advanced_settings', text = 'Advanced', onclick=function() closeAllDialogs() showAdvancedSettings(model, name) end }
  dlgSettings:button { id = 'generate', text = 'Generate', onclick = function()
    model.generate(model, current_default_json, name,
      "Settings")
  end }
      :button { id = 'reset', text = 'Reset', onclick = function()
        model.current_json = createJson.deepcopy(model.default_json)
        closeAllDialogs()
        openSettingsDialog(model, name)
      end }
      :button { id = 'cancel', text = 'Cancel', onclick = function()
        closeAllDialogs()
        openToolsDialog()
      end }
  -- :button{ text = 'Close', onclick=function() closeAllDialogs() end }
  show_warning_text(model, dlgSettings)
  dlgSettings:show {
    wait = false,
    autoscrollbars = true,
  }
  -- UpdateDialog(dlgSettings)
  SetDialogBounds(dlgSettings, dlgSettingsPosition)
end

function showAdvancedSettingsSkeleton(model, name)
  current_model = model
  dlgAdvancedSettings = Dialog { title = name, onclose = function()
    dlgAdvancedSettingsPosition = GetDialogPosition(dlgAdvancedSettings)
    model.onClose(model)
  end }

  showSkeletonSettings(dlgAdvancedSettings, model, current_default_json, name, true)

  SetDialogBounds(dlgAdvancedSettings, dlgAdvancedSettingsPosition)
end

function openSettingsDialogSkeleton(model, name, open_previous)
  current_model = model
  if open_previous == nil or model.default_json["use_selection"] ~= nil then
    model.openDialog(model)
  end
  if _show_advanced_settings then
    closeAllDialogs()
    showAdvancedSettingsSkeleton(model, name)
    return
  end
  dlgSettings = Dialog { title = name, onclose = function()
    dlgSettingsPosition = GetDialogPosition(dlgSettings)
    model.onClose(model)
  end }
  showSkeletonSettings(dlgSettings, model, current_default_json, name, false)

  show_warning_text(model, dlgSettings)
  dlgSettings:show {
    wait = false,
    autoscrollbars = true,
  }
  -- UpdateDialog(dlgSettings)
  SetDialogBounds(dlgSettings, dlgSettingsPosition)
end

function openDeprecatedToolsDialog()
  closeAllDialogs()

  dlgDeprecatedTools = Dialog { title = "Extra tools    ", onclose = function()
        dlgDeprecatedToolsPosition = GetDialogPosition(dlgDeprecatedTools)
        show_openTools = false
      end }
      :separator { text = "General tools" }
      :newrow { always = true }
      :button { id = 'general', text = 'Create image (old)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_general_images, "Generate general images")
      end }
      :button { id = 'canny', text = 'Sketch', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_canny, "Generate sketch")
        dlgTools:close()
      end, enabled = _tier > 0 }
      :separator { text = "Character tools" }
      :button { id = 'start', text = 'Start image (old)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_start_images, "Generate start image")
      end, enabled = _tier > 0 }
      :button { id = 'reshape', text = 'Reshape', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_reshape, "Generate reshape")
      end, enabled = _tier > 0 }
      :separator {}
      :button { id = "close_deprecrated_tools", text = 'Back', onclick = function()
        closeAllDialogs()
        openToolsDialog()
      end }
      :show {
        wait = false,
        autoscrollbars = true,
      }

  show_openTools = true
  SetDialogBounds(dlgDeprecatedTools, dlgDeprecatedToolsPosition)
end

function openToolsDialog()
  closeAllDialogs()
  dlgTools = Dialog { title = "PixelLab         ", onclose = function()
        dlgToolsPosition = GetDialogPosition(dlgTools)
        show_openTools = false
      end }
      :separator { text = "General tools" }
      :newrow { always = true }
      :button { id = 'style', text = 'Create image (style)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_style, "Generate image (style) (Ctrl+Space+S)")
      end }
      :button { id = 'style_old', text = 'Create image (style, old)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_style_old, "Generate image (style - old)")
      end }
      :button { id = 'general', text = 'Create large image', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_general_images_xl, "Generate large images")
      end }
      :button { id = 'tiles', text = 'Create map', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_tiles, "Generate maps")
      end, enabled = _tier > 0 }
      -- :button{ id = 'tiles_style', text = 'Map tiles (style)', onclick=function() closeAllDialogs() openSettingsDialog(generate_tiles_style, "Generate tiles (style) (Ctrl+Space+T)") end, enabled = _tier > 0 }
      :button { id = 'inpainting', text = 'Inpaint', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_inpainting, "Generate inpainting")
      end }
      :button { id = 'rotate single', text = 'Rotate', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_rotate_single, "Generate rotation")
      end }
      :separator { text = "Character tools" }
      :button { id = 'generate_character', text = 'Create character', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_character, "Generate character (Ctrl+Space+C)")
      end }
      :button { id = 'generate_character_old', text = 'Create character (old)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_character_old, "Generate character (old)")
      end }
      :button { id = 'movement', text = 'Animate (text)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_movement,
          "Generate animation                                                                                                      (Ctrl+Space+A)")
      end, enabled = _tier > 0 }
      :button { id = 'pose_animation', text = 'Animate (skeleton)', onclick = function()
        closeAllDialogs()
        -- openSettingsDialog(generate_pose_animation,
        --   "Skeleton animation                                                                                          (Ctrl+Space+Q)")
        openSettingsDialogSkeleton(generate_pose_animation,
          "Skeleton animation                                                                                          (Ctrl+Space+Q)")
      end, enabled = _tier > 0 }
      :button { id = 'interpolation', text = 'Interpolate', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_interpolation,
          "Generate interpolation (Generate animation)                                                                                              ")
      end, enabled = _tier > 0 }
      :separator { text = "Experimental tools" }
      :button { id = 'inpainting_map', text = 'Create map (new)', onclick = function()
        closeAllDialogs()
        openSettingsDialog(generate_inpainting_map, "Create map (new)")
      end, enabled = _tier > 1 }
      :separator {}
      :button { id = 'deprecated', text = "Extra tools", onclick = function()
        openDeprecatedToolsDialog()
      end
      }
      :button { id = 'help', text = "Documentation", onclick = function()
        local url = "https://www.pixellab.ai/docs"
        -- Open the URL in the default web browser
        if os.execute("start " .. url) == nil then
          if os.execute("xdg-open " .. url) == nil then
            if os.execute("open " .. url) == nil then
              print("Failed to open the URL.")
            end
          end
        end
      end
      }
      :check { id = 'always_open', text = 'Always open', selected = always_open,
        onclick = function()
          always_open = dlgTools.data.always_open
          dlgTools:modify { id = "close_tools", visible = (always_open == false) }
        end
      }
      :check { id = 'fullscreen', text = 'Reset UI to Aseprite', selected = fullscreen,
        onclick = function()
          fullscreen = dlgTools.data.fullscreen
        end
      }
      :button { id = "close_tools", text = 'Close', onclick = function() closeAllDialogs() end, visible = (always_open == false) }
      :show {
        wait = false,
        autoscrollbars = true,
      }

  show_openTools = true
  SetDialogBounds(dlgTools, dlgToolsPosition)
end

local function ResetAllToDefault()
  current_default_json = createJson.deepcopy(createJSON.default_json)
  generate_general_images.current_json = createJson.deepcopy(generate_general_images.default_json)
  generate_general_images_xl.current_json = createJson.deepcopy(generate_general_images_xl.default_json)
  generate_pose.current_json = createJson.deepcopy(generate_pose.default_json)
  generate_re_pose.current_json = createJson.deepcopy(generate_re_pose.default_json)
  generate_pose_animation.current_json = createJson.deepcopy(generate_pose_animation.default_json)
  generate_canny.current_json = createJson.deepcopy(generate_canny.default_json)
  generate_start_images.current_json = createJson.deepcopy(generate_start_images.default_json)
  generate_movement.current_json = createJson.deepcopy(generate_movement.default_json)
  generate_interpolation.current_json = createJson.deepcopy(generate_interpolation.default_json)
  generate_reshape.current_json = createJson.deepcopy(generate_reshape.default_json)
  generate_inpainting.current_json = createJson.deepcopy(generate_inpainting.default_json)
  generate_inpainting_map.current_json = createJson.deepcopy(generate_inpainting_map.default_json)
  generate_tiles.current_json = createJson.deepcopy(generate_tiles.default_json)
  generate_style.current_json = createJson.deepcopy(generate_style.default_json)
  generate_style_old.current_json = createJson.deepcopy(generate_style_old.default_json)
  generate_character.current_json = createJson.deepcopy(generate_character.default_json)
  generate_character_old.current_json = createJson.deepcopy(generate_character_old.default_json)
  generate_rotations.current_json = createJson.deepcopy(generate_rotations.default_json)
  generate_resize.current_json = createJson.deepcopy(generate_resize.default_json)
  generate_rotate_single.current_json = createJson.deepcopy(generate_rotate_single.default_json)
  generate_tiles_style.current_json = createJson.deepcopy(generate_tiles_style.default_json)
  _show_advanced_settings = false
  always_open = true
  fullscreen = true
end

local function LoadPreviousValues(plugin)
  _show_advanced_settings = plugin.preferences._show_advanced_settings
  if plugin.preferences.default_json ~= nil then
    current_default_json = createJson.deepcopy(plugin.preferences.default_json)
  else
    current_default_json = createJson.deepcopy(createJSON.default_json)
  end
  if plugin.preferences.generate_general_images ~= nil then
    generate_general_images.current_json = createJson.deepcopy(plugin.preferences.generate_general_images)
  end
  if plugin.preferences.generate_general_images_xl ~= nil then
    generate_general_images_xl.current_json = createJson.deepcopy(plugin.preferences.generate_general_images_xl)
  end
  if plugin.preferences.generate_pose ~= nil then
    generate_pose.current_json = createJson.deepcopy(plugin.preferences.generate_pose)
  end
  if plugin.preferences.generate_re_pose ~= nil then
    generate_re_pose.current_json = createJson.deepcopy(plugin.preferences.generate_re_pose)
  end
  if plugin.preferences.generate_pose_animation ~= nil then
    generate_pose_animation.current_json = createJson.deepcopy(plugin.preferences.generate_pose_animation)
    generate_pose_animation.current_json["selected_reference_image"] = ""
  end
  if plugin.preferences.generate_canny ~= nil then
    generate_canny.current_json = createJson.deepcopy(plugin.preferences.generate_canny)
  end
  if plugin.preferences.generate_start_images ~= nil then
    generate_start_images.current_json = createJson.deepcopy(plugin.preferences.generate_start_images)
  end
  if plugin.preferences.generate_movement ~= nil then
    generate_movement.current_json = createJson.deepcopy(plugin.preferences.generate_movement)
    generate_movement.current_json["selected_reference_image"] = ""
  end
  if plugin.preferences.generate_interpolation ~= nil then
    generate_interpolation.current_json = createJson.deepcopy(plugin.preferences.generate_interpolation)
    generate_interpolation.current_json["interpolation_from"] = ""
    generate_interpolation.current_json["interpolation_to"] = ""
    generate_interpolation.current_json["selected_reference_image"] = ""
  end
  if plugin.preferences.generate_reshape ~= nil then
    generate_reshape.current_json = createJson.deepcopy(plugin.preferences.generate_reshape)
  end
  if plugin.preferences.generate_inpainting ~= nil then
    generate_inpainting.current_json = createJson.deepcopy(plugin.preferences.generate_inpainting)
  end
  if plugin.preferences.generate_inpainting_map ~= nil then
    generate_inpainting_map.current_json = createJson.deepcopy(plugin.preferences.generate_inpainting_map)
  end
  if plugin.preferences.generate_rotations ~= nil then
    generate_rotations.current_json = createJson.deepcopy(plugin.preferences.generate_rotations)
  end
  if plugin.preferences.generate_tiles ~= nil then
    generate_tiles.current_json = createJson.deepcopy(plugin.preferences.generate_tiles)
  end
  if plugin.preferences.generate_style ~= nil then
    generate_style.current_json["style_image"] = "No"
    generate_style.current_json = createJson.deepcopy(plugin.preferences.generate_style)
  end
  if plugin.preferences.generate_style_old ~= nil then
    generate_style_old.current_json["style_image"] = "No"
    generate_style_old.current_json = createJson.deepcopy(plugin.preferences.generate_style_old)
  end
  if plugin.preferences.generate_character ~= nil then
    generate_character.current_json["style_image"] = "No"
    generate_character.current_json = createJson.deepcopy(plugin.preferences.generate_character)
  end
  if plugin.preferences.generate_character_old ~= nil then
    generate_character_old.current_json["style_image"] = "No"
    generate_character_old.current_json = createJson.deepcopy(plugin.preferences.generate_character_old)
  end
  if plugin.preferences.generate_resize ~= nil then
    generate_resize.current_json["style_image"] = "No"
    generate_resize.current_json = createJson.deepcopy(plugin.preferences.generate_resize)
  end
  if plugin.preferences.generate_tiles_style ~= nil then
    generate_tiles_style.current_json["style_image"] = "No"
    generate_tiles_style.current_json = createJson.deepcopy(plugin.preferences.generate_tiles_style)
  end
  if plugin.preferences.generate_rotate_single ~= nil then
    generate_rotate_single.current_json["from_image"] = ""
    generate_rotate_single.current_json = createJson.deepcopy(plugin.preferences.generate_rotate_single)
  end
  if plugin.preferences.dlgAdvancedSettingsPosition ~= nil then
    dlgAdvancedSettingsPosition = createJson.deepcopy(plugin.preferences.dlgAdvancedSettingsPosition)
  end
  if plugin.preferences.dlgSettingsPosition ~= nil then
    dlgSettingsPosition = createJson.deepcopy(plugin.preferences.dlgSettingsPosition)
  end
  if plugin.preferences.dlgToolsPosition ~= nil then
    dlgToolsPosition = createJson.deepcopy(plugin.preferences.dlgToolsPosition)
  end
  if plugin.preferences.dlgDeprecatedTools ~= nil then
    dlgDeprecatedToolsPosition = createJson.deepcopy(plugin.preferences.dlgDeprecatedToolsPosition)
  end
  if plugin.preferences.always_open ~= nil then
    always_open = createJson.deepcopy(plugin.preferences.always_open)
  else
    always_open = true
  end
  if plugin.preferences.fullscreen ~= nil then
    fullscreen = createJson.deepcopy(plugin.preferences.fullscreen)
  else
    fullscreen = true
  end
  show_openTools = always_open

  if plugin.preferences.dlgLoadingPosition ~= nil then
    dlgLoadingPosition = createJson.deepcopy(plugin.preferences.dlgLoadingPosition)
  end
end

function init(plugin)
  LoadPreviousValues(plugin)
  UpdateDialog()
  if plugin.preferences.version == nil or plugin.preferences.version ~= _version then
    ResetAllToDefault()
  end
  if always_open then
    openToolsDialog()
  end

  plugin:newMenuGroup {
    id = "pixellab_group",
    title = "PixelLab v" .. _version,
    group = "edit_new"
  }
  plugin:newCommand {
    id = 'PixelLab',
    title = 'Open plugin',
    group = 'pixellab_group',
    onclick = openToolsDialog,
  }

  plugin:newMenuSeparator {
    group = "pixellab_group"
  }

  plugin:newCommand {
    id = 'UpdatePlugin',
    title = 'Update plugin',
    group = 'pixellab_group',
    onclick = update_plugin.run
  }

  plugin:newCommand {
    id = 'FullscreenReset',
    title = 'Reset UI to Aseprite',
    group = 'pixellab_group',
    onclick = function()
      fullscreen = true
      closeAllDialogs()
      openToolsDialog()
    end
  }

  plugin:newCommand {
    id = 'PixelLab_Pose_Edit',
    title = 'Pose - edit',
    onclick = handle_pose.edit,
    onenabled = function()
      return current_model ~= nil and current_model.current_json ~= nil and
          current_model.current_json["model_name"] == "generate_pose_animation"
    end,
  }

  plugin:newCommand {
    id = 'PixelLab_Pose_Style',
    title = 'Pose - Style',
    onclick = function()
      closeAllDialogs()
      openSettingsDialog(generate_style, "Generate image (style) (Ctrl+Space+S)")
    end,
  }
  plugin:newCommand {
    id = 'PixelLab_Pose_Character',
    title = 'Pose - Style',
    onclick = function()
      closeAllDialogs()
      openSettingsDialog(generate_character, "Generate character (Ctrl+Space+C)")
    end,
  }
  plugin:newCommand {
    id = 'PixelLab_Pose_Animation',
    title = 'Pose - Animation',
    onclick = function()
      closeAllDialogs()
      openSettingsDialog(generate_movement,
        "Generate animation                                                                                                          (Ctrl+Space+A)")
    end,
  }
  plugin:newCommand {
    id = 'PixelLab_Pose_Skeleton',
    title = 'Pose - Skeleton',
    onclick = function()
      closeAllDialogs()
      openSettingsDialog(generate_pose_animation,
        "Skeleton animation                                                                                           (Ctrl+Space+Q)")
    end,
  }
  plugin:newCommand {
    id = 'PixelLab_Pose_Tiles',
    title = 'Pose - Tiles',
    onclick = function()
      closeAllDialogs()
      openSettingsDialog(generate_tiles_style, "Generate tiles (style) (Ctrl+Space+T)")
    end,
  }
end

function exit(plugin)
  if _updated == false then
    plugin.preferences.always_open = always_open
    plugin.preferences.fullscreen = fullscreen
    if dlgSettings ~= nil then
      plugin.preferences.dlgSettingsPosition = GetDialogPosition(dlgSettings)
    end
    if dlgAdvancedSettings ~= nil then
      plugin.preferences.dlgAdvancedSettingsPosition = GetDialogPosition(dlgAdvancedSettings)
    end
    if dlgTools ~= nil then
      plugin.preferences.dlgToolsPosition = GetDialogPosition(dlgTools)
    end
    if dlgDeprecatedTools ~= nil then
      plugin.preferences.dlgDeprecatedToolsPosition = GetDialogPosition(dlgDeprecatedTools)
    end
    if dlgLoadingPosition ~= nil then
      plugin.preferences.dlgLoadingPosition = dlgLoadingPosition
    end

    plugin.preferences.version = _version
    plugin.preferences.default_json = current_default_json
    plugin.preferences._show_advanced_settings = _show_advanced_settings
    plugin.preferences.generate_general_images = generate_general_images.current_json
    plugin.preferences.generate_general_images_xl = generate_general_images_xl.current_json
    plugin.preferences.generate_pose = generate_pose.current_json
    plugin.preferences.generate_re_pose = generate_re_pose.current_json
    generate_pose_animation.current_json["selected_reference_image"] = ""
    plugin.preferences.generate_pose_animation = generate_pose_animation.current_json
    plugin.preferences.generate_canny = generate_canny.current_json
    plugin.preferences.generate_start_images = generate_start_images.current_json
    generate_movement.current_json["selected_reference_image"] = ""
    plugin.preferences.generate_movement = generate_movement.current_json
    generate_interpolation.current_json["selected_reference_image"] = ""
    generate_interpolation.current_json["interpolation_from"] = ""
    generate_interpolation.current_json["interpolation_to"] = ""
    plugin.preferences.generate_interpolation = generate_interpolation.current_json
    plugin.preferences.generate_reshape = generate_reshape.current_json
    plugin.preferences.generate_inpainting = generate_inpainting.current_json
    plugin.preferences.generate_inpainting_map = generate_inpainting_map.current_json
    plugin.preferences.generate_tiles = generate_tiles.current_json
    generate_tiles_style.current_json["style_image"] = "No"
    plugin.preferences.generate_tiles_style = generate_tiles_style.current_json
    generate_style.current_json["style_image"] = "No"
    plugin.preferences.generate_style = generate_style.current_json
    generate_style_old.current_json["style_image"] = "No"
    plugin.preferences.generate_style_old = generate_style_old.current_json
    generate_character.current_json["style_image"] = "No"
    plugin.preferences.generate_character = generate_character.current_json
    generate_character_old.current_json["style_image"] = "No"
    plugin.preferences.generate_character_old = generate_character_old.current_json
    generate_resize.current_json["style_image"] = "No"
    plugin.preferences.generate_resize = generate_resize.current_json
    generate_rotate_single.current_json["from_image"] = ""
    plugin.preferences.generate_rotate_single = generate_rotate_single.current_json
    plugin.preferences.generate_rotations = generate_rotations.current_json
  end
end

local wasActiveSprite = nil
app.events:on('sitechange',
  function()
    local status, err = pcall(function()
      if dlgTools ~= nil and always_open and wasActiveSprite ~= app.activeSprite and show_openTools then
        if app.activeSprite ~= nil and app.activeSprite.filename == "Sketch - Canny" then
          if wasActiveSprite ~= nil and wasActiveSprite.filename == "Sketch - Canny" then
            dlgTools:close()
            dlgDeprecatedTools:close()
            openToolsDialog()
          end
        elseif wasActiveSprite ~= nil and wasActiveSprite.filename == "Sketch - Canny" then
        else
          if dlgTools ~= nil and always_open == false and show_openTools then
            wasActiveSprite = app.activeSprite
            dlgTools:close()
            dlgDeprecatedTools:close()
            openToolsDialog()
          end
        end
      end
      if current_model ~= nil then
        local d = getOpenDialog()
        if d ~= nil and d.data.warning_custom ~= nil then
          show_warning_text(current_model, d)
        end
      end
    end)
  end)

update_plugin.check_for_update()
