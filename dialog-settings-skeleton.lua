local getImage = dofile('./get-image.lua')
local mask = dofile('./mask.lua')
local createJson = dofile('./create-json.lua')

function showSkeletonSettings(dlg, model, current_default_json, name, advanced)
    dlg:tab { id = "skeleton_setup", text = "Skeleton setup" }
    if model.dialog_json.tabs.active_tab[1] == "skeleton_setup" then
        base_settings(dlg, model, "skeleton_setup")
    end
    dlg:tab { id = "generate", text = "Generation" }
    if model.dialog_json.tabs.active_tab[1] == "generate" then
        dialog_skeleton_preview:create_image_generate_display(model, dlg)

        dlg:button { id = 'selected_reference_image', text = 'Set reference', onclick = function()
            getImage.current_json = model.current_json
            model.dialog_json["pose"]
                ["handle_pose"].estimate_skeleton(true)
            model.current_json["selected_reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame,
                app.activeImage)
            model.dialog_json["selected_reference_frame"] = { app.activeFrame.frameNumber }
        end
        }
        showGenerateSettings(dlg, model, name, advanced)
    end
    dlg:endtabs { id = "main_tab", onchange = function()
        model.dialog_json.tabs.active_tab[1] = dlg.data.main_tab

        closeAllDialogs()
        openSettingsDialogSkeleton(model, name, true)
        app.refresh()
    end, selected = model.dialog_json.tabs.active_tab[1] }

    if model.dialog_json.tabs.active_tab[1] == "skeleton_setup" then
        showTemplateSkeletonSettings(dlg, model, name, advanced)
    end

    dlg:check { id = "advanced_options", label = "               ", text = "Advanced options", selected = _show_advanced_settings, onclick = function()
        _show_advanced_settings = dlg.data.advanced_options
        closeAllDialogs()
        openSettingsDialogSkeleton(model, name, true)
        app.refresh()
    end }
    dlg:newrow()

    -- action buttons
    dlg:button { id = 'insert_template', text = 'Insert template', onclick = function()
        model.dialog_json["pose"]
            ["handle_pose"].get_pose()
    end, visible = dlg.data.main_tab == "skeleton_setup" and dlg.data["skeleton_tabs"] == "template_skeleton" }
    dlg:button { id = 'rescale', text = 'Rescale', onclick = function()
        if #model.dialog_json["selected_frames"] > 0 then
            handle_pose.rescale_poses(model.dialog_json["selected_frames"],
                pose_references:get_rescaled_points_from_range(model.dialog_json["selected_frames"]))
        end
    end, visible = dlg.data.main_tab == "skeleton_setup" and dlg.data["skeleton_tabs"] == "animation_to_animation" }
    dlg:button { id = 'skeleton_setup_reset', text = 'Reset',
        onclick = function()
            model.current_json["size_height_pose"] = model.default_json["size_height_pose"]
            model.current_json["size_width_pose"] = model.default_json["size_width_pose"]
            model.current_json["size_head_pose"] = model.default_json["size_head_pose"]
            model.current_json["size_depth_pose"] = model.default_json["size_depth_pose"]
            model.current_json["x_pose"] = model.default_json["x_pose"]
            model.current_json["y_pose"] = model.default_json["y_pose"]
            model.current_json["fixed_head"] = model.default_json["fixed_head"]
            model.dialog_json["selected_reference_frame"] = {}
            model.dialog_json["selected_frames"] = {}
            model.dialog_json["show_reference_over_display"] = false
            closeAllDialogs()
            openSettingsDialogSkeleton(model, name, true)
        end, visible = dlg.data.main_tab == "skeleton_setup"
    }
    dlg:button { id = 'generate', text = 'Generate', onclick = function()
        model.generate(model, current_default_json, name,
            "Settings")
    end, visible = dlg.data.main_tab == "generate" }
    dlg:button { id = 'reset', text = 'Reset', onclick = function()
        model.current_json = createJson.deepcopy(model.default_json)
        model.dialog_json["selected_reference_frame"] = {}
        model.dialog_json["selected_frames"] = {}
        model.dialog_json["show_reference_over_display"] = false
        closeAllDialogs()
        openSettingsDialogSkeleton(model, name, true)
    end, visible = dlg.data.main_tab == "generate" }
    dlg:button { id = 'documentation', text = 'Documentation', onclick = function()
        local url = model.dialog_json["documentation_" .. dlg.data.skeleton_tabs]
        -- Open the URL in the default web browser
        if os.execute("start " .. url) == nil then
            if os.execute("xdg-open " .. url) == nil then
                if os.execute("open " .. url) == nil then
                    print("Failed to open the URL.")
                end
            end
        end
    end, visible = dlg.data.main_tab == "skeleton_setup" }
    dlg:button { id = 'cancel', text = 'Cancel', onclick = function()
        closeAllDialogs()
        openToolsDialog()
    end }

    dlg:show { wait = false, autoscrollbars = true }
