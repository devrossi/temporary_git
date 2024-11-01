local getImage = {}
local pcWhite = app.pixelColor.rgba(255, 255, 255, 255)
local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)
local pcTransparent = app.pixelColor.rgba(0, 0, 0, 0)

getImage.is_display = false
getImage.current_json = nil

local black_image = Image(4, 4)
for it in black_image:pixels() do
    it(app.pixelColor.rgba(0, 0, 0, 255))
end
black_image:resize(64, 64)

local function scaleImage(image)
    local scale_factor = 64 / math.max(image.width, image.height)
    local new_width = math.floor(image.width * scale_factor)
    local new_height = math.floor(image.height * scale_factor)

    image:resize(new_width, new_height)
end


local function getLayerVisible(sprite, name)
    local visible_layer = {}
    for i, layer in ipairs(sprite.layers) do
        if layer.name == "PixelLab - Reshape" or layer.name == "PixelLab - Inpainting" or string.match(layer.name, "Pose") then
            visible_layer[layer.name] = layer.isVisible
        end
    end
    return visible_layer
end

local function restoreLayerVisible(sprite, visible_layer)
    for i, layer in ipairs(sprite.layers) do
        if visible_layer[layer.name] ~= nil then
            layer.isVisible = visible_layer[layer.name]
        end
    end
    return visible_layer
end

local function showHideReshapeInpainting(sprite, show)
    for i, layer in ipairs(sprite.layers) do
        if layer.name == "PixelLab - Reshape" or layer.name == "PixelLab - Inpainting" or string.match(layer.name, "Pose") then
            layer.isVisible = show
        end
    end
end

function getImage.get_color_image_from_table(color_table)
    local color_image = Image(64, 64)

    for it in color_image:pixels() do
        for color_key, color_value in pairs(color_table) do
            if color_value > 0 then
                color_table[color_key] = color_value - 1
                color_image:drawPixel(it.x, it.y, color_key)
                color_table[color_key] = nil
                break
            end
        end
    end

    return color_image
end

function getImage.get_image_color_table(im, color_table)
    if im == "" or im == "No" or im:isEmpty() then
        return color_table
    end
    for it in im:pixels() do
        if app.pixelColor.rgbaA(it()) ~= 0 then
            local c = it()
            if color_table[c] == nil then
                color_table[c] = 1
            else
                color_table[c] = color_table[c] + 1
            end
        end
    end

    return color_table
end

function getImage.get_palette_table(sprite, frame, color_table)
    local palette = app.activeSprite.palettes[1]
    for i = 0, #(palette) - 1 do
        local c = palette:getColor(i)

        if color_table[c] == nil then
            color_table[c] = 1
        else
            color_table[c] = color_table[c] + 1
        end
    end

    return color_table
end

function getImage.get_image_color_from_current_image_and_palette(sprite, frame, image, use_color_or_palette,
                                                                 number_of_frames)
    if app.activeSprite == nil or string.lower(use_color_or_palette) == 'no' then
        return ""
    end

    local color_table = {}

    if string.find(use_color_or_palette, "image") then
        if use_color_or_palette == "Reference image" then
            local ref_im = current_model.current_json[current_model.dialog_json["color_image"]["reference_image"]]
            if ref_im == nil or ref_im == "" or ref_im == "No" or ref_im:isEmpty() then
                return ""
            end
            color_table = getImage.get_image_color_table(
                current_model.current_json[current_model.dialog_json["color_image"]["reference_image"]], color_table)
        elseif getImage.get_image(sprite, frame):isEmpty() then
            return ""
        elseif number_of_frames == nil then
            local im = getImage.get_image(sprite, frame)
            color_table = getImage.get_image_color_table(im, color_table)
        else
            local frame = app.activeFrame
            for i = 1, number_of_frames do
                if frame ~= nil then
                    local im = getImage.get_image(sprite, frame)
                    color_table = getImage.get_image_color_table(im, color_table)
                    frame = frame.previous
                end
            end
        end
    end

    if string.find(use_color_or_palette, "palette") then
        color_table = getImage.get_palette_table(sprite, frame, color_table)
    end

    return getImage.get_color_image_from_table(color_table)
end

function getImage.fix_selection_outside_image(image, color)
    if image == nil or image == "" then
        return image
    end
    for it in image:pixels() do
        local pixelValue = it()
        if pixelValue == 0 then
            it(color)
        end
    end
    return image
