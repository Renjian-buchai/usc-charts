--c r y s t a l l i z e d v1.1 (4k)
--12/01/2021
--Conversion of "c r y s t a l l i z e d" by Garin from osu!mania https://osu.ppy.sh/community/forums/topics/419005

--Designed for 75% receptor size (50% mini) but can be used for other sizes as well.

--"Oregairu_NP" used as a noteskin base. It can be found on EtternaOnline

--Most of the magic in this noteskin happens in "1 receptor.lua"
--Check that file if you want to know how it works. Comments explain things throughout


local Noteskin = ... or {};
local button = Var "Button"

--Column redirs. The way these are set up makes it so EVERYTHING BUT 4K IS NOT SUPPORTED!!!!!!!!
Noteskin.ButtonRedirs = {
	--Dance(4k)
	Left		= "1";
	Down		= "2";
	Up			= "3";
	Right		= "4";
};

--Element redirects
Noteskin.ElementRedirs = {
	--Redirect dim explosion
	["Tap Explosion Dim"] = "Tap Explosion Bright";

	--Redirect mine explosion to tap explosion
	["HitMine Explosion"] = "Tap Explosion Bright";

	--Redirect hold elements
	["Hold Body Inactive"]		= "Hold Body Active";
	--["Hold BottomCap Inactive"]	= "Hold BottomCap Active";

	--Redirect roll elements
	["Roll Body Inactive"]		= "Roll Body Active";
	--["Roll BottomCap Inactive"]	= "Roll BottomCap Active";

	--Redirect mines
	["Tap Mine"]				= "Mine Dot";
};

--Invisible elements
Noteskin.Hide = {
	["Tap Fake"] 				= true;
	["Tap Lift"] 				= true;
	["Hold Head Active"]		= true;
	["Hold Head Inactive"]		= true;
	["Hold Tail Active"]		= true;
	["Hold Tail Inactive"]		= true;
	["Roll Head Active"]		= true;
	["Roll Head Inactive"]		= true;
	["Roll Tail Active"]		= true;
	["Roll Tail Inactive"]		= true;
};

--Rotations
Noteskin.BaseRotX = {
	Left	= 0;
	UpLeft	= 0;
	Up		= 0;
	Down	= 0;
	UpRight	= 0;
	Right	= 0;
};
Noteskin.BaseRotY = {
	Left	= 0;
	UpLeft	= 0;
	Up		= 0;
	Down	= 0;
	UpRight	= 0;
	Right	= 0;
};

--This part loads elements but I honestly have no clue how it works
local function NoteskinLoader()
	local Button = Var "Button"
	local Element = Var "Element"

	if Noteskin.Hide[Element] then
		--Return a blank element. If SpriteOnly is set, we need to return a
		--sprite; otherwise just return a dummy actor.
		local t;
		if Var "SpriteOnly" then
			t = LoadActor( "_blank" );
		else
			t = Def.Actor {};
		end
		return t .. {
			InitCommand = function(self)
    			self:visible(false)
  			end
		};
	end;


	--Load element and button, using redirs
	local LoadElement = Noteskin.ElementRedirs[Element]
	if not LoadElement then
		LoadElement = Element;
	end;

	local LoadButton = Noteskin.ButtonRedirs[Button]
	if not LoadButton then
		LoadButton = Button;
	end;

	--Get path to thing
	local sPath = NOTESKIN:GetPath( LoadButton, LoadElement );

	--Make actor
	local t = LoadActor( sPath );

	--Apply rotation
	t.BaseRotationX=Noteskin.BaseRotX[sButton]
	t.BaseRotationY=Noteskin.BaseRotY[sButton]

	return t;
end

Noteskin.Load = NoteskinLoader;
Noteskin.CommonLoad = NoteskinLoader;
return Noteskin;