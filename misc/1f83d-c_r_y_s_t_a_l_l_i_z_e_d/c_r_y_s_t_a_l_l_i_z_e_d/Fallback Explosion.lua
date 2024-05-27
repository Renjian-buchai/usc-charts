local Reverse = string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsString("ModsLevel_Preferred"), "Reverse");

--DON'T EDIT THIS FILE
--All zooms in this file are set to 1 because they somehow set the base zoom of the explosions
--If these are edited, all zooms in "_Tap explosion bright.lua" and "_Hold Explosion.lua" will be scaled as well
--It's probably because the other files are actorframes within the actorframes in this file. I don't know how to only use this file
--Maybe trying not to use metrics for this at all wasn't worth it in the end :d


local t = Def.ActorFrame {
	NOTESKIN:LoadActor( Var "Button", "Hold Explosion" ) .. {
		InitCommand=function(self)
			self:blend("BlendMode_Add"):diffusealpha(0):zoom(1):zoomy(1)
		end,
		HoldingOnCommand=function(self)
			self:stoptweening():setstate(0):diffusealpha(1)
		end,
		HoldingOffCommand=function(self)
			self:stoptweening():diffusealpha(0)
		end,
		RollOnCommand=function(self)
			self:stoptweening():setstate(0):diffusealpha(1)
		end,
		RollOffCommand=function(self)
			self:stoptweening():diffusealpha(0)
		end
	};
	NOTESKIN:LoadActor( Var "Button", "Roll Explosion" ) .. {
		InitCommand=function(self)
			self:blend("BlendMode_Add"):diffusealpha(0):zoom(1):zoomy(1)
		end,
		HoldingOnCommand=function(self)
			self:stoptweening():setstate(0):diffusealpha(1)
		end,
		HoldingOffCommand=function(self)
			self:stoptweening():diffusealpha(0)
		end,
		RollOnCommand=function(self)
			self:stoptweening():setstate(0):diffusealpha(1)
		end,
		RollOffCommand=function(self)
			self:stoptweening():diffusealpha(0)
		end
	};
	NOTESKIN:LoadActor( Var "Button", "Tap Explosion Dim" ) .. {
		InitCommand=function(self)
			self:zoom(1):diffusealpha(0):blend("BlendMode_Add"):zoomy(1)
		end,
		--Custom command for merging most tap explosion commands
		BombCommand=function(self)
			--Diffusing to white resets to original texture colour
			self:stoptweening():diffuse(color("#FFFFFF")):setstate(0):diffusealpha(1):sleep(0.191):diffusealpha(0)
		end,
		HitMineCommand=function(self)
			--Set colour to red on mine hit
			self:stoptweening():diffuse(color("#D12A31")):setstate(0):diffusealpha(1):sleep(0.191):diffusealpha(0)
		end,
		W5Command=function(self)
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
			self:queuecommand("Bomb")
		end,
		JudgmentCommand=function(self)
			self:finishtweening()
		end;
		BrightCommand=function(self)
			self:visible(false)
		end;
		DimCommand=function(self)
			self:visible(true)
		end;
	};
	NOTESKIN:LoadActor( Var "Button", "Tap Explosion Bright" ) .. {
		InitCommand=function(self)
			self:zoom(1):diffusealpha(0):blend("BlendMode_Add"):zoomy(1)
		end,
		--Custom command for merging most tap explosion commands
		BombCommand=function(self)
			--Diffusing to white resets to original texture colour
			self:stoptweening():diffuse(color("#FFFFFF")):setstate(0):diffusealpha(1):sleep(0.191):diffusealpha(0)
		end,
		HitMineCommand=function(self)
			--Set colour to red on mine hit
			self:stoptweening():diffuse(color("#D12A31")):setstate(0):diffusealpha(1):sleep(0.191):diffusealpha(0)
		end,
		W5Command=function(self)
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
			self:queuecommand("Bomb")
		end,
		JudgmentCommand=function(self)
			self:finishtweening()
		end;
		BrightCommand=function(self)
			self:visible(true)
		end;
		DimCommand=function(self)
			self:visible(false)
		end;
	};
	NOTESKIN:LoadActor( Var "Button", "HitMine Explosion" ) .. {
		InitCommand=function(self)
			self:zoom(1):diffusealpha(0):blend("BlendMode_Add"):zoomy(1)
		end,
		HitMineCommand=function(self)
			--Set colour to red on mine hit
			self:stoptweening():diffuse(color("#D12A31")):setstate(0):diffusealpha(1):sleep(0.191):diffusealpha(0)
		end
	};
}
return t;
