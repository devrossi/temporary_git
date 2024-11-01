local getImage = dofile('./get-image.lua')

prepareForGeneration = {}

local function GetNextFrame(create_new_frames)
  local frame = app.activeFrame.next
  local sprite = app.activeSprite

  if create_new_frames or frame == nil then
    frame = sprite:newEmptyFrame(app.activeFrame.frameNumber + 1)
  end

  return frame
end

local function GetCurrentCel(frame)
  local sprite = app.activeSprite
  local layer = app.activeLayer
  local currenct_cel = layer:cel(frame)
  local new_cel

  if currenct_cel ~= nil then
    local current_image = currenct_cel.image:clone()
    local current_position = currenct_cel.position
    new_cel = app.activeSprite:newCel(layer, frame)
    new_cel.image:drawImage(current_image, current_position)
  else
    new_cel = sprite:newCel(layer, frame)
  end

  return new_cel
end

local function GetParentGroup(sprite)
  if sprite == nil then
    sprite = app.activeSprite
  end
  for i, layer in ipairs(app.activeSprite.layers) do
    if layer.name == "PixelLab" then
      return layer
    end
  end
  local group = sprite:newGroup()
  group.name = "PixelLab"
  return group
end

local function GetChildGroup(sprite, parent_group, group_name)
  if sprite == nil then
    sprite = app.activeSprite
  end

  for i, layer in ipairs(parent_group.layers) do
    if layer.name == group_name then
      return layer
    end
  end
  local group = sprite:newGroup()

  group.name = group_name
  group.parent = parent_group

  return group
end

local function ChangeLayerIfReshapeInpainting()
  if app.activeLayer ~= nil and (app.activeLayer.name == "PixelLab - Reshape" or app.activeLayer.name == "PixelLab - Inpainting" or app.activeLayer.name == "PixelLab - Pose") then
    for i, layer in ipairs(app.activeSprite.layers) do
      if layer.name ~= "PixelLab - Reshape" and layer.name ~= "PixelLab - Inpainting" and layer.name ~= "PixelLab - Pose" then
        app.activeLayer = layer
      end
    end
  end
end

local function GetPixelLabLayer()
  sprite = app.activeSprite


  for i, layer in ipairs(app.activeSprite.layers) do
    if layer.name == "PixelLab - Generation" then
      local reuse = layer.isVisible
      if layer.isVisible then
        for i, cel in ipairs(layer.cels) do
          if cel.image:isEmpty() == false then
            reuse = false
          end
        end
      end
      if reuse then
        return layer
      end
    end
  end
  local layer = sprite:newLayer()
  layer.name = "PixelLab - Generation"
  return layer
end

local function GetChildLayer(sprite, parent_group, group_name)
  if sprite == nil then
    sprite = app.activeSprite
  end

  for i, layer in ipairs(parent_group.layers) do
    if layer.name == group_name then
      return layer
    end
  end
  local layer = sprite:newLayer()

  layer.name = group_name
  layer.parent = parent_group

  return layer
end

