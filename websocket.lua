local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')

generatingImage = false
dlgLoading = nil

websocket = {}

function SetLoadingDialogBounds(dlg)
    if dlgLoadingPosition == nil then
        dlgLoadingPosition = GetDialogPosition(dlg)
    end
    SetDialogBounds(dlg, dlgLoadingPosition)
end

function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function websocket.review_generation(generation_id, review)
    local sent = false
    local review_ws = nil
    local review_request = json.encode({
        tier = _tier,
        version = _version,
        secret = _secret,
        review = review,
        generation_id = generation_id
    })

    local function handleMessageReview(mt, data)
        if review_ws ~= nil then
            if mt == WebSocketMessageType.OPEN and sent == false then
                review_ws:sendText(review_request)
                sent = true
            elseif mt == WebSocketMessageType.TEXT then
                review_ws:close()
                local json_data = json.decode(data)
                if json_data["detail"] ~= nil then
                    app.alert(json_data["detail"])
                end
            end
        end
        if mt == WebSocketMessageType.CLOSE then
            review_ws:close()
        end
    end
    review_ws = WebSocket {
        onreceive = handleMessageReview,
        url = _url .. "review-generation",
        deflate = false,
        minreconnectwait = 15,
        maxreconnectwait = 15
    }
    review_ws:connect()
end