end

function getImage.get_image(sprite, frame)
    if app.activeSprite == nil then
        return ""
    end

    local new_im = Image(sprite.width, sprite.height)

    local og_visibleLayers = getLayerVisible(sprite)

    showHideReshapeInpainting(sprite, false)

    if frame ~= nil then
        new_im:drawSprite(sprite, frame)
    else
        new_im:drawSprite(sprite, app.activeFrame)
    end

    restoreLayerVisible(sprite, og_visibleLayers)

    if getImage.current_json ~= nil and getImage.current_json["use_selection"] ~= nil and getImage.current_json["use_selection"] then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.isEmpty then
            if getImage.current_json["max_size"] ~= nil then
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    getImage.current_json["max_size"][1], getImage.current_json["max_size"][2])
            else
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    64, 64)
            end
        end
        new_im = Image(new_im, selection_rectangle)
    elseif getImage.is_display then
        scaleImage(new_im)
    end

    return new_im
end

function getImage.get_image_bytes(image)
    local image_bytes = ""
    image_bytes = image.bytes

    return image_bytes
end

function getImage.get_image_from_layer(sprite, frameNumber, layerName)
    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end
    -- mask:resize(64,64)
    return mask
end

function getImage.get_pose_display(sprite, frameNumber)
    if app.activeSprite == nil then
        return Image(64, 64)
    elseif #app.activeSprite.frames < frameNumber then
        local new_black_image = black_image:clone()
        return new_black_image
    end

    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if layer.name == "PixelLab - Inpainting" then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end

    local im_full = getImage.get_image(sprite, frameNumber)
    local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)
    for it in im_full:pixels() do
        if app.pixelColor.rgbaA(mask:getPixel(it.x, it.y)) ~= 0 then
            it(pcBlack)
        end
    end

    if im_full:isEmpty() then
        local new_black_image = black_image:clone()
        return new_black_image
    end

    return im_full
end

function getImage.get_mask_display(sprite, frameNumber, layerName)
    if app.activeSprite == nil then
        return Image(64, 64)
    end

    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end

    if getImage.current_json["use_selection"] ~= nil and getImage.current_json["use_selection"] then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.isEmpty then
            if getImage.current_json["max_size"] ~= nil then
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    getImage.current_json["max_size"][1], getImage.current_json["max_size"][2])
            else
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    64, 64)
            end
        end
        mask = Image(mask, selection_rectangle)
    elseif getImage.is_display then
        scaleImage(mask)
    end

    local im_full = getImage.get_image(sprite, frameNumber, app.activeImage)

    local pcWhite = app.pixelColor.rgba(255, 255, 255, 255)
    local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)
    for it in im_full:pixels() do
        if app.pixelColor.rgbaA(mask:getPixel(it.x, it.y)) ~= 0 then
            it(pcBlack)
        end
    end

    return im_full
end

function getImage.get_mask(sprite, frameNumber, layerName)
    if app.activeSprite == nil then
        return Image(64, 64)
    end

    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end

    if getImage.current_json["use_selection"] ~= nil and getImage.current_json["use_selection"] then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.isEmpty then
            if getImage.current_json["max_size"] ~= nil then
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    getImage.current_json["max_size"][1], getImage.current_json["max_size"][2])
            else
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    64, 64)
            end
        end
        mask = Image(mask, selection_rectangle)
    elseif getImage.is_display then
        scaleImage(mask)
    end

    for it in mask:pixels() do
        if app.pixelColor.rgbaA(it()) == 0 then
            it(pcBlack)
        else
            it(pcWhite)
        end
    end

    return mask
end

function getImage.get_tile_display_mask(sprite, frameNumber, layerName)
    if app.activeSprite == nil then
        return Image(64, 64)
    end

    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end

    if getImage.current_json["use_selection"] ~= nil and getImage.current_json["use_selection"] then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.isEmpty then
            if getImage.current_json["max_size"] ~= nil then
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    getImage.current_json["max_size"][1], getImage.current_json["max_size"][2])
            else
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    64, 64)
            end
        end
        mask = Image(mask, selection_rectangle)
    elseif getImage.is_display then
        scaleImage(mask)
    end

    local im_full = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)

    local pcWhite = app.pixelColor.rgba(255, 255, 255, 255)
    local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)
    for it in im_full:pixels() do
        if app.pixelColor.rgbaA(it()) == 0 or app.pixelColor.rgbaA(mask:getPixel(it.x, it.y)) ~= 0 then
            it(pcBlack)
        end
    end

    return im_full
