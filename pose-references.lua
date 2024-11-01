local json = dofile('./json.lua')
local all_skeletons = nil

local function distance(p1, p2)
    return math.sqrt((p1[1] - p2[1]) ^ 2 + (p1[2] - p2[2]) ^ 2)
end

function scale_limb(p1, p2, targetLength)
    local currentLength = distance(p1, p2)
    local scaleFactor = targetLength / currentLength
    return {
        scaleFactor,
        scaleFactor,
        0
    }
end

function scale_values(reference_points, reference_template_points, insert_template_points, limit_scale)
    if reference_template_points == nil or #reference_template_points == 0 then
        return
    end
    local bone_changes = {}
    for _, bone in pairs(handle_pose.humanoid_skeleton) do
        local bone_reference_point_1
        local bone_reference_point_2
        for _, p in pairs(reference_points) do
            if p.name == bone[1] then
                bone_reference_point_1 = p
            end
            if p.name == bone[2] then
                bone_reference_point_2 = p
            end
        end

        local bone_reference_template_1
        local bone_reference_template_2
        for _, p in pairs(reference_template_points) do
            if p.name == bone[1] then
                bone_reference_template_1 = p
            end
            if p.name == bone[2] then
                bone_reference_template_2 = p
            end
        end

        local bone_inserted_template_1
        local bone_inserted_template_2
        for _, p in pairs(insert_template_points) do
            if p.name == bone[1] then
                bone_inserted_template_1 = p
            end
            if p.name == bone[2] then
                bone_inserted_template_2 = p
            end
        end

        local estimate_length = distance(bone_reference_point_1.position, bone_reference_point_2.position)
        local insert_template_length = distance(bone_inserted_template_1.position, bone_inserted_template_2.position)

        local rescale_limb = scale_limb(bone_reference_template_1.position, bone_reference_template_2.position,
            distance(bone_reference_point_1.position, bone_reference_point_2.position))

        if limit_scale then
            if (bone_reference_point_2.name == "NOSE" or bone_reference_point_2.name == "RIGHT EYE" or bone_reference_point_2.name == "LEFT EYE" or bone_reference_point_2.name == "LEFT EAR" or bone_reference_point_2.name == "LEFT EAR") and
                insert_template_length * rescale_limb[1] > estimate_length * 1.2 then
                local scale_factor = (estimate_length * 1) / insert_template_length
                rescale_limb[1] = scale_factor
                rescale_limb[2] = scale_factor
            elseif insert_template_length * rescale_limb[1] > estimate_length * 2 then
                local scale_factor = (estimate_length * 1) / insert_template_length * 2
                rescale_limb[1] = scale_factor
                rescale_limb[2] = scale_factor
            end
        end
        bone_changes[bone[2]] = rescale_limb
    end

    return bone_changes
end

function scale_points_based_on_estimate(reference_points, points, bone_changes, first_pose_x, first_pose_y,
                                        same_direction)
    if points == nil or #points == 0 then
        return
    end

    local neck_position_pose
    for _, p in pairs(points) do
        if p.name == "NECK" then
            neck_position_pose = p.position
        end
    end

    local absolute_position = {}
    for _, p in pairs(reference_points) do
        if p.name == "NECK" then
            absolute_position[1] = p.position[1] + (neck_position_pose[1] - first_pose_x)
            absolute_position[2] = p.position[2] + (neck_position_pose[2] - first_pose_y)
        end
    end
    local skeleton = build_skeleton("NECK", points)

    function move_body_(bone)
        if bone.name == "NECK" then
            bone.vector.x = absolute_position[1]
            bone.vector.y = absolute_position[2]
        end
    end

    skeleton:traverse(move_body_)

    function scale_shoulders_and_legs_(bone)
        for k, p in pairs(bone_changes) do
            if k == bone.name then
                bone.scale = { x = p[1], y = p[2] }
            end
        end
    end

    skeleton:traverse(scale_shoulders_and_legs_)
    for _, bc in pairs(skeleton_to_keypoints(skeleton)) do
        for _, p in pairs(points) do
            if p.name == bc.label then
                p.position = { bc.x, bc.y, 0 }
            end
        end
    end
    -- Fixed head if same direction
    -- if same_direction then
    --     for _, p in pairs(points) do
    --         if p.name == "NOSE" or p.name == "LEFT EYE" or p.name == "RIGHT EYE" or p.name == "LEFT EAR" or p.name == "RIGHT EAR" then
    --             for _, hp in pairs(reference_points) do
    --                 if hp.name == p.name then
    --                     p.position = { hp.position[1] + (neck_position_pose[1] - first_pose_x),
    --                         hp.position[2] + (neck_position_pose[2] - first_pose_y),
    --                         0 }
    --                 end
    --             end
    --         end
    --     end
    -- end
