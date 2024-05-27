local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");

--Some positions rely on playerConfig. This check is for compatibility
if playerConfig then
	stagePosOffset = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates["4K"].NotefieldY
else
	stagePosOffset = 0
end

local rawMini = GAMESTATE:GetPlayerState(pn):GetCurrentPlayerOptions():Mini()
--Variable that scales back to 1 according to mini%. Works for both zoom and for some but not all coordinates
--Thanks to ecafree2 for this equation
local miniAdjustedScale = 1/(1-(rawMini/2))


--Set stage borders to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","StageBorderToggle")) == "off" then
	stageBorderActive = 0
else
	stageBorderActive = 1
end

--Set stage bottom to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","StageBottomToggle")) == "off" then
	stageBottomActive = 0
else
	stageBottomActive = 1
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
				self:diffuse(color("#d0f0ff"))
				self:blend("BlendMode_Add")
				self:addy(-4.5)
				self:zoomto(64,480)
				self:valign(1)
				self:diffusealpha(0)
			else
				self:diffuse(color("#d0f0ff"))
				self:blend("BlendMode_Add")
				self:addy(4.5)
				self:zoomto(64,256)
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

--Stage Right
	Def.Sprite {
				Texture="Stage/right";
				Frame0000=0;
				Delay0000=1;
				--OnCommand instead of InitCommand in order to make the screen check work
				OnCommand=function(self)

					--Fade texture if outside gameplay/practice
					--mainly for song select and player options preview
					if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplay" or SCREENMAN:GetTopScreen():GetName() == "ScreenGameplaySyncMachine" or SCREENMAN:GetTopScreen():GetName() == "ScreenGameplayPractice" then
						--No fade if in gameplay
						stageFade = 0
					else
						--Fade stage outside of gameplay
						--Mainly for song select and player options preview
						stageFade = 0.1
						--Mini is not applied outside gameplay, so let's just make this 1
						miniAdjustedScale = 1
					end


					if Reverse then
						self:halign(0)
						self:zoom(0.625 * miniAdjustedScale)
						self:diffusealpha(stageBorderActive)
						self:addx(32)
						self:addy((-163.5 - stagePosOffset) * miniAdjustedScale)
						self:fadebottom(stageFade)
						self:fadetop(stageFade)
					else
						self:halign(0)
						self:zoom(0.625 * miniAdjustedScale)
						self:diffusealpha(stageBorderActive)
						self:addx(32)
						self:addy((163.5 + stagePosOffset) * miniAdjustedScale)
						self:fadebottom(stageFade)
						self:fadetop(stageFade)
					end
				end,
			};

--Receptor button idle
	Def.Sprite {
		Texture="Stage/1 button idle";
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
		Texture="Stage/1 button pressed";
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

--Judgeline
Def.Sprite {
		Texture="Stage/judgeline";
		Frame0000=0;
		Delay0000=1;
		InitCommand=function(self)
			if Reverse then
				self:halign(0)
				self:zoomto(256,96)
				self:diffusealpha(1)
				self:addx(-224)
			else
				--Reversed alignment due to rotation
				self:halign(1)
				self:zoomto(256,96)
				self:diffusealpha(1)
				self:addx(-224)
				self:addrotationz(180)
			end
		end,
	};

--Stage bottom
Def.Sprite {
		Texture="Stage/bottom";
		Frame0000=0;
		Delay0000=1;
		InitCommand=function(self)
			if Reverse then
				self:valign(0)
				self:halign(0)
				self:zoomto(256,26)
				self:diffusealpha(stageBottomActive)
				self:addy(69 * miniAdjustedScale)
				self:addx(-224)
			else
				--Reversed alignment due to rotation
				self:valign(1)
				self:halign(1)
				self:zoomto(256,26)
				self:diffusealpha(stageBottomActive)
				--For some reason I need a different y offset for upscroll
				self:addy(-90 * miniAdjustedScale)
				self:addx(-224)
				self:addrotationz(180)
			end
		end,
	};

};

return t;