end

function getImage.get_tile_mask(sprite, frameNumber, layerName)
    if app.activeSprite == nil then
        return Image(64, 64)
    end

    local mask = Image(sprite.width, sprite.height)
    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            local _cel = layer:cel(frameNumber)
            if _cel ~= nil then
                local curr_im = _cel.image
                mask:drawImage(curr_im, curr_im.cel.position)
            end
        end
    end

    local im_full = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)

    local pcWhite = app.pixelColor.rgba(255, 255, 255, 255)
    local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)

    if getImage.current_json["use_selection"] ~= nil and getImage.current_json["use_selection"] then
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        if app.activeSprite.selection.bounds.isEmpty then
            if getImage.current_json["max_size"] ~= nil then
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    getImage.current_json["max_size"][1], getImage.current_json["max_size"][2])
            else
                selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
                    64, 64)
            end
        end
        mask = Image(mask, selection_rectangle)
    elseif getImage.is_display then
        scaleImage(mask)
    end

    for it in mask:pixels() do
        if app.pixelColor.rgbaA(im_full:getPixel(it.x, it.y)) == 0 then
            it(pcWhite)
        elseif app.pixelColor.rgbaA(it()) == 0 then
            it(pcBlack)
        else
            it(pcWhite)
        end
    end

    return mask
end

function getImage.get_canny()
    for i, sprite in ipairs(app.sprites) do
        if sprite.filename == "Sketch - Canny" then
            return getImage.get_image(sprite, 1, nil)
        end
    end

    return ""
end

function getImage.get_tiling_mask(use_select, tiling_position)
    local im = Image(64, 64)
    for it in im:pixels() do
        it(app.pixelColor.rgba(0, 0, 0, 255))
    end
    local im_black_rec = Image(16, 16)
    for it in im_black_rec:pixels() do
        it(app.pixelColor.rgba(255, 255, 255, 255))
    end

    local x = 16
    local y = 16
    if tiling_position == "northwest" then
        x = 16
        y = 16
    elseif tiling_position == "northeast" then
        x = 32
        y = 16
    elseif tiling_position == "southwest" then
        x = 16
        y = 32
    elseif tiling_position == "southeast" then
        x = 32
        y = 32
    end
    im:drawImage(im_black_rec, Point(x, y))

    return im
end

function getImage.get_tiling_mask_display(use_select, tiling_position)
    local im
    if use_select then
        -- local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y, app.activeSprite.selection.bounds.width, app.activeSprite.selection.bounds.height)
        local selection_rectangle = Rectangle(app.activeSprite.selection.origin.x, app.activeSprite.selection.origin.y,
            64, 64)
        -- local im_mask = getImage.get_tile_mask(app.activeSprite, app.activeFrame, "inpainting")
        im = getImage.get_image(app.activeSprite, app.activeFrame, nil)
        im = Image(im, selection_rectangle)
    else
        im = getImage.get_image(app.activeSprite, app.activeFrame, nil)
    end

    local im_black_rec = Image(16, 16)
    for it in im_black_rec:pixels() do
        it(app.pixelColor.rgba(0, 0, 0, 255))
    end

    local x = 16
    local y = 16
    if tiling_position == "northwest" then
        x = 16
        y = 16
    elseif tiling_position == "northeast" then
        x = 32
        y = 16
    elseif tiling_position == "southwest" then
        x = 16
        y = 32
    elseif tiling_position == "southeast" then
        x = 32
        y = 32
    end
    im:drawImage(im_black_rec, Point(x, y))

    return im
end

function getImage.get_display_selection_tiling(width, height, frame)
    local im_mask = getImage.get_tile_display_mask(app.activeSprite, frame, "PixelLab - Inpainting")
    return getImage.fix_selection_outside_image(im_mask, pcTransparent)
end

function getImage.get_selection_tiling(width, height, frame)
    local im_mask = getImage.get_tile_mask(app.activeSprite, frame, "PixelLab - Inpainting")
    return getImage.fix_selection_outside_image(im_mask, pcBlack)
end

