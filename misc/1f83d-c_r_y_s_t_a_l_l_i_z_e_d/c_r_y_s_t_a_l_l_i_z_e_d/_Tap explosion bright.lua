local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");
local bombScaleY

--This check basically makes sure the hold explosion is either "off" or "crystal"
local holdToggle
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","TapExplosionToggle")) == "off" then
	tapToggle = "off"
else
	tapToggle = "crystal"
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
		Name="Tap Bomb";
		Texture="Bombs/" .. "tap" .. " " .. tostring(tapToggle);
		Frames=Sprite.LinearFrames(12,0.192);
		InitCommand=function(self)
			--The textures aren't centered and I'm lazy. Offset y pos
			self:addy(bombOffsetY)
			self:zoom(miniAdjustedScale * playerBombScale)
			self:diffusealpha(0)
			self:blend("BlendMode_Add")
			self:zoomy(bombScaleY * playerBombScale)
		end,
		--Custom command for merging most tap explosion commands
		BombCommand=function(self)
			--Diffusing to white resets to original texture colour
			self:stoptweening()
			self:diffuse(color("#FFFFFF"))
			self:setstate(0)
			self:diffusealpha(0)
			self:linear(0.064)
			self:diffusealpha(1)
			self:sleep(0.064)
			--End animation 1ms earlier than it should
			--In some cases I've seen the animation show the first frame again
			--if the tweens are set to the exact loop time (192ms in this case)
			self:linear(0.063)
			self:diffusealpha(0)
		end,
		HitMineCommand=function(self)
			--Set colour to red on mine hit
			self:stoptweening()
			self:diffuse(color("#D12A31"))
			self:setstate(0)
			self:diffusealpha(0)
			self:linear(0.064)
			self:diffusealpha(1)
			self:sleep(0.064)
			self:linear(0.063)
			self:diffusealpha(0)
		end,
		W5Command=function(self)
		--Redirect to "BombCommand"
			self:queuecommand("Bomb")
		end,
		W4Command=function(self)
			self:queuecommand("Bomb")
		end,
		W3Command=function(self)
			self:queuecommand("Bomb")
		end,
		W2Command=function(self)
			self:queuecommand("Bomb")
		end,
		W1Command=function(self)
			self:queuecommand("Bomb")
		end,
		HeldCommand=function(self)
		--This doesn't include the fade-in of the texture since holds are already bright
			self:stoptweening()
			self:diffuse(color("#FFFFFF"))
			self:setstate(3)
			self:diffusealpha(1)
			self:sleep(0.080)
			self:linear(0.063)
			self:diffusealpha(0)
		end
	};

};

return t;