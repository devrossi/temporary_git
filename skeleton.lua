-- Define the skeleton connections
local skeleton = {
    {"NECK", "NOSE"},
    {"NECK", "RIGHT SHOULDER"},
    {"RIGHT SHOULDER", "RIGHT ELBOW"},
    {"RIGHT ELBOW", "RIGHT ARM"},
    {"NECK", "LEFT SHOULDER"},
    {"LEFT SHOULDER", "LEFT ELBOW"},
    {"LEFT ELBOW", "LEFT ARM"},
    {"NECK", "RIGHT HIP"},
    {"RIGHT HIP", "RIGHT KNEE"},
    {"RIGHT KNEE", "RIGHT LEG"},
    {"NECK", "LEFT HIP"},
    {"LEFT HIP", "LEFT KNEE"},
    {"LEFT KNEE", "LEFT LEG"},
    {"NOSE", "RIGHT EYE"},
    {"NOSE", "LEFT EYE"},
    {"RIGHT EYE", "RIGHT EAR"},
    {"LEFT EYE", "LEFT EAR"}
}

-- Bone class
Bone = {}
Bone.__index = Bone

function Bone:new(name, start_keypoint, end_keypoint, vector, scale, parent)
    local o = setmetatable({}, self)
    o.name = name
    o.vector = vector or {x = 0, y = 0}
    o.start_keypoint = start_keypoint
    o.end_keypoint = end_keypoint
    o.children = {}
    o.parent = parent
    o.scale = scale or {x = 1, y = 1}
    return o
end

function Bone:add_child(child)
    table.insert(self.children, child)
    child.parent = self
end

function Bone:traverse(callback)
    callback(self)
    for _, child in ipairs(self.children) do
        child:traverse(callback)
    end
end

-- Build the skeleton
function build_skeleton(root_bone_name, keypoints)
    local bones = get_bones(keypoints)
    local bones_dict = {}
    for _, pair in ipairs(bones) do
        local k1, k2 = pair[1], pair[2]
        if not bones_dict[k1.name] then
            bones_dict[k1.name] = {}
        end
        table.insert(bones_dict[k1.name], k2)

        if not bones_dict[k2.name] then
            bones_dict[k2.name] = {}
        end
        table.insert(bones_dict[k2.name], k1)
    end

    local keypoints_dict = {}
    for _, k in ipairs(keypoints) do
        keypoints_dict[k.name] = k
    end

    local function create_bone(bone_name, parent_bone)
        local start_keypoint = nil
        if parent_bone ~= nil then
            start_keypoint = parent_bone.end_keypoint
        end

        local end_keypoint = keypoints_dict[bone_name]
        local vector

        if parent_bone == nil then
            vector = {
                x = end_keypoint.position[1] - 0,
                y = end_keypoint.position[2] - 0
            }
        else
            vector = {
                x = end_keypoint.position[1] - start_keypoint.position[1],
                y = end_keypoint.position[2] - start_keypoint.position[2]
            }
        end

        local bone = Bone:new(bone_name, start_keypoint, end_keypoint, vector, nil, parent_bone)

        for _, child_keypoint in ipairs(bones_dict[bone_name]) do
            -- Remove the bone's end keypoint from the child's list
            for i, kp in ipairs(bones_dict[child_keypoint.name]) do
                if kp == bone.end_keypoint then
                    table.remove(bones_dict[child_keypoint.name], i)
                    break
                end
            end
            local child_bone = create_bone(child_keypoint.name, bone)
            bone:add_child(child_bone)
        end
        return bone
    end

    return create_bone(root_bone_name)
end

-- Convert skeleton to keypoints
function skeleton_to_keypoints(root_bone)
    local keypoints = {}
    local function traverse_bone(bone, parent_absolute_position)
        local absolute_position = parent_absolute_position and {
            x = parent_absolute_position.x + bone.vector.x * bone.scale.x,
            y = parent_absolute_position.y + bone.vector.y * bone.scale.y
        } or bone.vector

        local keypoint = {label = bone.name, x = absolute_position.x, y = absolute_position.y}
        for k, v in pairs(bone.end_keypoint) do
            if k ~= 'label' and k ~= 'x' and k ~= 'y' then
                keypoint[k] = v
            end
        end
        table.insert(keypoints, keypoint)

        for _, child in ipairs(bone.children) do
            traverse_bone(child, absolute_position)
        end
    end

    traverse_bone(root_bone)
    return keypoints
end

-- Helper function to get bones from keypoints
function get_bones(keypoints)
    local keypoints_dict = {}
    for _, k in ipairs(keypoints) do
        keypoints_dict[k.name] = k
    end

    local bones = {}
    for _, pair in ipairs(skeleton) do
        local start_point, end_point = pair[1], pair[2]
        table.insert(bones, {keypoints_dict[start_point], keypoints_dict[end_point]})
    end
    return bones
end
