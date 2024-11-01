local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local getImage = dofile('./get-image.lua')

handle_pose = {}
handle_pose.active = false

handle_pose.draw_points_order = { 13, 14, 15, 5, 7, 6, 8, 9, 11, 16, 4, 1, 2, 17, 18, 12, 10, 3 }
handle_pose.sprite = nil
handle_pose.layer = nil
handle_pose.cel = nil
handle_pose.editor = nil
handle_pose.option_points = "base"

handle_pose.humanoid_skeleton = {
    { "NECK",           "NOSE" },
    { "NECK",           "RIGHT SHOULDER" },
    { "RIGHT SHOULDER", "RIGHT ELBOW" },
    { "RIGHT ELBOW",    "RIGHT ARM" },
    { "NECK",           "LEFT SHOULDER" },
    { "LEFT SHOULDER",  "LEFT ELBOW" },
    { "LEFT ELBOW",     "LEFT ARM" },
    { "NECK",           "RIGHT HIP" },
    { "RIGHT HIP",      "RIGHT KNEE" },
    { "RIGHT KNEE",     "RIGHT LEG" },
    { "NECK",           "LEFT HIP" },
    { "LEFT HIP",       "LEFT KNEE" },
    { "LEFT KNEE",      "LEFT LEG" },
    { "NOSE",           "RIGHT EYE" },
    { "NOSE",           "LEFT EYE" },
    { "RIGHT EYE",      "RIGHT EAR" },
    { "LEFT EYE",       "LEFT EAR" },
}

handle_pose.default_points = {
    {
        { name = "NOSE",           color = Color { r = 255, g = 255, b = 0, a = 255 }, position = { 32, 28, 0 }, connected_points = { 2, 15, 16 } },
        { name = "NECK",           color = Color { r = 255, g = 245, b = 0, a = 255 }, position = { 32, 31, 0 }, connected_points = { 1, 3, 6, 9, 12 } },
        { name = "RIGHT SHOULDER", color = Color { r = 0, g = 0, b = 255, a = 255 },   position = { 28, 31, 0 }, connected_points = { 2, 4 } },
        { name = "RIGHT ELBOW",    color = Color { r = 10, g = 0, b = 255, a = 255 },  position = { 26, 36, 0 }, connected_points = { 3, 5 } },
        { name = "RIGHT ARM",      color = Color { r = 20, g = 0, b = 255, a = 255 },  position = { 24, 40, 0 }, connected_points = { 4 } },
        { name = "LEFT SHOULDER",  color = Color { r = 255, g = 10, b = 0, a = 255 },  position = { 37, 31, 0 }, connected_points = { 2, 7 } },
        { name = "LEFT ELBOW",     color = Color { r = 255, g = 20, b = 0, a = 255 },  position = { 38, 36, 0 }, connected_points = { 6, 8 } },
        { name = "LEFT ARM",       color = Color { r = 255, g = 30, b = 0, a = 255 },  position = { 40, 40, 0 }, connected_points = { 7 } },
        { name = "RIGHT HIP",      color = Color { r = 110, g = 0, b = 255, a = 255 }, position = { 29, 40, 0 }, connected_points = { 2, 10 } },
        { name = "RIGHT KNEE",     color = Color { r = 120, g = 0, b = 255, a = 255 }, position = { 29, 45, 0 }, connected_points = { 9, 11 } },
        { name = "RIGHT LEG",      color = Color { r = 130, g = 0, b = 255, a = 255 }, position = { 29, 50, 0 }, connected_points = { 10 } },
        { name = "LEFT HIP",       color = Color { r = 255, g = 100, b = 0, a = 255 }, position = { 35, 40, 0 }, connected_points = { 2, 13 } },
        { name = "LEFT KNEE",      color = Color { r = 255, g = 110, b = 0, a = 255 }, position = { 35, 45, 0 }, connected_points = { 12, 14 } },
        { name = "LEFT LEG",       color = Color { r = 255, g = 120, b = 0, a = 255 }, position = { 35, 50, 0 }, connected_points = { 13 } },
        { name = "RIGHT EYE",      color = Color { r = 0, g = 120, b = 255, a = 255 }, position = { 30, 26, 0 }, connected_points = { 1, 17 } },
        { name = "LEFT EYE",       color = Color { r = 255, g = 0, b = 190, a = 255 }, position = { 34, 26, 0 }, connected_points = { 1, 18 } },
        { name = "RIGHT EAR",      color = Color { r = 0, g = 130, b = 255, a = 255 }, position = { 29, 24, 0 }, connected_points = { 15 } },
        { name = "LEFT EAR",       color = Color { r = 255, g = 0, b = 180, a = 255 }, position = { 35, 25, 0 }, connected_points = { 16 } },
    },
    {
        { name = "NOSE",           color = Color { r = 255, g = 0, b = 0, a = 255 },   position = { 32, 28, 0 }, connected_points = { 2, 15, 16 } },
        { name = "NECK",           color = Color { r = 255, g = 85, b = 0, a = 255 },  position = { 32, 31, 0 }, connected_points = { 1, 3, 6, 9, 12 } },
        { name = "RIGHT SHOULDER", color = Color { r = 255, g = 170, b = 0, a = 255 }, position = { 28, 31, 0 }, connected_points = { 2, 4 } },
        { name = "RIGHT ELBOW",    color = Color { r = 255, g = 255, b = 0, a = 255 }, position = { 26, 36, 0 }, connected_points = { 3, 5 } },
        { name = "RIGHT ARM",      color = Color { r = 170, g = 255, b = 0, a = 255 }, position = { 24, 40, 0 }, connected_points = { 4 } },
        { name = "LEFT SHOULDER",  color = Color { r = 85, g = 255, b = 0, a = 255 },  position = { 37, 31, 0 }, connected_points = { 2, 7 } },
        { name = "LEFT ELBOW",     color = Color { r = 0, g = 255, b = 0, a = 255 },   position = { 38, 36, 0 }, connected_points = { 6, 8 } },
        { name = "LEFT ARM",       color = Color { r = 0, g = 255, b = 85, a = 255 },  position = { 40, 40, 0 }, connected_points = { 7 } },
        { name = "RIGHT HIP",      color = Color { r = 0, g = 255, b = 170, a = 255 }, position = { 29, 40, 0 }, connected_points = { 2, 10 } },
        { name = "RIGHT KNEE",     color = Color { r = 0, g = 255, b = 255, a = 255 }, position = { 29, 45, 0 }, connected_points = { 9, 11 } },
        { name = "RIGHT LEG",      color = Color { r = 0, g = 170, b = 255, a = 255 }, position = { 29, 50, 0 }, connected_points = { 10 } },
        { name = "LEFT HIP",       color = Color { r = 0, g = 85, b = 255, a = 255 },  position = { 35, 40, 0 }, connected_points = { 2, 13 } },
        { name = "LEFT KNEE",      color = Color { r = 0, g = 0, b = 255, a = 255 },   position = { 35, 45, 0 }, connected_points = { 12, 14 } },
        { name = "LEFT LEG",       color = Color { r = 85, g = 0, b = 255, a = 255 },  position = { 35, 50, 0 }, connected_points = { 13 } },
        { name = "RIGHT EYE",      color = Color { r = 170, g = 0, b = 255, a = 255 }, position = { 30, 26, 0 }, connected_points = { 1, 17 } },
        { name = "LEFT EYE",       color = Color { r = 255, g = 0, b = 255, a = 255 }, position = { 34, 26, 0 }, connected_points = { 1, 18 } },
        { name = "RIGHT EAR",      color = Color { r = 255, g = 0, b = 170, a = 255 }, position = { 29, 24, 0 }, connected_points = { 15 } },
        { name = "LEFT EAR",       color = Color { r = 255, g = 0, b = 85, a = 255 },  position = { 35, 25, 0 }, connected_points = { 16 } },
    }
}
handle_pose.points = createJSON.deepcopy(handle_pose.default_points[1])