function websocket.request(model, _json, _url, _cels, dlg_title, dlg_type)
    local function openPreviousDialog()
        closeAllDialogs()
        if dlg_type == "Advanced" then
            showAdvancedSettings(model, dlg_title)
        else
            openSettingsDialog(model, dlg_title, true)
        end
    end

    if _cels == nil then
        app.alert("Could not find the cels containing the image")
        if dlgLoading ~= nil then
            dlgLoading:close()
        end
        openPreviousDialog()
        return
    end
    local ws
    local progress = 0
    local jsonRequest
    local seed = "0"
    local discarded = false
    local startSprite
    local startFrame
    local open = false

    if _cels ~= nil and _cels[1] ~= nil then
        app.activeFrame = _cels[1].frame
        startSprite = _cels[1].sprite
        startFrame = _cels[1].frame
    end

    local function go_to_next_frame(cels)
        if cels ~= nil and #cels > 0 then
            local next_frame
            for i = 1, #cels do
                if cels[i] ~= nil then
                    next_frame = cels[#cels + 1 - i].frame
                    app.activeSprite = cels[#cels + 1 - i].sprite
                    app.activeFrame = next_frame
                    return
                end
            end
        end
    end

    local function onCloseLoading()
        ws:close()
        generatingImage = false
        dlgLoadingPosition = GetDialogPosition(dlgLoading)
        dlgLoading = nil
        -- ws = nil
    end

    local function resetSeed(jsonData)
        model.current_json["seed"] = 0
        json_table = json.decode(jsonData)
        json_table["seed"] = 0
        _json = json.encode(json_table)
    end

    local function removeCelsLayer()
        local status, err = pcall(function()
            if _cels ~= nil and #_cels > 0 and _cels[1] ~= nil then
                local canRemove = true
                for i, c in ipairs(_cels[1].layer.cels) do
                    if contains(_cels, c) == false and c.image ~= nil and c.image:isEmpty() == false then
                        canRemove = false
                    end
                end
                if canRemove then
                    _cels[1].sprite:deleteLayer(_cels[1].layer)
                end
            end
        end)
    end

    local function removeCelsFrame()
        local status, err = pcall(function()
            if _cels ~= nil and #_cels > 0 and _cels[1] ~= nil then
                for _, cel in pairs(_cels) do
                    local spr = cel.sprite
                    local f = cel.frame
                    local _image = cel.image

                    if spr ~= nil and f ~= nil then
                        local canRemove = true
                        for i, l in ipairs(spr.layers) do
                            if l.name ~= "PixelLab - Reshape" and cel.layer ~= l then
                                local _cel = l:cel(cel.frameNumber)
                                if _cel ~= nil then
                                    canRemove = false
                                end
                            end
                        end
                        if canRemove then
                            spr:deleteFrame(f)
                        else
                            spr:deleteCel(cel.layer, cel.frame)
                        end
                    end
                    app.refresh()
                end
            end
        end)
    end

    local function removeGeneration()
        if model.current_json["output_method"] ~= nil and model.current_json["output_method"] == "New layer with changes" then
            removeCelsLayer()
            removeCelsFrame()
        elseif model.current_json["output_method"] ~= nil and (model.current_json["output_method"] == "Modify current layer" or model.current_json["output_method"] == "Modify current layer, only changes") then
        elseif model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
        else
            removeCelsFrame()
        end
    end

    local function createLoadingDialog()
        closeAllDialogs()
        if dlgLoading ~= nil then
            dlgLoading:close()
        end
        app.refresh()

        dlgLoading = Dialog { title = "Connecting...                       ", onclose = function() onCloseLoading() end }
            -- dlgLoading:label{ id="loading", label="", text="Connecting...     "}
            :slider { id = "progress_slider", min = 0, enabled = false, max = 100, value = 0 }
            -- :button { id="settings", text = 'Settings', onclick=function() dlgPrevious.:show{wait=false} end }
            :button { id = "settings", text = 'Settings', onclick = function()
                openPreviousDialog()
            end }
            :newrow()
            :button { id = "try_again_overwrite", text = 'Try again', onclick = function()
                dlgLoading:close()
                resetSeed(_json)
                websocket.request(model, _json, _url, _cels, dlg_title, dlg_type)
            end, visible = false }
        if dlgPrevious ~= nil then
            dlgLoading:button { id = "cancel", text = 'Cancel', onclick = function()
                dlgLoading:close()
                openToolsDialog()
            end }
        else
            dlgLoading:button { id = "cancel", text = 'Cancel', onclick = function()
                dlgLoading:close()
                openPreviousDialog()
            end }
        end
        dlgLoading:show { wait = false }
        SetLoadingDialogBounds(dlgLoading)
    end

    local function createFinishedDialog(model, json_data)
        dlgLoading = Dialog { title = "Finished - Seed: " .. json_data["seed"], onclose = function() onCloseLoading() end }
            :button { id = "retry", text = 'Retry', onclick = function()
                dlgLoading:close()
                app.activeSprite = startSprite

                if startFrame.previous ~= nil and (model.current_json["output_method"] == nil or (model.current_json["output_method"] ~= nil and model.current_json["output_method"] == "New frame")) then
                    startFrame = startFrame.previous
                end

                app.activeFrame = startFrame

                if discarded == false and (model.current_json["output_method"] == nil or model.current_json["output_method"] == "New frame") then
                    go_to_next_frame(_cels)
                end

                resetSeed(_json)
                websocket.request(model, _json, _url, model.prepare_image(model, true), dlg_title, dlg_type)
            end }
            :newrow()
        if model.current_json["output_method"] ~= nil and (model.current_json["output_method"] == "Modify current layer" or model.current_json["output_method"] == "Modify current layer, only changes") then
        else
            dlgLoading:button { id = "discard", text = 'Discard', onclick = function()
                discarded = true
                dlgLoading:modify { id = "discard", enabled = false }
                removeGeneration()
            end,
                visible = model.current_json["use_selection"] == nil or (model.current_json["use_selection"] == false) }
        end

        dlgLoading:newrow()
            :button { id = "back_copy_seed", text = 'Back and reuse seed', onclick = function()
                dlgLoading:close()
                model.current_json["seed"] = seed
                openPreviousDialog()
            end }
            :newrow()
            :button { id = "back", text = 'Back', onclick = function()
                dlgLoading:close()
                openPreviousDialog()
            end }
            :button { id = "done", text = 'Done', onclick = function()
                dlgLoading:close()
                openToolsDialog()
            end }
            :separator { id = "rate", text = "Did you like this generation?" }
            :button { id = "like", text = 'Like', onclick = function()
                websocket.review_generation(json_data["generation_id"], true)
                dlgLoading:modify { id = "like", enabled = false }
                dlgLoading:modify { id = "dislike", enabled = false }
            end }
            :button { id = "dislike", text = 'Dislike', onclick = function()
                websocket.review_generation(json_data["generation_id"], false)
                dlgLoading:modify { id = "like", enabled = false }
                dlgLoading:modify { id = "dislike", enabled = false }
            end }
            :label { id = "rate", text = "Images are not saved" }
            :button { id = "help", text = 'Check out documentation', onclick = function()
                local url = "https://www.pixellab.ai/docs"
                if model.dialog_json ~= nil and model.dialog_json["documentation"] ~= nil then
                    url = model.dialog_json["documentation"]
                end
                if os.execute("start " .. url) == nil then
                    if os.execute("xdg-open " .. url) == nil then
                        if os.execute("open " .. url) == nil then
                            print("Failed to open the URL.")
                        end
                    end
                end
            end }
            :show { wait = false }
        SetLoadingDialogBounds(dlgLoading)
    end

    local function handleMessage(mt, data)
        if ws ~= nil and generatingImage then
            if mt == WebSocketMessageType.OPEN and progress == 0 and open == false then
                open = true
                ws:sendText(jsonRequest)
            elseif mt == WebSocketMessageType.ERROR then
                print("Error: Failed to connect to server")
            elseif mt == WebSocketMessageType.TEXT then
                json_data = json.decode(data)

                if json_data["detail"] ~= nil then
                    -- if json_data["code"] ~= 3003 then
                    --     dlgLoading:close()

                    -- else
                    --     dlgLoading:close()
                    --     openPreviousDialog()
                    -- end
                    dlgLoading:close()
                    openPreviousDialog()
                    if json_data["code"] == 3004 or json_data["code"] == 3010 then
                        local result = app.alert { title = "Old version", text = json_data["detail"], buttons = { "Update", "Close" } }
                        if result == 1 then
                            update_plugin.run()
                        end
                    else
                        app.alert(json_data["detail"])
                    end
                    removeGeneration()
                end

                if json_data["queue_position"] ~= nil then
                    queue_position = tonumber(json_data["queue_position"])
                    if queue_position == 0 then
                        dlgLoading:modify { title = "Loading..." }
                    else
                        dlgLoading:modify { title = "Waiting... (Queue position: " .. queue_position .. ")" }
                    end
                end

                if json_data["progress"] ~= nil then
                    progress = math.ceil(tonumber(json_data["progress"]) * 100)
                    -- dlgLoading:modify{ id = "loading", label="", text = "Generating... " .. progress .. "%"}
                    dlgLoading:modify { title = "Generating... " .. progress .. "%" }
                    dlgLoading:modify { id = "progress_slider", value = progress }
                    dlgLoading:modify { id = "try_again_overwrite", visible = true }
                end

                if json_data["image"] ~= nil and #(json_data["image"]["base64"]) ~= 0 then
                    local imageBytes = base64.decode(json_data['image']["base64"])
                    local index = 1

                    if json_data["index"] ~= nil then
                        index = json_data["index"] + 1
                    end

                    local status, err = pcall(function()
                        if app.activeSprite.selection.isEmpty == false then
                            app.command.Cancel()
                        end
                        if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
                            local im = Image(64, 64)
                            if model.current_json["image_size"] ~= nil then
                                im = Image(model.current_json["image_size"]["width"],
                                    model.current_json["image_size"]["height"])
                            end
                            im.bytes = imageBytes
                            local copy = cels[index].image:clone()
                            copy:clear(Rectangle(model.current_json["selection_origin"][1],
                                model.current_json["selection_origin"][2],
                                model.current_json["image_size"]["width"],
                                model.current_json["image_size"]["height"]))
                            copy:drawImage(im,
                                Point(model.current_json["selection_origin"][1],
                                    model.current_json["selection_origin"][2]), 255, BlendMode.SRC)
                            cels[index].image = copy
                        else
                            local im = Image(cels[index].bounds.width, cels[index].bounds.height)

                            im.bytes = imageBytes
                            local copy = cels[index].image:clone()
                            copy:clear(cels[index].bounds)
                            copy:drawImage(im, cels[index].bounds.origin, 255, BlendMode.SRC)
                            cels[index].image = copy
                        end
                    end)

                    app.refresh()
                end

                if json_data["images"] ~= nil and #(json_data["images"]) ~= 0 then
                    app.transaction(
                        function()
                            for i, item in ipairs(json_data["images"]) do
                                local status, err = pcall(function()
                                    if app.activeSprite.selection.isEmpty == false then
                                        app.command.Cancel()
                                    end
                                    local imageBytes = base64.decode(json_data['images'][i]["base64"])
                                    if model.current_json["use_selection"] ~= nil and model.current_json["use_selection"] then
                                        local im = Image(64, 64)
                                        if model.current_json["image_size"] ~= nil then
                                            im = Image(model.current_json["image_size"]["width"],
                                                model.current_json["image_size"]["height"])
                                        end
                                        im.bytes = imageBytes
                                        local copy = cels[i].image:clone()
                                        copy:clear(Rectangle(model.current_json["selection_origin"][1],
                                            model.current_json["selection_origin"][2],
                                            model.current_json["image_size"]["width"],
                                            model.current_json["image_size"]["height"]))
                                        copy:drawImage(im,
                                            Point(model.current_json["selection_origin"][1],
                                                model.current_json["selection_origin"][2]), 255, BlendMode.SRC)
                                        cels[i].image = copy
                                    else
                                        local im = Image(cels[i].bounds.width, cels[i].bounds.height)
                                        im.bytes = imageBytes
                                        local copy = cels[i].image:clone()
                                        copy:clear(cels[i].bounds)
                                        copy:drawImage(im, cels[i].bounds.origin, 255, BlendMode.SRC)
                                        cels[i].image = copy
                                    end
                                end)
                            end
                        end
                    )
                    app.refresh()
                end


                if json_data["type"] ~= nil and json_data["type"] == "connected" then
                    dlgLoading:modify { title = "Getting worker..." }
                end

                if json_data["type"] ~= nil and json_data["type"] == "message_done" then
                    seed = tostring(json_data["seed"])
                    request_history.insert_seed(tostring(json_data["seed"]))
                    if json_data["image"] ~= nil then
                        request_history.insert_image(base64.decode(json_data['image']["base64"]),
                            model.current_json["image_size"])
                    elseif json_data["images"] ~= nil and json_data['images'][1] ~= nil then
                        request_history.insert_image(base64.decode(json_data['images'][1]["base64"]),
                            model.current_json["image_size"])
                    end

                    dlgLoading:close()
                    createFinishedDialog(model, json_data)
                    dlgLoading:repaint()
                    ws:close()
                    generatingImage = false
                end
            end
        end

        if mt == WebSocketMessageType.CLOSE then
            -- dlgLoading:close()
        end
    end

    ws = nil
    cels = _cels
    jsonRequest = _json

    createLoadingDialog()

    ws = WebSocket {
        onreceive = handleMessage,
        url = _url,
        deflate = false,
        minreconnectwait = 10,
        maxreconnectwait = 15
    }
    generatingImage = true
    progress = 0
    ws:connect()

    -- Use to try to avoid people from generating from wrong sprite when using canny
    -- app.events:on('spritechange',
    --     function()
    --         if dlgLoading ~= nil then
    --             dlgLoading:close()
    --             closeAllDialogs()
    --             if dlg_type == "Advanced" then
    --                 showAdvancedSettings(model, dlg_title)
    --             else
    --                 openSettingsDialog(model, dlg_title, true)
    --             end
    --         end
    --     end)
end