end

function showTemplateSkeletonSettings(dlg, model, name, advanced)
    dlg:tab { id = "template_skeleton", text = "Template skeleton" }
    dialog_skeleton_preview:create_template_display(model, dlg, "template_skeleton")
    dlg:label { id = "help_text", text = "Use the settings and/or edit reference skeleton to ensure the template matches your character as well as possible." }
    templateSkeletonControllerSettings(dlg, model, "template_skeleton", advanced)
    dlg:tab { id = "animation_to_animation", text = "Animation to animation" }
    dialog_skeleton_preview:create_animation_to_animation_display(model, dlg, "animation_to_animation")
    dlg:label { id = "help_text_animation_to_animation", text = "Select multiple frames of the animation you wish to create skeletons for." }
    dlg:newrow()
    dlg:label { id = "help_text_animation_to_animation_2", text = "Use the settings to rescale your skeleton if necessary" }
    animationToAnimationControllerSettings(dlg, model, "animation_to_animation", advanced)
    dlg:endtabs { id = "skeleton_tabs", onchange = function()
        -- dlg:modify { id = "set_animation", visible = dlg.data.skeleton_tabs == "animation_to_animation" }
        dlg:modify { id = "insert_template", visible = dlg.data.skeleton_tabs == "template_skeleton" }
        dlg:modify { id = "rescale", visible = dlg.data.skeleton_tabs == "animation_to_animation" }
        model.dialog_json.tabs.active_tab[2] = dlg.data.skeleton_tabs
    end,
        selected = model.dialog_json.tabs.active_tab[2] }
end

function base_settings(dialog, model, id)
    dialog_skeleton_preview:create_reference_display(model, dialog, "selected_reference_image")
    dialog:button { id = 'selected_reference_image', text = 'Set reference', onclick = function()
        getImage.current_json = model.current_json
        model.dialog_json["pose"]
            ["handle_pose"].estimate_skeleton(true)
        model.current_json["selected_reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame,
            app.activeImage)
        model.dialog_json["selected_reference_frame"] = { app.activeFrame.frameNumber }
    end }

    dialog:button { id = 'estimate_skeleton', text = 'Estimate skeleton', onclick = function()
        model.dialog_json["pose"]
            ["handle_pose"].estimate_skeleton()
    end, visible = id == "skeleton_setup" }

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

