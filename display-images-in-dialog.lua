local getImage = dofile('./get-image.lua')
getImage.is_display = true

displayImagesInDialog = {}

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

function displayImagesInDialog.get_image_display_name(name)
    if "init_image" == name then
        return "From image"
    end

    if "from_image" == name then
        return "From image"
    end

    if "to_image" == name then
        return "To image"
    end

    if "interpolation_from" == name then
        return "From image"
    end

    if "interpolation_to" == name then
        return "To image"
    end

    if "frontal_image" == name then
        return "Frontal image"
    end

    if "start_image" == name then
        return "From image"
    end

    if "shape_image" == name then
        return "Target shape"
    end
    if "inpainting_image" == name then
        return "Inpaint image"
    end
    if "color_image" == name then
        return "target palette"
    end

    if "reference_image" == name then
        return "From image"
    end

    if "canny_image" == name then
        return "Canny image"
    end

    if "pose_image" == name then
        return "Pose image"
    end

    if "reference_images" == name then
        return "Reference images"
    end
    if "init_images" == name then
        return "Init images"
    end
    if "inspirational_image" == name then
        return "Init image"
    end
    if "resize_image" == name then
        return "Image"
    end
    if "tiling_image" == name then
        return "Force tiling"
    end

    if "style_image" == name then
        return "Style image"
    end

    if "rotation_images" == name then
        return "Rotation"
    end

    if "movement_images" == name then
        return "Movement"
    end

    if "selected_reference_image" == name then
        return "Reference"
    end

    if "pose_images" == name then
        return "Pose"
    end

    return ""
end

local function scaleImage(image, width, height)
    local scale_factor = 64 / math.max(image.width, image.height)
    local new_width = math.floor(image.width * scale_factor)
    local new_height = math.floor(image.height * scale_factor)

    image:resize(new_width, new_height)
end

local function CheckForImage(image)
    return (image == nil or image == "" or app.activeSprite == nil) == false
end

