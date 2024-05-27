dofile(foreground.GetPath() .. 'common.lua');

local window = Window:new();

local floor = math.floor;

local dimBot = fadeWrap(81, 94.25, 13.5, 1.5, 'dim_bot.png');
local dimTop = fadeWrap(93.5, 94.25, 0.25, 1.5, 'dim_top.png');
local dimsDone = false;

local textOffset = 0;
local text = {
  breaks = {
    ['and'] = 0,
    ['in'] = 0.24,
    ['that'] = 0.42,
    ['light'] = 0.64,
    ['I'] = 0.84,
    ['find'] = 1.08,
    ['deliverance'] = 1.4,
  },
  done = false,
  ending = 95.75,
  outTimer = 1,
  set = false,
  start = 93.75,
  timer = 0,
  x = {},
  ['and'] = Image:new('text/and.png'),
  ['in'] = Image:new('text/in.png'),
  ['that'] = Image:new('text/that.png'),
  ['light'] = Image:new('text/light.png'),
  ['I'] = Image:new('text/I.png'),
  ['find'] = Image:new('text/find.png'),
  ['deliverance'] = Image:new('text/deliverance.png'),
};

local lines = {
  fadeWrap(93.75, 95.75, 0.5, 0.25, 'line_left.png'),
  fadeWrap(93.75, 95.75, 0.5, 0.25, 'line_right.png'),
};
local linesDone = false;

local fadeTimer = 0;

local getDuration = function(measures) return (measures * 4) * secPerBeat end

local setDurations = function()
  dimBot.inDuration = getDuration(dimBot.inMeasures);
  dimBot.outDuration = getDuration(dimBot.outMeasures);
  dimTop.inDuration = getDuration(dimTop.inMeasures);
  dimTop.outDuration = getDuration(dimTop.outMeasures);

  lines[1].inDuration = getDuration(lines[1].inMeasures);
  lines[1].outDuration = getDuration(lines[1].outMeasures);
  lines[2].inDuration = getDuration(lines[2].inMeasures);
  lines[2].outDuration = getDuration(lines[2].outMeasures);
end

local setText = function()
  local x = window.w / 2;
  local half = text['I'].w / 2;

  text.x['I'] = x;

  text.x['find'] = text.x['I'] + half;
  text.x['deliverance'] = text.x['find'] + text['find'].w;

  text.x['light'] = text.x['I'] - half - text['light'].w;
  text.x['that'] = text.x['light'] - text['that'].w;
  text.x['in'] = text.x['that'] - text['in'].w;
  text.x['and'] = text.x['in'] - text['and'].w;

  text.set = true;
end

local drawDims = function(dt)
  if (dimsDone) then return; end

  if (measure >= dimBot.ending) then
    dimBot.timer = to0(dimBot.timer, dt, dimBot.outDuration);
    dimTop.timer = to0(dimTop.timer, dt, dimTop.outDuration);
    fadeTimer = to0(fadeTimer, dt, 0.4);

    if (dimBot.timer == 0) then dimsDone = true; end
  elseif (measure >= dimBot.start) then
    dimBot.timer = to1(dimBot.timer, dt, dimBot.inDuration);

    if (measure >= dimTop.start) then
      dimTop.timer = to1(dimTop.timer, dt, dimTop.inDuration);

      if (dimTop.timer > 0.8) then fadeTimer = to1(fadeTimer, dt, 0.2); end
    end
  end

  dimBot.image:draw({
    w = window.w,
    h = window.h,
    alpha = dimBot.timer,
  });

  gfx.BeginPath();
  gfx.FillColor(0, 0, 0, floor(255 * fadeTimer));
  gfx.Rect(0, 0, window.w, window.h);
  gfx.Fill();

  dimTop.image:draw({
    w = window.w,
    h = window.h,
    alpha = dimTop.timer,
  });
end

local drawLines = function(dt)
  if (linesDone) then return; end

  if (measure >= lines[1].ending) then
    lines[1].timer = to0(lines[1].timer, dt, lines[1].outDuration);
    lines[2].timer = to0(lines[2].timer, dt, lines[2].outDuration);

    if (lines[1].timer == 0) then linesDone = true; end
  elseif (measure >= lines[1].start) then
    lines[1].timer = to1(lines[1].timer, dt, lines[1].inDuration);
    lines[2].timer = to1(lines[2].timer, dt, lines[2].inDuration);
  end

  lines[1].image:draw({
    y = (window.h / 3) - (lines[1].image.h / 2),
    alpha = lines[1].timer,
  });
  
  lines[2].image:draw({
    x = window.w - lines[2].image.w,
    y = (window.h / 3) - (lines[2].image.h / 2),
    alpha = lines[2].timer,
  });
end

local drawText = function(str)
  local centered = str == 'I';
  local y = window.h / 3;

  if (str ~= 'I') then y = y - (text['I'].h / 2); end

  text[str]:draw({
    x = text.x[str] + textOffset,
    y = y,
    alpha = 0.4 * text.outTimer,
    centered = centered,
  });

  text[str]:draw({
    x = text.x[str],
    y = y,
    alpha = text.outTimer,
    centered = centered,
  });
end

local drawAllText = function(dt)
  if (text.done) then return; end

  if (not text.set) then setText(); end

  if (measure >= text.start) then
    text.timer = text.timer + dt;

    textOffset = math.random(-10, 10);

    for str, val in pairs(text.breaks) do
      if (text.timer > val) then drawText(str); end
    end

    if (measure >= text.ending) then
      text.outTimer = to0(text.outTimer, dt, 0.25);
    end

    if (text.outTimer == 0) then text.done = true; end
  end
end

local resetAll = function()
  if ((not dimBot) or (not lines[1]) or (not text)) then return; end

  dimsDone = false;
  dimBot.timer = 0;
  dimTop.timer = 0;

  linesDone = false;
  lines[1].timer = 0;
  lines[2].timer = 0;

  text.done = false;
  text.outTimer = 1;
  text.timer = 0;
end

render_fg = function(dt)
  updateTime();

  setDurations();

  window:set(true);

  if (measure == 0) then resetAll(); end
    
  drawDims(dt);
  drawLines(dt);
  drawAllText(dt);

  foreground.DrawShader();
end