end

function scale_points_based_on_estimate_animation(reference_points, points, bone_changes, fixed_head)
    if points == nil or #points == 0 then
        return
    end

    local skeleton = build_skeleton("NECK", points)

    function scale_shoulders_and_legs_(bone)
        for k, p in pairs(bone_changes) do
            if k == bone.name then
                bone.scale = { x = p[1], y = p[2] }
            end
        end
    end

    skeleton:traverse(scale_shoulders_and_legs_)
    for _, bc in pairs(skeleton_to_keypoints(skeleton)) do
        for _, p in pairs(points) do
            if p.name == bc.label then
                p.position = { bc.x, bc.y, 0 }
            end
        end
    end

    -- if fixed_head then
    --     local neck_position_pose
    --     for _, p in pairs(points) do
    --         if p.name == "NECK" then
    --             neck_position_pose = p.position
    --         end
    --     end
    --     local neck_position_reference
    --     for _, p in pairs(reference_points) do
    --         if p.name == "NECK" then
    --             neck_position_reference = p.position
    --         end
    --     end
    --     for _, p in pairs(points) do
    --         if p.name == "NOSE" or p.name == "LEFT EYE" or p.name == "RIGHT EYE" or p.name == "LEFT EAR" or p.name == "RIGHT EAR" then
    --             for _, hp in pairs(reference_points) do
    --                 if hp.name == p.name then
    --                     p.position = { hp.position[1] + (neck_position_pose[1] - neck_position_reference[1]),
    --                         hp.position[2] + (neck_position_pose[2] - neck_position_reference[2]),
    --                         0 }
    --                 end
    --             end
    --         end
    --     end
    -- end
end

function change_skeletons_head_to_reference(reference_points, points)
    if points == nil or #points == 0 then
        return
    end

    local neck_position_pose
    for _, p in pairs(points) do
        if p.name == "NECK" then
            neck_position_pose = p.position
        end
    end
    local neck_position_reference
    for _, p in pairs(reference_points) do
        if p.name == "NECK" then
            neck_position_reference = p.position
        end
    end

    for _, p in pairs(points) do
        if p.name == "NOSE" or p.name == "LEFT EYE" or p.name == "RIGHT EYE" or p.name == "LEFT EAR" or p.name == "RIGHT EAR" then
            for _, hp in pairs(reference_points) do
                if hp.name == p.name then
                    p.position = { hp.position[1] + (neck_position_pose[1] - neck_position_reference[1]),
                        hp.position[2] + (neck_position_pose[2] - neck_position_reference[2]),
                        0 }
                end
            end
        end
    end
end