local function create_dialog()
    local dlg = Dialog {
        title = "Editing skeleton           "
    }
    dlg:label { id = "point", label = "Selected: ", text = "None" }
    local bounds = dlg.bounds
    local rect = Rectangle(bounds.width * 2, 0, bounds.width, bounds.height)
    dlg:show { wait = false, bounds = rect }
    dlg:close()
    return dlg
end

handle_pose.dialog_edit = create_dialog()

function handle_pose.move_to_top()
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            layer.stackIndex = #(app.activeSprite.layers)
        end
    end
end

local function get_pose_layer()
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            return layer
        end
    end
    return nil
end

local function get_cel_by_layer(layer, frameNumber)
    if frameNumber == nil then
        frameNumber = app.activeFrame.frameNumber
    end
    local cel = layer:cel(frameNumber)
    if cel == nil then
        cel = app.activeSprite:newCel(layer, frameNumber)
        cel.image = Image(app.activeSprite.width, app.activeSprite.height)
    end
    return cel
end

function check_if_complete_skeleton()
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            local cel = get_cel_by_layer(layer)
            if cel.image:isEmpty() == false then
                local points = handle_pose.points
                local draw_points_order = createJSON.deepcopy(handle_pose.draw_points_order)

                local not_found_pose_points_order = {}
                for _, default_ps in ipairs(handle_pose.default_points) do
                    local points_found = 0
                    not_found_pose_points_order = {}
                    for it in cel.image:pixels() do
                        local pixelValue = it()
                        local alphaValue = app.pixelColor.rgbaA(pixelValue)
                        if alphaValue ~= 0 and alphaValue ~= 255 then
                            for i, k in ipairs(points) do
                                local d_p = default_ps[i]
                                if app.pixelColor.rgbaR(pixelValue) == d_p.color.red and app.pixelColor.rgbaG(pixelValue) == d_p.color.green and app.pixelColor.rgbaB(pixelValue) == d_p.color.blue then
                                    if draw_points_order[255 - alphaValue] == nil then
                                        draw_points_order[255 - alphaValue] = i
                                    else
                                        not_found_pose_points_order[255 - alphaValue] = i
                                    end
                                    points_found = points_found + 1
                                end
                            end
                        end
                    end
                    if points_found == #default_ps then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function get_pose_from_frame()
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            local cel = get_cel_by_layer(layer)
            if cel.image:isEmpty() == false then
                local points = createJSON.deepcopy(handle_pose.points)
                local draw_points_order = createJSON.deepcopy(handle_pose.draw_points_order)

                local not_found_pose_points_order = {}
                for _, default_ps in ipairs(handle_pose.default_points) do
                    local points_found = 0
                    not_found_pose_points_order = {}
                    for it in cel.image:pixels() do
                        local pixelValue = it()
                        local alphaValue = app.pixelColor.rgbaA(pixelValue)
                        if alphaValue ~= 0 and alphaValue ~= 255 then
                            for i, k in ipairs(points) do
                                local d_p = default_ps[i]
                                if app.pixelColor.rgbaR(pixelValue) == d_p.color.red and app.pixelColor.rgbaG(pixelValue) == d_p.color.green and app.pixelColor.rgbaB(pixelValue) == d_p.color.blue then
                                    k.position = { cel.bounds.origin.x + it.x, cel.bounds.origin.y + it.y, 0 }
                                    if draw_points_order[255 - alphaValue] == nil then
                                        draw_points_order[255 - alphaValue] = i
                                    else
                                        not_found_pose_points_order[255 - alphaValue] = i
                                    end
                                    points_found = points_found + 1
                                end
                            end
                        end
                    end
                    if points_found == #default_ps then
                        break
                    end
                end
                if #not_found_pose_points_order > 0 then
                    for _, k in ipairs(not_found_pose_points_order) do
                        for i = 1, #handle_pose.default_points do
                            if draw_points_order[i] == nil then
                                draw_points_order[i] = k
                            end
                        end
                    end
                end
                return points
            end
        end
    end
    return nil