function templateSkeletonControllerSettings(dlg, model, id, advanced)
    dlg:slider { id = id .. "_scroll_preview", min = 0, max = 2, label = "Scroll:", value = model.current_json["scroll_preview"],
        onchange = function()
            model.current_json["scroll_preview"] = dlg.data[id .. "_scroll_preview"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:combobox {
        id = id .. "_reference_direction",
        label = "Reference direction:",
        text = "",
        option = model.current_json["reference_direction"],
        options = model.dialog_json["guidance"]["reference_direction"],
        onchange = function()
            model.current_json["reference_direction"] = dlg.data[id .. "_reference_direction"]
            dialog_skeleton_preview:repaint(dlg)
        end,
    }
    dlg:combobox {
        id = id .. "_pose_template",
        label = "Animation template:",
        text = "",
        option = handle_pose.option_points,
        options = pose_references:get_options(),
        onchange = function()
            handle_pose.option_points = dlg.data[id .. "_pose_template"]
            dialog_skeleton_preview:repaint(dlg)
        end,
    }
    dlg:combobox {
        id = id .. "_view",
        label = "Template view/direction:",
        option = translateView(model.current_json["view"]),
        options = translateList(model.dialog_json["guidance"]["view"]),
        onchange = function()
            model.current_json["view"] = translateView(dlg.data[id .. "_view"])
            dialog_skeleton_preview:repaint(dlg)
        end,
    }
    dlg:combobox {
        id = id .. "_direction",
        option = translateDirection(model.current_json["direction"]),
        options = translateList(model.dialog_json["guidance"]["direction"]),
        onchange = function()
            model.current_json["direction"] = translateDirection(dlg.data[id .. "_direction"])

            local direction = model.current_json["direction"]
            dlg:modify { id = "template_skeleton_size_width_pose", visible = string.match(direction, "south") ~= nil or string.match(direction, "north") ~= nil }
            dlg:modify { id = "template_skeleton_size_depth_pose", visible = string.match(direction, "east") ~= nil or string.match(direction, "west") ~= nil }
            local label_skeleton_size = "Skeleton height/width:"
            if string.match(direction, "-") then
                label_skeleton_size = "Skeleton height/width/depth:"
            end
            dlg:modify { id = "template_skeleton_size_height_pose", label = label_skeleton_size }
            dialog_skeleton_preview:repaint(dlg)
        end,
    }
    if advanced then
        dlg:check {
            id = id .. "_fixed_head_always",
            label = "Fixed head (copy reference):",
            text = "Always",
            selected = model.current_json["fixed_head"] == "always",
            onclick = function()
                if dlg.data.template_skeleton_fixed_head_always then
                    dlg:modify { id = "animation_to_animation_fixed_head_always", selected = true }
                    dlg:modify { id = "template_skeleton_fixed_head_same_direction", selected = false }
                    model.current_json["fixed_head"] = "always"
                else
                    dlg:modify { id = "template_skeleton_fixed_head_same_direction", selected = false }
                    dlg:modify { id = "animation_to_animation_fixed_head_always", selected = false }
                    model.current_json["fixed_head"] = ""
                end
            end
        }
        dlg:check {
            id = id .. "_fixed_head_same_direction",
            text = "Same reference and template direction",
            selected = model.current_json["fixed_head"] == "same_direction",
            onclick = function()
                if dlg.data.animation_to_animation_fixed_head_always then
                    dlg:modify { id = "animation_to_animation_fixed_head_always", selected = false }
                    dlg:modify { id = "template_skeleton_fixed_head_always", selected = false }
                    model.current_json["fixed_head"] = "same_direction"
                else
                    dlg:modify { id = "animation_to_animation_fixed_head_always", selected = false }
                    dlg:modify { id = "template_skeleton_fixed_head_always", selected = false }
                    model.current_json["fixed_head"] = ""
                end
            end
        }
    end

    local label_skeleton_size = "Skeleton height/width:"

    if string.match(model.current_json["direction"], "-") then
        label_skeleton_size = "Skeleton height/width/depth:"
    end

    dlg:slider { id = id .. "_size_height_pose", min = 1, max = 50, label = label_skeleton_size, value = model.current_json["size_height_pose"],
        onchange = function()
            model.current_json["size_height_pose"] = dlg.data[id .. "_size_height_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:slider { id = id .. "_size_width_pose", min = 1, max = 50, value = model.current_json["size_width_pose"],
        onchange = function()
            model.current_json["size_width_pose"] = dlg.data[id .. "_size_width_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end,
        visible = (string.match(model.current_json["direction"], "south") ~= nil or string.match(model.current_json["direction"], "north") ~= nil)
    }

    dlg:slider { id = id .. "_size_depth_pose", min = 1, max = 50, value = model.current_json["size_depth_pose"],
        onchange = function()
            model.current_json["size_depth_pose"] = dlg.data[id .. "_size_depth_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end,
        visible = (string.match(model.current_json["direction"], "east") ~= nil or string.match(model.current_json["direction"], "west") ~= nil)
    }

    if advanced then
        dlg:slider { id = id .. "_size_head_pose", label = "Skeleton head size:", min = 1, max = 50, value = model.current_json["size_head_pose"],
            onchange = function()
                model.current_json["size_head_pose"] = dlg.data[id .. "_size_head_pose"]
                dialog_skeleton_preview:repaint(dlg)
            end
        }
    end

    dlg:slider { id = id .. "_x_pose", min = -50, max = 50, label = "Offset x/y:         ", value = model.current_json["x_pose"],
        onchange = function()
            model.current_json["x_pose"] = dlg.data[id .. "_x_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:slider { id = id .. "_y_pose", min = -50, max = 50, value = model.current_json["y_pose"],
        onchange = function()
            model.current_json["y_pose"] = dlg.data[id .. "_y_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
end

function animationToAnimationControllerSettings(dlg, model, id, advanced)
    dlg:slider { id = id .. "_scroll_preview", min = 0, max = 2, label = "Scroll:", value = model.current_json["scroll_preview"],
        onchange = function()
            model.current_json["scroll_preview"] = dlg.data[id .. "_scroll_preview"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:button { id = 'set_animation', text = 'Set animation', onclick = function()
        if app.range.isEmpty then
            app.alert(
                "Select frames in tab below. It will automatically give the image a skeleton which you can then rescale based on your reference/settings")
        else
            model.dialog_json["selected_frames"] = createJSON.deepcopy(app.range.frames)
            model.dialog_json["pose"]
                ["handle_pose"].estimate_skeleton(true)
        end
    end, visible = id == "animation_to_animation" }
    dlg:button { id = 'clear_animation', text = 'Clear animation', onclick = function()
        model.dialog_json["selected_frames"] = {}
    end, visible = id == "animation_to_animation" }

    model.dialog_json["show_reference_over_display"] = false
    dlg:button { id = 'show_reference_over_display', text = 'Show reference', onclick = function()
        if model.dialog_json["show_reference_over_display"] == false then
            model.dialog_json["show_reference_over_display"] = true
            dlg:modify { id = "show_reference_over_display", text = 'Hide reference' }
        else
            model.dialog_json["show_reference_over_display"] = false
            dlg:modify { id = "show_reference_over_display", text = 'Show reference' }
        end
    end }

    if advanced then
        dlg:check {
            id = id .. "_fixed_head_always",
            label = "Fixed head:",
            text = "Always (copy head from reference)",
            selected = model.current_json["fixed_head"] == "always",
            onclick = function()
                if dlg.data.animation_to_animation_fixed_head_always then
                    model.current_json["fixed_head"] = "always"
                    dlg:modify { id = "template_skeleton_fixed_head_same_direction", selected = false }
                    dlg:modify { id = "template_skeleton_fixed_head_always", selected = true }
                else
                    model.current_json["fixed_head"] = ""
                    dlg:modify { id = "template_skeleton_fixed_head_same_direction", selected = false }
                    dlg:modify { id = "template_skeleton_fixed_head_always", selected = false }
                end
                dialog_skeleton_preview:repaint(dlg)
            end
        }
    end

    local label_skeleton_size = "Skeleton height/width:"
    dlg:slider { id = id .. "_size_height_pose", min = 1, max = 50, label = label_skeleton_size, value = model.current_json["size_height_pose"],
        onchange = function()
            model.current_json["size_height_pose"] = dlg.data[id .. "_size_height_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:slider { id = id .. "_size_width_pose", min = 1, max = 50, value = model.current_json["size_width_pose"],
        onchange = function()
            model.current_json["size_width_pose"] = dlg.data[id .. "_size_width_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    if advanced then
        dlg:slider { id = id .. "_size_head_pose", label = "Skeleton head size:", min = 1, max = 50, value = model.current_json["size_head_pose"],
            onchange = function()
                model.current_json["size_head_pose"] = dlg.data[id .. "_size_head_pose"]
                dialog_skeleton_preview:repaint(dlg)
            end
        }
    end
    dlg:slider { id = id .. "_x_pose", min = -50, max = 50, label = "Offset x/y:         ", value = model.current_json["x_pose"],
        onchange = function()
            model.current_json["x_pose"] = dlg.data[id .. "_x_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
    dlg:slider { id = id .. "_y_pose", min = -50, max = 50, value = model.current_json["y_pose"],
        onchange = function()
            model.current_json["y_pose"] = dlg.data[id .. "_y_pose"]
            dialog_skeleton_preview:repaint(dlg)
        end
    }
end

function showGenerateSettings(dialog, model, name, advanced)
    dialog:check { id = "generation_setup_one_reference", label = "Generation setup:", text = "Freeze 1 -> Generate 3 frames", selected = (model.dialog_json["generate"]["number_of_freeze_frame"] == 1 and model.dialog_json["generate"]["number_of_generate_frame"] == 3), onclick = function()
        dialog:modify { id = "generation_setup_three_reference", selected = false }
        dialog:modify { id = "generation_setup_custom_reference", selected = false }
        dialog:modify { id = "generation_setup_text", text = "3 frames will be generated based on the frozen frame" }
        model.dialog_json["generate"]["generation_setup"] = "Freeze 1 -> Generate 3 frames"
        model.dialog_json["generate"]["number_of_freeze_frame"] = 1
        model.dialog_json["generate"]["number_of_generate_frame"] = 3

        dialog:modify { id = "use_inpainting", selected = model.current_json["use_inpainting"], enabled = true }
        -- dialog:modify { id = "selected_reference_image", visible = model.dialog_json["generate"]["generation_setup"] == "Custom" }
    end }
    dialog:check { id = "generation_setup_three_reference", selected = model.dialog_json["generate"]["number_of_freeze_frame"] == 3, text = "Freeze 3 -> Generate 1 frame", onclick = function()
        dialog:modify { id = "generation_setup_one_reference", selected = false }
        dialog:modify { id = "generation_setup_custom_reference", selected = false }
        dialog:modify { id = "generation_setup_text", text = "1 new frame will be generated based on the 3 frozen frames" }
        model.dialog_json["generate"]["generation_setup"] = "Freeze 3 -> Generate 1 frame"
        model.dialog_json["generate"]["number_of_freeze_frame"] = 3
        model.dialog_json["generate"]["number_of_generate_frame"] = 1

        dialog:modify { id = "use_inpainting", selected = model.current_json["use_inpainting"], enabled = true }
        -- dialog:modify { id = "selected_reference_image", visible = model.dialog_json["generate"]["generation_setup"] == "Custom" }
    end }
    dialog:check { id = "generation_setup_custom_reference", selected = model.dialog_json["generate"]["number_of_generate_frame"] == 4, text = "Custom", onclick = function()
        dialog:modify { id = "generation_setup_one_reference", selected = false }
        dialog:modify { id = "generation_setup_three_reference", selected = false }
        dialog:modify { id = "generation_setup_text", text = "Paint in the inpainting layer to select which frames to generate" }
        model.dialog_json["generate"]["generation_setup"] = "Custom"
        model.dialog_json["generate"]["number_of_freeze_frame"] = 0
        model.dialog_json["generate"]["number_of_generate_frame"] = 4

        dialog:modify { id = "use_inpainting", selected = true, enabled = false }
        -- dialog:modify { id = "selected_reference_image", visible = model.dialog_json["generate"]["generation_setup"] == "Custom" }
    end }
    dialog:label { id = "generation_setup_text", text = "3 frames will be generated based on the frozen frame" }
    dialog:check {
        id = "use_inpainting",
        text = "Use inpainting",
        selected = model.current_json["use_inpainting"],
        onclick = function()
            model.current_json["use_inpainting"] = dialog.data.use_inpainting
            if dialog.data.use_inpainting then
                if mask.layer_exist(app.activeSprite, "PixelLab - Inpainting", app.activeFrame) == false then
                    app.alert { title = "Inpainting - info", text = 'Draw black where you want to modify the image in the "PixelLab - Inpainting" layer or leave it empty to use size instead', buttons = "OK" }
                    mask.create_layer(app.activeSprite, "PixelLab - Inpainting", app.activeFrame)
                end
            end
        end,
        enabled = model.dialog_json["generate"]["generation_setup"] ~= "Custom"
    }
    dialog:separator { id = "separator_guidance", text = "Guidance" }
    if advanced then
        dialog:slider { id = "reference_guidance_scale", label = "Reference guidance weight:", min = 0, max = 200, value = model.current_json["reference_guidance_scale"] * 10, onchange = function()
            model.current_json["reference_guidance_scale"] =
                dialog.data.reference_guidance_scale / 10.0
        end }


        dialog:slider { id = "pose_guidance_scale", label = "Pose guidance weight:", min = 0, max = 200, value = model.current_json["pose_guidance_scale"] * 10, onchange = function()
            model.current_json["pose_guidance_scale"] =
                dialog.data.pose_guidance_scale / 10.0
        end }
    end
    dialog:combobox {
        id = "view",
        label = "Camera view:",
        option = translateView(model.current_json["view"]),
        options = translateList(model.dialog_json["guidance"]["view"]),
        visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
        onchange = function()
            model.current_json["view"] = translateView(dialog.data.view)
        end
    }
    dialog:combobox {
        id = "direction",
        label = "Direction:",
        option = translateDirection(model.current_json["direction"]),
        options = translateList(model.dialog_json["guidance"]["direction"]),
        visible = model.current_json["view_direction"] == nil or model.current_json["view_direction"],
        onchange = function()
            model.current_json["direction"] = translateDirection(dialog.data.direction)
        end
    }
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
    dialog:check {
        id = "oblique_projection",
        text = "Oblique projection (beta)",
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
    dialog:separator { id = "separator_init_image", text = "Init image" }
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
            dialog:modify { id = "canvas_init_images", visible = dialog.data.init_images == "Yes" }
            dialog:modify { id = "init_image_strength", enabled = model.current_json["init_images"][1] == "Yes" }
            dialog:modify { id = "init_image_strength", visible = model.current_json["init_images"][1] == "Yes" }
            -- To fix the size
            dialog:close()
            openSettingsDialogSkeleton(model, name, true)
        end,
        -- enabled=app.activeSprite ~= nil or dialog.data.init_images == "Yes"
    }
    displayImagesInDialog.displayImagesDialog(dialog, model, "init_images", model.current_json["init_images"][1] == "Yes")
    dialog:slider { id = "init_image_strength", min = 1, max = 999, value = model.current_json["init_image_strength"],
        label = "Init image strength:",
        enabled = dialog.data.init_image == "Yes" or dialog.data.init_images == "Yes",
        visible = dialog.data.init_image == "Yes" or dialog.data.init_images == "Yes",
        onchange = function()
            model.current_json["init_image_strength"] = dialog.data.init_image_strength
        end }
    dialog:separator { id = "separator_color", text = "Color" }
    dialog:combobox { id = 'color_image', label = 'Target palette:',
        option = model.current_json["color_image"],
        options = model.dialog_json["color_image"]["options"],
        -- enabled = app.activeSprite ~= nil,
        onchange = function()
            model.current_json["color_image"] = dialog.data.color_image
            -- dialog:modify{id="canvas_color_image", visible = dialog.data.color_image ~= "No"}
            if model.current_json["force_colors"] ~= nil and model.current_json["force_colors"] and dialog.data.color_image == "No" then
                dialog:modify { id = "force_colors", selected = false }
                model.current_json["force_colors"] = false
            end
            if model.current_json["forced_colors"] ~= nil then
                dialog:modify { id = "forced_colors", enabled = dialog.data.color_image ~= "No" }
                dialog:modify { id = "forced_colors", selected = dialog.data.color_image ~= "No" }
            end
        end
    }
    dialog:separator { id = "separator_general", text = "General" }
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
    if advanced then
        dialog:entry { id = "seed", label = "seed (0 = random seed):", text = model.current_json["seed"], onchange = function()
            model.current_json["seed"] =
                dialog.data.seed
        end }
        dialog:file {
            id = "get_history_request",
            label = "Load previous settings:",
            title = "Select history",
            load = true,
            save = false,
            filename = _path .. "request_history" .. separator .. model.default_json.model_name .. separator,
            filetypes = { "json", "png" },
            onchange = function()
                request_history.transfer_over(
                    request_history.load_request_from_filename(dialog.data.get_history_request),
                    model.current_json)
                dialog:close()
                showAdvancedSettingsSkeleton(model, name)
            end
        }
    end
end
