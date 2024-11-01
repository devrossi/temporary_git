local json = dofile('./json.lua')
local base64 = dofile('./base64.lua')
local displayImagesInDialog = dofile('./display-images-in-dialog.lua')

createJSON = {}

createJSON.default_json = {
    character = "cute dragon",
    view = "low top-down",
    hide_character = false,
  }

function createJSON.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = createJSON.deepcopy(orig_value)
        end
        setmetatable(copy, createJSON.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function createJSON.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function createJSON.mergeWithDefault(t1, default_current)
    local copy = {}
    for orig_key, orig_value in pairs(default_current) do
        copy[orig_key] = orig_value
    end

    for orig_key, orig_value in pairs(t1) do
        copy[orig_key] = orig_value
    end

    copy["version"]=_version
    copy["secret"]=_secret
    copy["tier"]=_tier
    return copy
end

function createJSON.create(model, data, default_current, images)
    if app.activeSprite ~= nil and (app.activeSprite.width ~= 64 or app.activeSprite.height ~= 64) and model.current_json["image_size"] == nil then
        app.alert("Image must be 64x64")
        return nil
    end
    if app.activeSprite.colorMode ~= ColorMode.RGB then
        app.alert("PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
        return nil
    end

    local jsonData = createJSON.deepcopy(data)

    jsonData["inpainting"]={
        base64_image={
            base64=base64.encode("")
        },
        base64_mask={
            base64=base64.encode("")
        },
        blur=jsonData["blur"],
        n_repaint=jsonData["n_repaint"]
    }

    if jsonData["seed"] == "" then
        jsonData["seed"] = 0
    end

    for orig_key, orig_value in pairs(images) do
        if type(model.default_json[orig_key]) == "table" then
            if model.default_json[orig_key] ~= nil and (model.default_json[orig_key][1] == nil or string.lower(model.current_json[orig_key][1]) ~= "no") then
                if #orig_value == 0 or orig_value[1] == "" or orig_value[#orig_value] == "" then
                    local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

                    if result == 2 then
                        local url = "https://www.pixellab.ai/docs/getting-started"
                        -- Open the URL in the default web browser
                        if os.execute("start " .. url) == nil then
                          if os.execute("xdg-open " .. url) == nil then
                            if os.execute("open " .. url) == nil then
                              print("Failed to open the URL.")
                            end
                          end
                        end
                    end

                    return nil
                end
                for i = 1, #orig_value do 
                    if orig_value[i] == "" or orig_value[i] == nil then
                        local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

                        if result == 2 then
                            local url = "https://www.pixellab.ai/docs/getting-started"
                            -- Open the URL in the default web browser
                            if os.execute("start " .. url) == nil then
                              if os.execute("xdg-open " .. url) == nil then
                                if os.execute("open " .. url) == nil then
                                  print("Failed to open the URL.")
                                end
                              end
                            end
                        end
                        return nil
                    end
                end
            end
        elseif model.default_json[orig_key] ~= nil and type(model.current_json[orig_key]) == type("") and string.lower(model.current_json[orig_key]) ~= "no" and (string.lower(orig_value) == "" or string.lower(orig_value) == "no") then
            local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

            if result == 2 then
                local url = "https://www.pixellab.ai/docs/getting-started"
                -- Open the URL in the default web browser
                if os.execute("start " .. url) == nil then
                  if os.execute("xdg-open " .. url) == nil then
                    if os.execute("open " .. url) == nil then
                      print("Failed to open the URL.")
                    end
                  end
                end
            end
            return nil
        end 

        if model.default_json[orig_key] ~= nil and type(model.default_json[orig_key]) == "table" then
            jsonData[orig_key] = {}
            for i = 1, #orig_value do 
                jsonData[orig_key][i]={
                    base64= base64.encode(orig_value[i]),
                    -- width=size,
                    -- height=size
                }
            end
        else
            if model.default_json[orig_key] ~= nil then
                jsonData[orig_key]={
                    base64= base64.encode(orig_value),
                    -- width=size,
                    -- height=size
                }
            end
        end

    end

    jsonData = createJSON.mergeWithDefault(jsonData, default_current)

    return json.encode(jsonData)
end

function createJSON.create_with_size(model, data, default_current, images, width, height)
    local jsonData = createJSON.deepcopy(data)

    if app.activeSprite.colorMode ~= ColorMode.RGB then
        app.alert("PixelLab only supports color mode RGB at the moment. (Top menu -> Sprite -> Color mode -> RGB color)")
        return nil
    end
    
    jsonData["inpainting"]={
        base64_image={
            base64=base64.encode("")
        },
        base64_mask={
            base64=base64.encode("")
        },
        blur=jsonData["blur"],
        n_repaint=jsonData["n_repaint"]
    }

    if jsonData["seed"] == "" then
        jsonData["seed"] = 0
    end

    for orig_key, orig_value in pairs(images) do
        if type(model.default_json[orig_key]) == "table" then
            if model.default_json[orig_key] ~= nil and (model.default_json[orig_key][1] == nil or string.lower(model.current_json[orig_key][1]) ~= "no") then
                if #orig_value == 0 or orig_value[1] == "" or orig_value[#orig_value] == "" then
                    local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

                    if result == 2 then
                        local url = "https://www.pixellab.ai/docs/getting-started"
                        -- Open the URL in the default web browser
                        if os.execute("start " .. url) == nil then
                          if os.execute("xdg-open " .. url) == nil then
                            if os.execute("open " .. url) == nil then
                              print("Failed to open the URL.")
                            end
                          end
                        end
                    end
                    return nil
                end
                for i = 1, #orig_value do 
                    if orig_value[i] == "" or orig_value[i] == nil then
                        local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

                        if result == 2 then
                            local url = "https://www.pixellab.ai/docs/getting-started"
                            -- Open the URL in the default web browser
                            if os.execute("start " .. url) == nil then
                              if os.execute("xdg-open " .. url) == nil then
                                if os.execute("open " .. url) == nil then
                                  print("Failed to open the URL.")
                                end
                              end
                            end
                        end

                        return nil
                    end
                end
            end
        elseif model.default_json[orig_key] ~= nil and type(model.current_json[orig_key]) == type("") and string.lower(model.current_json[orig_key]) ~= "no" and (string.lower(orig_value) == "" or  string.lower(orig_value) == "no") then
            local result = app.alert{title="Missing image", text="Missing image: " .. displayImagesInDialog.get_image_display_name(orig_key), buttons={"OK", "Help"}}

            if result == 2 then
                local url = "https://www.pixellab.ai/docs/getting-started"
                -- Open the URL in the default web browser
                if os.execute("start " .. url) == nil then
                  if os.execute("xdg-open " .. url) == nil then
                    if os.execute("open " .. url) == nil then
                      print("Failed to open the URL.")
                    end
                  end
                end
            end

            return nil
        end 

        if model.default_json[orig_key] ~= nil and type(model.default_json[orig_key]) == "table" then
            jsonData[orig_key] = {}
            for i = 1, #orig_value do 
                jsonData[orig_key][i]={
                    base64= base64.encode(orig_value[i]),
                    -- width=size,
                    -- height=size
                }
            end
        else
            if model.default_json[orig_key] ~= nil then
                jsonData[orig_key]={
                    base64= base64.encode(orig_value),
                    -- width=size,
                    -- height=size
                }
            end
        end

    end

    jsonData = createJSON.mergeWithDefault(jsonData, default_current)

    return json.encode(jsonData)
end


return createJSON