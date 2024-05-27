local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");

local rawMini = GAMESTATE:GetPlayerState(pn):GetCurrentPlayerOptions():Mini()
--Variable that scales back to 1 according to mini%. Works for both zoom and for some but not all coordinates
--Thanks to ecafree2 for this equation
local miniAdjustedScale = 1/(1-(rawMini/2))

--Some positions rely on playerConfig. This check is for compatibility
if playerConfig then
	stagePosOffset = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates["4K"].NotefieldY
else
	stagePosOffset = 0
end


--Set health bar to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","HealthbarToggle")) == "off" then
	healthActive = 0
else
	healthActive = 1
end

--Set stage borders to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","StageBorderToggle")) == "off" then
	stageBorderActive = 0
else
	stageBorderActive = 1
end

--Set stage buttons to on/off depending on metrics
if tostring(NOTESKIN:GetMetric("NoteskinPreferences","StageButtonToggle")) == "off" then
	stageButtonActive = 0
else
	stageButtonActive = 1
end

--Define health bar positions
local healthbarPosX	= 235
local healthbarPosYDown = -53
local healthbarPosYUp = 260

--Check which stage background is used
--This is used for an exception that prevents squishing of the "sakura" background type
local stageBackgroundType = tostring(NOTESKIN:GetMetric("NoteskinPreferences","BackgroundType"))

--From this point onward you'll find the actual elements
local t = Def.ActorFrame{

--Stage Background
	Def.Sprite {
			Texture="Stage/background " .. tostring(NOTESKIN:GetMetric("NoteskinPreferences","BackgroundType"));
			Frame0000=0;
			Delay0000=1;
			InitCommand=function(self)
					self:queuecommand("StageBackground")
			end,

			--Regular stage background command
			StageBackgroundCommand=function(self)
				if Reverse then
					--Make sure position is correct when switching from up/down scroll
					self:zoom(0.44444444)
					self:zoomy(0.8 * miniAdjustedScale)
					self:diffusealpha(1)
					self:addy(-187 * miniAdjustedScale)
					self:addx(96)
				else
					self:zoom(0.44444444)
					self:zoomy(0.8 * miniAdjustedScale)
					self:diffusealpha(1)
					self:addy(187 * miniAdjustedScale)
					self:addx(96)
					self:addrotationz(180)
				end
			end,

		};

--Health bar
	Def.Sprite {
			Name="Health chill";
			Texture="Stage/health chill";
			Frame0000=0;
			Delay0000=1;
			OnCommand=function(self)
			local health = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetCurrentLife()

				if SCREENMAN:GetTopScreen():GetName() ~= "ScreenGameplay" and SCREENMAN:GetTopScreen():GetName() ~= "ScreenGameplaySyncMachine" and SCREENMAN:GetTopScreen():GetName() ~= "ScreenGameplayPractice" then
					miniAdjustedScale = 1
				end

				if Reverse then
					self:halign(0)
					self:zoom(.43 * miniAdjustedScale)
					self:diffusealpha(healthActive)
					self:addy((stagePosOffset + healthbarPosYDown) * miniAdjustedScale)
					self:addx(healthbarPosX)
				else
					self:halign(0)
					self:zoom(.43 * miniAdjustedScale)
					self:diffusealpha(healthActive)
					self:addy((stagePosOffset + healthbarPosYUp) * miniAdjustedScale)
					self:addx(healthbarPosX)
				end

				--If there's no crop on init the health bar will jitter on first hit, so croptop() is necessary here
				self:croptop(health)

			end,
			JudgmentMessageCommand=function(self)
			--Smooth cropping based on HP
			--Sectioned so it uses a different texture under 40% health
			local health = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetCurrentLife()
					--croptop(1 - health) effectively reverses the value of the command
					--100% health makes "health" 1, which would make the bar disappear without the reversal
					self:stoptweening()
					self:decelerate(0.128)
					self:diffusealpha(healthActive)
					self:croptop( 1 - health )
			end
		};

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
--CAN BE FOUND IN 4 receptor.lua
--it's there for draw order reasons

--Stage Left
	Def.Sprite {
		Texture="Stage/left";
		Frame0000=0;
		Delay0000=1;
		--OnCommand instead of InitCommand in order to make the screen check work (see below)
		OnCommand=function(self)

			if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplay" or SCREENMAN:GetTopScreen():GetName() == "ScreenGameplaySyncMachine" or SCREENMAN:GetTopScreen():GetName() == "ScreenGameplayPractice" then
				--No fade if in gameplay
				stageFade = 0
			else
				--Fade stage outside of gameplay
				--Mainly for song select and player options preview
				stageFade = 1
				--Mini is not applied outside gameplay, so let's just make this 1
				miniAdjustedScale = 1
			end

			if Reverse then
				self:halign(1)
				self:zoom(0.625 * miniAdjustedScale)
				self:diffusealpha(stageBorderActive)
				self:addx(-32)
				self:addy((-163.5 - stagePosOffset) * miniAdjustedScale)
				self:fadeleft(stageFade)
				--self:fadetop(stageFade)
			else
				self:halign(1)
				self:zoom(0.625 * miniAdjustedScale)
				self:diffusealpha(stageBorderActive)
				self:addx(-32)
				self:addy((163.5 + stagePosOffset) * miniAdjustedScale)
				self:fadeleft(stageFade)
				--self:fadetop(stageFade)
			end
		end,
	};

--Stage Right
--CAN BE FOUND IN 4 receptor.lua

};
return t;