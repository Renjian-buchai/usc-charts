dofile(background.GetPath() .. 'common.lua');

background.LoadTexture('bgTex', 'bg_gray.png');

local started = false;

local swapMeasure = 94;
local swapped = false;

render_bg = function(dt)
  if ((measure == 0) and (not started)) then
    background.LoadTexture('bgTex', 'bg_gray.png');

    started = true;
    swapped = false;
  end

  if ((measure >= swapMeasure) and (not swapped)) then
    background.LoadTexture('bgTex', 'bg.png');

    started = false;
    swapped = true;
  end

  background.DrawShader();

  updateTime();
end