end

local function load_pose_from_frame(create_if_not_found)
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            handle_pose.layer = layer
            local cel = get_cel_by_layer(layer)
            handle_pose.cel = cel
            -- if cel.image:isEmpty() == false and cel.properties.pose_points_order == nil then

            if cel.image:isEmpty() == false then
                local not_found_pose_points_order = {}
                for _, default_ps in ipairs(handle_pose.default_points) do
                    local points_found = 0
                    not_found_pose_points_order = {}
                    for it in cel.image:pixels() do
                        local pixelValue = it()
                        local alphaValue = app.pixelColor.rgbaA(pixelValue)
                        if alphaValue ~= 0 and alphaValue ~= 255 then
                            for i, k in ipairs(handle_pose.points) do
                                local d_p = default_ps[i]
                                if app.pixelColor.rgbaR(pixelValue) == d_p.color.red and app.pixelColor.rgbaG(pixelValue) == d_p.color.green and app.pixelColor.rgbaB(pixelValue) == d_p.color.blue then
                                    k.position = { cel.bounds.origin.x + it.x, cel.bounds.origin.y + it.y, 0 }
                                    if handle_pose.draw_points_order[255 - alphaValue] == nil then
                                        handle_pose.draw_points_order[255 - alphaValue] = i
                                    else
                                        not_found_pose_points_order[255 - alphaValue] = i
                                    end
                                    points_found = points_found + 1
                                end
                            end
                        end
                    end
                    if points_found == #default_ps or #not_found_pose_points_order == #default_ps then
                        break
                    end
                end
                if #not_found_pose_points_order > 0 then
                    for _, k in ipairs(not_found_pose_points_order) do
                        for i = 1, #handle_pose.default_points do
                            if handle_pose.draw_points_order[i] == nil then
                                handle_pose.draw_points_order[i] = k
                            end
                        end
                    end
                end
            end
        end
    end

    -- Couldnt find pose
    if handle_pose.cel == nil and create_if_not_found then
        handle_pose.get_pose()
    end
end