function getImage.get_display_selection_inpainting(width, height, frame)
    local im_mask = getImage.get_mask_display(app.activeSprite, frame, "PixelLab - Inpainting")
    return getImage.fix_selection_outside_image(im_mask, pcTransparent)
end

function getImage.get_selection_inpainting(width, height, frame)
    local im_mask = getImage.get_mask(app.activeSprite, frame, "PixelLab - Inpainting")

    return getImage.fix_selection_outside_image(im_mask, pcBlack)
end

function getImage.get_selection(width, height, frame)
    local im = getImage.get_image(app.activeSprite, frame, app.activeImage)
    return getImage.fix_selection_outside_image(im, pcTransparent)
end

function getImage.get_images_from_model_from_json(json)
    getImage.current_json = json
    local data_images = {}

    if json["selected_reference_image"] ~= nil then
        -- if json["model_name"] == "generate_pose_animation" and current_model.dialog_json["generate"]["generation_setup"] ~= "Custom" then
        --     data_images["selected_reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame,
        --         app.activeImage)
        -- else
        if json["model_name"] == "generate_pose_animation" and #current_model.dialog_json["selected_reference_frame"] > 0 then
            data_images["selected_reference_image"] = getImage.get_image(app.activeSprite,
                current_model.dialog_json["selected_reference_frame"][1])
        else
            data_images["selected_reference_image"] = json["selected_reference_image"]
        end
    end

    if json["interpolation_from"] ~= nil then
        data_images["interpolation_from"] = json["interpolation_from"]
    end

    if json["interpolation_to"] ~= nil then
        data_images["interpolation_to"] = json["interpolation_to"]
    end
    if json["init_image"] ~= nil and string.lower(json["init_image"]) == "yes" and app.activeSprite then
        if json["use_selection"] ~= nil and json["use_selection"] then
            if json["max_size"] ~= nil then
                data_images["init_image"] = getImage.get_selection(json["max_size"][1], json["max_size"][2],
                    app.activeFrame)
            else
                data_images["init_image"] = getImage.get_selection(64, 64, app.activeFrame)
            end
        else
            data_images["init_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    else
        data_images["init_image"] = ""
    end
    if json["resize_image"] ~= nil then
        local im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        if im:isEmpty() then
            data_images["resize_image"] = ""
        else
            data_images["resize_image"] = im
        end
    end
    if json["inspirational_image"] ~= nil then
        local im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        if im:isEmpty() then
            data_images["inspirational_image"] = ""
        else
            data_images["inspirational_image"] = im
        end
    end

    if json["from_image"] ~= nil then
        if json["model_name"] == "generate_rotate_single" then
            data_images["from_image"] = json["from_image"]
        else
            data_images["from_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    end

    if json["to_image"] ~= nil then
        data_images["to_image"] = getImage.get_image(app.activeSprite, app.activeFrame.next, app.activeImage)
    end

    if json["frontal_image"] ~= nil then
        data_images["frontal_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
    end

    if json["start_image"] ~= nil then
        data_images["start_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
    end

    if json["rotation_images"] ~= nil then
        local frame = app.activeFrame
        local number_of_frames = 4

        data_images["rotation_images"] = {}
        data_images["inpainting_images"] = {}
        for index = 1, number_of_frames do
            if frame == nil then
                data_images["rotation_images"][index] = "none"
                data_images["inpainting_images"][index] = ""
            else
                local rotation_image = getImage.get_image(app.activeSprite, frame, app.activeImage)
                if rotation_image == "" or rotation_image:isEmpty() then
                    data_images["rotation_images"][index] = "none"

                    local inpainting_image = getImage.get_mask(app.activeSprite, frame, "PixelLab - Inpainting")
                    if inpainting_image:isPlain(app.pixelColor.rgba(0, 0, 0, 255)) == false then
                        data_images["inpainting_images"][index] = inpainting_image
                        data_images["rotation_images"][index] = rotation_image
                    else
                        data_images["inpainting_images"][index] = ""
                    end
                else
                    data_images["rotation_images"][index]   = rotation_image
                    data_images["inpainting_images"][index] = getImage.get_mask(app.activeSprite, frame,
                        "PixelLab - Inpainting")
                end
            end

            if frame ~= nil then
                frame = frame.next
            end
        end
    end

    if json["movement_images"] ~= nil then
        local frame = app.activeFrame
        local number_of_frames = 4

        data_images["movement_images"] = {}
        data_images["inpainting_images"] = {}
        for index = 1, number_of_frames do
            if frame == nil then
                data_images["movement_images"][index] = "none"
                data_images["inpainting_images"][index] = ""
            else
                local movement_image = getImage.get_image(app.activeSprite, frame, app.activeImage)
                if json["use_selection"] ~= nil and json["use_selection"] then
                    movement_image = getImage.get_selection(json["max_size"][1], json["max_size"][2], frame)
                end
                local inpainting_image = getImage.get_mask(app.activeSprite, frame, "PixelLab - Inpainting")
                if json["use_selection"] ~= nil and json["use_selection"] then
                    inpainting_image = getImage.get_selection_inpainting(json["max_size"][1], json["max_size"][2], frame)
                end
                if movement_image == nil or movement_image == "" or movement_image:isEmpty() then
                    if inpainting_image == nil or inpainting_image:isEmpty() or inpainting_image:isPlain(app.pixelColor.rgba(0, 0, 0, 255)) then
                        data_images["movement_images"][index] = "none"
                        data_images["inpainting_images"][index] = ""
                    else
                        data_images["inpainting_images"][index] = inpainting_image
                        data_images["movement_images"][index] = movement_image
                    end
                else
                    data_images["movement_images"][index] = movement_image
                    data_images["inpainting_images"][index] = inpainting_image
                end
            end

            if frame ~= nil then
                frame = frame.next
            end
        end
    end

    if json["style_image"] ~= nil then
        if json["style_image"] == "No" then
            data_images["style_image"] = ""
        else
            data_images["style_image"] = json["style_image"]
        end
    end

    if json["shape_image"] ~= nil then
        data_images["shape_image"] = getImage.get_mask(app.activeSprite, app.activeFrame, "PixelLab - Reshape")
    end

    if json["inpainting_image"] ~= nil then
        if json["model_name"] == "generate_inpainting_map" then
            data_images["inpainting_image"] = getImage.get_tile_mask(app.activeSprite, app.activeFrame,
                "PixelLab - Inpainting")
        elseif json["model_name"] == "generate_tiles" or json["model_name"] == "generate_tiles_style" then
            if json["use_selection"] ~= nil and json["use_selection"] then
                data_images["inpainting_image"] = getImage.get_selection_tiling(json["max_size"][1], json["max_size"][2],
                    app.activeFrame)
            else
                data_images["inpainting_image"] = getImage.get_tile_mask(app.activeSprite, app.activeFrame,
                    "PixelLab - Inpainting")
            end
        elseif json["model_name"] == "generate_style" or json["model_name"] == "generate_rotate_single" or json["model_name"] == "generate_style_old" then
            if json["use_inpainting"] then
                local frame = app.activeFrame
                -- if json["init_image"] == "No" or json["init_image"] == "" then
                --     frame = app.activeFrame
                -- end
                local inpainting_image = getImage.get_mask(app.activeSprite, frame, "PixelLab - Inpainting")
                if inpainting_image:isPlain(app.pixelColor.rgba(0, 0, 0, 255)) then
                    data_images["inpainting_image"] = ""
                else
                    data_images["inpainting_image"] = inpainting_image
                end
            else
                data_images["inpainting_image"] = ""
            end
        else
            if json["use_selection"] ~= nil and json["use_selection"] then
                data_images["inpainting_image"] = getImage.get_selection_inpainting(64, 64, app.activeFrame)
            else
                data_images["inpainting_image"] = getImage.get_mask(app.activeSprite, app.activeFrame,
                    "PixelLab - Inpainting")
            end
        end
    end
    if json["tiling_image"] ~= nil then
        data_images["tiling_image"] = Image(64, 64)
        -- if json["use_tiling"] ~= nil and json["use_tiling"] then
        --     data_images["tiling_image"] = getImage.get_tiling_mask(json["use_selection"], json["tiling_position"])
        -- else
        --     data_images["tiling_image"] = Image(64, 64)
        -- end
    end
    if json["reference_image"] ~= nil then
        if json["use_selection"] ~= nil and json["use_selection"] then
            if json["max_size"] ~= nil then
                data_images["reference_image"] = getImage.get_selection(json["max_size"][1], json["max_size"][2],
                    app.activeFrame)
            else
                data_images["reference_image"] = getImage.get_selection(64, 64, app.activeFrame)
            end
        elseif json["model_name"] == "generate_re_paint" then
            data_images["reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame.previous,
                app.activeImage)
        else
            data_images["reference_image"] = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    end

    if json["color_image"] ~= nil then
        if json["reference_images"] ~= nil then
            data_images["color_image"] = getImage.get_image_color_from_current_image_and_palette(app.activeSprite,
                app.activeFrame, app.activeImage, json["color_image"], json["reference_images_amount"])
        else
            if json["model_name"] == "generate_rotate_single" then
                if json["init_image"] == "No" then
                    data_images["color_image"] = getImage.get_image_color_from_current_image_and_palette(
                        app.activeSprite, app.activeFrame, app.activeImage, json["color_image"], nil)
                else
                    data_images["color_image"] = getImage.get_image_color_from_current_image_and_palette(
                        app.activeSprite, app.activeFrame.previous, app.activeImage, json["color_image"], nil)
                end
            else
                data_images["color_image"] = getImage.get_image_color_from_current_image_and_palette(app.activeSprite,
                    app.activeFrame, app.activeImage, json["color_image"], nil)
            end
        end
    end

    if json["canny_image"] ~= nil then
        data_images["canny_image"] = getImage.get_canny()
    end

    if json["horizontal_tiling_image"] ~= nil then
        data_images["horizontal_tiling_image"] = ""
    end

    if json["vertical_tiling_image"] ~= nil then
        data_images["vertical_tiling_image"] = ""
    end

    if json["pose_images"] ~= nil then
        local frame = app.activeFrame
        local number_of_frames = 4

        data_images["pose_images"] = {}
        data_images["inpainting_images"] = {}
        for index = 1, number_of_frames do
            if frame == nil then
                data_images["pose_images"][index] = "none"
                data_images["inpainting_images"][index] = ""
            else
                local movement_image = getImage.get_image(app.activeSprite, frame, app.activeImage)
                if index <= current_model.dialog_json["generate"]["number_of_freeze_frame"] then
                    data_images["pose_images"][index] = movement_image
                    black_image:resize(app.activeSprite.width, app.activeSprite.height)
                    data_images["inpainting_images"][index] = black_image
                elseif index <= current_model.dialog_json["generate"]["number_of_freeze_frame"] + current_model.dialog_json["generate"]["number_of_generate_frame"] then
                    data_images["pose_images"][index] = movement_image
                    if json["use_inpainting"] or current_model.dialog_json["generate"]["generation_setup"] == "Custom" then
                        local inpainting_image = getImage.get_mask(app.activeSprite, frame, "PixelLab - Inpainting")
                        if movement_image == nil or movement_image == "" or movement_image:isEmpty() then
                            if inpainting_image == nil or inpainting_image:isEmpty() or inpainting_image:isPlain(app.pixelColor.rgba(0, 0, 0, 255)) then
                                data_images["pose_images"][index] = "none"
                                data_images["inpainting_images"][index] = ""
                            else
                                data_images["inpainting_images"][index] = inpainting_image
                                data_images["pose_images"][index] = movement_image
                            end
                        else
                            data_images["pose_images"][index] = movement_image
                            data_images["inpainting_images"][index] = inpainting_image
                        end
                    else
                        data_images["inpainting_images"][index] = ""
                    end
                end
            end

            if frame ~= nil then
                frame = frame.next
            end
        end
    end

    if json["reference_images"] ~= nil then
        local frame = app.activeFrame
        local number_of_frames = json["reference_images_amount"]

        data_images["reference_images"] = {}
        for i = 1, number_of_frames do
            local index = number_of_frames - i + 1
            if frame == nil then
                data_images["reference_images"][index] = ""
            else
                data_images["reference_images"][index] = getImage.get_image(app.activeSprite, frame, app.activeImage)
            end

            if frame ~= nil then
                frame = frame.previous
            end
        end
    end

    if json["init_images"] ~= nil then
        if string.lower(json["init_images"][1]) == "yes" and app.activeSprite then
            local frame = app.activeFrame.next
            local number_of_frames = 4
            if json["init_images_amount"] ~= nil then
                number_of_frames = json["init_images_amount"]
            else
                if json["model_name"] == "generate_simple_movement" then
                    number_of_frames = 3 - json["reference_images_amount"]
                elseif json["model_name"] == "generate_rotations" or json["model_name"] == "generate_movement" or json["model_name"] == "generate_pose_animation" then
                    frame = app.activeFrame
                    number_of_frames = 4
                else
                    number_of_frames = 4 - json["reference_images_amount"]
                end
            end
            data_images["init_images"] = {}
            for i = 1, number_of_frames do
                if frame == nil then
                    data_images["init_images"][i] = ""
                else
                    local init_im = getImage.get_image(app.activeSprite, frame, nil)
                    if json["use_selection"] ~= nil and json["use_selection"] then
                        init_im = getImage.get_selection(json["max_size"][1], json["max_size"][2], frame)
                    end

                    data_images["init_images"][i] = init_im
                end

                if frame ~= nil then
                    frame = frame.next
                end
            end
        else
            data_images["init_images"] = {}
        end
    end

    return data_images
end

function getImage.get_images_bytes_from_json(json)
    local data_images = getImage.get_images_from_model_from_json(json)
    local copy = {}

    for name, image in pairs(data_images) do
        if image == "" then
            copy[name] = ""
        else
            if type(image) == "table" then
                copy[name] = {}
                for i = 1, #image do
                    if image[i] == "" then
                        copy[name][i] = ""
                    elseif image[i] == "none" then
                        copy[name][i] = "none"
                    else
                        copy[name][i] = getImage.get_image_bytes(image[i])
                    end
                end
            else
                copy[name] = getImage.get_image_bytes(image)
            end
        end
    end

    return copy
end

function getImage.get_display_image_for_model_from_name(name, model)
    if app.activeSprite == nil then
        return Image(64, 64)
    end

    if "init_image" == name then
        if model.default_json["use_selection"] ~= nil and model.current_json["use_selection"] then
            if model.current_json["max_size"] ~= nil then
                return getImage.get_selection(model.current_json["max_size"][1], model.current_json["max_size"][2],
                    app.activeFrame)
            else
                return getImage.get_selection(64, 64, app.activeFrame)
            end
        else
            return getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    end

    if "selected_reference_image" == name then
        return model.current_json["selected_reference_image"]
    end

    if "interpolation_from" == name then
        return model.current_json["interpolation_from"]
    end

    if "interpolation_to" == name then
        return model.current_json["interpolation_to"]
    end

    if "resize_image" == name then
        local im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        if im:isEmpty() then
            return ""
        end
        return im
    end
    if "inspirational_image" == name then
        local im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        if im:isEmpty() then
            return ""
        end
        return im
    end
    if "from_image" == name then
        if model.default_json["model_name"] == "generate_rotate_single" then
            return model.current_json["from_image"]
        else
            return getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    end

    if "to_image" == name then
        return getImage.get_image(app.activeSprite, app.activeFrame.next, app.activeImage)
    end

    if "frontal_image" == name then
        return getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
    end

    if "start_image" == name then
        return getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
    end

    if "reference_image" == name then
        if model.default_json["use_selection"] ~= nil and model.current_json["use_selection"] then
            if model.current_json["max_size"] ~= nil then
                return getImage.get_selection(model.current_json["max_size"][1], model.current_json["max_size"][2],
                    app.activeFrame)
            else
                return getImage.get_selection(64, 64, app.activeFrame)
            end
        elseif model.default_json["model_name"] == "generate_re_paint" then
            return getImage.get_image(app.activeSprite, app.activeFrame.previous, app.activeImage)
        else
            return getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)
        end
    end

    if "pose_images" == name then
        local frame = app.activeFrame

        local images = {}

        for i = 1, 4 do
            local pose_image = getImage.get_pose_display(app.activeSprite, frame)

            if frame == nil then
                local im_black = Image(64, 64)
                for it in im_black:pixels() do
                    it(app.pixelColor.rgba(0, 0, 0, 255))
                end
                images[i] = im_black
            else
                images[i] = pose_image
            end

            if frame ~= nil then
                frame = frame.next
            end
        end

        return images
    end

    if "reference_images" == name then
        local frame = app.activeFrame
        local number_of_frames = model.current_json["reference_images_amount"]

        local images = {}
        for i = 1, number_of_frames do
            local index = number_of_frames - i + 1
            if frame == nil then
                images[index] = ""
            else
                images[index] = getImage.get_image(app.activeSprite, frame, app.activeImage)
            end

            if frame ~= nil then
                frame = frame.previous
            end
        end

        return images
    end

    if "init_images" == name then
        local frame = app.activeFrame.next
        local number_of_frames = 4
        if model.current_json["init_images_amount"] ~= nil then
            number_of_frames = model.current_json["init_images_amount"]
        else
            if model.current_json["model_name"] == "generate_simple_movement" then
                number_of_frames = 3 - model.current_json["reference_images_amount"]
            elseif model.current_json["model_name"] == "generate_rotations" or model.current_json["model_name"] == "generate_movement" or model.current_json["model_name"] == "generate_pose_animation" then
                frame = app.activeFrame
                number_of_frames = 4
            else
                number_of_frames = 4 - model.current_json["reference_images_amount"]
            end
        end
        local images = {}

        for i = 1, number_of_frames do
            if frame == nil then
                images[i] = ""
            else
                local init_im = getImage.get_image(app.activeSprite, frame, app.activeImage)
                if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
                    init_im = getImage.get_selection(model.current_json["max_size"][1], model.current_json["max_size"]
                        [2], frame)
                end
                images[i] = init_im
            end

            if frame ~= nil then
                frame = frame.next
            end
        end

        return images
    end

    if "shape_image" == name then
        return getImage.get_image_from_layer(app.activeSprite, app.activeFrame, "PixelLab - Reshape")
    end

    if "style_image" == name then
        return model.current_json["style_image"]
    end

    if "inpainting_image" == name then
        if model.default_json["model_name"] == "generate_inpainting_map" then
            return getImage.get_tile_display_mask(app.activeSprite, app.activeFrame, "PixelLab - Inpainting")
        elseif model.default_json["model_name"] == "generate_tiles" or model.default_json["model_name"] == "generate_tiles_style" then
            if model.default_json["use_selection"] ~= nil and model.current_json["use_selection"] then
                return getImage.get_display_selection_tiling(model.current_json["max_size"][1],
                    model.current_json["max_size"][2], app.activeFrame)
            else
                return getImage.get_tile_display_mask(app.activeSprite, app.activeFrame, "PixelLab - Inpainting")
            end
        else
            if model.default_json["use_selection"] ~= nil and model.current_json["use_selection"] then
                if model.current_json["max_size"] ~= nil then
                    return getImage.get_display_selection_inpainting(model.current_json["max_size"][1],
                        model.current_json["max_size"][2], app.activeFrame)
                else
                    return getImage.get_display_selection_inpainting(64, 64, app.activeFrame)
                end
            else
                return getImage.get_mask_display(app.activeSprite, app.activeFrame, "PixelLab - Inpainting")
            end
        end
    end
    if "tiling_image" == name then
        if model.default_json["use_tiling"] ~= nil and model.current_json["use_tiling"] then
            return getImage.get_tiling_mask_display(model.current_json["use_selection"],
                model.current_json["tiling_position"])
        else
            return Image(64, 64)
        end
    end
    if "color_image" == name then
        return getImage.get_image_color_from_current_image_and_palette(app.activeSprite, app.activeFrame, app
            .activeImage, model.current_json["color_image"], nil)
    end

    if "canny_image" == name then
        return getImage.get_canny()
    end

    if "movement_images" == name then
        local frame = app.activeFrame

        local images = {}

        for i = 1, 4 do
            local movement_image = getImage.get_mask_display(app.activeSprite, frame, "PixelLab - Inpainting")
            if frame == nil or movement_image:isEmpty() then
                local im_black = Image(64, 64)
                for it in im_black:pixels() do
                    it(app.pixelColor.rgba(0, 0, 0, 255))
                end
                images[i] = im_black
            else
                images[i] = movement_image
            end

            if frame ~= nil then
                frame = frame.next
            end
        end

        return images
    end

    if "rotation_images" == name then
        local frame = app.activeFrame

        local images = {}

        for i = 1, 4 do
            if frame == nil or getImage.get_mask_display(app.activeSprite, frame, "PixelLab - Inpainting"):isEmpty() then
                local im_black = Image(app.activeSprite)
                for it in im_black:pixels() do
                    it(app.pixelColor.rgba(0, 0, 0, 255))
                end
                images[i] = im_black
            else
                images[i] = getImage.get_mask_display(app.activeSprite, frame, "PixelLab - Inpainting")
            end

            if frame ~= nil then
                frame = frame.next
            end
        end

        return images
    end

    return Image(app.activeSprite.width, app.activeSprite.height)
end

return getImage