local function find_next_position(x, y, occupied)
    -- Directions to move in a spiral: right, down, left, up
    local directions = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }
    local step = 1              -- Number of steps in a direction
    local turn = 2              -- Steps before turning
    local current_direction = 1 -- Start by moving right
    local dx, dy = x, y

    while true do
        for _ = 1, step do
            dx, dy = dx + directions[current_direction][1], dy + directions[current_direction][2]
            local key = dx .. ":" .. dy
            if not occupied[key] then
                occupied[key] = true
                return { x = dx, y = dy }
            end
        end
        current_direction = (current_direction % #directions) + 1
        turn = turn - 1
        if turn == 0 then
            step = step + 1
            turn = 2
        end
    end
end

-- Function to resolve duplicates
function resolve_duplicates(points)
    local occupied = {}

    -- First pass to identify duplicates
    for _, point in ipairs(points) do
        local key = point.position[1] .. ":" .. point.position[2]
        if occupied[key] then
            -- If the point is already occupied, find the next available position
            local new_position = find_next_position(point.position[1], point.position[2], occupied)
            point.position[1] = new_position.x
            point.position[2] = new_position.y
        else
            -- Mark this position as occupied
            occupied[key] = true
        end
    end
end

local function get_skeleton_by_path(key, path)
    if all_skeletons ~= nil and all_skeletons[key] ~= nil then
        return all_skeletons[key]
    end
    local exists = app.fs.isFile(_path .. "skeleton_references/pixellab/" .. path)
    if exists == false then
        app.alert(
            "PixelLab failed to download template, try restarting Aseprite. If that doesn't solve the issue, contact the developers")
        return nil
    end

    local file = io.open(_path .. "skeleton_references/pixellab/" .. path, "r")
    local skeleton_json = file:read("*all")
    io.close(file)
    all_skeletons = json.decode(skeleton_json)
    return all_skeletons[key]
end

local function mean_squared_error(y_true, y_pred)
    local neck_position_true_x = 0
    local neck_position_true_y = 0
    for _, p in pairs(y_true) do
        if p["name"] == "NECK" then
            neck_position_true_x = p["position"][1]
            neck_position_true_y = p["position"][2]
        end
    end
    local neck_position_pred_x = 0
    local neck_position_pred_y = 0
    for _, p in pairs(y_pred) do
        if p["name"] == "NECK" then
            neck_position_pred_x = p["position"][1] * app.activeSprite.width
            neck_position_pred_y = p["position"][2] * app.activeSprite.height
        end
    end
    local neck_diff_x = neck_position_true_x - neck_position_pred_x
    local neck_diff_y = neck_position_true_y - neck_position_pred_y

    local sum = 0

    local n = #y_pred
    for i = 1, n do
        if
            y_true[i]["name"] == "RIGHT HIP" or y_true[i]["name"] == "RIGHT SHOULDER" or y_true[i]["name"] == "LEFT HIP" or y_true[i]["name"] == "LEFT SHOULDER" or
            y_true[i]["name"] == "NOSE" or y_true[i]["name"] == "NECK" or y_true[i]["name"] == "LEFT KNEE" or y_true[i]["name"] == "RIGHT KNEE"
        then
            local error_x = (y_true[i]["position"][1] - neck_diff_x) - y_pred[i]["position"][1] * app.activeSprite.width
            local error_y = (y_true[i]["position"][2] - neck_diff_y) - y_pred[i]["position"][2] * app.activeSprite
                .height
            local squared_error = error_x * error_x + error_y * error_y
            sum = sum + squared_error
        end
    end

    return sum / n
end

local function nearest_reference(estimate_points)
    local view = { "high_top_down", "low_top_down", "side" }
    local directions = { "north", "north_north_east", "north_east", "east_north_east", "east", "east_south_east",
        "south_east", "south_south_east", "south", "south_south_west", "south_west", "west_south_west", "west",
        "west_north_west", "north_west", "north_north_west" }
    local min_distance = 9999999999999999
    local nearest_reference_points
    local nearest_direction
    local nearest_view
    for _, v in pairs(view) do
        for _, d in pairs(directions) do
            local base_points = createJSON.deepcopy(get_skeleton_by_path("base", "base.json")[v][d].points[1])
            local distance = mean_squared_error(estimate_points, base_points)
            if distance < min_distance then
                min_distance = distance
                nearest_reference_points = createJSON.deepcopy(base_points)
                nearest_direction = d
                nearest_view = v
            end
        end
    end

    return { nearest_reference_points, nearest_direction, nearest_view }
end

pose_references = {
    get_options = function(self)
        local options = {}
        for key, value in pairs(self) do
            if type(value) == "table" and value.option_text then
                options[value.index] = value.option_text
            end
        end
        return options
    end,
    get_points_by_option = function(self, option)
        local points = {}
        for key, value in pairs(self) do
            if type(value) == "table" and value.option_text == option then
                local view = current_model.current_json.view:gsub("-", "_")
                view = view:gsub(" ", "_")
                value = get_skeleton_by_path(key, value.path)

                if value == nil then
                    return points
                elseif value[view] == nil then
                    app.alert("There is no template for this view")
                    return points
                end

                local direction = current_model.current_json.direction:gsub("-", "_")
                local flip = false

                if value[view][direction] == nil then
                    if value.symmetry and string.match(direction, "west") then
                        direction = direction:gsub("west", "east")
                        flip = true
                    elseif value.symmetry and string.match(direction, "east") then
                        direction = direction:gsub("east", "west")
                        flip = true
                    end

                    if value[view][direction] == nil then
                        app.alert("There is no template for this direction")
                        return points
                    end
                end

                local degree = 0
                if string.match(direction, "east") or string.match(direction, "west") then
                    degree = math.pi / 2
                    if string.match(direction, "north") or string.match(direction, "south") then
                        degree = math.pi / 4
                    end
                end

                local value_animation = value[view][direction]
                points = createJSON.deepcopy(value_animation.points)
                local scale_width_factor = 0
                local scale_height_factor = 0
                local scale_head_factor = 0

                local norm_factor = math.abs(math.cos(degree)) + math.abs(math.sin(degree))
                scale_width_factor = scale_width_factor +
                    (current_model.current_json.size_width_pose / 10 * math.cos(degree) / norm_factor) +
                    (current_model.current_json.size_depth_pose / 10 * math.sin(degree) / norm_factor)
                scale_height_factor = scale_height_factor + current_model.current_json.size_height_pose / 10

                scale_head_factor = scale_head_factor + current_model.current_json.size_head_pose / 10
                local scale_nose_factor = current_model.current_json.size_head_pose / 10 * math.sin(degree)
                local center_x = 0.5 * app.activeSprite.width
                local center_y = 0.5 * app.activeSprite.height

                function rescale_points_to_canvas_size(points)
                    for _, po in pairs(points) do
                        for _, p in pairs(po) do
                            if flip then
                                p.position[1] = (1 - p.position[1] - value_animation.offset[1]) * app.activeSprite.width
                            else
                                p.position[1] = (p.position[1] + value_animation.offset[1]) * app.activeSprite.width
                            end
                            p.position[2] = (p.position[2] + value_animation.offset[2]) * app.activeSprite.height
                            p.position[3] = p.position[3] * app.activeSprite.width
                        end
                    end
                end

                rescale_points_to_canvas_size(points)
                local points_on_canvas = nil
                if #current_model.dialog_json["selected_reference_frame"] > 0 then
                    points_on_canvas = get_pose_from_frame_number(current_model.dialog_json
                        ["selected_reference_frame"][1])
                    -- else
                    --     points_on_canvas = get_pose_from_frame()
                end
                local reference_direction
                local fixed_head = false
                if points_on_canvas ~= nil then
                    reference_direction = current_model.current_json.reference_direction:gsub("-", "_")

                    local base_points
                    if reference_direction ~= "automatic" then
                        base_default = get_skeleton_by_path("base", "base.json")
                        if base_default[view][reference_direction] == nil then
                            app.alert("There is no template for this direction")
                            return points
                        end

                        base_points = createJSON.deepcopy(base_default[view][reference_direction].points)
                    else
                        local nearest_reference_result = nearest_reference(points_on_canvas)
                        base_points = { nearest_reference_result[1] }
                        reference_direction = nearest_reference_result[2]:gsub("-", "_")
                        -- print(reference_direction .. "  -- " .. nearest_reference_result[3])
                    end
                    fixed_head = (current_model.current_json["fixed_head"] ~= nil and (current_model.current_json["fixed_head"] == "always" or (current_model.current_json["fixed_head"] == "same_direction" and reference_direction == direction)))

                    rescale_points_to_canvas_size(base_points)
                    local scaled_values = scale_values(points_on_canvas, base_points[1], points[1], true)
                    local neck_position_first_pose_x = 0
                    local neck_position_first_pose_y = 0
                    for _, p in pairs(points[1]) do
                        if p.name == "NECK" then
                            neck_position_first_pose_x = p.position[1]
                            neck_position_first_pose_y = p.position[2]
                        end
                    end

                    for _, po in pairs(points) do
                        scale_points_based_on_estimate(points_on_canvas, po, scaled_values, neck_position_first_pose_x,
                            neck_position_first_pose_y,
                            fixed_head)
                    end

                    for _, p in pairs(handle_pose.points) do
                        if p.name == "NECK" then
                            center_x = p.position[1]
                            center_y = p.position[2]
                        end
                    end
                end
                for _, po in pairs(points) do
                    for _, p in pairs(po) do
                        if string.match(p.name, "EYE") or string.match(p.name, "EAR") then
                            p.position[1] = math.max(0,
                                math.min(app.activeSprite.width - 1,
                                    ((p.position[1] - center_x) * scale_head_factor) + center_x))
                        end
                        if string.match(p.name, "NOSE") then
                            p.position[1] = math.max(0,
                                math.min(app.activeSprite.width - 1,
                                    ((p.position[1] - center_x) * scale_nose_factor) + center_x))
                        end

                        p.position[1] = math.floor(math.max(0,
                            math.min(app.activeSprite.width - 1,
                                ((p.position[1] - center_x) * scale_width_factor) + center_x +
                                current_model.current_json.x_pose)) + 0.5)
                        p.position[2] = math.floor(math.max(0,
                            math.min(app.activeSprite.height - 1,
                                ((p.position[2] - center_y) * scale_height_factor) + center_y +
                                current_model.current_json.y_pose)) + 0.5)
                    end
                end

                if fixed_head and points_on_canvas ~= nil then
                    for i, po in pairs(points) do
                        change_skeletons_head_to_reference(points_on_canvas, po)
                    end
                end

                for _, po in pairs(points) do
                    resolve_duplicates(po)
                end

                return points
            end
        end
        return points
    end,
    get_points_order_by_option = function(self, option)
        local points = {}
        for key, value in pairs(self) do
            if type(value) == "table" and value.option_text == option then
                local view = current_model.current_json.view:gsub("-", "_")
                view = view:gsub(" ", "_")
                value = get_skeleton_by_path(key, value.path)
                if value == nil then
                    return points
                elseif value[view] == nil then
                    app.alert("There is no template for this view")
                    return points
                end

                local direction = current_model.current_json.direction:gsub("-", "_")
                if value[view][direction] == nil then
                    if value.symmetry and string.match(direction, "west") then
                        direction = direction:gsub("west", "east")
                    elseif value.symmetry and string.match(direction, "east") then
                        direction = direction:gsub("east", "west")
                    end

                    if value[view][direction] == nil then
                        return points
                    end
                end
                return createJSON.deepcopy(value[view][direction].points_order)
            end
        end
        return points
    end,
    get_rescaled_points_from_range = function(self, range)
        local points = {}
        for index, frame in ipairs(range) do
            table.insert(points, createJSON.deepcopy(get_pose_from_frame_number(frame.frameNumber)))
        end
        local scale_width_factor = 0
        local scale_height_factor = 0
        local scale_head_factor = 0
        scale_width_factor = scale_width_factor +
            (current_model.current_json.size_width_pose / 10)
        scale_height_factor = scale_height_factor + current_model.current_json.size_height_pose / 10

        scale_head_factor = scale_head_factor + current_model.current_json.size_head_pose / 10

        -- local points_on_canvas = {}
        -- if current_model.dialog_json["selected_reference_frame"] ~= nil and #current_model.dialog_json["selected_reference_frame"] > 0 then
        --     if (current_model.current_json["fixed_head"] ~= nil and current_model.current_json["fixed_head"] == "always") then
        --         points_on_canvas = createJSON.deepcopy(get_pose_from_frame_number(current_model.dialog_json
        --             ["selected_reference_frame"][1]))
        --         if points_on_canvas ~= nil then
        --             local base_points = points_on_canvas

        --             -- local scaled_values_list = {}
        --             -- for _, po in pairs(points) do
        --             --     table.insert(scaled_values_list, scale_values(points_on_canvas, po, points_on_canvas, false))
        --             -- end
        --             -- for i, po in pairs(points) do
        --             --     scale_points_based_on_estimate_animation(points_on_canvas, po, scaled_values_list[i],
        --             --         (current_model.current_json["fixed_head"] ~= nil and current_model.current_json["fixed_head"] == "always"))
        --             -- end
        --             for i, po in pairs(points) do
        --                 change_skeletons_head_to_reference(points_on_canvas, po)
        --             end
        --         end
        --     end
        -- end
        points_center_x = {}
        points_center_y = {}
        for _, po in pairs(points) do
            for _, p in pairs(po) do
                if p.name == "NECK" then
                    table.insert(points_center_x, p.position[1])
                    table.insert(points_center_y, p.position[2])
                end
            end
        end
        for i, po in pairs(points) do
            local center_x = points_center_x[i]
            local center_y = points_center_y[i]
            for _, p in pairs(po) do
                if string.match(p.name, "EYE") or string.match(p.name, "EAR") then
                    p.position[1] = math.floor(math.max(0,
                        math.min(app.activeSprite.width - 1,
                            ((p.position[1] - center_x) * scale_head_factor) + center_x)))
                end

                p.position[1] = math.floor(math.max(0,
                    math.min(app.activeSprite.width - 1,
                        ((p.position[1] - center_x) * scale_width_factor) + center_x +
                        current_model.current_json.x_pose)) + 0.5)
                p.position[2] = math.floor(math.max(0,
                    math.min(app.activeSprite.height - 1,
                        ((p.position[2] - center_y) * scale_height_factor) + center_y +
                        current_model.current_json.y_pose)) + 0.5)
            end
        end

        if current_model.dialog_json["selected_reference_frame"] ~= nil and #current_model.dialog_json["selected_reference_frame"] > 0 then
            if (current_model.current_json["fixed_head"] ~= nil and current_model.current_json["fixed_head"] == "always") then
                local points_in_reference = createJSON.deepcopy(get_pose_from_frame_number(current_model.dialog_json
                    ["selected_reference_frame"][1]))
                if points_in_reference ~= nil then
                    for i, po in pairs(points) do
                        change_skeletons_head_to_reference(points_in_reference, po)
                    end
                end
            end
        end
        for _, po in pairs(points) do
            resolve_duplicates(po)
        end

        return points
    end,
    version = "0.0.0",
    base = { index = 1, option_text = "base", path = "base.json" },
    walk_4_frames = {
        index = 2,
        option_text = "walk, 4 frames",
        path = "walk_4_frames.json"
    },
    walk_6_frames = {
        index = 3,
        option_text = "walk, 6 frames",
        path = "walk_6_frames.json"
    },
    walk_8_frames = {
        index = 4,
        option_text = "walk, 8 frames",
        path = "walk_8_frames.json"
    }
}

-- local function get_skeleton_reference()
--    local filesData = {}
--    local folderPath = _path .. "skeleton_references"
--    local command

--    if isWindows() then
--        -- Windows command to list all .json files (recursive)
--        command = 'dir "' .. folderPath .. '\\*.json" /b /s'
--    else
--        -- Unix/Linux command to list all .json files (recursive)
--        command = 'find "' .. folderPath .. '" -type f -name "*.json"'
--    end

--    local p = io.popen(command) -- Lists all JSON files
--    for filePath in p:lines() do
--        local file, err = io.open(filePath, "r")
--        if not file then
--          app.alert("Failed to open file: " .. filePath .. " - " .. err)
--        else
--            local fileContent = file:read("*a") -- Read the entire file content
--            file:close() -- Close the file after reading

--            local jsonData = json.decode(fileContent)
--            table.insert(filesData, jsonData)
--        end
--    end
--    p:close()

--    for _, data in ipairs(filesData) do
--       for k,d in pairs(filesData[1]) do
--          pose_references[k] = d
--       end
--    end
-- end

local function download_skeleton_references()
    local ws
    local open = false

    local request = { version = pose_references["version"] }
    local function handleMessage(mt, data)
        if ws ~= nil and updatingPlugin then
            if mt == WebSocketMessageType.OPEN and open == false then
                open = true
                ws:sendText(json.encode(request))
            elseif mt == WebSocketMessageType.TEXT then
                local json_data = json.decode(data)
                if json_data == nil or json_data["detail"] ~= nil then

                else
                    app.fs.makeAllDirectories(_path .. "skeleton_references/pixellab")
                    for i, item in pairs(json_data) do
                        local path = _path .. "skeleton_references/pixellab/" .. i .. ".json"
                        if json_data["version"] ~= nil then
                            path = _path .. "skeleton_references/version.json"
                        end
                        local file = io.open(path, "w+")
                        file:write(json.encode(json_data))
                        io.close(file)
                    end
                end
            end
        end
        if mt == WebSocketMessageType.CLOSE then
            open = true
            updatingPlugin = false
            ws:close()
        end
    end

    ws = nil
    jsonRequest = _json
    ws = WebSocket {
        onreceive = handleMessage,
        url = _url .. "get-skeleton-references",
        deflate = false,
        minreconnectwait = 15,
        maxreconnectwait = 15
    }
    updatingPlugin = true
    ws:connect()
end

local function load_options()
    local file = io.open(_path .. "skeleton_references/version.json", "r")
    local versionJson = file:read("*all")
    io.close(file)
    local version = json.decode(versionJson)
    for k, d in pairs(version) do
        pose_references[k] = d
    end
end

if app.apiVersion >= 26 then
    local exists = app.fs.isDirectory(_path .. "/skeleton_references")
    if exists then
        local status, err = pcall(function()
            load_options()
        end)
    end
    local status, err = pcall(function()
        download_skeleton_references()
    end)
end