function get_pose_from_frame_number(frameNumber)
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            local cel = layer:cel(frameNumber)
            if cel ~= nil and cel.image ~= nil and cel.image:isEmpty() == false then
                local points = createJSON.deepcopy(handle_pose.points)
                local draw_points_order = createJSON.deepcopy(handle_pose.draw_points_order)

                local not_found_pose_points_order = {}
                for _, default_ps in ipairs(handle_pose.default_points) do
                    local points_found = 0
                    not_found_pose_points_order = {}
                    for it in cel.image:pixels() do
                        local pixelValue = it()
                        local alphaValue = app.pixelColor.rgbaA(pixelValue)
                        if alphaValue ~= 0 and alphaValue ~= 255 then
                            for i, k in ipairs(points) do
                                local d_p = default_ps[i]
                                if app.pixelColor.rgbaR(pixelValue) == d_p.color.red and app.pixelColor.rgbaG(pixelValue) == d_p.color.green and app.pixelColor.rgbaB(pixelValue) == d_p.color.blue then
                                    k.position = { cel.bounds.origin.x + it.x, cel.bounds.origin.y + it.y, 0 }
                                    if draw_points_order[255 - alphaValue] == nil then
                                        draw_points_order[255 - alphaValue] = i
                                    else
                                        not_found_pose_points_order[255 - alphaValue] = i
                                    end
                                    points_found = points_found + 1
                                end
                            end
                        end
                    end
                    if points_found == #default_ps then
                        break
                    end
                end
                if #not_found_pose_points_order > 0 then
                    for _, k in ipairs(not_found_pose_points_order) do
                        for i = 1, #handle_pose.default_points do
                            if draw_points_order[i] == nil then
                                draw_points_order[i] = k
                            end
                        end
                    end
                end
                return points
            end
        end
    end
    return nil
end

local function create_pose_layer(points_order, points_position)
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            return
        end
    end
    local layer = app.activeSprite:newLayer()
    layer.name = "PixelLab - Pose"
    -- layer.isEditable = false
    layer.opacity = 255
    handle_pose.layer = layer
    handle_pose.cel = get_cel_by_layer(layer)
end


