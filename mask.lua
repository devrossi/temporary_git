local getImage = dofile('./get-image.lua')

local white = Color{r=255, g=255, b=255, a=255}
local black = Color{r=0, g=0, b=0, a=255}
local clear = Color{r=0, g=0, b=0, a=0}

local pcWhite = app.pixelColor.rgba(255, 255, 255, 255)
local pcBlack = app.pixelColor.rgba(0, 0, 0, 255)
local pcClear = app.pixelColor.rgba(0, 0, 0, 0)

local im_mask

local screen_position_x
local screen_position_y
local zoom
local screen_width
local screen_height
local original_screen_position_x = 144
local original_screen_position_y = 96
local mask = {}

function mask.move_mask_to_top()
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == "PixelLab - Reshape" or layer.name == "PixelLab - Inpainting" then
            layer.stackIndex = #(app.activeSprite.layers)
        end
    end
end

function mask.layer_exist(sprite, name, frame)
    for i, layer in ipairs(app.activeSprite.layers) do
        if string.lower(layer.name) == string.lower(name) then
            return true
        end
    end

    return false
end

function mask.create_layer(sprite, name, frame)
    if app.sprite.selection.isEmpty == false then
        app.command.Cancel()
    end
        
    local layer = sprite:newLayer()
    layer.opacity = 180
    layer.name = name

    local cel = sprite:newCel(layer, frame)

end

local function get_mask(sprite, layerName, frame)
    local mask_exist = false

    for i, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(layerName) then
            if layer:cel(frame) ~= nil then
                return layer:cel(frame).image
            else
                return sprite:newCel(layer, frame).image
            end
        end
    end

    if mask_exist == false then
        return create_layer(sprite, layerName, frame)
    end
end

function mask.showHideInpainting(dlg_menu)
    if dlg_menu.data.init_image ~= nil then
        if dlg_menu.data.init_image == "Yes" then       
            dlg_menu:modify{id="use_inpainting", enabled = true}
        else
            dlg_menu:modify{id="use_inpainting", enabled = false, selected = false}
        end
    end

    dlg_menu:modify{id="inpainting", visible=dlg_menu.data.use_inpainting}
    dlg_menu:modify{id="blur", visible=dlg_menu.data.use_inpainting}
    dlg_menu:modify{id="n_repaint", visible=dlg_menu.data.use_inpainting} 
end



local function draw(im, im_mask, org_im, x, y, size, pcColor)
    x = math.floor((x - (screen_position_x)) / zoom + 0.5)
    y = math.floor((y - (screen_position_y)) / zoom + 0.5)
    local radius = math.floor(size / 2 + 0.5)

    if pcColor == pcClear then
        for it in im:pixels(Rectangle(x - radius, y - radius, size, size)) do 
            if (x - it.x)^2 + (y - it.y)^2 < (size / 2)^2 then
                it(org_im:getPixel(it.x, it.y))
                im_mask:drawPixel(it.x, it.y, clear)
            end
        end
    elseif pcColor == pcBlack then
        for it in im:pixels(Rectangle(x - radius, y - radius, size, size)) do 
            if (it.x - x)^2 + (it.y - y)^2 < (radius)^2 then
                it(pcBlack)
                im_mask:drawPixel(it.x, it.y, black)
            end
        end
    end
end

