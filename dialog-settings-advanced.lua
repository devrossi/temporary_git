local mask = dofile('./mask.lua')
local getImage = dofile('./get-image.lua')

function imageAdvancedDialog(dialog, model, current_default_json, name)
  if model.default_json["model_name"] == "generate_rotations" and model.default_json["model_name"] == "generate_movement" then
    dialog:label { id = "rotation_inpainting_info", text = "Black area will be inpainted. Everything else will remain unchanged" }
  end
  select_image(dialog, model, name, "from_image", "From image:", false)
  if model.default_json["style_image"] ~= nil then
    dialog:button { id = 'set_style_image', label = "Style image:", text = "Set", onclick = function()
      model.default_json["style_image"] = ""
      getImage.current_json = model.current_json
      if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
        model.current_json["style_image"] = getImage.get_selection(model.current_json["max_size"][1],
          model.current_json["max_size"][2])
      else
        model.current_json["style_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
      end
      dialog:close()
      openSettingsDialog(model, name)
    end
    }
    dialog:button { id = 'clear_style_image', text = "Clear", onclick = function()
      model.default_json["style_image"] = "No"
      model.current_json["style_image"] = "No"
      dialog:close()
      openSettingsDialog(model, name)
    end
    }
  end
  if model.default_json["use_selection"] ~= nil then
    dialog:check { id = 'use_selection', text = 'Paint in selection', selected = model.current_json["use_selection"],
      onclick = function()
        model.current_json["use_selection"] = dialog.data.use_selection
      end
    }
  end
  local selection_size = "160x160"
  if model.default_json["model_name"] == "generate_tiles_style" or model.default_json["model_name"] == "generate_style" or model.default_json["model_name"] == "generate_style_old" then
    selection_size = "140x140"
  end
  if _tier < 2 then
    if model.default_json["model_name"] == "generate_tiles_style" or model.default_json["model_name"] == "generate_style" or model.default_json["model_name"] == "generate_style_old" then
      selection_size = "80x80"
    else
      selection_size = "100x100"
    end
  end
  if model.default_json["max_size"] ~= nil and model.default_json["model_name"] ~= "generate_movement" and model.default_json["model_name"] ~= "generate_interpolation" then
    dialog:check { id = 'max_size', text = "Custom size (max " .. selection_size .. ")", selected = model.current_json["max_size"][1] == 160 or model.current_json["max_size"][1] == 140, enabled = _tier > 0,
      onclick = function()
        if dialog.data.max_size then
          if _tier > 1 then
            if model.default_json["model_name"] == "generate_tiles_style" or model.default_json["model_name"] == "generate_style" or model.default_json["model_name"] == "generate_style_old" then
              model.current_json["max_size"][1] = 140
              model.current_json["max_size"][2] = 140
            else
              model.current_json["max_size"][1] = 160
              model.current_json["max_size"][2] = 160
            end
          else
            if model.default_json["model_name"] == "generate_tiles_style" or model.default_json["model_name"] == "generate_style" or model.default_json["model_name"] == "generate_style_old" then
              model.current_json["max_size"][1] = 80
              model.current_json["max_size"][2] = 80
            else
              model.current_json["max_size"][1] = 100
              model.current_json["max_size"][2] = 100
            end
          end
        else
          model.current_json["max_size"][1] = 64
          model.current_json["max_size"][2] = 64
        end
        if dialog.data.max_size and app.activeSprite ~= nil and app.activeSprite.height * app.activeSprite.width > 80 * 80 then
          show_warning("warning_custom_size", true)
        else
          show_warning("warning_custom_size", false)
        end
        -- if model.current_json["use_tiling"] ~= nil and model.current_json["use_tiling"] and dialog.data.max_size then
        --   model.current_json["max_size"][1] = 64
        --   model.current_json["max_size"][2] = 64
        --   dialog:modify { id = "max_size", selected = false }
        --   app.alert("To use " .. selection_size .. " force tiling must be off")
        -- end
      end
    }
  end

  -- if model.default_json["use_tiling"] ~= nil then
  --   dialog:check { id = 'use_tiling', text = 'Force tiling', selected = model.current_json["use_tiling"],
  --     onclick = function()
  --       model.current_json["use_tiling"] = dialog.data.use_tiling
  --       dialog:modify { id = "tiling_position", visible = model.current_json["use_tiling"] }
  --       dialog:modify { id = "vertical_tiling", visible = model.current_json["use_tiling"] }
  --       dialog:modify { id = "horizontal_tiling", visible = model.current_json["use_tiling"] }

  --       if model.current_json["use_tiling"] then
  --         model.current_json["max_size"][1] = 64
  --         model.current_json["max_size"][2] = 64
  --         dialog:modify { id = "max_size", selected = false }
  --         app.alert("To use " .. selection_size .. " force tiling must be off")
  --       end
  --     end
  --   }
  --   dialog:combobox {
  --     id = "tiling_position",
  --     label = "Tiling position:",
  --     option = model.current_json["tiling_position"],
  --     options = {
  --       "northwest",
  --       "northeast",
  --       "southwest",
  --       "southeast"
  --     },
  --     visible = model.current_json["use_tiling"],
  --     onchange = function() model.current_json["tiling_position"] = dialog.data.tiling_position end
  --   }
  --   dialog:check { id = 'vertical_tiling', text = 'vertical tiling', selected = model.current_json["vertical_tiling"], visible = model.current_json["use_tiling"],
  --     onclick = function()
  --       model.current_json["vertical_tiling"] = dialog.data.vertical_tiling
  --     end
  --   }
  --   dialog:check { id = 'horizontal_tiling', text = 'horizontal tiling', selected = model.current_json["horizontal_tiling"], visible = model.current_json["use_tiling"],
  --     onclick = function()
  --       model.current_json["horizontal_tiling"] = dialog.data.horizontal_tiling
  --     end
  --   }
  -- end
  if model.dialog_json["warning_custom_size"] ~= nil then
    dialog:label { id = "warning_custom_size", text = "Warning! Sizes above 80x80 are only experimentally supported and may cause artifacts like duplications.", enabled = false }
    if dialog.data.max_size and app.activeSprite ~= nil and app.activeSprite.height * app.activeSprite.width > 80 * 80 then
      show_warning("warning_custom_size", true)
    else
      show_warning("warning_custom_size", false)
    end
  end
  if model.default_json["selected_reference_image"] ~= nil then
    dialog:button { id = 'selected_reference_image', text = 'Set reference image', onclick = function()
      getImage.current_json = model.current_json
      if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
        model.current_json["selected_reference_image"] = getImage.get_selection(model.current_json["max_size"][1],
          model.current_json["max_size"][2])
      else
        model.current_json["selected_reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame,
          app.activeImage)
      end
    end
    }
  end
  if model.dialog_json["pose"] ~= nil then
    if model.dialog_json["pose"]["edit"] ~= nil then
      dialog:button { id = 'edit', text = 'Edit skeleton (ctrl+space+e)', onclick = function()
        if model.dialog_json["pose"]["edit"] then
          model.dialog_json["pose"]["edit"] = false
          dialog:modify { id = "edit", text = "Edit skeleton (ctrl+space+e)" }
        else
          model.dialog_json["pose"]["edit"] = true
          dialog:modify { id = "edit", text = "Stop edit (ctrl+space+e)" }
        end
        model.dialog_json["pose"]["handle_pose"].edit()
      end }
    end
    dialog:newrow()
    dialog:combobox {
      id = "reference_direction",
      label = "Reference direction:",
      text = "",
      option = model.current_json["reference_direction"],
      options = model.dialog_json["guidance"]["reference_direction"],
      onchange = function()
        model.current_json["reference_direction"] = dialog.data.reference_direction
      end
    }

    dialog:combobox {
      id = "pose_template",
      label = "Animation template:",
      text = "",
      option = handle_pose.option_points,
      options = pose_references:get_options(),
      onchange = function() handle_pose.option_points = dialog.data.pose_template end
    }
    dialog:button { id = 'show_skeleton_preview', text = 'Change skeleton template size',
      onclick = function()
        model.current_json["show_skeleton_preview"] = true
        dialog_skeleton_preview:show_hide(true)
      end
    }
    dialog:check {
      id = "fixed_head_always",
      label = "Fixed head:",
      text = "Always",
      selected = model.current_json["fixed_head"] == "always",
      onclick = function()
        if dialog.data.fixed_head_same_direction then
          model.current_json["fixed_head"] = "always"
          dialog:modify { id = "fixed_head_same_direction", selected = false }
        else
          model.current_json["fixed_head"] = ""
        end
      end
    }
    dialog:check {
      id = "fixed_head_same_direction",
      text = "Same reference and template direction",
      selected = model.current_json["fixed_head"] == "same_direction",
      onclick = function()
        if dialog.data.fixed_head_same_direction then
          model.current_json["fixed_head"] = "same_direction"
          dialog:modify { id = "fixed_head_always", selected = false }
        else
          model.current_json["fixed_head"] = ""
        end
      end
    }
    dialog:newrow()
    dialog:button { id = 'get_pose', text = 'Insert skeletons', onclick = function()
      model.dialog_json["pose"]
          ["handle_pose"].get_pose()
    end }
    dialog:button { id = 'get_pose', text = 'Estimate skeleton', onclick = function()
      model.dialog_json["pose"]
          ["handle_pose"].estimate_skeleton()
    end }
    dialog:button { id = 'reset_pose', text = 'Reset skeleton', onclick = function()
      model.dialog_json["pose"]
          ["handle_pose"].reset()
    end }
  end
  if model.default_json["interpolation_from"] ~= nil then
    dialog:button { id = 'selected_interpolation_from', text = 'Set from image', onclick = function()
      getImage.current_json = model.current_json
      if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
        model.current_json["interpolation_from"] = getImage.get_selection(model.current_json["max_size"][1],
          model.current_json["max_size"][2])
      else
        model.current_json["interpolation_from"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
      end
    end
    }
  end
  if model.default_json["interpolation_to"] ~= nil then
    dialog:button { id = 'selected_interpolation_to', text = 'Set to image', onclick = function()
      getImage.current_json = model.current_json
      if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
        model.current_json["interpolation_to"] = getImage.get_selection(model.current_json["max_size"][1],
          model.current_json["max_size"][2])
      else
        model.current_json["interpolation_to"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
      end
    end
    }
  end
  if model.current_json["image_guidance_scale"] ~= nil then
    dialog:slider { id = "image_guidance_scale", min = 0, max = 200, label = "Image guidance weight:", value = model.current_json["image_guidance_scale"] * 10,
      onchange = function()
        model.current_json["image_guidance_scale"] = dialog.data.image_guidance_scale / 10.0
      end
    }
  end
  if model.current_json["resize_image_strength"] ~= nil then
    dialog:slider { id = "resize_image_strength", min = 1, max = 999, label = "Image strength:", value = model.current_json["resize_image_strength"],
      onchange = function()
        model.current_json["resize_image_strength"] = dialog.data.resize_image_strength
      end
    }
  end
  if model.current_json["inspirational_image_strength"] ~= nil then
    dialog:slider { id = "inspirational_image_strength", min = 1, max = 999, label = "Init image strength:", value = model.current_json["inspirational_image_strength"],
      onchange = function()
        model.current_json["inspirational_image_strength"] = dialog.data.inspirational_image_strength
      end
    }
  end

  if model.current_json["use_inpainting"] ~= nil then
    dialog:check {
      id = "use_inpainting",
      text = "Use inpainting",
      selected = model.current_json["use_inpainting"],
      onclick = function()
        model.current_json["use_inpainting"] = dialog.data.use_inpainting
        if model.current_json["size"] ~= nil then
          dialog:modify { id = "size", visible = dialog.data.use_inpainting == false }
        end
        if dialog.data.use_inpainting then
          if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
            app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer.', buttons = "OK" }
            mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
          end
          model.current_json["inpainting_image"] = ""
        else
          model.current_json["inpainting_image"] = "No"
        end
        dialog:close()
        showAdvancedSettings(model, name)
      end
    }
  end

  if model.current_json["style_strength"] ~= nil and model.current_json["style_image"] ~= nil and model.current_json["style_image"] ~= "No" then
    dialog:slider { id = "style_strength", min = 10, max = 100, label = "Style image strength", value = model.current_json["style_strength"] * 90 + 10, onchange = function()
      model.current_json["style_strength"] =
          (dialog.data.style_strength - 10) / 90.0
    end, visible = dialog.data.use_style_image }
  end

  if model.current_json["style_guidance_scale"] ~= nil and model.current_json["style_image"] ~= nil and model.current_json["style_image"] ~= "No" then
    dialog:slider { id = "style_guidance_scale", min = 0, max = 100, label = "Style guidance weight:", value = model.current_json["style_guidance_scale"] * 10, onchange = function()
      model.current_json["style_guidance_scale"] =
          dialog.data.style_guidance_scale / 10.0
    end, visible = dialog.data.use_style_image }
  end

  if model.current_json["intermediate_guidance_scale"] ~= nil then
    dialog:slider { id = "intermediate_guidance_scale", min = 0, max = 200, label = "Intermediate guidance weight:", value = model.current_json["intermediate_guidance_scale"] * 10, onchange = function()
      model.current_json["intermediate_guidance_scale"] =
          dialog.data.intermediate_guidance_scale / 10.0
    end }
  end

  if model.current_json["shape_guidance_scale"] ~= nil then
    dialog:slider { id = "shape_guidance_scale", label = "Shape guidance weight:", min = 0, max = 200, value = model.current_json["shape_guidance_scale"] * 10, onchange = function()
      model.current_json["shape_guidance_scale"] =
          dialog.data.shape_guidance_scale / 10.0
    end }
  end

  if model.current_json["reference_guidance_scale"] ~= nil then
    dialog:slider { id = "reference_guidance_scale", label = "Reference guidance weight:", min = 0, max = 200, value = model.current_json["reference_guidance_scale"] * 10, onchange = function()
      model.current_json["reference_guidance_scale"] =
          dialog.data.reference_guidance_scale / 10.0
    end }
  end
  if model.current_json["pose_guidance_scale"] ~= nil then
    dialog:slider { id = "pose_guidance_scale", label = "Pose guidance weight:", min = 0, max = 200, value = model.current_json["pose_guidance_scale"] * 10, onchange = function()
      model.current_json["pose_guidance_scale"] =
          dialog.data.pose_guidance_scale / 10.0
    end }
  end
  if model.current_json["inpainting_guidance_scale"] ~= nil then
    dialog:slider { id = "inpainting_guidance_scale", label = "Inpainting guidance weight:", min = model.dialog_json["guidance"]["inpainting_guidance_scale"][1], max = model.dialog_json["guidance"]["inpainting_guidance_scale"][2], value = model.current_json["inpainting_guidance_scale"] * 10, onchange = function()
      model.current_json["inpainting_guidance_scale"] =
          dialog.data.inpainting_guidance_scale / 10.0
    end }
  end
end

function characterAdvancedDialog(dialog, model, current_default_json, name)
  if model.current_json["description"] ~= nil then
    dialog:separator { id = "separator_character", text = "Guidance" }
  else
    dialog:separator { id = "separator_character", text = "Character" }
  end
  if current_default_json["hide_character"] ~= nil and current_default_json["hide_character"] and (model.current_json["model_name"] == "generate_simple_movement" or model.current_json["model_name"] == "generate_style" or model.current_json["model_name"] == "generate_tiles_style" or model.current_json["model_name"] == "generate_movement" or model.current_json["model_name"] == "generate_rotations" or model.current_json["model_name"] == "generate_attack" or model.current_json["model_name"] == "generate_rotate_single" or model.default_json["model_name"] == "generate_style_old") then
    dialog:button { id = 'hide_character', text = 'Show options', onclick = function()
      current_default_json["hide_character"] = false
      dialog:close()
      showAdvancedSettings(model, name)
    end
    }
    return
  end
  if model.current_json["description"] ~= nil then
    dialog:entry { id = "description", label = "Description:", text = model.current_json["description"], onchange = function()
      model.current_json["description"] =
          dialog.data.description
    end }
  elseif model.default_json["model_name"] ~= "generate_pose_animation" and model.default_json["model_name"] ~= "generate_rotate_single" then
    dialog:entry { id = "character", label = "Character Description:", text = current_default_json["character"], onchange = function()
      current_default_json["character"] =
          dialog.data.character
    end }
  end
  if model.current_json["negative_description"] ~= nil then
    dialog:entry { id = "negative_description", label = "Negative description:", text = model.current_json["negative_description"], onchange = function()
      model.current_json["negative_description"] =
          dialog.data.negative_description
    end }
    if model.current_json["model_name"] == "generate_inpainting" or model.current_json["model_name"] == "generate_style" then
      dialog:label { text = '(e.g. "strong dithering", "artefacts", "mixels")' }
    end
  end
  -- If no action guidance scale place action here
  if model.current_json["action_guidance_scale"] == nil then
    if model.current_json["action"] ~= nil then
      dialog:entry { id = "action", label = "Action description:", text = model.current_json["action"], onchange = function()
        model.current_json["action"] =
            dialog.data.action
      end }
    end

    if model.default_json["model_name"] == "generate_movement" then
      dialog:label { text = '(e.g. "walk", "run", "fly", "fireball attack", "gun attack", "slash attack")' }
    elseif model.current_json["model_name"] == "generate_simple_movement" then
      dialog:label { text = 'E.g. "walk", "fly"' }
    elseif model.default_json["model_name"] == "generate_attack" then
      dialog:label { text = 'E.g. "slash", "fire breath"' }
    end
  end

  if model.dialog_json["guidance"] ~= nil and model.current_json["view_direction"] ~= nil then
    dialog:check { id = 'view_direction', text = 'Use view and direction', selected = model.current_json["view_direction"],
      onclick = function()
        model.current_json["view_direction"] = dialog.data.view_direction
        dialog:modify { id = "view", visible = model.current_json["view_direction"] }
        dialog:modify { id = "direction", visible = model.current_json["view_direction"] }
      end
    }
  end

  if model.current_json["from_view"] ~= nil then
    dialog:combobox {
      id = "from_view",
      label = "From view:",
      text = "",
      option = translateView(model.current_json["from_view"]),
      options = translateList(model.dialog_json["guidance"]["from_view"]),
      onchange = function() model.current_json["from_view"] = translateView(dialog.data.from_view) end
    }
  end

  if model.current_json["to_view"] ~= nil then
    dialog:combobox {
      id = "to_view",
      label = "To view:",
      text = "",
      option = translateView(model.current_json["to_view"]),
      options = translateList(model.dialog_json["guidance"]["to_view"]),
      onchange = function() model.current_json["to_view"] = translateView(dialog.data.to_view) end
    }
  end

  if model.current_json["from_direction"] ~= nil then
    dialog:combobox {
      id = "from_direction",
      label = "From direction:",
      text = "",
      option = translateDirection(model.current_json["from_direction"]),
      options = translateList(model.dialog_json["guidance"]["from_direction"]),
      onchange = function() model.current_json["from_direction"] = translateDirection(dialog.data.from_direction) end
    }
  end

  if model.current_json["to_direction"] ~= nil then
    dialog:combobox {
      id = "to_direction",
      label = "To direction:",
      text = "",
      option = translateDirection(model.current_json["to_direction"]),
      options = translateList(model.dialog_json["guidance"]["to_direction"]),
      onchange = function() model.current_json["to_direction"] = translateDirection(dialog.data.to_direction) end
    }
  end
  if model.current_json["view"] ~= nil and model.dialog_json["guidance"] ~= nil and model.dialog_json["guidance"]["view"] ~= nil then
    local options = model.dialog_json["guidance"]["view"]
    if model.dialog_json["guidance"]["view"]["tier_1"] ~= nil then
      if _tier == 2 then
        options = model.dialog_json["guidance"]["view"]["tier_2"]
      else
        options = model.dialog_json["guidance"]["view"]["tier_1"]
      end
    end
    dialog:combobox {
      id = "view",
      label = "Camera view:",
      option = translateView(model.current_json["view"]),
      options = translateList(options),
      visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
      onchange = function()
        model.current_json["view"] = translateView(dialog.data.view)
      end
    }
  end
  if model.current_json["direction"] ~= nil and model.dialog_json["guidance"] ~= nil and model.dialog_json["guidance"]["direction"] ~= nil then
    local options = model.dialog_json["guidance"]["direction"]
    if model.dialog_json["guidance"]["direction"]["tier_1"] ~= nil then
      if _tier == 2 then
        options = model.dialog_json["guidance"]["direction"]["tier_2"]
      else
        options = model.dialog_json["guidance"]["direction"]["tier_1"]
      end
    end
    dialog:combobox {
      id = "direction",
      label = "Direction:",
      option = translateDirection(model.current_json["direction"]),
      options = translateList(options),
      visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
      onchange = function()
        model.current_json["direction"] = translateDirection(dialog.data.direction)
      end
    }
  end
  dialog:newrow { always = false }
  if model.current_json["outline"] ~= nil then
    dialog:combobox {
      id = "outline",
      label = "Outline/Shading/Details:",
      option = model.current_json["outline"],
      options = { "", "single color black outline", "single color outline", "selective outline", "lineless" },
      onchange = function()
        model.current_json["outline"] = dialog.data.outline
      end
    }
  end
  if model.current_json["shading"] ~= nil then
    dialog:combobox {
      id = "shading",
      option = model.current_json["shading"],
      options = { "", "flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading" },
      onchange = function()
        model.current_json["shading"] = dialog.data.shading
      end
    }
  end
  if model.current_json["detail"] ~= nil then
    dialog:combobox {
      id = "detail",
      option = model.current_json["detail"],
      options = { "", "low detail", "medium detail", "highly detailed" },
      onchange = function()
        model.current_json["detail"] = dialog.data.detail
      end
    }
    dialog:newrow { always = true }
  end
  if model.current_json["coverage_percentage"] ~= nil then
    dialog:slider { id = "coverage_percentage", min = 50, max = 100, value = model.current_json["coverage_percentage"] * 100,
      label = "Canvas coverage (%):",
      onchange = function()
        model.current_json["coverage_percentage"] = dialog.data.coverage_percentage / 100
      end
    }
  end
  if model.current_json["n_frames"] ~= nil and model.default_json["model_name"] == "generate_movement" then
    dialog:slider { id = "n_frames", label = "Number of frames / Start frame", min = 2, max = 20, value = model.current_json["n_frames"],
      onchange = function()
        model.current_json["n_frames"] = dialog.data.n_frames
        dialog:modify { id = "start_frame_index", max = model.current_json["n_frames"] }
        dialog:repaint()
      end
    }
  end

  if model.current_json["start_frame_index"] ~= nil then
    dialog:slider { id = "start_frame_index", min = 0, max = model.current_json["n_frames"], value = model.current_json["start_frame_index"],
      onchange = function()
        model.current_json["start_frame_index"] = dialog.data.start_frame_index
      end
    }
  end
  dialog:newrow { always = false }
  if model.current_json["isometric"] ~= nil then
    dialog:check {
      id = "isometric",
      text = "Isometric",
      selected = model.current_json["isometric"],
      enabled = (_tier == 2 or model.current_json["model_name"] ~= "generate_tiles_style"),
      onclick = function()
        model.current_json["isometric"] = dialog.data.isometric
        if model.current_json["oblique_projection"] ~= nil then
          model.current_json["oblique_projection"] = false
          dialog:modify { id = "oblique_projection", selected = model.current_json["oblique_projection"] }
        end
        if model.current_json["view"] ~= "high top-down" and model.current_json["isometric"] then
          model.current_json["view"] = "high top-down"
          dialog:modify { id = "view", option = translateView("high top-down") }
        end
        if model.current_json["isometric"] and model.current_json["map_zoom"] ~= nil and model.current_json["map_zoom"] ~= "32x32" then
          app.alert("Isometric only gives good results with 32x32")
        end
      end
    }
  end
  if model.current_json["oblique_projection"] ~= nil then
    dialog:check {
      id = "oblique_projection",
      text = "Oblique projection  (beta)",
      selected = model.current_json["oblique_projection"],
      enabled = (_tier == 2 or model.current_json["model_name"] ~= "generate_tiles_style"),
      onclick = function()
        model.current_json["oblique_projection"] = dialog.data.oblique_projection
        if model.current_json["isometric"] ~= nil then
          model.current_json["isometric"] = false
          dialog:modify { id = "isometric", selected = model.current_json["isometric"] }
        end
        if model.current_json["view"] ~= "high top-down" and model.current_json["oblique_projection"] then
          model.current_json["view"] = "high top-down"
          dialog:modify { id = "view", option = translateView("high top-down") }
        end
      end
    }
  end
  dialog:newrow { always = true }
  if model.current_json["size"] ~= nil then
    local text = "Size of character:"

    dialog:slider { id = "size", label = text, min = 10, max = 64, value = model.current_json["size"],
      onchange = function()
        model.current_json["size"] = dialog.data.size
      end
    }
    if model.current_json["use_inpainting"] ~= nil then
      dialog:modify { id = "size", visible = model.current_json["use_inpainting"] == false }
    end
  end
  if model.current_json["map_zoom"] ~= nil then
    dialog:combobox {
      id = "map_zoom",
      label = "Tile size:",
      option = translateDirection(model.current_json["map_zoom"]),
      options = {
        "32x32",
        "16x16",
        -- "8x8",
      },
      onchange = function()
        if model.current_json["isometric"] and dialog.data.map_zoom ~= "32x32" then
          app.alert("Isometric only gives good results with 32x32")
        else
          model.current_json["map_zoom"] = dialog.data.map_zoom
        end
      end
    }
  end
  if model.current_json["pose_image"] ~= nil and model.default_json["pose_image"] ~= "No" then
    dialog:file {
      id = "pose",
      label = "Add Pose:",
      title = "Select file",
      load = true,
      save = false,
      filetypes = { "png" },
      onchange = function()
        model.current_json["pose_image"] = dialog.data.pose
        if model.current_json["pose_image"] ~= "No" then
          dialog:modify { id = "pose", filename = model.current_json["pose_image"] }
        end
      end
    }
    if model.current_json["pose_image"] ~= "No" then
      dialog:modify { id = "pose", filename = model.current_json["pose_image"] }
    end
  end

  if model.current_json["action_guidance_scale"] ~= nil and model.current_json["model_name"] ~= "generate_movement" and model.current_json["model_name"] ~= "generate_simple_movement" then
    if model.current_json["action"] ~= nil then
      dialog:entry { id = "action", label = "Action description:", text = model.current_json["action"], onchange = function()
        model.current_json["action"] =
            dialog.data.action
      end }
    end

    if model.default_json["model_name"] == "generate_attack" then
      dialog:label { text = 'E.g. "slash attack", "fire breath attack", "magic attack"' }
    elseif model.default_json["model_name"] == "generate_simple_movement" then
      dialog:label { text = 'E.g. "walk", "fly"' }
    else
      dialog:label { text = 'E.g. "walk", "run" "fly"' }
    end

    dialog:slider { id = "action_guidance_scale", label = "Action guidance weight:", min = 0, max = 200, value = model.current_json["action_guidance_scale"] * 10, onchange = function()
      model.current_json["action_guidance_scale"] =
          dialog.data.action_guidance_scale / 10.0
    end }
  end
  if model.current_json["text_guidance_scale"] ~= nil then
    if model.dialog_json["guidance"] ~= nil and model.dialog_json["guidance"]["text_guidance_scale"] ~= nil then
      dialog:slider { id = "text_guidance_scale", label = "Guidance weight:", min = model.dialog_json["guidance"]["text_guidance_scale"][1], max = model.dialog_json["guidance"]["text_guidance_scale"][2], value = model.current_json["text_guidance_scale"] * 10, onchange = function()
        model.current_json["text_guidance_scale"] =
            dialog.data.text_guidance_scale / 10.0
      end }
    else
      dialog:slider { id = "text_guidance_scale", label = "Guidance weight:", min = 0, max = 200, value = model.current_json["text_guidance_scale"] * 10, onchange = function()
        model.current_json["text_guidance_scale"] =
            dialog.data.text_guidance_scale / 10.0
      end }
    end
  end

  if model.current_json["guidance_scale"] ~= nil then
    if model.dialog_json["guidance"]["guidance_scale"] ~= nil then
      dialog:slider { id = "guidance_scale", label = "Guidance weight:", min = model.dialog_json["guidance"]["guidance_scale"][1], max = model.dialog_json["guidance"]["guidance_scale"][2], value = model.current_json["guidance_scale"] * 10, onchange = function()
        model.current_json["guidance_scale"] =
            dialog.data.guidance_scale / 10.0
      end }
    else
      dialog:slider { id = "guidance_scale", label = "Guidance weight:", min = 0, max = 200, value = model.current_json["guidance_scale"] * 10, onchange = function()
        model.current_json["guidance_scale"] =
            dialog.data.guidance_scale / 10.0
      end }
    end
  end
  if model.default_json["zoom"] ~= nil then
    dialog:slider { id = "zoom", min = 1, max = 50, label = "Zoom (20 = x2):", value = model.current_json["zoom"] * 10,
      onchange = function()
        model.current_json["zoom"] = dialog.data.zoom / 10
      end
    }
  end
  if model.default_json["fidelity"] ~= nil then
    dialog:slider { id = "fidelity", min = 0, max = 10, label = "Fidelity:", value = model.current_json["fidelity"] * 10,
      onchange = function()
        model.current_json["fidelity"] = dialog.data.fidelity / 10
      end
    }
  end
  if current_default_json["hide_character"] ~= nil and current_default_json["hide_character"] == false and (model.current_json["model_name"] == "generate_simple_movement" or model.current_json["model_name"] == "generate_style" or model.current_json["model_name"] == "generate_tiles_style" or model.current_json["model_name"] == "generate_movement" or model.current_json["model_name"] == "generate_rotations" or model.current_json["model_name"] == "generate_attack" or model.current_json["model_name"] == "generate_rotate_single") then
    dialog:button { id = 'hide_character', text = 'Hide options', onclick = function()
      current_default_json["hide_character"] = true
      dialog:close()
      showAdvancedSettings(model, name)
    end
    }
  end
end

function actionAdvancedDialog(dialog, model, current_default_json)
  if model.current_json["model_name"] ~= "generate_simple_movement" then
    return
  end
  dialog:separator { id = "separator_action", text = "Action" }
  if model.current_json["action_guidance_scale"] ~= nil then
    if model.current_json["action"] ~= nil then
      dialog:entry { id = "action", label = "Action description:", text = model.current_json["action"], onchange = function()
        model.current_json["action"] =
            dialog.data.action
      end }
    end

    if model.default_json["model_name"] == "generate_attack" then
      dialog:label { text = 'E.g. "slash attack", "fire breath attack", "magic attack"' }
    elseif model.current_json["model_name"] == "generate_simple_movement" then
      dialog:label { text = 'E.g. "walk", "fly"' }
    else
      dialog:label { text = 'E.g. "walk", "run" "fly"' }
    end

    dialog:slider { id = "action_guidance_scale", label = "Guidance weight:", min = 0, max = 200, value = model.current_json["action_guidance_scale"] * 10, onchange = function()
      model.current_json["action_guidance_scale"] =
          dialog.data.action_guidance_scale / 10.0
    end }
  end
end

function cameraAdvancedDialog(dialog, model, current_default_json)
  dialog:separator { id = "camera_separator", text = "Camera" }

  if model.current_json["view_direction"] ~= nil then
    dialog:check { id = 'view_direction', text = 'Use view and direction', selected = model.current_json["view_direction"],
      onclick = function()
        model.current_json["view_direction"] = dialog.data.view_direction
        dialog:modify { id = "view", visible = model.current_json["view_direction"] }
        dialog:modify { id = "direction", visible = model.current_json["view_direction"] }
      end }
  end

  if model.current_json["view"] ~= nil and model.dialog_json["camera"] ~= nil and model.dialog_json["camera"]["view"] ~= nil then
    local options = model.dialog_json["camera"]["view"]
    if model.dialog_json["camera"]["view"]["tier_1"] ~= nil then
      if _tier == 2 then
        options = model.dialog_json["camera"]["view"]["tier_2"]
      else
        options = model.dialog_json["camera"]["view"]["tier_1"]
      end
    end
    dialog:combobox {
      id = "view",
      label = "View:",
      option = translateView(model.current_json["view"]),
      options = translateList(options),
      visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
      onchange = function() model.current_json["view"] = translateView(dialog.data.view) end
    }
  end
  if model.current_json["direction"] ~= nil and model.dialog_json["camera"] ~= nil and model.dialog_json["camera"]["direction"] ~= nil then
    local options = model.dialog_json["camera"]["direction"]
    if model.dialog_json["camera"]["direction"]["tier_1"] ~= nil then
      if _tier == 2 then
        options = model.dialog_json["camera"]["direction"]["tier_2"]
      else
        options = model.dialog_json["camera"]["direction"]["tier_1"]
      end
    end
    dialog:combobox {
      id = "direction",
      label = "Direction:",
      option = translateDirection(model.current_json["direction"]),
      options = translateList(options),
      visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
      onchange = function() model.current_json["direction"] = translateDirection(dialog.data.direction) end
    }
  end

  if model.current_json["view_direction_guidance_scale"] ~= nil then
    dialog:slider { id = "view_direction_guidance_scale", label = "Guidance weight:", min = 0, max = 100, value = model.current_json["view_direction_guidance_scale"] * 10,
      onchange = function()
        model.current_json["view_direction_guidance_scale"] = dialog.data
            .view_direction_guidance_scale / 10.0
      end,
      visible = model.current_json["view_direction"]
    }
  end

  if model.current_json["view_direction_size_guidance_scale"] ~= nil then
    dialog:slider { id = "view_direction_size_guidance_scale", label = "Guidance weight:", min = 0, max = 100, value = model.current_json["view_direction_size_guidance_scale"] * 10, onchange = function()
      model.current_json["view_direction_size_guidance_scale"] =
          dialog.data.view_direction_size_guidance_scale / 10.0
    end }
  end
end

function colorAdvancedDialog(dialog, model)
  local show = false
  dialog:separator { id = "separator_color", text = "Color", visible = false }
  if model.current_json["color_image"] ~= nil then
    show = true
    local options = { "No", "Color palette", "Current image" }
    if model.dialog_json["color_image"] ~= nil then
      options = model.dialog_json["color_image"]["options"]
    end
    dialog:combobox { id = 'color_image', label = 'Target palette:',
      option = model.current_json["color_image"],
      options = options,
      -- enabled = app.activeSprite ~= nil,
      onchange = function()
        if model.current_json["color_guidance_scale"] ~= nil then
          dialog:modify { id = "color_guidance_scale", enabled = dialog.data.color_image ~= "No" }
        end
        if model.current_json["force_colors"] ~= nil and model.current_json["force_colors"] and dialog.data.color_image == "No" then
          dialog:modify { id = "force_colors", selected = false }
          model.current_json["force_colors"] = false
        end
        if model.current_json["forced_colors"] ~= nil then
          dialog:modify { id = "forced_colors", selected = dialog.data.color_image ~= "No" }
          dialog:modify { id = "forced_colors", enabled = dialog.data.color_image ~= "No" }
        end
        -- dialog:modify{id="canvas_color_image", visible = dialog.data.color_image ~= "No"}
        model.current_json["color_image"] = dialog.data.color_image
      end
    }
    -- displayImagesInDialog.displayImagesDialog(dialog, model, "color_image", dialog.data.color_image ~= "No")
  end
  if model.current_json["color_guidance_scale"] ~= nil then
    show = true
    dialog:slider { id = "color_guidance_scale", min = 0, max = 200, label = "Guidance weight:", value = 20, value = model.current_json["color_guidance_scale"] * 10, onchange = function()
      model.current_json["color_guidance_scale"] =
          dialog.data.color_guidance_scale / 10.0
    end, enabled = dialog.data.color_image ~= "No" }
  end
  if model.current_json["force_colors"] ~= nil then
    dialog:check {
      id = "force_colors",
      text = "Force colors",
      selected = model.current_json["force_colors"],
      onclick = function()
        if dialog.data.force_colors and model.current_json["color_image"] == "No" then
          dialog:modify { id = "force_colors", selected = false }
          app.alert("Force colors require a target palette")
        else
          model.current_json["force_colors"] = dialog.data.force_colors
        end
      end
    }
  end
  if model.current_json["forced_colors"] ~= nil then
    show = true
    dialog:check { id = 'forced_colors', text = 'Force colors', selected = model.current_json["forced_colors"], enabled = dialog.data.color_image ~= "No", onclick = function()
      model.current_json["forced_colors"] =
          dialog.data.forced_colors
    end }
  end
  dialog:modify { id = "separator_color", visible = show }
end

function initImageAdvancedDialog(dialog, model, name)
  local show = false
  dialog:separator { id = "separator_init_image", text = "Init image", visible = false }
  if model.current_json["init_image"] ~= nil then
    show = true
    dialog:combobox {
      id = "init_image",
      label = "Use init image: ",
      option = model.current_json["init_image"],
      options = {
        "Yes",
        "No"
      },
      onchange = function()
        model.current_json["init_image"] = dialog.data.init_image
        dialog:modify { id = "init_image_strength", enabled = model.current_json["init_image"] == "Yes" }
        dialog:modify { id = "init_image_strength", visible = model.current_json["init_image"] == "Yes" }
        dialog:modify { id = "canvas_init_image", visible = model.current_json["init_image"] == "Yes" }
        dialog:close()
        openSettingsDialog(model, name)
        -- mask.showHideInpainting(dlg)
      end,
      -- enabled=app.activeSprite ~= nil
    }
    displayImagesInDialog.displayImagesDialog(dialog, model, "init_image", dialog.data.init_image == "Yes")
  end

  if model.current_json["init_images"] ~= nil then
    show = true
    dialog:combobox {
      id = "init_images",
      label = "Use init images:",
      option = model.current_json["init_images"][1],
      options = {
        "Yes",
        "No"
      },
      onchange = function()
        model.current_json["init_images"][1] = dialog.data.init_images
        dialog:modify { id = "init_image_strength", enabled = model.current_json["init_images"][1] == "Yes" }
        dialog:modify { id = "init_image_strength", visible = model.current_json["init_images"][1] == "Yes" }
        dialog:modify { id = "canvas_init_images", visible = dialog.data.init_images == "Yes" }
        dialog:close()
        openSettingsDialog(model, name)
      end,
      -- enabled=app.activeSprite ~= nil or dialog.data.init_images == "Yes"
    }
    displayImagesInDialog.displayImagesDialog(dialog, model, "init_images", dialog.data.init_images == "Yes")
  end

  if model.current_json["init_image_strength"] ~= nil then
    dialog:slider { id = "init_image_strength", min = 1, max = 999, label = "Init image strength:", value = model.current_json["init_image_strength"],
      enabled = dialog.data.init_image == "Yes" or dialog.data.init_images == "Yes",
      visible = dialog.data.init_image == "Yes" or dialog.data.init_images == "Yes",
      onchange = function()
        model.current_json["init_image_strength"] = dialog.data.init_image_strength
      end }
  end

  dialog:modify { id = "separator_init_image", visible = show }
end

function generalAdvancedDialog(dialog, model)
  local show = false
  dialog:separator { id = "separator_general", text = "General", visible = false }
  if model.current_json["output_method"] ~= nil then
    show = true
    dialog:combobox {
      id = "output_method",
      label = "Output method:",
      option = model.current_json["output_method"],
      options = {
        "New frame",
        "New layer",
        "New layer with changes",
        "Modify current layer, only changes",
        "Modify current layer"
      },
      onchange = function() model.current_json["output_method"] = dialog.data.output_method end
    }
  end

  if model.current_json["no_background"] ~= nil then
    dialog:check { id = 'no_background', text = 'Remove background', selected = model.current_json["no_background"],
      onclick = function()
        model.current_json["no_background"] = dialog.data.no_background
        if model.current_json["no_background_guidance_scale"] ~= nil then
          dialog:modify { id = "no_background_guidance_scale", visible = model.current_json["no_background"] }
        end
      end }
    if model.current_json["style_mode"] ~= nil then
      dialog:modify { id = "no_background", visible = model.current_json["use_inpainting"] }
    end
    if model.current_json["no_background_guidance_scale"] ~= nil then
      dialog:slider { id = "no_background_guidance_scale", label = "Gray background guidance weight:", min = 0, max = 100, value = model.current_json["no_background_guidance_scale"] * 10, onchange = function()
        model.current_json["no_background_guidance_scale"] =
            dialog.data.no_background_guidance_scale / 10.0
      end, visible = model.current_json["no_background"] }
    end
  end
  if model.current_json["transparent_background"] ~= nil then
    dialog:check { id = 'transparent_background', text = 'Remove background', selected = model.current_json["transparent_background"],
      onclick = function()
        model.current_json["transparent_background"] = dialog.data.transparent_background
      end }
  end
  if model.current_json["pixelart_style_guidance_scale"] ~= nil then
    dialog:slider { id = "pixelart_style_guidance_scale", label = "Pixelart style guidance weight:", min = 0, max = 200, value = model.current_json["pixelart_style_guidance_scale"] * 10, onchange = function()
      model.current_json["pixelart_style_guidance_scale"] =
          dialog.data.pixelart_style_guidance_scale / 10.0
    end, enabled = model.current_json["pixelart_style"] }
  end

  if model.current_json["n_frames"] ~= nil and model.default_json["model_name"] ~= "generate_movement" then
    dialog:slider { id = "n_frames", label = "Number of frames:", min = 0, max = 20, value = model.current_json["n_frames"],
      onchange = function()
        model.current_json["n_frames"] = dialog.data.n_frames
      end
    }
  end

  if model.current_json["intermediate"] ~= nil then
    dialog:slider { id = "intermediate", label = "Intermediate:", min = 0, max = 100, value = model.current_json["intermediate"] * 100,
      onchange = function()
        model.current_json["intermediate"] = dialog.data.intermediate / 100
      end
    }
  end

  if model.current_json["forced_symmetry"] ~= nil then
    dialog:check { id = 'forced_symmetry', text = 'Force symmetry', selected = model.current_json["forced_symmetry"], onclick = function()
      model.current_json["forced_symmetry"] =
          dialog.data.forced_symmetry
    end }
  end

  dialog:entry { id = "seed", label = "seed (0 = random seed):", text = model.current_json["seed"], onchange = function()
    model.current_json["seed"] =
        dialog.data.seed
  end }
  show = true
  dialog:modify { id = "separator_general", visible = show }
end