function displayImagesInDialog.displayImagesDialog(dlg, model, image_name, show)
    if model == nil then
        return
    end

    getImage.current_json = model.current_json

    if model.default_json[image_name] ~= nil and type(model.default_json[image_name]) == "table" then
        dlg:canvas { id = "canvas_" .. image_name,
            width = 210,
            height = 64,
            onpaint = function(ev)
                local ctx = ev.context
                local key = key
                local display_images = getImage.get_display_image_for_model_from_name(image_name, model)

                if not CheckForImage(display_images) then
                    return
                end

                local distance_between_image = 72
                local start_position = distance_between_image * (#display_images - 1) * 0.5
                for i = 1, #display_images do
                    local display_image = display_images[i]
                    local image = alpha_background_image:clone()

                    local displace = distance_between_image * (i - 1) - start_position
                    if CheckForImage(display_image) and display_name ~= "" then
                        display_image = display_image:clone()
                        ctx.opacity = 255
                        ctx.antialias = false

                        ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                        ctx.strokeWidth = 10

                        scaleImage(display_image)
                        image:resize(display_image.width, display_image.height)
                        image:drawImage(display_image)
                        ctx:drawImage(image, ctx.width / 2 - 32 + displace, 5)
                    else
                        ctx:drawImage(image, ctx.width / 2 - 32 + displace, 5)

                        ctx:fillText("Missing image", ctx.width / 2 - 32 + (32 - #("Missing image")) / 3 + displace, 32)
                    end
                end
            end,
            visible = show
        }
    else
        dlg:canvas { id = "canvas_" .. image_name,
            width = 64,
            height = 64,
            onpaint = function(ev)
                local image = alpha_background_image:clone()
                local display_image = getImage.get_display_image_for_model_from_name(image_name, model)

                local ctx = ev.context
                ctx.opacity = 255
                ctx.antialias = false
                ctx.color = Color { r = 255, g = 255, b = 255, a = 255 }

                if CheckForImage(display_image) then
                    display_image = display_image:clone()
                    scaleImage(display_image)
                    image:resize(display_image.width, display_image.height)
                    image:drawImage(display_image)
                    ctx:drawImage(image, ctx.width / 2 - 32, 0)
                else
                    ctx:drawImage(image, ctx.width / 2 - 32, 0)
                    ctx.strokeWidth = 10
                    ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                    ctx:fillText("Missing image", ctx.width / 2 - 32 + (32 - #("Missing image")) / 3, 32)
                end
            end,
            visible = show
        }
    end
end

function displayImagesInDialog.displayAllWaysVisibleImagesInDialog(dlg, model)
    if model == nil then
        return
    end
    getImage.current_model = model
    local images_data = getImage.get_images_from_model_from_json(model.current_json)

    if next(images_data) == nil then
        return
    end

    for key, image in pairs(images_data) do
        if model.current_json[key] == "" or (model.default_json[key] == "" and (model.default_json["model_name"] == "generate_movement" or model.default_json["model_name"] == "generate_interpolation" or model.default_json["model_name"] == "generate_resize" or model.default_json["model_name"] == "generate_style" or model.default_json["model_name"] == "generate_tiles_style" or model.default_json["model_name"] == "generate_rotate_single" or model.default_json["model_name"] == "generate_pose_animation" or model.default_json["model_name"] == "generate_style_old")) then
            local display_name = displayImagesInDialog.get_image_display_name(key)
            dlg:canvas { id = "display_name",
                width = 64,
                height = 85,
                onpaint = function(ev)
                    local ctx = ev.context
                    local key = key
                    local image = alpha_background_image:clone()
                    local display_image = getImage.get_display_image_for_model_from_name(key, model)

                    if CheckForImage(display_image) and display_name ~= "" then
                        display_image = display_image:clone()
                        ctx.opacity = 255
                        ctx.antialias = false

                        ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                        ctx.strokeWidth = 10

                        scaleImage(display_image)
                        image:resize(display_image.width, display_image.height)
                        image:drawImage(display_image)
                        ctx:drawImage(image, ctx.width / 2 - 32, 5)

                        ctx:fillText(display_name, ctx.width / 2 - 32 + (32 - #(display_name)) / 3, 73)
                    else
                        ctx:drawImage(image, ctx.width / 2 - 32, 5)

                        ctx:fillText("Missing image", ctx.width / 2 - 32 + (32 - #("Missing image")) / 3, 32)
                        ctx:fillText(display_name, ctx.width / 2 - 32 + (32 - #(display_name)) / 3, 73)
                    end
                end
            }
        elseif type(model.default_json[key]) == "table" and model.default_json[key][1] == nil then
            dlg:canvas { id = "display_name",
                width = 210,
                height = 85,
                onpaint = function(ev)
                    local ctx = ev.context
                    local key = key
                    local display_images = getImage.get_display_image_for_model_from_name(key, model)

                    if not CheckForImage(display_images) then
                        return
                    end

                    local distance_between_image = 72
                    local start_position = distance_between_image * (#display_images - 1) * 0.5
                    for i = 1, #display_images do
                        local image = alpha_background_image:clone()
                        local display_image = display_images[i]

                        local displace = distance_between_image * (i - 1) - start_position
                        if CheckForImage(display_image) and display_name ~= "" then
                            display_image = display_image:clone()
                            ctx.opacity = 255
                            ctx.antialias = false

                            ctx.color = Color { r = 0, g = 0, b = 0, a = 255 }
                            ctx.strokeWidth = 10

                            scaleImage(display_image)
                            image:resize(display_image.width, display_image.height)
                            image:drawImage(display_image)
                            ctx:drawImage(image, ctx.width / 2 - 32 + displace, 5)
                        else
                            ctx:drawImage(image, ctx.width / 2 - 32 + displace, 5)

                            ctx:fillText("Missing image", ctx.width / 2 - 32 + (32 - #("Missing image")) / 3 + displace,
                                32)
                        end

                        if model.default_json["always_visible_display_images_name"] then
                            ctx:fillText(model.default_json["always_visible_display_images_name"][i],
                                ctx.width / 2 - 32 +
                                (32 - #(model.default_json["always_visible_display_images_name"][i])) / 3 + displace, 73)
                        end
                    end
                end
            }
        end
    end
end

return displayImagesInDialog
