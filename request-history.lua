request_history = {}
request_history["request_history_file_paths"] = {}
request_history["current_model_name"] = {}
request_history["latest_file_name"] = nil
request_history["latest_model_name"] = nil

function request_history.instantiate_request_history_list(model_name)
    local directory = _path .. "request_history/" .. model_name .. "/"
    app.fs.makeAllDirectories(directory)

    local files = app.fs.listFiles(directory)
    local jsonFiles = {}
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            table.insert(jsonFiles, file)
        end
    end
    files = jsonFiles

    request_history["request_history_file_paths"] = files
    current_model_name = model_name
end

function request_history.size()
    return #request_history["request_history_file_paths"]
end

function request_history.exist(model_name, fileName)
    for _, filePath in ipairs(request_history["request_history_file_paths"]) do
        if filePath == fileName then
            return true
        end
    end
    return false
end

function request_history.load_request_from_filename(fileName)
    fileNameCut = fileName:gsub("%.%w+$", "")
    local fileNamePath = fileNameCut .. ".json"
    local old_request = {}

    if app.fs.isFile(fileNamePath) then
        local file = io.open(fileNamePath, "r")
        if file then
            local content = file:read("*a")
            old_request = json.decode(content) or {}
            file:close()
        end
    end

    return old_request
end

function request_history.load_request(model_name, fileName)
    fileNameCut = fileName:gsub("%.%w+$", "")
    local fileNamePath = "request_history/" .. model_name .. "/" .. fileNameCut .. ".json"
    local old_request = {}

    if app.fs.isFile(_path .. fileNamePath) then
        local file = io.open(_path .. fileNamePath, "r")
        if file then
            local content = file:read("*a")
            old_request = json.decode(content) or {}
            file:close()
        end
    end

    return old_request
end

function request_history.insert_request(model_name, request)
    local directory = _path .. "request_history/" .. model_name .. "/"

    if app.fs.makeAllDirectories(directory) then
        request_history.instantiate_request_history_list(model_name)
    end

    request["points"] = nil
    request["selected_reference_image"] = nil
    request["interpolation_from"] = nil
    request["interpolation_to"] = nil
    request["style_image"] = nil
    request["from_image"] = nil

    local time = os.time()
    local fileName = os.date("%Y%m%d%H%M%S", time)
    local file = io.open(directory .. fileName .. ".json", "w")
    if file then
        file:write(json.encode(request))
        file:close()
    end
    table.insert(request_history["request_history_file_paths"], directory .. fileName .. ".json")
    request_history["latest_file_name"] = fileName
    request_history["latest_model_name"] = model_name
end

function request_history.delete_history(model_name)
    local directory = _path .. "request_history/" .. model_name .. "/"
    local files = app.fs.listFiles(directory)

    for _, file in ipairs(files) do
        app.fs.removeFile(file)
    end

    request_history.instantiate_request_history_list(model_name)
end

function request_history.transfer_over(from, to)
    for key, value in pairs(from) do
        if to[key] ~= nil and type(value) ~= 'userdata' then
            if type(value) == 'table' then
                request_history.transfer_over(value, to[key])
            else
                to[key] = value
            end
        end
    end
end

function request_history.insert_seed(seed)
    if request_history["latest_model_name"] ~= nil and request_history["latest_file_name"] ~= nil then
        local fileName = "request_history/" ..
            request_history["latest_model_name"] .. "/" .. request_history["latest_file_name"] .. ".json"
        if app.fs.isFile(_path .. fileName) then
            local file = io.open(_path .. fileName, "r")
            if file then
                local content = file:read("*a")
                file:close()
                local request = json.decode(content)
                request["seed"] = seed
                file = io.open(_path .. fileName, "w")
                file:write(json.encode(request))
                file:close()
            end
        end
    end
end

function request_history.insert_image(imageBytes, size)
    if request_history["latest_model_name"] ~= nil and request_history["latest_file_name"] ~= nil then
        local fileName = "request_history/" ..
            request_history["latest_model_name"] .. "/" .. request_history["latest_file_name"] .. ".png"
        local filePath = _path .. fileName
        local image = Image(64, 64)
        if size ~= nil then
            image = Image(size["width"], size["height"])
        end
        image.bytes = imageBytes
        if image then
            image:saveAs(filePath)
        end
    end
end
