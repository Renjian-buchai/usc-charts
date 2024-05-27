local floor = math.floor;
local min = math.min;
local max = math.max;

chartBPM = 234;
chartOffset = 0;
chartTime = 0;
measure = 0;
beat = 0;
secPerBeat = 60.000 / chartBPM;

-- Update time information
updateTime = function()
	local G, _, __;
	G = background or foreground;
	_, __, chartTime = G.GetTiming();

	chartTime = chartTime - chartOffset;
	beat = floor((chartTime / secPerBeat) % 4.0);

	if (chartTime <= 0) then
		measure = 0;
	else
		measure = 1 + floor(chartTime / (secPerBeat * 4)) + (0.25 * beat);
	end
end

-- Fading image wrapper
---@param startingMeasure number
---@param endingMeasure number
---@param inMeasures number
---@param outMeasures number
---@param path string
---@return FadeImage
fadeWrap = function(startingMeasure, endingMeasure, inMeasures, outMeasures, path)
	---@class FadeImage
	local f = {
		image = Image:new(path),
		inDuration = 0,
		outDuration = 0,
		inMeasures = inMeasures,
		outMeasures = outMeasures,
		start = startingMeasure,
		ending = endingMeasure,
		timer = 0,
	};

	return f;
end

-- Decreases a timer to 0
---@param t number # timer
---@param dt number
---@param d number # duration, in seconds
---@return number
to0 = function(t, dt, d) return max(t - (dt * (1 / d)), 0); end

-- Increases a timer to 1
---@param t number # timer
---@param dt number
---@param d number # duration, in seconds
---@return number
to1 = function(t, dt, d) return min(t + (dt * (1 / d)), 1); end

---@class ImageClass
Image = {
	-- Image constructor
	---@param this ImageClass
	---@param path string
	---@return Image
	new = function(this, path)
		local G = background or foreground;
		---@class Image : ImageClass
		local t = {
			image = assert(gfx.CreateImage(G.GetPath() .. path, 0)),
			w = 500,
			h = 500,
		};

		t.w, t.h = gfx.ImageSize(t.image);
		
		setmetatable(t, this);
		this.__index = this;

		return t;
	end,

	-- Draw the current image
	---@param this Image
	---@param p table #
	-- ```
	-- {
	-- 	x: number = 0,
	-- 	y: number = 0,
	-- 	w: number = 500,
	-- 	h: number = 500,
	-- 	alpha: number = 1,
	-- 	blendOp?: integer,
	-- 	centered: boolean = false,
	-- 	scale: number = 1,
	-- }
	-- ```
	draw = function(this, p)
		local scale = p.scale or 1;
		local x = p.x or 0;
		local y = p.y or 0;
		local w = (p.w or this.w) * scale;
		local h = (p.h or this.h) * scale;

		if (p.centered) then
			x = x - (w / 2);
			y = y - (h / 2);
		end

		gfx.BeginPath();

		if (p.blendOp) then gfx.GlobalCompositeOperation(p.blendOp); end

		gfx.ImageRect(x, y, w, h, this.image, p.alpha or 1, 0);
	end,
};

---@class WindowClass
Window = {
  -- Window constructor
  ---@param this WindowClass
  ---@return Window
  new = function(this)
    ---@class Window : WindowClass
    local t = {
      isPortrait = false,
      resX = 0,
      resY = 0,
      scaleFactor = 1,
      w = 0,
      h = 0,
    };

    setmetatable(t, this);
    this.__index = this;

    return t;
  end,

  -- Returns the scaling factor of the current window
  ---@param this Window
  ---@return number
  getScale = function(this) return this.scaleFactor; end,

  -- Undos any scaling currently applied to the drawn elements
  ---@param this Window
  unscale = function(this) gfx.Scale(1 / this.scaleFactor, 1 / this.scaleFactor); end,

  -- Scales any proceeding elements by the current scaling factor
  ---@param this Window
  scale = function(this) gfx.Scale(this.scaleFactor, this.scaleFactor); end,

  -- Sets the scaling factor, scaled width, and scaled height for the current window
  ---@param this Window
  ---@param scale boolean
  set = function(this, scale)
    local resX, resY = game.GetResolution();

    if ((this.resX ~= resX) or (this.resY ~= this.resY)) then
      this.isPortrait = resY > resX;
      this.w = (this.isPortrait and 1080) or 1920;
      this.h = this.w * (resY / resX);
      this.scaleFactor = resX / this.w;

      this.resX = resX;
      this.resY = resY;
    end

    if (scale) then this:scale(); end
  end,
};

debug = function(t)
  if (not t) then return end

  local w = 0;
  local h = 0;
  local i = 0;
  local n = 0;

  gfx.FontSize(30);
  gfx.LoadSkinFont('NovaMono.ttf');

  for k, v in pairs(t) do
  local x1, y1, x2, y2 = gfx.TextBounds(0, 0, ('%s: %s'):format(k, v));

  if ((x2 - x1) > w) then w = x2 - x1; end
  if ((y2 - y1) > h) then h = y2 - y1; end

  n = n + 1;
  end

  gfx.Save();
  gfx.Translate(8, 4);

  gfx.BeginPath();
  gfx.FillColor(0, 0, 0, 255);
  gfx.Rect(-8, -4, w + 16, (h * n) + 8);
  gfx.Fill();

  gfx.BeginPath();
  gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP);
  gfx.FillColor(255, 255, 255, 255);

  for k, v in pairs(t) do
  gfx.Text(('%s: %s'):format(k, v), 0, h * i);

  i = i + 1;
  end

  gfx.Restore();
end