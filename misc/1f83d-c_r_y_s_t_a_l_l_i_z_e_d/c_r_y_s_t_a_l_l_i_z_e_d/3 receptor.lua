local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");

--Some positions rely on playerConfig. This check is for compatibility
if playerConfig then
	stagePosOffset = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates["4K"].NotefieldY
else
	stagePosOffset = 0
end

--Set stage buttons to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","StageButtonToggle")) == "off" then
	stageButtonActive = 0
else
	stageButtonActive = 1
end

local t = Def.ActorFrame{

--Notefield laser graphic
	Def.Sprite {
		Texture="Lasers/" .. tostring(NOTESKIN:GetMetric("NoteskinPreferences","LaserToggle"));
		Frame0000=0;
		Delay0000=1;
		InitCommand=function(self)
			if Reverse then
				self:diffuse(color("#61b7ff"))
				self:blend("BlendMode_Add")
				self:addy(-4.5)
				self:zoomto(64,480)
				self:valign(1)
				self:diffusealpha(0)
			else
				self:diffuse(color("#61b7ff"))
				self:blend("BlendMode_Add")
				self:addy(4.5)
				self:zoomto(64,480)
				self:valign(1)
				self:diffusealpha(0)
				self:addrotationz(180)
			end
		end,
		PressCommand=function(self)
			self:stoptweening()
			self:zoomto(64,480)
			self:linear(.032)
			self:diffusealpha(.68)
		end,
		LiftCommand=function(self)
			self:stoptweening()
			self:linear(.15)
			self:zoomto(64,0)
			self:diffusealpha(0)
		end,
		NoneCommand=function(self)
		end
	};

--Receptor button idle
	Def.Sprite {
		Texture="Stage/2 button idle";
		Frame0000=0;
		Delay0000=1;
		InitCommand=function(self)
			if Reverse then
				self:zoomto(64,160)
				self:diffusealpha(stageButtonActive)
				self:addy(40)
			else
				self:zoomto(64,160)
				self:diffusealpha(stageButtonActive)
				self:addy(-40)
				self:addrotationz(180)
			end
		end,
		PressCommand=function(self)
			self:diffusealpha(stageButtonActive)
		end,
		LiftCommand=function(self)
			self:stoptweening()
		end,
		NoneCommand=function(self)
			self:diffusealpha(stageButtonActive)
		end
	};

--Receptor button pressed
	Def.Sprite {
		Texture="Stage/2 button pressed";
		Frame0000=0;
		Delay0000=1;
		InitCommand=function(self)
			if Reverse then
				self:zoomto(64,160)
				self:diffusealpha(0)
				self:addy(40)
			else
				self:zoomto(64,160)
				self:diffusealpha(0)
				self:addy(-40)
				self:addrotationz(180)
			end
		end,
		PressCommand=function(self)
			self:stoptweening()
			self:linear(.016)
			self:diffusealpha(stageButtonActive)
		end,
		LiftCommand=function(self)
			self:stoptweening()
			self:sleep(.032)
			self:linear(.064)
			self:diffusealpha(0)
		end,
		NoneCommand=function(self)
			self:diffusealpha(0)
		end
	};

};

return t;