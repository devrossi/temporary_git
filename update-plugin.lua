local json = dofile('./json.lua')

update_plugin = {}

local function createJSON()
    dataJSON = {
      secret=_secret,
      version=_version,
      tier=_tier
    }

    return json.encode(dataJSON)
end

function extractDirectoryPath(fullPath)
    -- Pattern matches everything up to the last slash
    local pattern = "(.+)/[^/]+$"
    local directoryPath = string.match(fullPath, pattern)
    return directoryPath
end

local function request(_json, _url)
  local ws
  local progress = 0
  local jsonRequest
  local open = false

  local function onCloseLoading()
      ws:close()  
      dlgLoading = nil
      updatingPlugin = false
  end

  local function createLoadingDialog()
      if dlgLoading ~= nil then
          dlgLoading:close()
      end
      app.refresh()
  
      dlgLoading = Dialog{title="Connecting...", onclose=function() onCloseLoading() end}
      dlgLoading:label{ id="loading", label="", text="Connecting...     "}
        :button { id="cancel", text = 'Cancel', onclick=function() dlgLoading:close() end } 
          :newrow()
      dlgLoading:show{wait=false}
  end

  local function overwriteFiles(json_data)
      dlgLoading:close()

      if json_data["latest_plugin_version"] == "Up to date" then
        app.alert("Already up-to-date")
      else
        for i, item in pairs(json_data["latest_plugin_version"]) do
            if string.find("/", i) then
                app.fs.makeAllDirectories(_path .. extractDirectoryPath(i))
            end

            local file = io.open(_path .. i, "w+")   
            file:write(item)
            io.close(file)
        end
        _updated = true
        
        dlgComplete = Dialog{title="Update completed", onclose=function()  end}
        dlgComplete:label{ id="Restart", text="You need to restart Aseprite for the update to take effect"}
            :button{ text = 'Close', onclick=function() dlgComplete:close() end } 
            :show{wait=false}
      end
  end

  local function handleMessage(mt, data)
      if ws ~= nil and updatingPlugin then
          if mt == WebSocketMessageType.OPEN and progress == 0 and open == false then
              open = true
              ws:sendText(jsonRequest)
          elseif mt == WebSocketMessageType.TEXT then
            progress = 1
            ws:close()
            local json_data = json.decode(data)
            if json_data["detail"] ~= nil then
                dlgLoading:close()
                app.alert(json_data["detail"])
            elseif json_data["latest_plugin_version"] ~= nil then
                overwriteFiles(json_data)
            end
          end
      end
      if mt == WebSocketMessageType.CLOSE then 
            progress = 1
            ws:close()
          -- dlgLoading:close()
      end
  end

  ws = nil
  jsonRequest = _json

  createLoadingDialog()

  ws = WebSocket{
      onreceive = handleMessage,
      url = _url,
      deflate = false,
      minreconnectwait=15,
      maxreconnectwait=15
  }
  updatingPlugin = true
  progress = 0
  ws:connect()
end

function update_plugin.run()
    request(createJSON(), _url .. "get-latest-pixellab")
end
  
local function request_check_for_update(_json, _url)
    local ws
    local progress = 0
    local jsonRequest
    local updatingPlugin = false

    local function handleMessage(mt, data)
        if ws ~= nil and updatingPlugin then
            if mt == WebSocketMessageType.OPEN and progress == 0 then
                ws:sendText(jsonRequest)
            elseif mt == WebSocketMessageType.TEXT then
                progress = 1
                ws:close()

                local json_data = json.decode(data)

                if json_data["detail"] ~= nil and updatingPlugin then
                    updatingPlugin = false
                    app.alert(json_data["detail"])
                elseif json_data["latest_plugin_version"] ~= nil and updatingPlugin then
                    updatingPlugin = false
                    if json_data["latest_plugin_version"] == "Up to date" then

                    else
                        local result = app.alert{ title="Update PixelLab",
                        text="You have an old version/wrong tier of PixelLab",
                        buttons={"Update", "Cancel"}}

                        if result == 1 then
                            update_plugin.run()
                        end
                    end
                end
            end
        end
        if mt == WebSocketMessageType.CLOSE then 
            progress = 1
            ws:close()
            -- dlgLoading:close()
        end
    end

    ws = nil
    jsonRequest = _json

    ws = WebSocket{
        onreceive = handleMessage,
        url = _url,
        deflate = false,
        minreconnectwait=15,
        maxreconnectwait=15
    }    
    updatingPlugin = true
    progress = 0
    ws:connect()
end

function update_plugin.check_for_update()
    request_check_for_update(createJSON(), _url .. "check-latest-pixellab")
end  

return update_plugin