function GetSpriteFixPalette()
  local sprite
  if app.activeSprite ~= nil then
    local palette = app.activeSprite.palettes[1]
    sprite = app.activeSprite

    sprite.palettes[1]:resize(#palette)
    for i = 1, #palette - 1 do
      sprite.palettes[1]:setColor(i, palette:getColor(i))
    end
  else
    sprite = Sprite(64, 64, ColorMode.RGB)
    sprite:setPalette(Palette { fromResource = "DB32" })
  end
  return sprite
end

function prepareForGeneration.prepare_general(create_new_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  local sprite = app.activeSprite
  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local new_image = app.activeSprite == nil

      -- local layer = GetPixelLabLayer()
      local layer = app.activeLayer

      local frame = GetNextFrame(create_new_frames)

      cels[1] = sprite:newCel(layer, frame)

      app.activeLayer = layer
    end
  )
  return cels
end

function prepareForGeneration.prepare_image(create_new_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  local sprite = GetSpriteFixPalette()
  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local new_image = app.activeSprite == nil

      -- local layer = GetPixelLabLayer()
      local layer = app.activeLayer
      local frame
      -- if (app.activeFrame ~= nil and app.activeImage == nil) or app.activeImage:isEmpty() then
      --   frame = app.activeFrame
      -- else
      frame = GetNextFrame(create_new_frames)
      -- end

      cels[1] = sprite:newCel(layer, frame)
      app.activeLayer = layer
    end
  )

  return cels
end

function prepareForGeneration.prepare_same_image(model, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  -- local sprite = GetSpriteFixPalette()
  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local layer = app.activeLayer

      if model.current_json["output_method"] ~= nil and (model.current_json["output_method"] == "New layer with changes" or model.current_json["output_method"] == "New layer") then
        layer = GetPixelLabLayer()
        app.activeLayer = layer
      end

      local prev_cel = layer:cel(app.activeFrame)
      if prev_cel ~= nil then
        local prev_image = prev_cel.image:clone()
        local prev_position = prev_cel.position
        local new_cel = app.activeSprite:newCel(layer, app.activeFrame)
        new_cel.image:drawImage(prev_image, prev_position)
        cels[1] = new_cel
      else
        cels[1] = app.activeSprite:newCel(layer, app.activeFrame)
      end

      app.activeLayer = layer
    end
  )

  return cels
end

function prepareForGeneration.prepare_image_reshape(model, create_new_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local sprite = app.activeSprite

      -- local layer = GetPixelLabLayer()
      local layer = app.activeLayer

      local frame = GetNextFrame(create_new_frames)

      cels[1] = sprite:newCel(layer, frame)

      app.activeLayer = layer
    end
  )
  return cels
end

function prepareForGeneration.add_frame_inbetween(nFrames, create_new_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local sprite = app.activeSprite

      -- local layer = GetPixelLabLayer()
      local layer = app.activeLayer

      for i = 1, nFrames do
        frame = GetNextFrame(create_new_frames)

        cels[i] = sprite:newCel(layer, frame)
      end
      app.activeLayer = layer
    end
  )
  return cels
end

function prepareForGeneration.prepare_images_animation(model, create_new_frames, number_of_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  cels = {}
  local sprite = GetSpriteFixPalette()
  ChangeLayerIfReshapeInpainting()
  local layer = app.activeLayer

  if model.current_json["output_method"] ~= nil and model.current_json["output_method"] ~= "New frame" then
    app.transaction(
      function()
        if model.current_json["output_method"] ~= nil and (model.current_json["output_method"] == "New layer with changes" or model.current_json["output_method"] == "New layer") then
          layer = GetPixelLabLayer()
          app.activeLayer = layer
        end

        local frame = app.activeFrame

        -- local layer = GetPixelLabLayer()
        for i = 1, number_of_frames do
          cels[i] = GetCurrentCel(frame)

          if app.activeFrame.next ~= nil then
            frame = app.activeFrame.next
            app.activeFrame = frame
          elseif i ~= number_of_frames then
            frame = GetNextFrame(create_new_frames)
          end
        end

        app.activeLayer = layer
      end
    )
  else
    app.transaction(
      function()
        ChangeLayerIfReshapeInpainting()

        local layer = app.activeLayer
        -- local layer = GetPixelLabLayer()
        for i = 1, number_of_frames do
          local frame = GetNextFrame(create_new_frames)
          cels[i] = sprite:newCel(layer, frame)

          if model.current_json["model_name"] == "generate_pose_animation" then
            local pose_layer

            for i, layer in ipairs(app.activeSprite.layers) do
              if layer.name == "PixelLab - Pose" then
                pose_layer = layer
              end
            end

            if cels[1].frameNumber >= model.generate_from_frameNumber + i then
              local prev_cel = pose_layer:cel(cels[i].frameNumber -
                (cels[i].frameNumber - i - model.generate_from_frameNumber + 1))
              if prev_cel ~= nil then
                if pose_layer:cel(cels[i].frameNumber) == nil and prev_cel.image ~= nil then
                  sprite:newCel(pose_layer, cels[i].frameNumber, prev_cel.image, prev_cel.position)
                end
              end
            end
          end
        end

        app.activeLayer = layer
      end
    )
  end

  return cels
end

function prepareForGeneration.prepare_images_rotation(model, create_new_frames, name)
  if app.activeSprite.selection.isEmpty == false then
    app.command.Cancel()
  end
  local cels = {}
  local sprite = GetSpriteFixPalette()

  app.transaction(
    function()
      ChangeLayerIfReshapeInpainting()
      local layer = app.activeLayer
      local frame = GetNextFrame(create_new_frames)
      -- local layer = GetPixelLabLayer()
      cels[1] = sprite:newCel(layer, frame)

      frame = GetNextFrame(create_new_frames)

      cels[2] = sprite:newCel(layer, frame)

      frame = GetNextFrame(create_new_frames)

      cels[3] = sprite:newCel(layer, frame)

      frame = GetNextFrame(create_new_frames)

      cels[4] = sprite:newCel(layer, frame)

      app.activeLayer = layer
    end
  )
  return cels
end

return prepareForGeneration