function get_points_from_frame(frameNumber)
    local points_in_frame = {}
    for _, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Pose" then
            local cel = layer:cel(frameNumber)
            if cel ~= nil and cel.image ~= nil and cel.image:isEmpty() == false then
                local not_found_pose_points_order = {}
                local pose_points_order = {}
                local pose_points_position = {}
                for _, default_ps in ipairs(handle_pose.default_points) do
                    local points_found = 0
                    not_found_pose_points_order = {}
                    pose_points_order = {}
                    pose_points_position = {}
                    for it in cel.image:pixels() do
                        local pixelValue = it()
                        local alphaValue = app.pixelColor.rgbaA(pixelValue)
                        if alphaValue ~= 0 and alphaValue ~= 255 then
                            for i, k in ipairs(handle_pose.points) do
                                local d_p = default_ps[i]
                                if app.pixelColor.rgbaR(pixelValue) == d_p.color.red and app.pixelColor.rgbaG(pixelValue) == d_p.color.green and app.pixelColor.rgbaB(pixelValue) == d_p.color.blue then
                                    pose_points_position[i] = { cel.bounds.origin.x + it.x, cel.bounds.origin.y + it.y, 0 }
                                    if pose_points_order[255 - alphaValue] == nil then
                                        pose_points_order[255 - alphaValue] = i
                                    else
                                        not_found_pose_points_order[255 - alphaValue] = i
                                    end
                                    points_found = points_found + 1
                                end
                            end
                        end
                    end
                    if points_found == #default_ps then
                        break
                    end
                end

                for i, k in ipairs(pose_points_order) do
                    points_in_frame[i] = {
                        label = handle_pose.points[k].name,
                        x = pose_points_position[k][1],
                        y =
                            pose_points_position[k][2],
                        z_index = i
                    }
                end

                if #not_found_pose_points_order > 0 then
                    for _, k in ipairs(not_found_pose_points_order) do
                        for i = 1, #handle_pose.default_points do
                            if points_in_frame[i] == nil then
                                points_in_frame[i] = {
                                    label = handle_pose.points[k].name,
                                    x = pose_points_position[k]
                                        [1],
                                    y = pose_points_position[k][2],
                                    z_index = i
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return points_in_frame
end

local function draw_line(p1, p2, color)
    -- local line_color = Color{r=255, g=255, b=255, a=255}
    local line_color = Color { r = color.red, g = color.green, b = color.blue, a = 255 }

    local brush = Brush(1)
    app.useTool {
        tool = "line",
        color = line_color,
        points = { Point(p1[1], p1[2]), Point(p2[1], p2[2]) },
        brush = brush,
        layer = handle_pose.layer,
        cel = handle_pose.cel
    }
end

local function draw_circle(x, y, color, size)
    local brush = Brush {
        type = BrushType.CIRCLE,
        size = size,
    }
    app.useTool {
        tool = "pencil",
        color = color,
        points = { Point(x, y) },
        brush = brush,
        layer = handle_pose.layer,
        cel = handle_pose.cel,
        ink = "copy_color",
    }
end

local function draw_points()
    for i, point_order in ipairs(handle_pose.draw_points_order) do
        local point = handle_pose.points[point_order]
        -- Draw circles
        local size = 3
        if app.activeSprite.width <= 16 then
            size = 1
        elseif app.activeSprite.width <= 32 then
            size = 2
        end
        local point_color = handle_pose.default_points[1][point_order]["color"]
        local surrounding_color = Color { r = 255, g = 255, b = 255, a = 255 }
        -- local surrounding_color = Color{r=point_color.red, g=point_color.green, b=point_color.blue, a=255}
        draw_circle(point["position"][1], point["position"][2], surrounding_color, size)
    end
    for i, point_order in ipairs(handle_pose.draw_points_order) do
        local point = handle_pose.points[point_order]
        local point_color = handle_pose.default_points[1][point_order]["color"]
        --Hide order in color
        local color_order = Color { r = point_color.red, g = point_color.green, b = point_color.blue, a = point_color.alpha }
        color_order.alpha = 255 - i
        draw_circle(point["position"][1], point["position"][2], color_order, 1)
    end
end

local function draw_pose()
    if app.activeSprite.selection.isEmpty == false then
        app.command.Cancel()
        app.activeSprite.selection:deselect()
    end
    for _, point_order in ipairs(handle_pose.draw_points_order) do
        point = handle_pose.points[point_order]
        i = point_order
        for _, connectedPointIndex in ipairs(handle_pose.default_points[1][point_order].connected_points) do
            local connectedPoint = handle_pose.points[connectedPointIndex]
            local color = handle_pose.default_points[1][point_order].color
            if connectedPointIndex > i then
                color = handle_pose.default_points[1][connectedPointIndex].color
            end
            draw_line(point.position, connectedPoint.position, color)
        end
    end
    draw_points()
end

local function reset_missing_point()
    for i = 1, #handle_pose.default_points do
        if handle_pose.points[i].name ~= handle_pose.default_points[1][i].name then
            handle_pose.points[i] = createJSON.deepcopy(handle_pose.default_points[1][i])
        end
    end
end

local function re_order(p_move)
    local temp = handle_pose.draw_points_order[p_move]
    -- -- Now shift all elements up by one position
    for i = p_move, #handle_pose.draw_points_order - 1 do
        handle_pose.draw_points_order[i] = handle_pose.draw_points_order[i + 1]
    end
    handle_pose.draw_points_order[#handle_pose.draw_points_order] = temp

    reset_missing_point()
    app.refresh()
end

local function distance(p1, p2)
    return (p1.x - p2[1]) ^ 2 + (p1.y - p2[2]) ^ 2
end

local function get_closest_point_index_and_within_distance(mouse_position, max_distance)
    local index = nil
    local dist_nearest = 10000

    for i, point_order in ipairs(handle_pose.draw_points_order) do
        local p = handle_pose.points[point_order]
        distance_between_points = distance(mouse_position, p.position)
        if distance_between_points <= max_distance ^ 2 and distance_between_points < dist_nearest then
            dist_nearest = distance_between_points
            index = i
            if dist_nearest == 0 then
                return index
            end
        end
    end
    return index
end

function handle_pose.reset()
    if app.activeSprite.colorMode ~= ColorMode.RGB then
        return app.alert(
            "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
    end
    if app.activeSprite.selection.isEmpty == false then
        app.command.Cancel()
        app.activeSprite.selection:deselect()
    end
    create_pose_layer()
    handle_pose.cel = get_cel_by_layer(get_pose_layer(), app.frame.frameNumber)

    if handle_pose.cel ~= nil and handle_pose.cel.properties ~= nil and handle_pose.cel.properties.option_index ~= nil and handle_pose.cel.properties.option ~= nil then
        local default_reference_points = pose_references:get_points_by_option(handle_pose.cel.properties.option)
        handle_pose.points = createJSON.deepcopy(default_reference_points[handle_pose.cel.properties.option_index])
    else
        local default_reference_points = pose_references:get_points_by_option(handle_pose.option_points)
        handle_pose.points = createJSON.deepcopy(default_reference_points[1])
    end

    handle_pose.cel.image:clear()
    draw_pose()
    app.refresh()
end

function handle_pose.start()
    handle_pose.active = true
    local target_point = nil

    local function move_point_if_stacking(ev)
        local new_point = Point(ev.point.x, ev.point.y)
        local redraw = false
        if target_point ~= nil then
            local nearest_point = get_closest_point_index_and_within_distance(new_point, 0.99)
            while
                nearest_point ~= nil and target_point.name ~= handle_pose.points[handle_pose.draw_points_order[nearest_point]].name do
                new_point.x = new_point.x + 1
                redraw = true
                nearest_point = get_closest_point_index_and_within_distance(new_point, 0.99)
            end

            if redraw then
                target_point.position[1] = new_point.x
                target_point.position[2] = new_point.y
                if handle_pose.cel ~= nil then
                    handle_pose.cel.image:clear()
                    draw_pose()
                end
            end
        end
    end

    local function move_point(ev)
        if target_point ~= nil then
            target_point.position[1] = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
            target_point.position[2] = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))

            handle_pose.cel.image:clear()
            draw_pose()
        else
            local target_point_index = get_closest_point_index_and_within_distance(ev.point, 3)
            if target_point_index ~= nil then
                target_point = handle_pose.points[handle_pose.draw_points_order[target_point_index]]
                handle_pose.dialog_edit:modify { id = "point", text = handle_pose.points[handle_pose.draw_points_order[target_point_index]].name }
                re_order(target_point_index)
            else
                target_point = nil
            end
        end
    end

    local function delayed_restart()
        target_point = nil
        if app.activeSprite.selection.isEmpty == false then
            app.command.Cancel()
            app.activeSprite.selection:deselect()
        end
        local timer
        timer = Timer {
            interval = 0.01,
            ontick = function()
                handle_pose.editor:askPoint {
                    title = "Edit pose",
                    onclick = function(ev)
                        move_point_if_stacking(ev)
                        delayed_restart()
                        handle_pose.dialog_edit:modify { id = "point", text = "None" }
                    end,
                    onchange = function(ev)
                        move_point(ev)
                    end,
                    oncancel = function(ev)
                        handle_pose.stop()
                    end,
                }
                timer:stop()
            end }
        timer:start()
    end

    if app.editor ~= nil then
        local bounds = handle_pose.dialog_edit.bounds
        handle_pose.dialog_edit:show { wait = false }

        handle_pose.editor = app.editor
        app.editor:askPoint {
            title = "Edit pose",
            onclick = function(ev)
                delayed_restart()
            end,
            onchange = function(ev) move_point(ev) end,
            oncancel = function(ev)
                handle_pose.stop()
            end,
        }
    end
end

function handle_pose.stop()
    handle_pose.active = false
    handle_pose.cel = nil
    handle_pose.layer = nil
    handle_pose.dialog_edit:close()

    if handle_pose.editor ~= nil then
        handle_pose.editor:cancel()
    end
    if current_model ~= nil and current_model.dialog_json ~= nil and current_model.dialog_json["pose"] ~= nil then
        current_model.dialog_json["pose"]["edit"] = false
    end

    local status, err = pcall(function()
        local dialog = getOpenDialog()
        if dialog ~= nil then
            local dlg_bounds = Rectangle(dialog.bounds.origin.x, dialog.bounds.origin.y, dialog.bounds.width,
                dialog.bounds.height)
            dialog:modify { id = "edit", text = "Edit skeleton (ctrl+space+e)" }
            dialog.bounds = dlg_bounds
        end
    end)
end

function handle_pose.get_pose()
    local status, err = pcall(function()
        if app.activeSprite.colorMode ~= ColorMode.RGB then
            return app.alert(
                "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
        end
        if app.activeSprite.selection.isEmpty == false then
            app.command.Cancel()
            app.activeSprite.selection:deselect()
        end
        create_pose_layer()
        local start_frame = app.frame
        local frame = app.frame
        local default_reference_points = pose_references:get_points_by_option(handle_pose.option_points)
        local default_reference_points_order = pose_references:get_points_order_by_option(handle_pose.option_points)
        for i, reference_points in ipairs(default_reference_points) do
            app.activeSprite:newEmptyFrame(app.frame.frameNumber + 1)
        end
        app.activeFrame = start_frame.next

        for i, reference_points in ipairs(default_reference_points) do
            handle_pose.cel = get_cel_by_layer(get_pose_layer(), app.frame.frameNumber)

            handle_pose.points = reference_points
            handle_pose.draw_points_order = default_reference_points_order[i]
            handle_pose.cel.properties.option_index = i
            handle_pose.cel.properties.option = handle_pose.option_points
            handle_pose.cel.image:clear()
            draw_pose()

            app.frame = app.frame.next
        end
        app.activeFrame = start_frame
        app.refresh()
    end)
end

function handle_pose.rescale_poses(frames, new_poses)
    local status, err = pcall(function()
        if app.activeSprite.colorMode ~= ColorMode.RGB then
            return app.alert(
                "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
        end
        if app.activeSprite.selection.isEmpty == false then
            app.command.Cancel()
            app.activeSprite.selection:deselect()
        end
        create_pose_layer()

        for i, new_points in ipairs(new_poses) do
            app.frame = frames[i]
            handle_pose.cel = get_cel_by_layer(get_pose_layer(), frames[i])

            handle_pose.points = new_points
            handle_pose.cel.properties.option = handle_pose.option_points
            handle_pose.cel.image:clear()
            draw_pose()
        end
    end)
end

function handle_pose.edit()
    if app.activeSprite.colorMode ~= ColorMode.RGB then
        return app.alert(
            "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
    end
    if app.activeSprite.selection.isEmpty == false then
        app.command.Cancel()
        app.activeSprite.selection:deselect()
    end
    if get_pose_layer() == nil then
        create_pose_layer()
    end
    if handle_pose.active then
        handle_pose.stop()
    else
        local status, err = pcall(function()
            local dialog = getOpenDialog()
            if dialog ~= nil then
                local dlg_bounds = Rectangle(dlg.bounds.origin.x, dlg.bounds.origin.y, dialog.bounds.width,
                    dialog.bounds.height)
                dialog:modify { id = "edit", text = "Stop edit (ctrl+space+e)" }
                dialog.bounds = dlg_bounds
            end
        end)
        load_pose_from_frame(true)
        handle_pose.cel.image:clear()
        draw_pose()
        app.refresh()
        handle_pose.start()
    end
end

function handle_pose.estimate_skeleton(create_only_if_doesnt_exist)
    if app.activeSprite == nil then
        return app.alert("Failed to find canvas")
    end
    if app.activeSprite.width > 256 or app.activeSprite.height > 256 then
        return app.alert("Canvas be less or equal to 256x256")
    end
    if app.activeSprite.colorMode ~= ColorMode.RGB then
        return app.alert(
            "PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
    end
    local frames = { app.activeFrame.frameNumber }
    local frames_range = { app.activeFrame }
    if app.range.isEmpty == false then
        frames = {}
        frames_range = app.range.frames
    end

    create_pose_layer()
    app.refresh()

    local images_request = {}
    for i, f in ipairs(frames_range) do
        local im = getImage.get_image(app.activeSprite, f)
        if im == nil or im == "" or im:isEmpty() then
        elseif create_only_if_doesnt_exist and get_pose_from_frame() ~= nil then
        else
            table.insert(images_request, { base64 = base64.encode(im.bytes) })
            table.insert(frames, f)
        end
    end

    if #images_request == 0 and create_only_if_doesnt_exist then
        return
    elseif #images_request == 0 then
        return app.alert("Images are empty")
    end
    local ws
    local open = false
    local jsonRequest = json.encode({
        version = _version,
        secret = _secret,
        tier = _tier,
        images = images_request,
        image_size = { width = app.activeSprite.width, height = app.activeSprite.height }
    })
    local dlgConnecting

    local function handleMessage(mt, data)
        if ws ~= nil and not_complete then
            if mt == WebSocketMessageType.OPEN and open == false then
                open = true
                ws:sendText(jsonRequest)
                dlgConnecting = Dialog { title = "Connecting...                       ", onclose = function() ws:close() end }
                    :slider { id = "progress_slider", min = 0, enabled = false, max = 100, value = 0 }
                    :button { id = "cancel", text = 'Cancel', onclick = function() dlgConnecting:close() end }:show { wait = false }
                local layer = get_pose_layer()
                if layer ~= nil then
                    local cel = get_cel_by_layer(layer)
                    if cel ~= nil then
                        cel.image:clear()
                    end
                end
            elseif mt == WebSocketMessageType.ERROR and not_complete then
                print("Error: Failed to connect to server")
            elseif mt == WebSocketMessageType.TEXT then
                local json_data = json.decode(data)
                if json_data["detail"] ~= nil then
                    app.alert(json_data["detail"])
                    dlgConnecting:close()
                elseif json_data["queue_position"] ~= nil then
                    queue_position = tonumber(json_data["queue_position"])
                    if queue_position == 0 then
                        dlgConnecting:modify { title = "Loading..." }
                    else
                        dlgConnecting:modify { title = "Waiting... (Queue position: " .. queue_position .. ")" }
                    end
                elseif json_data["progress"] ~= nil then
                    progress = math.ceil(tonumber(json_data["progress"]) * 100 + 100 * (json_data["index"]) / #frames)
                    dlgConnecting:modify { title = "Generating... " .. progress .. "%" }
                    dlgConnecting:modify { id = "progress_slider", value = progress }
                elseif json_data["keypoints"] ~= nil and #json_data["keypoints"] > 0 then
                    for _, kp in ipairs(json_data["keypoints"]) do
                        for _, hp in ipairs(handle_pose.points) do
                            if hp["name"] == kp["label"] then
                                hp["position"][1] = math.floor((kp["x"] * app.activeSprite.width) + 0.5)
                                hp["position"][2] = math.floor((kp["y"] * app.activeSprite.height) + 0.5)
                            end
                        end
                    end

                    app.activeFrame = frames[json_data["index"] + 1]
                    resolve_duplicates(handle_pose.points)
                    handle_pose.layer = get_pose_layer()
                    handle_pose.cel = get_cel_by_layer(handle_pose.layer)
                    app.refresh()
                    draw_pose()
                    if json_data["index"] + 1 == #frames then
                        dlgConnecting:close()
                        not_complete = false
                    end
                end
            end
        end
        if mt == WebSocketMessageType.CLOSE then
            not_complete = false
            ws:close()
            dlgConnecting:close()
            -- dlgLoading:close()
        end
    end

    ws = nil
    ws = WebSocket {
        onreceive = handleMessage,
        url = _url .. "estimate-skeleton",
        deflate = false,
        minreconnectwait = 15,
        maxreconnectwait = 15
    }
    not_complete = true
    ws:connect()
end

local wasActiveSprite = nil
local sprite_size = { 0, 0 }
local saved_all_poses_points = {}

app.events:on('sitechange',
    function()
        if next(saved_all_poses_points) == nil then
            handle_pose.stop()
            if app.activeSprite ~= nil then
                local pose_layer = get_pose_layer()
                if pose_layer ~= nil and pose_layer:cel(app.activeFrame.frameNumber) ~= nil then
                    load_pose_from_frame(false)
                end
            end
        end
    end)

app.events:on('beforecommand',
    function(ev)
        if ev.name == "PlayAnimation" then
            handle_pose.stop()
        elseif ev.name == "SpriteSize" then
            if app.activeSprite ~= nil and get_pose_layer() ~= nil then
                sprite_size[1] = app.activeSprite.width
                sprite_size[2] = app.activeSprite.height

                for i, frame in ipairs(app.activeSprite.frames) do
                    saved_all_poses_points[i] = get_points_from_frame(i)
                end
            end
        end
    end)

app.events:on('aftercommand',
    function(ev)
        if ev.name == "SpriteSize" then
            if app.activeSprite ~= nil and sprite_size[1] ~= 0 and sprite_size[2] ~= 0 and app.activeSprite.width ~= sprite_size[1] and app.activeSprite.height ~= sprite_size[2] then
                local start_active_frame = app.activeFrame

                for i, frame in ipairs(app.activeSprite.frames) do
                    app.activeFrame = i
                    for _, kp in ipairs(saved_all_poses_points[i]) do
                        if kp then
                            -- Edit positions
                            for _, hp in ipairs(handle_pose.points) do
                                if hp["name"] == kp["label"] then
                                    hp["position"][1] = math.floor(kp["x"] * app.activeSprite.width / sprite_size[1] +
                                        0.5)
                                    hp["position"][2] = math.floor(kp["y"] * app.activeSprite.height / sprite_size[1] +
                                        0.5)
                                    break
                                end
                            end

                            -- Edit order
                            for j, dp in ipairs(handle_pose.default_points[1]) do
                                if dp["name"] == kp["label"] then
                                    handle_pose.draw_points_order[kp["z_index"]] = j
                                    break
                                end
                            end
                        end
                    end
                    if next(saved_all_poses_points[i]) ~= nil then
                        resolve_duplicates(handle_pose.points)
                        handle_pose.layer = get_pose_layer()
                        handle_pose.cel = get_cel_by_layer(handle_pose.layer)
                        handle_pose.cel.image:clear()
                        app.refresh()
                        draw_pose()
                    end
                end
                app.activeFrame = start_active_frame
            end
            sprite_size = { 0, 0 }
            saved_all_poses_points = {}
        end
    end)

local activeSpriteFixSkeletonSelection = nil
local listenerCodeFixSkeletonSelection = nil
local listenerCodeUpdateSkeleton = nil
local previous_origin = nil
local previous_bounds = nil
local updateSkeleton = false
app.events:on('sitechange',
    function()
        if app.activeSprite ~= activeSpriteFixSkeletonSelection then
            if listenerCodeFixSkeletonSelection ~= nil then
                activeSpriteFixSkeletonSelection.events:off(listenerCodeFixSkeletonSelection)
                listenerCodeFixSkeletonSelection = nil

                activeSpriteFixSkeletonSelection.events:off(listenerCodeUpdateSkeleton)
                listenerCodeUpdateSkeleton = nil
                activeSpriteFixSkeletonSelection = nil
            end
            if app.activeSprite ~= nil then
                activeSpriteFixSkeletonSelection = app.activeSprite
                listenerCodeFixSkeletonSelection = activeSpriteFixSkeletonSelection.events:on('change', function(ev)
                    -- handle_pose.active checks if edit skeleton is active
                    if ev.fromUndo or handle_pose.active then
                        return
                    end
                    if
                        app.activeSprite.selection.isEmpty == false and (
                            previous_origin == nil or previous_bounds == nil or
                            (previous_bounds.width ~= app.activeSprite.selection.bounds.width or
                                previous_bounds.height ~= app.activeSprite.selection.bounds.height or
                                previous_bounds.x ~= app.activeSprite.selection.bounds.x or
                                previous_bounds.y ~= app.activeSprite.selection.bounds.y or
                                previous_origin.x ~= app.activeSprite.selection.origin.x or
                                previous_origin.y ~= app.activeSprite.selection.origin.y
                            ))
                    then
                        updateSkeleton = true
                        previous_origin = app.activeSprite.selection.origin
                        previous_bounds = app.activeSprite.selection.bounds
                    end
                end)
                listenerCodeUpdateSkeleton = activeSpriteFixSkeletonSelection.events:on('change', function(ev)
                    -- handle_pose.active checks if edit skeleton is active
                    if ev.fromUndo or handle_pose.active then
                        return
                    end
                    if updateSkeleton and app.activeSprite and app.activeSprite.selection.isEmpty then
                        local pose_layer = get_pose_layer()
                        if pose_layer ~= nil then
                            local cel = pose_layer:cel(app.activeFrame.frameNumber)
                            if cel ~= nil and cel.image:isEmpty() == false and check_if_complete_skeleton() then
                                if pose_layer ~= nil and pose_layer then
                                    updateSkeleton = false
                                    load_pose_from_frame(true)
                                    handle_pose.cel.image:clear()
                                    draw_pose()
                                    app.refresh()
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

return handle_pose
