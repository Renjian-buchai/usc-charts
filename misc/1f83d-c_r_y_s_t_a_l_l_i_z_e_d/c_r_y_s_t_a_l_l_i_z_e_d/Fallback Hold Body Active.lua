local noteType = "bar"

if Var "Button" == "Left" then 
	local File = ...
	return
		Def.Sprite {
		Texture=NOTESKIN:GetPath("", "Notes/" .. noteType .. "/_White Body" )   
	};
end
if Var "Button" == "Down" then 
	local File = ...
	return
		Def.Sprite {
		Texture=NOTESKIN:GetPath("", "Notes/" .. noteType .. "/_Blue body" )    
	};
end
if Var "Button" == "Up" then 
	local File = ...
	return
		Def.Sprite {
		Texture=NOTESKIN:GetPath("", "Notes/" .. noteType .. "/_Blue body" )   
	};
end
if Var "Button" == "Right" then 
	local File = ...
	return
		Def.Sprite {
		Texture=NOTESKIN:GetPath("", "Notes/" .. noteType .. "/_White Body" )   
	};
end
