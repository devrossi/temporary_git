local getImage = dofile('./get-image.lua')

local alpha_background_image = Image(4, 4)
for it in alpha_background_image:pixels() do
    local t = it.y % 2
    if it.x % 2 == t then
        it(app.pixelColor.rgba(128, 128, 128, 255))
    else
        it(app.pixelColor.rgba(192, 192, 192, 255))
    end
end
alpha_background_image:resize(64, 64)

local distance_between_image = 80

local im_black = Image(64, 64)
for it in im_black:pixels() do
    it(app.pixelColor.rgba(0, 0, 0, 255))
end

dialog_skeleton_preview = {
    update_speed = 0.2,
    last_updated_reference_display = 0,
    last_updated_animation_to_animation_display = 0,
    last_updated_template_display = 0,
    last_updated_generate_display = 0,
    user_repaint = false,
    repaint_timer = nil,
    repaint_in_a_bit = function(self, dlg)
        if self.repaint_timer ~= nil and self.repaint_timer.isRunning then
            self.repaint_timer:stop()
        end
        self.repaint_timer = Timer {
            interval = 0.2,
            ontick = function()
                dlg:repaint()
                self.repaint_timer:stop()
            end }
        self.repaint_timer:start()
    end,
    create_reference_display = function(self, model, dlg, id)
        dlg:canvas { id = "display_name",
            width = 320,
            height = 64,
            -- focus = false,
            onpaint = function(ev, t)
                local ctx = ev.context
                if not self.user_repaint then
                    if os.clock() < dialog_skeleton_preview.last_updated_reference_display + dialog_skeleton_preview.update_speed then
                        ctx.antialias = true
                        ctx.strokeWidth = 3
                        ctx:drawImage(alpha_background_image, ctx.width / 2 - 32, 0)
                        dialog_skeleton_preview:repaint_in_a_bit(dlg)
                        return
                    else
                        dialog_skeleton_preview.last_updated_reference_display = os.clock()
                    end
                end

                local selected_frames = model.dialog_json["selected_reference_frame"]

                if selected_frames == nil or selected_frames == {} or #selected_frames == 0 then
                    ctx.antialias = true
                    ctx.strokeWidth = 3

                    ctx:drawImage(alpha_background_image, ctx.width / 2 - 32, 0)
                    ctx:fillText("Set reference", ctx.width / 2 - 28, 32)
                else
                    local start_position = distance_between_image * (#selected_frames - 1) * 0.5
                    for index, selected_frame in ipairs(selected_frames) do
                        local offset_x = ctx.width / 2 - 32 + distance_between_image * (index - 1) - start_position
                        ctx.antialias = true
                        ctx.strokeWidth = 3
                        ctx:drawImage(alpha_background_image, offset_x, 0)

                        if app.activeSprite ~= nil then
                            local canvas_im = getImage.get_image(app.activeSprite, selected_frame,
                                app.activeImage)
                            canvas_im:resize(64, 64)
                            ctx:drawImage(canvas_im, offset_x, 0)

                            if canvas_im:isEmpty() then
                                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                                ctx:fillText("Missing image", offset_x + 4, 32)
                            end
                            reference_points = { get_pose_from_frame_number(selected_frame) }
                            if reference_points ~= nil and #reference_points > 0 then
                                dialog_skeleton_preview:add_skeleton_to_canvas(ctx, reference_points[1], offset_x)
                            end
                        end
                    end
                end
                self.user_repaint = false
            end
        }
    end,
    create_template_display = function(self, model, dlg, id)
        dlg:canvas { id = "display_name",
            width = 320,
            height = 64,
            focus = false,
            onpaint = function(ev)
                local ctx = ev.context
                if not self.user_repaint then
                    if os.clock() < dialog_skeleton_preview.last_updated_template_display + dialog_skeleton_preview.update_speed then
                        ctx.antialias = true
                        ctx.strokeWidth = 3
                        ctx:drawImage(alpha_background_image, ctx.width / 2 - 32 - 64, 0)
                        dialog_skeleton_preview:repaint_in_a_bit(dlg)
                        return
                    else
                        dialog_skeleton_preview.last_updated_template_display = os.clock()
                    end
                end

                local reference_points_list = pose_references:get_points_by_option(handle_pose.option_points)
                dlg:modify { id = id .. "_scroll_preview", max = (#reference_points_list - 1) // 4, visible = #reference_points_list > 4, value = math.min(model.current_json["scroll_preview"], (#reference_points_list - 1) // 4) }
                for index, reference_points in ipairs(reference_points_list) do
                    reference_points = { reference_points }
                    local offset_x = (index - 1) * 80 - model.current_json["scroll_preview"] * 320
                    -- + math.max(0, 220 - #reference_points_list * 40)
                    if #reference_points_list <= 4 then
                        local start_position = distance_between_image * (#reference_points_list - 1) * 0.5 + 64
                        offset_x = ctx.width / 2 - 32 + distance_between_image * (index - 1) - start_position
                    end

                    ctx.antialias = true
                    ctx.strokeWidth = 3
                    ctx:drawImage(alpha_background_image, offset_x, 0)
                    if app.activeSprite ~= nil then
                        local canvas_im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
                        canvas_im:resize(64, 64)
                        ctx:drawImage(canvas_im, offset_x, 0)
                    end

                    if reference_points ~= nil and #reference_points > 0 then
                        dialog_skeleton_preview:add_skeleton_to_canvas(ctx, reference_points[1], offset_x)
                    end
                end
            end
        }
    end,
    create_animation_to_animation_display = function(self, model, dlg, id)
        dlg:canvas { id = "display_name",
            width = 320,
            height = 64,
            focus = false,
            onpaint = function(ev)
                local ctx = ev.context
                if not self.user_repaint then
                    if os.clock() < dialog_skeleton_preview.last_updated_animation_to_animation_display + dialog_skeleton_preview.update_speed then
                        ctx.antialias = true
                        ctx:drawImage(alpha_background_image, ctx.width / 2 - 32 - 64, 0)
                    else
                        dialog_skeleton_preview.last_updated_animation_to_animation_display = os.clock()
                    end
                end

                local selected_frames = model.dialog_json["selected_frames"]

                if selected_frames == nil or selected_frames == {} or #selected_frames == 0 then
                    dlg:modify { id = id .. "_scroll_preview", visible = false }

                    ctx.antialias = true
                    ctx.strokeWidth = 3
                    ctx:drawImage(alpha_background_image, ctx.width / 2 - 32 - 64, 0)
                    ctx:fillText("Select frames", ctx.width / 2 - 28 - 64, 32)
                else
                    dlg:modify { id = id .. "_scroll_preview", max = (#selected_frames - 1) // 4, visible = #selected_frames > 4, value = math.min(#selected_frames, (#selected_frames - 1) // 4) }
                    local reference_points_list = pose_references:get_rescaled_points_from_range(selected_frames)
                    for index = 1, #selected_frames, 1 do
                        local offset_x = (index - 1) * 80 - model.current_json["scroll_preview"] * 320
                        -- + math.max(0, 220 - #reference_points_list * 40)
                        if #selected_frames <= 4 then
                            local start_position = distance_between_image * (#selected_frames - 1) * 0.5 + 64
                            offset_x = ctx.width / 2 - 32 + distance_between_image * (index - 1) - start_position -
                                model.current_json["scroll_preview"] * 320
                        end
                        ctx.antialias = true
                        ctx.strokeWidth = 3
                        ctx:drawImage(alpha_background_image, offset_x, 0)
                        if app.activeSprite ~= nil then
                            local canvas_im = getImage.get_image(app.activeSprite, selected_frames[index],
                                app.activeImage)
                            canvas_im:resize(64, 64)
                            ctx:drawImage(canvas_im, offset_x, 0)

                            if canvas_im:isEmpty() then
                                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                                ctx:fillText("Missing image", offset_x + 4, 32)
                            end
                        end
                        if reference_points_list and reference_points_list[index] then
                            local reference_points = { reference_points_list[index] }
                            if model.dialog_json["show_reference_over_display"] and #model.dialog_json["selected_reference_frame"] > 0 then
                                reference_points = { get_pose_from_frame_number(model.dialog_json
                                    ["selected_reference_frame"][1]) }
                            end
                            if reference_points ~= nil and #reference_points > 0 then
                                dialog_skeleton_preview:add_skeleton_to_canvas(ctx, reference_points[1], offset_x)
                            end
                        end
                    end
                end
            end
        }
    end,
    create_image_generate_display = function(self, model, dlg, id)
        getImage.current_json = model.current_json
        dlg:canvas { id = "display_name",
            width = 320,
            height = 85,
            onpaint = function(ev)
                local ctx = ev.context
                if not self.user_repaint then
                    if os.clock() < dialog_skeleton_preview.last_updated_generate_display + dialog_skeleton_preview.update_speed then
                        ctx.antialias = true
                        local start_position = distance_between_image * (5) * 0.5
                        for index = 0, 4, 1 do
                            local offset_x = ctx.width / 2 + distance_between_image * (index) - start_position
                            ctx:drawImage(alpha_background_image, offset_x, 0)
                        end
                        dialog_skeleton_preview:repaint_in_a_bit(dlg)
                        return
                    else
                        dialog_skeleton_preview.last_updated_generate_display = os.clock()
                    end
                end

                ctx.antialias = true
                ctx.strokeWidth = 3

                local number_of_freeze_frame = model.dialog_json["generate"]["number_of_freeze_frame"]
                local number_of_generate_frame = model.dialog_json["generate"]["number_of_generate_frame"]
                local use_inpainting = model.current_json["use_inpainting"]
                local generation_setup = model.dialog_json["generate"]["generation_setup"]

                local start_position = distance_between_image *
                    (1 + number_of_freeze_frame + number_of_generate_frame - 1) * 0.5

                local offset_x = ctx.width / 2 - 32 - start_position
                ctx:drawImage(alpha_background_image, offset_x, 0)

                if app.activeSprite ~= nil then
                    -- local reference_frame = app.activeFrame.frameNumber
                    -- if generation_setup == "Custom" then
                    --     if #model.dialog_json["selected_reference_frame"] > 0 then
                    --         reference_frame = model.dialog_json["selected_reference_frame"][1]
                    --     else
                    --         reference_frame = nil
                    --     end
                    -- end
                    local reference_frame = model.dialog_json["selected_reference_frame"][1]
                    if reference_frame then
                        local canvas_im = getImage.get_image(app.activeSprite,
                            reference_frame,
                            app.activeImage)
                        canvas_im:resize(64, 64)
                        ctx:drawImage(canvas_im, offset_x, 0)

                        if canvas_im:isEmpty() then
                            ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                            ctx:fillText("Missing image", offset_x + 4, 32)
                        else
                            local reference_points = get_pose_from_frame_number(reference_frame)
                            if reference_points ~= nil then
                                dialog_skeleton_preview:add_skeleton_to_canvas(ctx, reference_points, offset_x)
                            else
                                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                                ctx:fillText("Missing", offset_x + 20, 28)
                                ctx:fillText("skeleton", offset_x + 17, 36)
                            end
                        end
                    else
                        ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                        ctx:fillText("Missing", offset_x + 20, 28)
                        ctx:fillText("reference", offset_x + 13, 36)
                    end
                else
                    ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                    ctx:fillText("Missing", offset_x + 20, 28)
                    ctx:fillText("reference", offset_x + 13, 36)
                end

                -- draw line
                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                ctx.strokeWidth = 2
                ctx:beginPath()
                ctx:moveTo(
                    ctx.width / 2 - 32 -
                    start_position +
                    72, 64)
                ctx:lineTo(
                    ctx.width / 2 - 32 -
                    start_position +
                    72, 0)
                ctx:closePath()
                ctx:stroke()
                ctx.strokeWidth = 3

                ctx:fillText("Reference image",
                    ctx.width / 2 - 32 -
                    start_position, 73)

                ctx.color = Color { r = 255, g = 255, b = 255, a = 255 }

                for index = 0, number_of_freeze_frame - 1, 1 do
                    offset_x = ctx.width / 2 - 32 + distance_between_image * (1 + index) - start_position
                    ctx:drawImage(alpha_background_image, offset_x, 0)
                    if app.activeSprite and app.activeFrame then
                        local freeze_frame = app.activeFrame.frameNumber + index
                        local freeze_points = get_pose_from_frame_number(freeze_frame)

                        local canvas_im = getImage.get_image(app.activeSprite, freeze_frame,
                            app.activeImage)
                        canvas_im:resize(64, 64)
                        ctx:drawImage(canvas_im, offset_x, 0)
                        if canvas_im:isEmpty() then
                            ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                            ctx:fillText("Missing image", offset_x + 4, 32)
                        else
                            if freeze_points ~= nil and #freeze_points > 0 then
                                dialog_skeleton_preview:add_skeleton_to_canvas(ctx, freeze_points, offset_x)
                            else
                                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                                ctx:fillText("Missing", offset_x + 20, 28)
                                ctx:fillText("skeleton", offset_x + 17, 36)
                            end
                        end
                    else
                        ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                        ctx:fillText("Missing freeze", offset_x + 4, 32)
                    end
                end

                if number_of_freeze_frame > 0 then
                    ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                    -- ctx.strokeWidth = 2
                    ctx:fillText("->",
                        ctx.width / 2 - 32 + distance_between_image * (number_of_freeze_frame) - start_position + 68, 32)
                    ctx.strokeWidth = 3
                    -- ctx:closePath()
                    local text_display = "Frozen frame"
                    if number_of_freeze_frame > 1 then
                        text_display = "Frozen frames"
                    end
                    ctx:fillText(text_display,
                        ctx.width / 2 - 32 + distance_between_image * (1 + number_of_freeze_frame // 2) -
                        start_position, 73)
                end

                for index = 0, number_of_generate_frame - 1, 1 do
                    offset_x = ctx.width / 2 - 32 + distance_between_image * (1 + index + number_of_freeze_frame) -
                        start_position
                    ctx:drawImage(alpha_background_image, offset_x, 0)
                    if app.activeSprite and app.activeFrame then
                        local generate_frame = app.activeFrame.frameNumber + number_of_freeze_frame + index

                        local canvas_im = dialog_skeleton_preview:get_image_display(generate_frame,
                            use_inpainting, generation_setup)
                        canvas_im:resize(64, 64)
                        ctx:drawImage(canvas_im, offset_x, 0)

                        local generate_points = get_pose_from_frame_number(generate_frame)

                        if generate_points ~= nil and #generate_points > 0 then
                            dialog_skeleton_preview:add_skeleton_to_canvas(ctx, generate_points, offset_x)
                        else
                            if canvas_im:isPlain(Color { r = 0, g = 0, b = 0, a = 255 }) then
                                ctx.color = Color { r = 255, g = 255, b = 255, a = 255 }
                            else
                                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                            end

                            ctx:fillText("Missing", offset_x + 20, 28)
                            ctx:fillText("skeleton", offset_x + 17, 36)
                        end
                    else
                        if canvas_im:isPlain(Color { r = 0, g = 0, b = 0, a = 255 }) then
                            ctx.color = Color { r = 255, g = 255, b = 255, a = 255 }
                        else
                            ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                        end
                        ctx:fillText("Missing frame", offset_x + 8, 32)
                    end
                end

                ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                ctx:fillText("Generated frame",
                    ctx.width / 2 - 32 +
                    distance_between_image * (1 + number_of_freeze_frame + number_of_generate_frame // 2) -
                    start_position, 73)
            end
        }
    end,
    add_skeleton_to_canvas = function(self, ctx, points, offset_x, name, factor)
        if factor == nil then
            factor = 64 / app.activeSprite.width
        end
        for _, point_order in ipairs(handle_pose.draw_points_order) do
            local point = points[point_order]
            i = point_order
            for _, connectedPointIndex in ipairs(handle_pose.default_points[1][point_order].connected_points) do
                local connectedPoint = points[connectedPointIndex]
                local color = handle_pose.default_points[1][point_order].color
                if connectedPointIndex > i then
                    color = handle_pose.default_points[1][connectedPointIndex].color
                end
                ctx:save()
                ctx:beginPath()
                ctx.color = color
                ctx:moveTo(math.floor(point.position[1]) * factor + offset_x,
                    math.floor(point.position[2]) * factor)
                ctx:lineTo(math.floor(connectedPoint.position[1]) * factor + offset_x,
                    math.floor(connectedPoint.position[2]) * factor)
                ctx:closePath()
                ctx:stroke()
            end
        end

        for i, point_order in ipairs(handle_pose.draw_points_order) do
            local point = points[point_order]
            local point_color = handle_pose.default_points[1][point_order]["color"]
            local surrounding_color = Color { r = 255, g = 255, b = 255, a = 255 }

            ctx:save()
            ctx:beginPath()
            ctx.color = surrounding_color
            ctx:roundedRect(
                Rectangle(math.floor(point["position"][1]) * factor - 3 + offset_x,
                    math.floor(point["position"][2]) * factor - 2, 4, 4), 500)
            ctx:closePath()
            ctx:fill()
        end
    end,
    get_image_display = function(self, frame, use_inpainting, generation_setup)
        if use_inpainting or generation_setup == "Custom" then
            return getImage.get_pose_display(app.activeSprite, frame)
        else
            return im_black
        end
    end,
    repaint = function(self, dlg)
        self.user_repaint = true
        dlg:repaint()
    end
}
