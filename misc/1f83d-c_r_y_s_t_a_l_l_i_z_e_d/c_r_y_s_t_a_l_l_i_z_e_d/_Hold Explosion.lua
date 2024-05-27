local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");
local bombScaleY

--This check basically makes sure the hold explosion is either "off" or "crystal"
local holdToggle
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","HoldExplosionToggle")) == "off" then
	holdToggle = "off"
else
	holdToggle = "crystal"
end

local rawMini = GAMESTATE:GetPlayerState(pn):GetCurrentPlayerOptions():Mini()
--Variable that scales back to 1 according to mini%. Works for both zoom and for some but not all coordinates
--Thanks to ecafree2 for this equation
local miniAdjustedScale = 1/(1-(rawMini/2))

--Grab tap explosion scale from metrics
local playerBombScale = tonumber(NOTESKIN:GetMetric("NoteskinPreferences","TapExplosionScale"))

--Vertically flip explosion if upscroll
if Reverse then
	bombScaleY = miniAdjustedScale
	bombOffsetY = 12
else
	bombScaleY = miniAdjustedScale * -1
	bombOffsetY = -12
end

local t = Def.ActorFrame{
	Def.Sprite {
		Name="Hold Bomb";
		Texture="Bombs/" .. "hold" .. " " .. tostring(holdToggle);
		Frames=Sprite.LinearFrames(12,0.192);
		InitCommand=function(self)
			self:addy(bombOffsetY)
			self:blend("BlendMode_Add")
			self:diffusealpha(0)
			self:zoom(miniAdjustedScale * playerBombScale)
			self:zoomy(bombScaleY * playerBombScale)
		end,
		HoldingOnCommand=function(self)
			self:stoptweening()
			self:setstate(0)
			self:linear(0.064)
			self:diffusealpha(1)
		end,
		HoldingOffCommand=function(self)
			self:stoptweening()
			self:diffusealpha(0)
		end,
		RollOnCommand=function(self)
			self:stoptweening()
			self:setstate(0)
			self:linear(0.064)
			self:diffusealpha(1)
		end,
		RollOffCommand=function(self)
			self:stoptweening()
			self:diffusealpha(0)
		end
	};


};

return t;