function mask.add_mask_window(name)
    local im_size
    
    screen_position_x = 144
    screen_position_y = 96

    screen_width = 64
    screen_height = 64
    zoom = 1.0

    im_mask = get_mask(app.activeSprite, name, app.activeFrame)
    local org_im = getImage.get_image(app.activeSprite, app.activeFrame, app.activeImage)


    local mouseDown = false
    local mouseButton
    local distance_mouse_screen

    local im = org_im:clone()

    -- Reset image to previous mask
    for it in im_mask:pixels() do
        if it() == pcBlack then   
            im:drawPixel(it.x, it.y, black)
        end
    end

    local dlg_mask = Dialog(name)
        :separator{ id="brush_information_0", text = "Draw what you wish to inpaint here or" }
        :separator{ id="brush_information_1", text = "draw in the layer named '" .. name .. "' and draw a mask in black" }
        :separator{ id="brush_information_2", text = "Mask is drawn on the same frame as the init image" }
    dlg_mask:canvas{ id="mask_canvas",
            width=256,
            height=256,
            hexpand=false,
            onpaint = function(ev)
                local ctx = ev.context
                ctx.antialias = false
                im_size = math.ceil(screen_width * zoom)
                local rescaled_im = im:clone()

                for it in rescaled_im:pixels() do
                    if app.pixelColor.rgbaA(it()) == 0 or it() == pcClear then
                        it(pcWhite)
                    end           
                end
                rescaled_im:resize(im_size, im_size)
                ctx:drawImage(rescaled_im, screen_position_x, screen_position_y)

            end,
            onmousedown=function(ev) 
                mouseDown = true
                if ev.button ~= nil then
                    mouseButton = ev.button

                    if mouseButton == MouseButton.LEFT then
                        draw(im, im_mask, org_im, ev.x, ev.y, dlg_mask.data.brush_size, pcBlack)
                    elseif mouseButton == MouseButton.RIGHT then
                        draw(im, im_mask, org_im, ev.x, ev.y, dlg_mask.data.brush_size, pcClear)
                    elseif mouseButton == MouseButton.MIDDLE then
                        distance_mouse_screen_x = screen_position_x - ev.x
                        distance_mouse_screen_y = screen_position_y - ev.y
                    end
                end
                dlg_mask:repaint()
            end,
            onmouseup=function(ev) 
                mouseDown = false  
                mouseButton = nil
            end,
            onmousemove=function(ev) 
                if mouseDown then
                    if ev.button ~= nil then
                        if mouseButton == MouseButton.LEFT then
                            draw(im, im_mask, org_im, ev.x, ev.y, dlg_mask.data.brush_size, pcBlack)
                        elseif mouseButton == MouseButton.RIGHT then
                            draw(im, im_mask, org_im, ev.x, ev.y, dlg_mask.data.brush_size, pcClear)
                        elseif mouseButton == MouseButton.MIDDLE then
                            screen_position_x = ev.x + distance_mouse_screen_x
                            screen_position_y = ev.y + distance_mouse_screen_y
                        end
                    
                    end
                end
                dlg_mask:repaint()
            end,
            onwheel=function(ev) 
                if ev.deltaY then
                    if ev.deltaY > 0 then
                        zoom = zoom - 0.5
                    else
                        zoom = zoom + 0.5
                    end
                    dlg_mask:repaint()
                end
                
            end,
        }
        :separator{ id="brush_information_0", text = "Left click: Inpaint, Right click: Remove, Middle button: Move window, Scroll: Zoom" }
        :label{ id="brush_information", label = "", text = "Brush size:" }
        :slider{id="brush_size", label="", min=1, max=16, value=2}   
        :button{id='clear', text='Clear', onclick=function() im_mask:clear( clear ) im = org_im:clone() end}
        :button{id='close', text='Close', onclick=function() dlg_mask:close() end}
        dlg_mask:show()
end

function mask.get_layer_bytes(sprite, frameNumber, name)
    local temp_mask = getImage.get_image_from_layer(sprite, frameNumber, name):clone()

    if temp_mask:isEmpty() then   
        return ""
    end

    for it in temp_mask:pixels() do
        if app.pixelColor.rgbaA(it()) == 0 then   
            it(pcBlack)
        else 
            it(pcWhite)
        end
    end

    return getImage.get_image_bytes(temp_mask) 
end

function mask.get_inpainting_bytes(dlg_menu)
    local inpainting_bytes = ""

    if app.activeSprite ~= nil and dlg_menu.data.use_inpainting then
        inpainting_bytes = mask.get_layer_bytes(app.activeSprite, app.activeFrame, "PixelLab - Inpainting")

        if inpainting_bytes == "" then
            app.alert("Missing mask, make sure the selected contains an inpainting mask")
            return
        end
    end

    return inpainting_bytes
end

function mask.fill_layer(sprite, name)
    for l, layer in ipairs(sprite.layers) do
        if string.lower(layer.name) == string.lower(name) then
            for i = 1,#sprite.frames do
                local cel = layer:cel(i)
                if cel == nil then
                    cel = sprite:newCel(layer, i)
                elseif cel.image == nil then
                    cel = sprite:newCel(layer, i)
                end

                if cel.image:isEmpty() then
                    local new_mask = Image(sprite.width, sprite.height)
                    new_mask:drawSprite(sprite, i)
                    for it in new_mask:pixels() do
                        if app.pixelColor.rgbaA(it()) > 5 then   
                            it(pcBlack)
                        end
                    end                  
                    cel.image = new_mask
                end
            end
        end
    end
    app.refresh()
end

return mask