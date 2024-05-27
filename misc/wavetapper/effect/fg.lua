local _log = {}
local is_debug = false;

function rlog(s)
    table.insert(_log,1,s)
end
function log(s)
    if is_debug then
        rlog(s)
    end
end

if track == nil or track.CreateShadedMeshOnTrack == nil then
    rlog("You need a newer version of USC to use this chart bga")
    function do_sections() end
else
    log("Starting bga")

local share_tex = gfx.LoadSharedSkinTexture ~= nil

if share_tex then
    log("Trying shared textures")
    gfx.LoadSharedSkinTexture("fxbuttonhold", "fxbuttonhold.png")
    gfx.LoadSharedSkinTexture("fxbutton", "fxbutton.png")
    gfx.LoadSharedSkinTexture("buttonhold", "buttonhold.png")
    gfx.LoadSharedSkinTexture("button", "button.png")

    local sanity = pcall(function() 
        local test2 = gfx.CreateShadedMesh();
        test2:AddSharedTexture("mainTex","button");
    end)
    if not sanity then
        log("AddSharedTexture sanity check failed")
        share_tex = false
    end
else
    log("Not using shared textures")
end
share_tex = false


-- ======= Fake Note Wrapper ======= 
-- You can use this yourself if you would like!

function make_button(fx, long)
    local test = nil
    if long then
        test = track.CreateShadedMeshOnTrack("holdbutton");
    else
        test = track.CreateShadedMeshOnTrack("button");
    end
    if share_tex then
        if fx and long then
            test:AddSharedTexture("mainTex","fxbuttonhold");
        elseif fx then
            test:AddSharedTexture("mainTex","fxbutton");
        elseif long then
            test:AddSharedTexture("mainTex","buttonhold");
        else
            test:AddSharedTexture("mainTex","button");
        end
    else
        if fx and long then
            test:AddSkinTexture("mainTex","fxbuttonhold.png");
        elseif fx then
            test:AddSkinTexture("mainTex","fxbutton.png");
        elseif long then
            test:AddSkinTexture("mainTex","buttonhold.png");
        else
            test:AddSkinTexture("mainTex","button.png");
        end
    end
    test:SetPrimitiveType(test.PRIM_TRIFAN)
    if long then
        test:SetBlendMode(test.BLEND_ADD)
    else
        test:SetBlendMode(test.BLEND_MULT)
    end

    if fx then
        test:UseGameMesh("fxbutton")
    else
        test:UseGameMesh("button")
    end
    test:SetClipWithTrack(true)

    test:SetParam("hasSample", 0.0);
    test:SetParam("hiddenCutoff", 0.0);
    test:SetParam("hiddenFadeWindow", 0.1);
    test:SetParam("suddenCutoff", 1.0);
    test:SetParam("suddenFadeWindow", 0.1);
    test:SetParam("trackPos", 0.0);
    test:SetParam("trackScale", 1.0);
    return {
        fx=fx,
        long=long,
        m=test,
        Hide=function(self) self.m:SetPosition(-100,-100) end
    }
end

-- Default lanes xpos when not split
Ln = {
    a = track.GetCurrentLaneXPos(1),
    b = track.GetCurrentLaneXPos(2),
    c = track.GetCurrentLaneXPos(3),
    d = track.GetCurrentLaneXPos(4),
    l = track.GetCurrentLaneXPos(5),
    r = track.GetCurrentLaneXPos(6),
}

function hide_objects(l)
    for _, n in ipairs(l) do
        for i=2,#n do
            track.HideObject(n[1], n[i])
        end
    end
end

function move_note_z(note,time, x, t, speed)
    if time >= t then
        return move_note(note, x, t, speed)
    end
    local y = track.GetYPosForTime(t) * speed
    note.m:SetPosition(x, .05, y)
    return y
end

function move_note(note, x, time, speed)
    local y = track.GetYPosForTime(time) * speed
    note.m:SetPosition(x, y)
    return y
end

function long_glow(note,time,start)
    if time < start then
        note.m:SetParam("hitState", 1)

    else
        local s;
        if time%100 < 50 then
            s = 0
        else
            s = 1
        end
        note.m:SetParam("hitState", math.floor(2+s))
    end
end

function move_long_note(note,time, x, start, dur, speed)
    local y = track.GetYPosForTime(start)*speed
    note.m:SetPosition(x, y)
    local l = track.GetLengthForDuration(math.floor(start), math.floor(dur))*speed
    note.m:ScaleToLength(l)
    long_glow(note,time,start)
    return y
end

function move_long_note_z(note,time, x, start, dur, speed)
    if time >= start then
        return move_long_note(note,time, x, start, dur, 1)
    end

    local y = track.GetYPosForTime(start)*speed
    note.m:SetPosition(x, .05, y)
    local l = track.GetLengthForDuration(math.floor(time), math.floor(dur))
    note.m:ScaleToLength(l)
    long_glow(note,time,start)
    return y
end

function move_long_note_with_cutoff(note,time, x, start, dur, speed, cutoff)
    if time < start-cutoff then
        note.m:SetPosition(-100,-100)
        return -100,-100
    end

    local delta = time - (start-cutoff)
    if delta > dur then delta = dur end

    local y = track.GetYPosForTime(start)*speed
    note.m:SetPosition(x, y)
    local l = track.GetLengthForDuration(start, math.floor(delta))*speed
    note.m:ScaleToLength(l)
    long_glow(note,time,start)
    return y
end

local _sections = {}
local _avalible_bn = {}
local _avalible_bnl = {}
local _avalible_fx = {}
local _avalible_fxl = {}

function dont_add_section(a,b,c,d,e)
end

function add_section(opts, f_or_more)
    local sid = #_sections + 1
    if opts.btn_count == nil then
        opts.btn_count = 0
    end
    if opts.fx_count == nil then
        opts.fx_count = 0
    end
    if opts.btn_long_count == nil then
        opts.btn_long_count = 0
    end
    if opts.fx_long_count == nil then
        opts.fx_long_count = 0
    end
    local f = f_or_more
    while type(f) == 'table' do
        if f.btn_count ~= nil then
            opts.btn_count = f.btn_count
        end
        if f.fx_count ~= nil then
            opts.fx_count = f.fx_count
        end
        if f.btn_long_count ~= nil then
            opts.btn_long_count = f.btn_long_count
        end
        if f.fx_long_count ~= nil then
            opts.fx_long_count = f.fx_long_count
        end
        if f.f ~= nil then
            f = f.f
        elseif f.get_f ~= nil then
            f = f.get_f(opts)
        else
            error("Could not get function for section "+sid)
        end
    end
    if type(f) ~= 'function' then
        error("Could not get function for section "+sid)
    end

    _sections[sid] = {
        start_t = opts.start_time,
        end_t = opts.end_time,
        bn = opts.btn_count,
        bln = opts.btn_long_count,
        fn = opts.fx_count,
        fln = opts.fx_long_count,
        f = f,
        s = nil,
    }
end

function init_sections()
    local bn  = 0
    local bln = 0
    local fn  = 0
    local fln = 0
    -- Find the max number of fake objects we will have rendering at once
    -- This way we can save on the number of meshes we create
    for i, s in ipairs(_sections) do
        local tbn = s.bn
        local tbln = s.bln
        local tfn = s.fn
        local tfln = s.fln
        for j, ss in ipairs(_sections) do
            if i ~= j then
                if s.start_t <= ss.end_t and s.end_t >= ss.start_t then
                    -- Time intersection
                    tbn = tbn + ss.bn
                    tbln = tbln + ss.bln
                    tfn = tfn + ss.fn
                    tfln = tfln + ss.fln
                end
            end
        end
        if tbn > bn then
            bn = tbn
        end
        if tbln > bln then
            bln = tbln
        end
        if tfn > fn then
            fn = tfn
        end
        if tfln > fln then
            fln = tfln
        end
    end
    log("Creating "..bn.." btn, "..fn.." fx, "..bln.." long btn, "..fln.." long fx")
    for i=1,bn do
        table.insert(_avalible_bn, make_button(false, false))
    end
    for i=1,bln do
        table.insert(_avalible_bnl, make_button(false, true))
    end
    for i=1,fn do
        table.insert(_avalible_fx, make_button(true, false))
    end
    for i=1,fln do
        table.insert(_avalible_fxl, make_button(true, true))
    end
end

--XXX We could probably generate the draw function at startup to make this faster
function _draw_all(self)
    for i=1,self.bn do
        self["b"..i].m:Draw()
    end
    for i=1,self.bln do
        self["bl"..i].m:Draw()
    end
    for i=1,self.fn do
        self["f"..i].m:Draw()
    end
    for i=1,self.fln do
        self["fl"..i].m:Draw()
    end
end

function do_sections(time)
    for i, s in ipairs(_sections) do
        if s.start_t <= time and s.end_t >= time then
            if s.s == nil then
                log("Entering section "..i)
                -- If we entered for the first time, grab the needed buttons
                s.s = {}
                for j=1,s.bn do
                    local b = table.remove(_avalible_bn)
                    -- Reset button
                    b.m:SetScale(1,1)
                    b.m:SetPosition(-100,-100)
                    s.s["b"..j] = b
                end
                for j=1,s.bln do
                    local b = table.remove(_avalible_bnl)
                    -- Reset button
                    b.m:SetScale(1,1)
                    b.m:SetPosition(-100,-100)
                    s.s["bl"..j] = b
                end
                for j=1,s.fn do
                    local b = table.remove(_avalible_fx)
                    -- Reset button
                    b.m:SetScale(1,1)
                    b.m:SetPosition(-100,-100)
                    s.s["f"..j] = b
                end
                for j=1,s.fln do
                    local b = table.remove(_avalible_fxl)
                    -- Reset button
                    b.m:SetScale(1,1)
                    b.m:SetPosition(-100,-100)
                    s.s["fl"..j] = b
                end
                s.s.bn = s.bn
                s.s.bln = s.bln
                s.s.fn = s.fn
                s.s.fln = s.fln
                s.s.draw_all = _draw_all
            end

            -- Do the actual section code
            s.f(s.s, time)
        elseif s.s ~=nil then
            log("Exiting section "..i)
            -- Once the section is over, return the buttons
            for j=1,s.bn do
                table.insert(_avalible_bn, s.s["b"..j])
            end
            for j=1,s.bln do
                table.insert(_avalible_bnl, s.s["bl"..j])
            end
            for j=1,s.fn do
                table.insert(_avalible_fx, s.s["f"..j])
            end
            for j=1,s.fln do
                table.insert(_avalible_fxl, s.s["fl"..j])
            end
            s.s = nil
        end
    end
end

function slide_long(note, time, tick, long_dur, trigger, from, to, duration)
    local x = from
    if time >= trigger then
        if time < trigger + duration then
            local delta = time - trigger
            local dif = to - from
            x = from + dif * delta / duration
        else
            x = to
        end
    end
    local y = move_long_note(note,time, x, tick, long_dur, 1)
    return x, y
end

function slide(note, time, tick, trigger, from, to, duration)
    local x = from
    if time >= trigger then
        if time < trigger + duration then
            local delta = time - trigger
            local dif = to - from
            x = from + dif * delta / duration
        else
            x = to
        end
    end
    local y = move_note(note, x, tick, 1)
    return x, y
end

function slide_at_y(note, time, y, trigger, from, to, duration)
    local x = from
    if time >= trigger then
        if time < trigger + duration then
            local delta = time - trigger
            local dif = to - from
            x = from + dif * delta / duration
        else
            x = to
        end
    end
    note.m:SetPosition(x, y)
    return x, y
end


function simple_buttons(lanes, then_f)
    local f = function(opts)
        local code = 'return function(s, time)\n'
        local btn_c = opts.btn_count + 1
        local fx_c = opts.fx_count + 1
        for i, l in ipairs(lanes) do
            local lane_num = l[1]
            for _, t in ipairs(l[3]) do
                local lane_name = string.char(96+lane_num)
                if lane_num == 5 then
                    lane_name = 'l'
                elseif lane_num == 6 then
                    lane_name = 'r'
                end

                local opts = {}
                if #l > 3 then
                    opts = l[4]
                end
                local cutoff = opts.cutoff

                -- Hide or show an object x ms before its hit window
                if cutoff~=nil then
                    if cutoff < 0 then
                        cutoff = t + cutoff
                        code = code .. 'if time < '..cutoff..' then\n'
                    else
                        cutoff = t - cutoff
                        code = code .. 'if time >= '..cutoff..' then\n'
                    end
                end

                local bname = 'b'..btn_c
                if lane_num > 4 then bname = 'f'..fx_c end

                if opts.use_z then
                    code = code .. 'move_note_z(s.'..bname..',time, Ln.'..lane_name..', '..t..', '..l[2]..')\n'
                else
                    code = code .. 'move_note(s.'..bname..', Ln.'..lane_name..', '..t..', '..l[2]..')\n'
                end

                if cutoff ~=nil then
                    -- Hide object
                    code = code .. 'else\ns.'..bname..'.m:SetPosition(-100,-100)\nend\n'
                end
                track.HideObject(t, lane_num)

                if lane_num > 4 then
                    fx_c = fx_c + 1 -- Use next button
                else
                    btn_c = btn_c + 1 -- Use next button
                end
            end
        end
        if then_f ~= nil then
            code = 'return function(arg)\nlocal then_f = arg\n' .. code .. 'then_f(s, time)\nend\n'
        else
            code = code .. 's:draw_all()\n'
        end
        code = code .. 'end'
        --log(code)
        --error(code)
        local f = load(code)
        if then_f ~= nil then
            f = f()(then_f)
        else
            f = f()
        end
        return {
            f=f,
            btn_count=btn_c-1,
            fx_count=fx_c-1,
        }
    end
    return { get_f = f }
end


-- ======== Start Chart ========
-- 112's 16th is 134
add_section({ -- 1-1-1
    start_time = 2142 - 10,
    end_time   = 4017,
    btn_count  = 1,
},

function(s, time)
    -- Stopping buttons
    if time < 2142 then
        move_note(s.b1, Ln.a, 2142, 1)
        
	elseif time > 4017 then
		move_note(s.b1, Ln.a, 2142, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {4285, 1},
})

add_section({ -- 1-1-2
    start_time = 2678 - 10,
    end_time   = 4017,
    btn_count  = 1,
},
function(s, time)
    
	if time < 2678 then
        move_note(s.b1, Ln.a, 3214, 1)
    elseif time > 4017 then
		move_note(s.b1, Ln.a, 3214, 10)
	end
    s:draw_all()
end)
hide_objects({
    {4821, 1},
})

add_section({ -- 1-1-3
    start_time = 3080 - 10,
    end_time   = 4017,
    btn_count  = 1,
},

function(s, time)
    
	if time < 3080 then
        move_note(s.b1, Ln.a, 4018, 1)
    elseif time > 4017 then
		move_note(s.b1, Ln.a, 4018, 10)
	end
    s:draw_all()
end)
hide_objects({
   {5223, 1},
})

add_section({ -- 1-1-4
    start_time = 3348 - 10,
    end_time   = 4017,
    btn_count  = 1,
},

function(s, time)
    
	if time < 3348 then
        move_note(s.b1, Ln.a, 4454, 1)
    elseif time > 4017 then
		move_note(s.b1, Ln.a, 4454, 10)
	end
    s:draw_all()
end)
hide_objects({
   {5491, 1},
})

add_section({ -- 1-1-5
    start_time = 3616 - 10,
    end_time   = 4017,
    btn_count  = 1,
},

function(s, time)
   
	if time < 3616 then
        move_note(s.b1, Ln.a, 5090, 1)
    elseif time > 4017 then
		move_note(s.b1, Ln.a, 5090, 10)
	end
    s:draw_all()
end)
hide_objects({
   {5758, 1},
})

add_section({ -- 1-1-6
    start_time = 3750 - 10,
    end_time   = 4017,
    btn_count  = 1,
},

function(s, time)
   
	if time < 3750 then
        move_note(s.b1, Ln.a, 5358, 1)
    elseif time > 4017 then
		move_note(s.b1, Ln.a, 5358, 10)
	end
    s:draw_all()
end)
hide_objects({
   {5892, 1},
})

add_section({ -- 1-2-1
    start_time = 6428 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)

    if time < 6428 then
        move_note(s.b1, Ln.a, 6428, 1)
        
	elseif time > 8303 then
		move_note(s.b1, Ln.a, 6428, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {8571, 1},
})

add_section({ -- 1-2-2
    start_time = 6964 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)
   
	if time < 6964 then
        move_note(s.b1, Ln.a, 7500, 1)
    elseif time > 8303 then
		move_note(s.b1, Ln.a, 7500, 10)
	end
    s:draw_all()
end)
hide_objects({
    {9107, 1},
})

add_section({ -- 1-2-3
    start_time = 7366 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)
    
	if time < 7366 then
        move_note(s.b1, Ln.a, 8304, 1)
    elseif time > 8303 then
		move_note(s.b1, Ln.a, 8304, 10)
	end
    s:draw_all()
end)
hide_objects({
   {9509, 1},
})

add_section({ -- 1-2-4
    start_time = 7634 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)
    
	if time < 7634 then
        move_note(s.b1, Ln.a, 8740, 1)
    elseif time > 8303 then
		move_note(s.b1, Ln.a, 8740, 10)
	end
    s:draw_all()
end)
hide_objects({
   {9777, 1},
})

add_section({ -- 1-2-5
    start_time = 7902 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)
    
	if time < 7902 then
        move_note(s.b1, Ln.a, 9376, 1)
    elseif time > 8303 then
		move_note(s.b1, Ln.a, 9376, 10)
	end
    s:draw_all()
end)
hide_objects({
   {10044, 1},
})

add_section({ -- 1-2-6
    start_time = 8036 - 10,
    end_time   = 8303,
    btn_count  = 1,
},

function(s, time)
    -- Stopping buttons
	if time < 8036 then
        move_note(s.b1, Ln.a, 9644, 1)
    elseif time > 8303 then
		move_note(s.b1, Ln.a, 9644, 10)
	end
    s:draw_all()
end)
hide_objects({
   {10178, 1},
})

---------------------------------------------------------------------

add_section({ -- 2-1-1
    start_time = 10982 - 10,
    end_time   = 12857,
    btn_count  = 1,
},

function(s, time)
    
	if time < 10982 then
        move_note(s.b1, Ln.d, 10982, 1)
    elseif time > 12857 then
		move_note(s.b1, Ln.d, 10982, 10)
	end
    s:draw_all()
end)
hide_objects({
   {13125, 4},
})

add_section({ -- 2-1-2
    start_time = 11383 - 10,
    end_time   = 12857,
    btn_count  = 1,
},

function(s, time)
    
	if time < 11383 then
        move_note(s.b1, Ln.d, 11784, 1)
    elseif time > 12857 then
		move_note(s.b1, Ln.d, 11784, 10)
	end
    s:draw_all()
end)
hide_objects({
   {13526, 4},
})

add_section({ -- 2-1-3
    start_time = 12053 - 10,
    end_time   = 12857,
    btn_count  = 1,
},

function(s, time)
    
	if time < 12053 then
        move_note(s.b1, Ln.d, 13124, 1)
    elseif time > 12857 then
		move_note(s.b1, Ln.d, 13124, 10)
	end
    s:draw_all()
end)
hide_objects({
   {14196, 4},
})

add_section({ -- 2-1-4
    start_time = 12455 - 10,
    end_time   = 12857,
    btn_count  = 1,
},

function(s, time)
    
	if time < 12455 then
        move_note(s.b1, Ln.d, 13928, 1)
    elseif time > 12857 then
		move_note(s.b1, Ln.d, 13928, 10)
	end
    s:draw_all()
end)
hide_objects({
   {14597, 4},
})

add_section({ -- 2-2-1
    start_time = 15267 - 10,
    end_time   = 17142,
    btn_count  = 1,
},

function(s, time)
    
	if time < 15267 then
        move_note(s.b1, Ln.d, 15267, 1)
    elseif time > 17142 then
		move_note(s.b1, Ln.d, 15267, 10)
	end
    s:draw_all()
end)
hide_objects({
   {17410, 4},
})

add_section({ -- 2-2-2
    start_time = 15668 - 10,
    end_time   = 17142,
    btn_count  = 1,
},

function(s, time)
    
	if time < 15668 then
        move_note(s.b1, Ln.d, 16069, 1)
    elseif time > 17142 then
		move_note(s.b1, Ln.d, 16069, 10)
	end
    s:draw_all()
end)
hide_objects({
   {17811, 4},
})

add_section({ -- 2-2-3
    start_time = 16338 - 10,
    end_time   = 17142,
    btn_count  = 1,
},

function(s, time)
    
	if time < 16338 then
        move_note(s.b1, Ln.d, 17409, 1)
    elseif time > 17142 then
		move_note(s.b1, Ln.d, 17409, 10)
	end
    s:draw_all()
end)
hide_objects({
   {18481, 4},
})

add_section({ -- 2-2-4
    start_time = 16740 - 10,
    end_time   = 17142,
    btn_count  = 1,
},

function(s, time)
    
	if time < 16740 then
        move_note(s.b1, Ln.d, 18213, 1)
    elseif time > 17142 then
		move_note(s.b1, Ln.d, 18213, 10)
	end
    s:draw_all()
end)
hide_objects({
   {18883, 4},
})
---------------------------------------------------------------------

add_section({ -- 3-1-1
    start_time = 19253 - 2000,
    end_time   = 44968,
    btn_count  = 48,
},
simple_buttons({
    { 4, 2, {19521, 19923, 20593, 20994, 21664, 22066, 22735, 23137, 23807, 24209, 24878, 25280, 25950, 26351 ,27021 ,27423 ,
	         28093, 28494, 29164, 29565, 30235, 30637, 31307, 31709, 32379, 32780, 33450, 33851, 34521, 34922 ,35592 ,35994 ,
			 36664, 37066, 37735, 38137, 38807, 39208, 39878, 40280, 40950, 41350, 42020, 42421, 43091, 43492 ,44162 ,44563}}
}))

---------------------------------------------------------------------

add_section({ -- 4-1-1
    start_time = 51412 - 10,
    end_time   = 53555,
    btn_count  = 1,
},
function(s, time)
    
    if time < 51412 then
        move_note(s.b1, Ln.d, 51576, 1)
        
	elseif time > 53421 then
		move_note(s.b1, Ln.d, 53555, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {53555, 4},
})

add_section({ -- 4-1-2
    start_time = 51546 - 10,
    end_time   = 53689,
    btn_count  = 1,
},
function(s, time)

    if time < 51546 then
        move_note(s.b1, Ln.c, 51814, 1)
        
	elseif time > 53421 then
		move_note(s.b1, Ln.c, 53689, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {53689, 3},
})

add_section({ -- 4-1-3
    start_time = 51680 - 10,
    end_time   = 53823,
    btn_count  = 1,
},

function(s, time)
    
    if time < 51680 then
        move_note(s.b1, Ln.b, 52082, 1)
        
	elseif time > 53421 then
		move_note(s.b1, Ln.b, 53823, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {53823, 2},
})

add_section({ -- 4-1-4
    start_time = 51814 - 10,
    end_time   = 53957,
    btn_count  = 1,
},

function(s, time)
    
    if time < 51814 then
        move_note(s.b1, Ln.a, 52350, 1)
        
	elseif time > 53421 then
		move_note(s.b1, Ln.a, 53957, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {53957, 1},
})

add_section({ -- 4-1-5
    start_time = 51948 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
   
    if time < 51948 then
        move_note(s.b1, Ln.d, 52618, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.d, 52618, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54091, 4},
})

add_section({ -- 4-1-6
    start_time = 52082 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
   
    if time < 52082 then
        move_note(s.b1, Ln.b, 52886, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.b, 52886, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54225, 2},
})

add_section({ -- 4-1-7
    start_time = 52216 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52216 then
        move_note(s.b1, Ln.d, 53154, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.d, 53154, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54359, 4},
})

add_section({ -- 4-1-8
    start_time = 52350 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52350 then
        move_note(s.b1, Ln.a, 53422, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.a, 53422, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54359, 1},
})

add_section({ -- 4-1-9
    start_time = 52484 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52484 then
        move_note(s.b1, Ln.c, 53690, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.c, 53690, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54626, 3},
})

add_section({ -- 4-1-10
    start_time = 52617 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52617 then
        move_note(s.b1, Ln.a, 54092, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.a, 54092, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54760, 1},
})

add_section({ -- 4-1-11
    start_time = 52751 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52751 then
        move_note(s.b1, Ln.d, 54494, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.d, 54494, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {54894, 4},
})

add_section({ -- 4-1-12
    start_time = 52885 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
    
    if time < 52885 then
        move_note(s.b1, Ln.c, 54896, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.c, 54896, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {55028, 3},
})

add_section({ -- 4-1-13
    start_time = 53019 - 10,
    end_time   = 53153,
    btn_count  = 1,
},

function(s, time)
   
    if time < 53019 then
        move_note(s.b1, Ln.b, 55298, 1)
        
	elseif time > 53153 then
		move_note(s.b1, Ln.b, 55298, 10)
	end
	
    s:draw_all()
end)
hide_objects({
    {55162, 2},
})

---------------------------------------------------------------------

add_section({ -- 5-1-1
    start_time = 53555 - 10,
    end_time   = 54091,
    btn_count  = 1,
},

function(s, time)
    if time > 53555 then
		move_note(s.b1, Ln.d, 54091, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-2
    start_time = 53689 - 10,
    end_time   = 54225,
    btn_count  = 1,
},

function(s, time)
    if time > 53689 then
		move_note(s.b1, Ln.b, 54225, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-3
    start_time = 53823 - 10,
    end_time   = 54359,
    btn_count  = 1,
},

function(s, time)
    if time > 53823 then
		move_note(s.b1, Ln.d, 54359, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-4
    start_time = 53555 - 10,
    end_time   = 54091,
    btn_count  = 1,
},

function(s, time)
    if time > 53555 then
		move_note(s.b1, Ln.d, 54091, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-5
    start_time = 53689 - 10,
    end_time   = 54225,
    btn_count  = 1,
},

function(s, time)
   if time > 53689 then
		move_note(s.b1, Ln.b, 54225, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-6
    start_time = 53823 - 10,
    end_time   = 54359,
    btn_count  = 1,
},

function(s, time)
    if time > 53823 then
		move_note(s.b1, Ln.d, 54359, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-7
    start_time = 53957 - 10,
    end_time   = 54493,
    btn_count  = 1,
},

function(s, time)
    if time > 53957 then
		move_note(s.b1, Ln.a, 54493, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-8
    start_time = 54091 - 10,
    end_time   = 54627,
    btn_count  = 1,
},

function(s, time)
    if time > 54091 then
		move_note(s.b1, Ln.c, 54627, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-9
    start_time = 54225 - 10,
    end_time   = 54761,
    btn_count  = 1,
},

function(s, time)
    if time > 54225 then
		move_note(s.b1, Ln.a, 54761, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-10
    start_time = 54359 - 10,
    end_time   = 54895,
    btn_count  = 1,
},

function(s, time)
    if time > 54359 then
		move_note(s.b1, Ln.d, 54895, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-11
    start_time = 54493 - 10,
    end_time   = 55029,
    btn_count  = 1,
},

function(s, time)
    if time > 54493 then
		move_note(s.b1, Ln.c, 55029, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-1-12
    start_time = 54627 - 10,
    end_time   = 55163,
    btn_count  = 1,
},

function(s, time)
    if time > 54627 then
		move_note(s.b1, Ln.b, 55163, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-1
    start_time = 55162 - 10,
    end_time   = 55698,
    btn_count  = 1,
},

function(s, time)
    
    if time < 55162 then
        move_note(s.b1, Ln.d, 55430, 1)
        
	elseif time > 55430 then
		move_note(s.b1, Ln.d, 55698, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {55698, 4},
})

add_section({ -- 5-2-2
    start_time = 55162 - 10,
    end_time   = 55832,
    btn_count  = 1,
},

function(s, time)
    
    if time < 55162 then
        move_note(s.b1, Ln.c, 55564, 1)
        
	elseif time > 55430 then
		move_note(s.b1, Ln.c, 55832, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {55832, 3},
})

add_section({ -- 5-2-3
    start_time = 55162 - 10,
    end_time   = 55966,
    btn_count  = 1,
},

function(s, time)
    
    if time < 55162 then
        move_note(s.b1, Ln.b, 55698, 1)
        
	elseif time > 55430 then
		move_note(s.b1, Ln.b, 55966, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {55966, 2},
})

add_section({ -- 5-2-4
    start_time = 55162 - 10,
    end_time   = 56100,
    btn_count  = 1,
},

function(s, time)
    
    if time < 55162 then
        move_note(s.b1, Ln.a, 55832, 1)
        
	elseif time > 55430 then
		move_note(s.b1, Ln.a, 56100, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {56100, 1},
})

add_section({ -- 5-2-5
    start_time = 55698 - 10,
    end_time   = 56234,
    btn_count  = 1,
},

function(s, time)
	if time < 55698 then
		move_note(s.b1, Ln.d, 56234, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-6
    start_time = 55832 - 10,
    end_time   = 56367,
    btn_count  = 1,
},

function(s, time)
	if time < 55832 then
		move_note(s.b1, Ln.b, 56367, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-7
    start_time = 55966 - 10,
    end_time   = 56501,
    btn_count  = 1,
},

function(s, time)
	if time < 55966 then
		move_note(s.b1, Ln.d, 56501, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-8
    start_time = 56100 - 10,
    end_time   = 56635,
    btn_count  = 1,
},

function(s, time)
	if time < 56100 then
		move_note(s.b1, Ln.a, 56635, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-9
    start_time = 56234 - 10,
    end_time   = 56769,
    btn_count  = 1,
},

function(s, time)
	if time < 56234 then
		move_note(s.b1, Ln.c, 56769, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-10
    start_time = 56367 - 10,
    end_time   = 56903,
    btn_count  = 1,
},

function(s, time)
	if time < 56367 then
		move_note(s.b1, Ln.a, 56903, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-11
    start_time = 56501 - 10,
    end_time   = 57037,
    btn_count  = 1,
},

function(s, time)
    if time < 56501 then
		move_note(s.b1, Ln.d, 57037, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-12
    start_time = 56635 - 10,
    end_time   = 57171,
    btn_count  = 1,
},

function(s, time)
    if time < 56635 then
		move_note(s.b1, Ln.c, 57171, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2-13
    start_time = 56769 - 10,
    end_time   = 57305,
    btn_count  = 1,
},

function(s, time)
    if time < 56769 then
		move_note(s.b1, Ln.b, 57305, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-2(Flash)
    start_time = 55162 - 10,
    end_time   = 55430,
    btn_count  = 9,
},

function(s, time)
    
    if time < 55162 then
        move_note(s.b1, Ln.d, 55966, 1)
        move_note(s.b2, Ln.b, 56100, 1)
        move_note(s.b3, Ln.d, 56234, 1)
		move_note(s.b4, Ln.a, 56367, 1)
		move_note(s.b5, Ln.c, 56501, 1)
		move_note(s.b6, Ln.a, 56635, 1)
		move_note(s.b7, Ln.d, 56769, 1)
		move_note(s.b8, Ln.c, 56903, 1)
		move_note(s.b9, Ln.b, 57037, 1)
	elseif time > 55430 then
		move_note(s.b1, Ln.d, 56234, 1)
		move_note(s.b2, Ln.b, 56367, 1)
		move_note(s.b3, Ln.d, 56501, 1)
		move_note(s.b4, Ln.a, 56635, 1)
		move_note(s.b5, Ln.c, 56769, 1)
		move_note(s.b6, Ln.a, 56903, 1)
		move_note(s.b7, Ln.d, 57037, 1)
		move_note(s.b8, Ln.c, 57171, 1)
		move_note(s.b9, Ln.b, 57305, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {56234, 4},
	{56234, 2},
	{56501, 4},
	{56635, 1},
	{56769, 3},
	{56903, 1},
	{57037, 4},
	{57037, 3},
	{57305, 2},
})

add_section({ -- 5-3(Flash)
    start_time = 57305 - 10,
    end_time   = 57570,
    btn_count  = 13,
},

function(s, time)
    
    if time < 57305 then
	    move_note(s.b1, Ln.d, 57572, 1)
		move_note(s.b2, Ln.c, 57707, 1)
		move_note(s.b3, Ln.b, 57841, 1)
		move_note(s.b4, Ln.a, 57975, 1)
        move_note(s.b5, Ln.d, 58109, 1)
        move_note(s.b6, Ln.b, 58243, 1)
        move_note(s.b7, Ln.d, 58377, 1)
		move_note(s.b8, Ln.a, 58510, 1)
		move_note(s.b9, Ln.c, 58644, 1)
		move_note(s.b10, Ln.a, 58778, 1)
		move_note(s.b11, Ln.d, 58912, 1)
		move_note(s.b12, Ln.c, 59046, 1)
		move_note(s.b13, Ln.b, 59180, 1)
	elseif time > 57570 then
	    move_note(s.b1, Ln.d, 55698, 1)
		move_note(s.b2, Ln.c, 55832, 1)
		move_note(s.b3, Ln.b, 55966, 1)
		move_note(s.b4, Ln.a, 56100, 1)
		move_note(s.b5, Ln.d, 56234, 1)
		move_note(s.b6, Ln.b, 56367, 1)
		move_note(s.b7, Ln.d, 56501, 1)
		move_note(s.b8, Ln.a, 56635, 1)
		move_note(s.b9, Ln.c, 56769, 1)
		move_note(s.b10, Ln.a, 56903, 1)
		move_note(s.b11, Ln.d, 57037, 1)
		move_note(s.b12, Ln.c, 57171, 1)
		move_note(s.b13, Ln.b, 57305, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3(Flash-2)
    start_time = 57573 - 10,
    end_time   = 57707,
    btn_count  = 9,
},

function(s, time)
    
    if time < 57573 then
        move_note(s.b1, Ln.d, 58243, 1)
        move_note(s.b2, Ln.c, 58377, 1)
        move_note(s.b3, Ln.b, 58510, 1)
		move_note(s.b4, Ln.a, 58644, 1)
		move_note(s.b5, Ln.d, 58778, 1)
		move_note(s.b6, Ln.b, 58912, 1)
		move_note(s.b7, Ln.c, 59046, 1)
		move_note(s.b8, Ln.d, 59180, 1)
		move_note(s.b9, Ln.a, 59314, 1)
	elseif time > 57707 then
		move_note(s.b1, Ln.d, 56367, 1)
		move_note(s.b2, Ln.c, 56501, 1)
		move_note(s.b3, Ln.b, 56635, 1)
		move_note(s.b4, Ln.a, 56769, 1)
		move_note(s.b5, Ln.d, 56903, 1)
		move_note(s.b6, Ln.b, 57037, 1)
		move_note(s.b7, Ln.b, 57171, 1)
		move_note(s.b8, Ln.d, 57305, 1)
		move_note(s.b9, Ln.a, 57409, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {58376, 4},
	{58510, 3},
	{58644, 2},
	{58778, 1},
	{58912, 4},
	{59046, 2},
	{59180, 3},
	{59314, 4},
	{59448, 1},
})

add_section({ -- 5-3-1
    start_time = 57573 - 10,
    end_time   = 57841,
    btn_count  = 1,
},

function(s, time)
    
    if time < 57573 then
        move_note(s.b1, Ln.a, 57707, 1)
        
	elseif time > 57707 then
		move_note(s.b1, Ln.a, 57841, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {57841, 1},
})

add_section({ -- 5-3-2
    start_time = 57573 - 10,
    end_time   = 57975,
    btn_count  = 1,
},

function(s, time)
    
    if time < 57573 then
        move_note(s.b1, Ln.b, 57841, 1)
        
	elseif time > 57707 then
		move_note(s.b1, Ln.b, 57975, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {57975, 2},
})

add_section({ -- 5-3-3
    start_time = 57573 - 10,
    end_time   = 58109,
    btn_count  = 1,
},

function(s, time)
    
    if time < 57573 then
        move_note(s.b1, Ln.c, 57975, 1)
        
	elseif time > 57707 then
		move_note(s.b1, Ln.c, 58109, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {58109, 3},
})

add_section({ -- 5-3-4
    start_time = 57573 - 10,
    end_time   = 58242,
    btn_count  = 1,
},

function(s, time)
    
    if time < 57573 then
        move_note(s.b1, Ln.a, 58109, 1)
        
	elseif time > 57707 then
		move_note(s.b1, Ln.a, 58242, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {58242, 1},
})

add_section({ -- 5-3-5
    start_time = 57841 - 10,
    end_time   = 58376,
    btn_count  = 1,
},

function(s, time)
    
    if time > 57841 then
        move_note(s.b1, Ln.d, 58376, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-6
    start_time = 57975 - 10,
    end_time   = 58510,
    btn_count  = 1,
},

function(s, time)
    
    if time > 57975 then
        move_note(s.b1, Ln.c, 58510, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-7
    start_time = 58109 - 10,
    end_time   = 58644,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58109 then
        move_note(s.b1, Ln.b, 58644, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-8
    start_time = 58242 - 10,
    end_time   = 58778,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58242 then
        move_note(s.b1, Ln.a, 58778, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-9
    start_time = 58376 - 10,
    end_time   = 58912,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58376 then
        move_note(s.b1, Ln.d, 58912, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-10
    start_time = 58510 - 10,
    end_time   = 59046,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58510 then
        move_note(s.b1, Ln.b, 59046, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-11
    start_time = 58644 - 10,
    end_time   = 59180,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58644 then
        move_note(s.b1, Ln.c, 59180, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-12
    start_time = 58778 - 10,
    end_time   = 59314,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58778 then
        move_note(s.b1, Ln.d, 59314, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-13
    start_time = 58912 - 10,
    end_time   = 59448,
    btn_count  = 1,
},

function(s, time)
    
    if time > 58912 then
        move_note(s.b1, Ln.a, 59448, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-4(Flash-1)
    start_time = 59448 - 10,
    end_time   = 59716,
    btn_count  = 8,
},

function(s, time)
    
    if time < 59448 then
        move_note(s.b1, Ln.d, 60251, 1)
        move_note(s.b2, Ln.c, 60385, 1)
        move_note(s.b3, Ln.b, 60519, 1)
		move_note(s.b4, Ln.a, 60653, 1)
		move_note(s.b5, Ln.d, 60787, 1)
		move_note(s.b6, Ln.b, 60921, 1)
		move_note(s.b7, Ln.c, 61055, 1)
		move_note(s.b8, Ln.d, 61189, 1)

	elseif time > 59716 then
		move_note(s.b1, Ln.d, 56367, 1)
		move_note(s.b2, Ln.c, 56501, 1)
		move_note(s.b3, Ln.b, 56635, 1)
		move_note(s.b4, Ln.a, 56769, 1)
		move_note(s.b5, Ln.d, 56903, 1)
		move_note(s.b6, Ln.b, 57037, 1)
		move_note(s.b7, Ln.b, 57171, 1)
		move_note(s.b8, Ln.d, 57305, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {60519, 4},
	{60653, 3},
	{60252, 2},
	{60921, 1},
	{61055, 4},
	{61189, 2},
	{61323, 3},
	{61457, 4},
})

add_section({ -- 5-4-1
    start_time = 59448 - 10,
    end_time   = 59984,
    btn_count  = 1,
},

function(s, time)
    
    if time < 59448 then
        move_note(s.b1, Ln.a, 59716, 1)
        
	elseif time > 59716 then
		move_note(s.b1, Ln.a, 59984, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {59984, 1},
})

add_section({ -- 5-4-2
    start_time = 59448 - 10,
    end_time   = 60117,
    btn_count  = 1,
},

function(s, time)
   
    if time < 59448 then
        move_note(s.b1, Ln.b, 59850, 1)
        
	elseif time > 59716 then
		move_note(s.b1, Ln.b, 60117, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {60117, 2},
})

add_section({ -- 5-4-3
    start_time = 59448 - 10,
    end_time   = 60251,
    btn_count  = 1,
},

function(s, time)
    
    if time < 59448 then
        move_note(s.b1, Ln.c, 59984, 1)
        
	elseif time > 59716 then
		move_note(s.b1, Ln.c, 60251, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {60251, 3},
})

add_section({ -- 5-4-4
    start_time = 59448 - 10,
    end_time   = 60385,
    btn_count  = 1,
},

function(s, time)
    
    if time < 59448 then
        move_note(s.b1, Ln.a, 60117, 1)
        
	elseif time > 59716 then
		move_note(s.b1, Ln.a, 60385, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {60385, 1},
})

add_section({ -- 5-3-5
    start_time = 59984 - 10,
    end_time   = 60519,
    btn_count  = 1,
},

function(s, time)
   
    if time < 59984 then
        move_note(s.b1, Ln.d, 60519, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-6
    start_time = 60119 - 10,
    end_time   = 60653,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60119 then
        move_note(s.b1, Ln.c, 60653, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-7
    start_time = 60251 - 10,
    end_time   = 60787,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60251 then
        move_note(s.b1, Ln.b, 60787, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-8
    start_time = 60385 - 10,
    end_time   = 60921,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60385 then
        move_note(s.b1, Ln.a, 60921, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-9
    start_time = 60519 - 10,
    end_time   = 61055,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60519 then
        move_note(s.b1, Ln.d, 61055, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-10
    start_time = 60653 - 10,
    end_time   = 61189,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60653 then
        move_note(s.b1, Ln.b, 61189, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-11
    start_time = 60787 - 10,
    end_time   = 61323,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60787 then
        move_note(s.b1, Ln.c, 61323, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 5-3-12
    start_time = 60921 - 10,
    end_time   = 61457,
    btn_count  = 1,
},

function(s, time)
    
    if time < 60921 then
        move_note(s.b1, Ln.d, 61457, 1)
	end
	
    s:draw_all()
end)

---------------------------------------------------------------------

add_section({ -- 6-1-1 {spawner-a)
    start_time = 61591 - 7000,
    end_time   = 70162,
    btn_count  = 1,
},

function(s, time)
    
    if time < 61591 then
        move_note(s.b1, Ln.a, 61591, 1)
		
	elseif time > 61591 and time < 62394 then
        move_note(s.b1, Ln.a, 61591, -1.7)
		
	elseif time > 62394 and time < 63734 then --hit
        move_note(s.b1, Ln.a, 63734, 1)
		
	elseif time > 63734 and time < 64537 then
        move_note(s.b1, Ln.a, 63734, -1.7)
		
	elseif time > 64537 and time < 65876 then --hit
        move_note(s.b1, Ln.a, 65876, 1)
		
	elseif time > 65876 and time < 66680 then
        move_note(s.b1, Ln.a, 65876, -1.7)
		
	elseif time > 66680 and time < 68019 then --hit
        move_note(s.b1, Ln.a, 68019, 1)
		
	elseif time > 68019 and time < 68823 then 
        move_note(s.b1, Ln.a, 68019, -1.7)
		
	elseif time > 68823 and time < 70162 then --hit
        move_note(s.b1, Ln.a, 70162, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {61591, 1},
    {63734, 1},
    {65876, 1},
    {68019, 1},
    {70162, 1},
})

add_section({ -- 6-1-2 {spawner-b)
    start_time = 61725 - 7000,
    end_time   = 70296,
    btn_count  = 1,
},

function(s, time)
    
	if time < 61725 then
		move_note(s.b1, Ln.b, 61725, 1)
		
	elseif time > 61725 and time < 62528 then
        move_note(s.b1, Ln.b, 61725, -1.7)
		
	elseif time > 62528 and time < 63868 then --hit
        move_note(s.b1, Ln.b, 63868, 1)
		
	elseif time > 63868 and time < 64671 then
        move_note(s.b1, Ln.b, 63868, -1.7)
		
	elseif time > 64671 and time < 66010 then --hit
        move_note(s.b1, Ln.b, 66010, 1)
		
	elseif time > 66010 and time < 66814 then
        move_note(s.b1, Ln.b, 66010, -1.7)
		
	elseif time > 66814 and time < 68153 then --hit
        move_note(s.b1, Ln.b, 68153, 1)
		
	elseif time > 68153 and time < 68957 then 
        move_note(s.b1, Ln.b, 68153, -1.7)
		
	elseif time > 68957 and time < 70296 then --hit
        move_note(s.b1, Ln.b, 70296, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {61725, 2},
    {63868, 2},
    {66010, 2},
    {68153, 2},
    {70296, 2},
})

add_section({ -- 6-1-3 {spawner-c)
    start_time = 61859 - 7000,
    end_time   = 70430,
    btn_count  = 1,
},

function(s, time)
    
	if time < 61859 then
		move_note(s.b1, Ln.c, 61859, 1)
		
	elseif time > 61859 and time < 62662 then
        move_note(s.b1, Ln.c, 61859, -1.7)
		
	elseif time > 62662 and time < 64002 then --hit
        move_note(s.b1, Ln.c, 64002, 1)
		
	elseif time > 64002 and time < 64805 then
        move_note(s.b1, Ln.c, 64002, -1.7)
		
	elseif time > 64805 and time < 66144 then --hit
        move_note(s.b1, Ln.c, 66144, 1)
		
	elseif time > 66144 and time < 66948 then
        move_note(s.b1, Ln.c, 66144, -1.7)
		
	elseif time > 66948 and time < 68287 then --hit
        move_note(s.b1, Ln.c, 68287, 1)
		
	elseif time > 68287 and time < 69091 then 
        move_note(s.b1, Ln.c, 68287, -1.7)
		
	elseif time > 69091 and time < 70430 then --hit
        move_note(s.b1, Ln.c, 70430, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {61859, 3},
    {64002, 3},
    {66144, 3},
    {68287, 3},
    {70430, 3},
})

add_section({ -- 6-1-4 {spawner-d)
    start_time = 61993 - 7000,
    end_time   = 70564,
    btn_count  = 1,
},

function(s, time)
    -- Stopping buttons
	if time < 61993 then
		move_note(s.b1, Ln.d, 61993, 1)
		
	elseif time > 61993 and time < 62796 then
        move_note(s.b1, Ln.d, 61993, -1.7)
		
	elseif time > 62796 and time < 64136 then --hit
        move_note(s.b1, Ln.d, 64136, 1)
		
	elseif time > 64136 and time < 64939 then
        move_note(s.b1, Ln.d, 64136, -1.7)
		
	elseif time > 64939 and time < 66278 then --hit
        move_note(s.b1, Ln.d, 66278, 1)
		
	elseif time > 66278 and time < 67082 then
        move_note(s.b1, Ln.d, 66278, -1.7)
		
	elseif time > 67082 and time < 68421 then --hit
        move_note(s.b1, Ln.d, 68421, 1)
		
	elseif time > 68421 and time < 69225 then 
        move_note(s.b1, Ln.d, 68421, -1.7)
		
	elseif time > 69225 and time < 70564 then --hit
        move_note(s.b1, Ln.d, 70564, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {61993, 4},
    {64136, 4},
    {66278, 4},
    {68421, 4},
    {70564, 4},
})

add_section({ -- 6-2-1
    start_time = 61859 - 50,
    end_time   = 62126,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {62126}}
}))

add_section({ -- 6-2-2
    start_time = 61992 - 67,
    end_time   = 62260,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {62260}}
}))

add_section({ -- 6-2-3
    start_time = 62126,
    end_time   = 62394,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {62394}}
}))

add_section({ -- 6-2-4
    start_time = 62260 - 168,
    end_time   = 62528,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {62528}}
}))

add_section({ -- 6-2-5
    start_time = 62394 - 335,
    end_time   = 62662,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {62662}}
}))

add_section({ -- 6-2-6
    start_time = 62528 - 201,
    end_time   = 62796,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {62796}}
}))

add_section({ -- 6-2-7
    start_time = 62662 - 503,
    end_time   = 62930,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {62930}}
}))

add_section({ -- 6-2-8
    start_time = 62796 - 469,
    end_time   = 63064,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {63064}}
}))

add_section({ -- 6-2-9
    start_time = 62930 - 603,
    end_time   = 63198,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {63198}}
}))

add_section({ -- 6-2-10
    start_time = 63064 - 535,
    end_time   = 63332,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {63332}}
}))

add_section({ -- 6-2-11
    start_time = 63198 - 802,
    end_time   = 63466,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {63466}}
}))

add_section({ -- 6-2-12
    start_time = 63332 - 802,
    end_time   = 63600,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {63600}}
}))

add_section({ -- 6-3-1
    start_time = 64001 - 50,
    end_time   = 64269,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {64269}}
}))

add_section({ -- 6-3-2
    start_time = 64135 - 67,
    end_time   = 64403,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {64403}}
}))

add_section({ -- 6-3-3
    start_time = 64269,
    end_time   = 64537,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {64537}}
}))

add_section({ -- 6-3-4
    start_time = 64403 - 168,
    end_time   = 64671,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {64671}}
}))

add_section({ -- 6-3-5
    start_time = 64537 - 335,
    end_time   = 64805,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {64805}}
}))

add_section({ -- 6-3-6
    start_time = 64671 - 201,
    end_time   = 64939,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {64939}}
}))

add_section({ -- 6-3-7
    start_time = 64805 - 503,
    end_time   = 65073,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {65073}}
}))

add_section({ -- 6-3-8
    start_time = 64939 - 469,
    end_time   = 65207,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {65207}}
}))

add_section({ -- 6-3-9
    start_time = 65073 - 603,
    end_time   = 65341,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {65341}}
}))

add_section({ -- 6-3-10
    start_time = 65207 - 535,
    end_time   = 65475,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {65475}}
}))

add_section({ -- 6-3-11
    start_time = 65341 - 802,
    end_time   = 65609,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {65609}}
}))

add_section({ -- 6-3-12
    start_time = 65475 - 802,
    end_time   = 65742,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {65742}}
}))

add_section({ -- 6-4-1
    start_time = 66144 - 50,
    end_time   = 66412,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {66412}}
}))

add_section({ -- 6-4-2
    start_time = 66278,
    end_time   = 66546,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {66546}}
}))

add_section({ -- 6-4-3
    start_time = 66412 - 134,
    end_time   = 66680,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {66680}}
}))

add_section({ -- 6-4-4
    start_time = 66546 - 67,
    end_time   = 66814,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {66814}}
}))

add_section({ -- 6-4-5
    start_time = 66680 - 233,
    end_time   = 66948,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {66948}}
}))

add_section({ -- 6-4-6
    start_time = 66814 - 469,
    end_time   = 67082,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {67082}}
}))

add_section({ -- 6-4-7
    start_time = 66948 - 402,
    end_time   = 67216,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {67216}}
}))

add_section({ -- 6-4-8
    start_time = 67082 - 568,
    end_time   = 67350,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {67350}}
}))

add_section({ -- 6-4-9
    start_time = 67216 - 501,
    end_time   = 67484,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {67484}}
}))

add_section({ -- 6-4-10
    start_time = 67350 - 804,
    end_time   = 67617,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {67617}}
}))

add_section({ -- 6-4-11
    start_time = 67484 - 804,
    end_time   = 67751,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {67751}}
}))

add_section({ -- 6-4-12
    start_time = 67617 - 737,
    end_time   = 67885,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {67885}}
}))

add_section({ -- 6-4-1
    start_time = 68287 - 50,
    end_time   = 68555,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {68555}}
}))

add_section({ -- 6-4-2
    start_time = 68421,
    end_time   = 68689,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {68689}}
}))

add_section({ -- 6-4-3
    start_time = 68555 - 134,
    end_time   = 68823,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {68823}}
}))

add_section({ -- 6-4-4
    start_time = 68689 - 67,
    end_time   = 68957,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {68957}}
}))

add_section({ -- 6-4-5
    start_time = 68823 - 233,
    end_time   = 69091,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {69091}}
}))

add_section({ -- 6-4-6
    start_time = 68957 - 469,
    end_time   = 69225,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {69225}}
}))

add_section({ -- 6-4-7
    start_time = 69091 - 402,
    end_time   = 69359,
    btn_count  = 1,
},
simple_buttons({
    {3,1, {69359}}
}))

add_section({ -- 6-4-8
    start_time = 69225 - 568,
    end_time   = 69492,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {69492}}
}))

add_section({ -- 6-4-9
    start_time = 69359 - 501,
    end_time   = 69626,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {69626}}
}))

add_section({ -- 6-4-10
    start_time = 69492 - 804,
    end_time   = 69760,
    btn_count  = 1,
},
simple_buttons({
    {1,1, {69760}}
}))

add_section({ -- 6-4-11
    start_time = 69626 - 804,
    end_time   = 69894,
    btn_count  = 1,
},
simple_buttons({
    {2,1, {69894}}
}))

add_section({ -- 6-4-12
    start_time = 69760 - 737,
    end_time   = 70028,
    btn_count  = 1,
},
simple_buttons({
    {4,1, {70028}}
}))

---------------------------------------------------------------------

add_section({ -- 7-1-1
    start_time = 71640 - 7000,
    end_time   = 72042,
    fx_count  = 4,
},
function(s, time)
    slide(s.f1,time,  71640,  71100, Ln.l/2,Ln.r, 238)
    slide(s.f2,time,  71774,  71235, Ln.l/2,Ln.r, 238)
    slide(s.f3,time,  71908,  71370, Ln.l/2,Ln.l, 238)
    slide(s.f4,time,  72042,  71505, Ln.l/2,Ln.l, 238)
    s:draw_all()
end)
hide_objects({
    {71640, 6},
    {71774, 6},
    {71908, 5},
    {72042, 5},
})

add_section({ -- 7-1-2
    start_time = 72583 - 7000,
    end_time   = 74862,
    btn_count  = 4,
    fx_long_count = 4,
},

function(s, time)

    slide(s.b1,time,  73656,  73388, Ln.a,Ln.c, 268)
    slide(s.b2,time,  73656,  73388, Ln.b,Ln.d, 268)
    slide(s.b3,time,  74058,  73790, Ln.c,Ln.a, 268)
    slide(s.b4,time,  74058,  73790, Ln.d,Ln.b, 268)
	
    slide_long(s.fl1,time,  72853,401,  72585, Ln.r,Ln.l, 268)
    slide_long(s.fl2,time,  73256,401,  72987, Ln.l,Ln.r, 268)
    slide_long(s.fl3,time,  74058,401,  73790, Ln.r,Ln.l, 268)
    slide_long(s.fl4,time,  74460,401,  74192, Ln.l,Ln.r, 268)

    s:draw_all()
end)
hide_objects({
    {72853, 5},
    {73254, 6},
    {73656, 3},
    {73656, 4},
    {74058, 1},
    {74058, 2},
    {74058, 5},
    {74460, 6},

})

add_section({ -- 7-2-1
    start_time = 75940	- 7000,
    end_time   = 76342,
    fx_count  = 4,
},
function(s, time)
    slide(s.f1,time,  75940,  75397, Ln.l/2,Ln.r, 238)
    slide(s.f2,time,  76074,  75533, Ln.l/2,Ln.r, 238)
    slide(s.f3,time,  76208,  75669, Ln.l/2,Ln.l, 238)
    slide(s.f4,time,  76342,  75805, Ln.l/2,Ln.l, 238)
    s:draw_all()
end)
hide_objects({
    {75940, 6},
    {76074, 6},
    {76208, 5},
    {76342, 5},
})

add_section({ -- 7-2-2
    start_time = 76886 - 7000,
    end_time   = 81230,
    btn_count  = 4,
    fx_long_count  = 4,
},
function(s, time)

    slide(s.b1,time,  77957,  77689, Ln.c,Ln.a, 268)
    slide(s.b2,time,  77957,  77689, Ln.d,Ln.b, 268)
    slide(s.b3,time,  78359,  78091, Ln.a,Ln.c, 268)
    slide(s.b4,time,  78359,  78091, Ln.b,Ln.d, 268)
	
    slide_long(s.fl1,time,  77154,401,  76886, Ln.l,Ln.r, 268)
    slide_long(s.fl2,time,  77555,401,  77288, Ln.r,Ln.l, 268)
    slide_long(s.fl3,time,  78359,401,  78091, Ln.l,Ln.r, 268)
    slide_long(s.fl4,time,  78761,401,  78493, Ln.r,Ln.l, 268)
	
    s:draw_all()
end)
hide_objects({
    {77153, 6},
    {77555, 5},
    {77857, 1},
    {77957, 2},
    {78359, 3},
    {78359, 4},
    {78359, 6},
    {78761, 5},
})

add_section({ -- 7-3-1
    start_time = 80242	- 7000,
    end_time   = 80644,
    fx_count  = 4,
},
function(s, time)
    slide(s.f1,time,  80242,  79698, Ln.l/2,Ln.r, 238)
    slide(s.f2,time,  80376,  79834, Ln.l/2,Ln.r, 238)
    slide(s.f3,time,  80510,  79970, Ln.l/2,Ln.l, 238)
    slide(s.f4,time,  80644,  80106, Ln.l/2,Ln.l, 238)
    s:draw_all()
end)
hide_objects({
    {80242, 6},
    {80376, 6},
    {80510, 5},
    {80644, 5},
})

add_section({ -- 7-3-2
    start_time = 81420 - 7000,
    end_time   = 83429,
    btn_count  = 4,
    fx_long_count = 4,
},

function(s, time)

    slide(s.b1,time,  82224,  81956, Ln.a,Ln.c, 268)
    slide(s.b2,time,  82224,  81956, Ln.b,Ln.d, 268)
    slide(s.b3,time,  82626,  82358, Ln.c,Ln.a, 268)
    slide(s.b4,time,  82626,  82358, Ln.d,Ln.b, 268)
	
    slide_long(s.fl1,time,  81420,401,  81152, Ln.r,Ln.l, 268)
    slide_long(s.fl2,time,  81822,401,  81554, Ln.l,Ln.r, 268)
    slide_long(s.fl3,time,  82626,401,  82358, Ln.r,Ln.l, 268)
    slide_long(s.fl4,time,  83027,401,  82760, Ln.l,Ln.r, 268)

    s:draw_all()
end)
hide_objects({
    {81420, 5},
    {81822, 6},
    {82224, 3},
    {82224, 4},
    {82626, 1},
    {82626, 2},
    {82626, 5},
    {83027, 6},

})

add_section({ -- 7-4-1
    start_time = 83965 - 7000,
    end_time   = 87715,
    btn_count  = 27,
    fx_count  = 2,
},

function(s, time)

    slide(s.b1,time,  83965,  83965-804, 12,Ln.d, 268)
    slide(s.b2,time,  84099,  84099-804, -12,Ln.b, 268)
    slide(s.b3,time,  84233,  84233-804, 12,Ln.d, 268)
	
    slide(s.b4,time,  84367,  84367-804, -12,Ln.a, 268)
    slide(s.b5,time,  84501,  84501-804, -12,Ln.a, 268)
	
    slide(s.f1,time,  84635,  84635-804, -12,Ln.r, 268)
	
	slide(s.b6,time,  84768,  84768-804, -12,Ln.b, 268)
	slide(s.b7,time,  84902,  84902-804, -12,Ln.b, 268)
	slide(s.b8,time,  85036,  85036-804, -12,Ln.b, 268)
	
	slide(s.b9,time,  85170,  85170-804, 12,Ln.d, 268)
	slide(s.b10,time,  85304,  85304-804, 12,Ln.d, 268)
	slide(s.b11,time,  85438,  85438-804, 12,Ln.d, 268)
	
	slide(s.b12,time,  85572,  85572-804, -12,Ln.b, 268)
	slide(s.b13,time,  85706,  85706-804, -12,Ln.b, 268)
	slide(s.b14,time,  85840,  85840-804, -12,Ln.b, 268)
	
	slide(s.b15,time,  85974,  85974-804, -12,Ln.c, 268)
	slide(s.b16,time,  86108,  86108-804, 12,Ln.d, 268)
	
	slide(s.f2,time,  86242,  86242-804, 12,Ln.r, 268)
	
	slide(s.b17,time,  86376,  86376-804, -12,Ln.a, 268)
	slide(s.b18,time,  86510,  86510-804, 12,Ln.a, 268)
	
	slide(s.b19,time,  86643,  86643-804, -12,Ln.b, 268)
	slide(s.b20,time,  86777,  86777-804, 12,Ln.b, 268)
	
	slide(s.b21,time,  86911,  86911-804, -12,Ln.c, 268)
	slide(s.b22,time,  87045,  87045-804, 12,Ln.c, 268)
	
	slide(s.b23,time,  87179,  87179-804, -12,Ln.d, 268)
	
	slide(s.b24,time,  87313,  87313-804, 12,Ln.a, 268)
	slide(s.b25,time,  87447,  87447-804, -12,Ln.c, 268)
	slide(s.b26,time,  87581,  87581-804, 12,Ln.a, 268)
	slide(s.b27,time,  87715,  87715-804, -12,Ln.c, 268)
	
    s:draw_all()
	
end)
hide_objects({
    {83965, 4},
    {84099, 2},
    {84233, 4},
	
    {84367, 1},
    {84501, 1},
	
    {84635, 6},
	
    {84768, 2},
    {84902, 2},
    {85036, 2},
	
    {85170, 4},
    {85304, 4},
    {85438, 4},
	
    {85572, 2},
    {85706, 2},
    {85840, 2},
	
    {85974, 3},
    {86108, 4},
    {86242, 6},
	
    {86376, 1},
    {86510, 1},
	
    {86643, 2},
    {86777, 2},
	
    {86911, 3},
    {87045, 3},
	
    {87179, 4},
	
    {87313, 1},
    {87447, 3},
    {87581, 1},
    {87715, 3},

})

add_section({ -- 7-5-1
    start_time = 87850 - 7000,
    end_time   = 90000,
    btn_count  = 16,
},
function(s, time)
	if time > 87850 then
		move_note(s.b1, Ln.a, 87850, -1)
		move_note(s.b2, Ln.b, 87900, -1)
		move_note(s.b3, Ln.c, 87950, -1)
		move_note(s.b4, Ln.d, 88050, -1)		
		move_note(s.b5, Ln.a, 88100, -1)
		move_note(s.b6, Ln.b, 88150, -1)
		move_note(s.b7, Ln.c, 88200, -1)
		move_note(s.b8, Ln.d, 88250, -1)
		move_note(s.b9, Ln.a, 88250, -1)
		move_note(s.b10, Ln.b, 88300, -1)
		move_note(s.b11, Ln.c, 88350, -1)
		move_note(s.b12, Ln.d, 88400, -1)
		move_note(s.b13, Ln.a, 88450, -1)
		move_note(s.b14, Ln.b, 88500, -1)
		move_note(s.b15, Ln.c, 88550, -1)
		move_note(s.b16, Ln.d, 88600, -1)
	
    s:draw_all()
	end
end)

---------------------------------------------------------------------

add_section({ -- 8-1-1
    start_time = 98429-10,
    end_time   = 98563,
    btn_count  = 1,
},

function(s, time)
	 if time < 98429 then
        move_note(s.b1, Ln.b, 98429, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-1-2
    start_time = 98831,
    end_time   = 99635,
    btn_count  = 2,
},
function(s, time)

    move_note(s.b1, Ln.b, 98831, -1.25)
    move_note(s.b2, Ln.b, 98831+402, -1.25)

    s:draw_all()
end)
hide_objects({
    {98831, 2},
    {99233, 2},
})

add_section({ -- 8-2-1
    start_time = 99635-10,
    end_time   = 99768,
    btn_count  = 1,
},

function(s, time)
	 if time < 99635 then
        move_note(s.b1, Ln.c, 99902, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-2-2
    start_time = 99902,
    end_time   = 100706,
    btn_count  = 2,
},
function(s, time)

    move_note(s.b1, Ln.c, 99902+201, 1.25)
    move_note(s.b2, Ln.c, 99902-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {99902, 3},
    {99902+402, 3},
})

add_section({ -- 8-2-3
    start_time = 99902+402,
    end_time   = 100706,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.c, 99902+402+201, 1.25)
	move_note(s.b2, Ln.c, 99902+402-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-3-1
    start_time = 99635+1072-10,
    end_time   = 99768+1072,
    btn_count  = 1,
},

function(s, time)
	 if time < 99635+1072 then
        move_note(s.b1, Ln.a, 99902+1072, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-3-2
    start_time = 99902+1072,
    end_time   = 100706+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.a, 99902+1072+201, 1.25)
	move_note(s.b2, Ln.a, 99902+1072-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {99902+1072, 1},
    {99902+1072+402, 1},
})

add_section({ -- 8-3-3
    start_time = 99902+402+1072,
    end_time   = 100706+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.a, 99902+1072+402+201, 1.25)
	move_note(s.b2, Ln.a, 99902+1072+402-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-4-1
    start_time = 101777-10,
    end_time   = 101911,
    btn_count  = 1,
},

function(s, time)
	 if time < 101777 then
        move_note(s.b1, Ln.d, 102045+568, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-4-2
    start_time = 102045,
    end_time   = 102849,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.d, 102045+568+201, 1.25)
	move_note(s.b2, Ln.d, 102045-568-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {102045, 4},
    {102045+402, 4},
})

add_section({ -- 8-4-3
    start_time = 102045+402,
    end_time   = 102849,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.d, 102045+402+568+201, 1.25)
	move_note(s.b2, Ln.d, 102045+402-568-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-5-1
    start_time = 101777+1072-10,
    end_time   = 101911+1072,
    btn_count  = 1,
},

function(s, time)
	 if time < 101777+1072 then
        move_note(s.b1, Ln.b, 102045+1072+568, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-5-2
    start_time = 102045+1072,
    end_time   = 102849+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.b, 102045+1072+568+201, 1.25)
	move_note(s.b2, Ln.b, 102045+1072-568-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {102045+1072, 2},
    {102045+1072+402, 2},
})

add_section({ -- 8-5-3
    start_time = 102045+1072+402,
    end_time   = 102849+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.b, 102045+1072+402+568+201, 1.25)
	move_note(s.b2, Ln.b, 102045+1072+402-568-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-6-1
    start_time = 103920-10,
    end_time   = 104054,
    btn_count  = 1,
},

function(s, time)
	 if time < 103920 then
        move_note(s.b1, Ln.c, 104188+501, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-6-2
    start_time = 102045+1072+1072,
    end_time   = 102849+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.c, 102045+1072+1072+501+201, 1.25)
	move_note(s.b2, Ln.c, 102045+1072+1072-501-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {104188, 3},
    {104590, 3},
})

add_section({ -- 8-6-3
    start_time = 102045+1072+1072+402,
    end_time   = 102849+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.c, 102045+1072+1072+402+501+201, 1.25)
	move_note(s.b2, Ln.c, 102045+1072+1072+402-501-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-7-1
    start_time = 104992-10,
    end_time   = 105126,
    btn_count  = 1,
},

function(s, time)
	 if time < 104992 then
        move_note(s.b1, Ln.a, 105260+134, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-7-2
    start_time = 102045+1072+1072+1072,
    end_time   = 102849+1072+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.a, 102045+1072+1072+1072+134+201, 1.25)
	move_note(s.b2, Ln.a, 102045+1072+1072+1072-134-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {105260, 1},
    {105661, 1},
})

add_section({ -- 8-7-3
    start_time = 102045+1072+1072+1072+402,
    end_time   = 102849+1072+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.a, 102045+1072+1072+1072+402+134+201, 1.25)
	move_note(s.b2, Ln.a, 102045+1072+1072+1072+402-134-201, -1.25)

    s:draw_all()
end)

add_section({ -- 8-8-1
    start_time = 106063-10,
    end_time   = 106197,
    btn_count  = 1,
},

function(s, time)
	 if time < 106063 then
        move_note(s.b1, Ln.d, 106331+402, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 8-8-2
    start_time = 102045+1072+1072+1072+1072,
    end_time   = 102849+1072+1072+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.d, 102045+1072+1072+1072+1072+402+201, 1.25)
	move_note(s.b2, Ln.d, 102045+1072+1072+1072+1072-402-201, -1.25)

    s:draw_all()
end)
hide_objects({
    {106331, 4},
    {106733, 4},
})

add_section({ -- 8-8-3
    start_time = 106733,
    end_time   = 102849+1072+1072+1072+1072,
    btn_count  = 2,
},
function(s, time)

	move_note(s.b1, Ln.d, 106733+402, 1.25)
	move_note(s.b2, Ln.d, 106733-402-201, -1.25)

    s:draw_all()
end)

---------------------------------------------------------------------

add_section({ -- 9-0-1 (Flash)
    start_time = 107147-7000,
    end_time   = 122280+134-10,
    fx_count  = 2,
},

function(s, time)
	 if time > 107147 and time < 122147 then
        move_note(s.f1, Ln.r, 122147-268-536-35-35, -1)
        move_note(s.f2, Ln.l, 122147-268-536-35-35, -1)

	end
	
    s:draw_all()
end)

add_section({ -- 9-0-2 (Flash)
    start_time = 122280+268-10,
    end_time   = 122280+536,
    fx_count  = 2,
},

function(s, time)

	if time < 122280+268 then
		move_note(s.f1, Ln.r, 122280+268+268+536+35, 1)
		move_note(s.f2, Ln.l, 122280+268+268+536+35, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 9-0-3 (Flash)
    start_time = 122280+268+268+134-10,
    end_time   = 122280+268+536,
    fx_count  = 2,
},

function(s, time)

	if time < 122280+268+268+134 then
		move_note(s.f1, Ln.r, 122280+268+268+268+536+134+35, 1)
		move_note(s.f2, Ln.l, 122280+268+268+268+536+134+35, 1)
	end
	
    s:draw_all()
end)

add_section({ -- 9-0-4 (Flash + Move)
    start_time = 122280+268+268+134+268+134-10,
    end_time   = 140897,
    fx_count  = 2,
},


function(s, time)

	if time < 122280+268+268+134+268+134 then
		move_note(s.f1, Ln.r, 122280+268+268+268+268+536+134+134+35, 1)
		move_note(s.f2, Ln.l, 122280+268+268+268+268+536+134+134+35, 1)
	elseif time > 139959+67 then
		move_note(s.f1, Ln.r, 140897, 1)
		move_note(s.f2, Ln.l, 140897, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {140897, 5},
    {140897, 6},
})

add_section({ -- 9-0-5 (All fx long cut off from fx)
    start_time = 123754-10,
    end_time   = 141432,
    fx_long_count  = 9,
},
function(s, time)
	--(.., .., .., target time, hold duration, speed, cutoff postion)
	move_long_note_with_cutoff(s.fl1,time, Ln.l, 127236,         236, 1, 836)
	move_long_note_with_cutoff(s.fl2,time, Ln.l, 127236+402,     236, 1, 836)
	move_long_note_with_cutoff(s.fl3,time, Ln.l, 127236+402+402, 402, 1, 836)
	
	move_long_note_with_cutoff(s.fl4,time, Ln.r, 131522,         236, 1, 836)
	move_long_note_with_cutoff(s.fl5,time, Ln.r, 131522+402,     236, 1, 836)
	move_long_note_with_cutoff(s.fl6,time, Ln.r, 131522+402+402, 402, 1, 836)	
	
	move_long_note_with_cutoff(s.fl7,time, Ln.l, 135807,         236, 1, 836)
	move_long_note_with_cutoff(s.fl8,time, Ln.l, 135807+402,     236, 1, 836)
	move_long_note_with_cutoff(s.fl9,time, Ln.l, 135807+402+402, 402, 1, 836)
	
	s:draw_all()
end)
hide_objects({
    {126432+402+402, 5},
    {126432+402+402+402, 5},
    {126432+402+402+402+402, 5},
	
    {131522, 6},
    {131522+402, 6},
    {131522+402+402, 6},
	
	{135807, 5},
    {135807+402, 5},
    {135807+402+402, 5},
})

add_section({ -- 9-1-1 (base)
    start_time = 123754-10,
    end_time   = 124691-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.d, 123754-402, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.d, 123754+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {124691, 4},
})

add_section({ -- 9-1-2 
    start_time = 123754-10,
    end_time   = 124691+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.a, 123754-402+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.a, 123754+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {124825, 1},
})

add_section({ -- 9-1-3 
    start_time = 123754-10,
    end_time   = 124691+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.b, 123754-402+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.b, 123754+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {124959, 2},
})

add_section({ -- 9-1-4
    start_time = 123754-10,
    end_time   = 124691+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.d, 123754-402+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.d, 123754+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125093, 4},
})

add_section({ -- 9-1-5
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.b, 123754-402+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.b, 123754+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125227, 2},
})


add_section({ -- 9-1-6
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.c, 123754-402+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.c, 123754+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125361, 3},
})


add_section({ -- 9-1-7
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.a, 123754-402+134+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.a, 123754+134+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125495, 1},
})


add_section({ -- 9-1-8
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.d, 123754-402+134+134+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.d, 123754+134+134+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125269, 4},
})


add_section({ -- 9-1-9
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.b, 123754-402+134+134+134+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.b, 123754+134+134+134+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125763, 2},
})


add_section({ -- 9-1-10
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.c, 123754-402+134+134+134+134+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.c, 123754+134+134+134+134+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {125897, 3},
})


add_section({ -- 9-1-11
    start_time = 123754-10,
    end_time   = 124691+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

	if time < 123754 then
		move_note(s.b1, Ln.b, 123754-402+134+134+134+134+134+134+134+134+134+134, -1)
	elseif time > 124289 then
		move_note(s.b1, Ln.b, 123754+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
	
    s:draw_all()
end)
hide_objects({
    {126030, 2},
})

add_section({ -- 9-1-12 (Backward Long)
    start_time = 123754-10,
    end_time   = 128575,
    fx_long_count  = 2,
},

function(s, time)

	if time > 124289 and time < 126432 then
		move_long_note(s.fl1, time, Ln.l, 123754+134+134+134+134+134+134+134+134+134+134+134+134+134+134,268, -1)
		move_long_note(s.fl2, time, Ln.l, 123754+134+134+134+134+134+134+134+134+134+134+134+134+134+134+402,268, -1)
	elseif time > 126432 then
		move_long_note(s.fl1, time, Ln.l, 126834,268, 1)
		move_long_note(s.fl2, time, Ln.l, 126432,268, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {126432, 5},
	{126432+402, 5},
})

add_section({ -- 9-2-1 (base)
    start_time = 128575-10,
    end_time   = 128977-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 128575-402, -1)
	
    s:draw_all()
end)
hide_objects({
    {128977, 1},
})

add_section({ -- 9-2-2 
    start_time = 128575-10,
    end_time   = 128977+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 128575-402+134, -1)

    s:draw_all()
end)
hide_objects({
    {129111, 4},
})

add_section({ -- 9-2-3 
    start_time = 128575-10,
    end_time   = 128977+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 128575-402+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129245, 3},
})

add_section({ -- 9-2-4 
    start_time = 128575-10,
    end_time   = 128977+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 128575-402+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129379, 1},
})

add_section({ -- 9-2-5 
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 128575-402+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129513, 3},
})

add_section({ -- 9-2-6
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 128575-402+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129647, 2},
})

add_section({ -- 9-2-7
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 128575-402+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129780, 4},
})

add_section({ -- 9-2-8
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 128575-402+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {129914, 1},
})

add_section({ -- 9-2-9
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 128575-402+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {130048, 3},
})

add_section({ -- 9-2-10
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 128575-402+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {130182, 2},
})

add_section({ -- 9-2-11
    start_time = 128575-10,
    end_time   = 128977+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 128575-402+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {130316, 3},
})

add_section({ -- 9-2-12 (Backward Long)
    start_time = 128575-10,
    end_time   = 132861,
    fx_long_count  = 2,
},

function(s, time)

	if time > 128575 and time < 130718 then
		move_long_note(s.fl1, time, Ln.r, 128575-402+134+134+134+134+134+134+134+134+134+134+134+134+134,268, -1)
		move_long_note(s.fl2, time, Ln.r, 128575-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134,268, -1)
	elseif time > 130718 then
		move_long_note(s.fl1, time, Ln.r, 131120,268, 1)
		move_long_note(s.fl2, time, Ln.r, 130718,268, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {130718, 6},
	{131120, 6},
})

add_section({ -- 9-3-1 (base)
    start_time = 132861-10,
    end_time   = 133263-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 132861-402, -1)

    s:draw_all()
end)
hide_objects({
    {133263, 1},
})

add_section({ -- 9-3-2 
    start_time = 132861-10,
    end_time   = 133263+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 132861-402+134, -1)

    s:draw_all()
end)
hide_objects({
    {133397, 3},
})

add_section({ -- 9-3-3 
    start_time = 132861-10,
    end_time   = 133263+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 132861-402+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {133530, 2},
})

add_section({ -- 9-3-4 
    start_time = 132861-10,
    end_time   = 133263+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 132861-402+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {133664, 4},
})

add_section({ -- 9-3-5 
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 132861-402+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {133798, 1},
})

add_section({ -- 9-3-6
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 132861-402+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {133932, 3},
})

add_section({ -- 9-3-7
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 132861-402+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134066, 1},
})

add_section({ -- 9-3-8
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 132861-402+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134200, 4},
})

add_section({ -- 9-3-9
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 132861-402+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134334, 2},
})

add_section({ -- 9-3-10
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 132861-402+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134468, 4},
})

add_section({ -- 9-3-11
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 132861-402+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134602, 1},
})

add_section({ -- 9-3-12
    start_time = 132861-10,
    end_time   = 133263+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 132861-402+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {134736, 3},
})

add_section({ -- 9-3-14
    start_time = 132861-10,
    end_time   = 137147,
    fx_long_count  = 2,
},

function(s, time)

	if time > 132861 and time < 135004 then
		move_long_note(s.fl1, time, Ln.l, 132861-402+134+134+134+134+134+134+134+134+134+134+134+134+134,268, -1)
		move_long_note(s.fl2, time, Ln.l, 132861-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134,268, -1)
	elseif time > 135004 then
		move_long_note(s.fl1, time, Ln.l, 135405,268, 1)
		move_long_note(s.fl2, time, Ln.l, 135004,268, 1)
	end
	
    s:draw_all()
end)
hide_objects({
    {135004, 5},
	{135405, 5},
})

add_section({ -- 9-4-1 (base)
    start_time = 137147-10,
    end_time   = 137548-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 137147-402, -1)

    s:draw_all()
end)
hide_objects({
    {137548, 1},
})

add_section({ -- 9-4-2 
    start_time = 137147-10,
    end_time   = 137548+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 137147-402+134, -1)

    s:draw_all()
end)
hide_objects({
    {137682, 3},
})

add_section({ -- 9-4-3 
    start_time = 137147-10,
    end_time   = 137548+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 137147-402+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {137816, 2},
})

add_section({ -- 9-4-4 
    start_time = 137147-10,
    end_time   = 137548+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 137147-402+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {137950, 4},
})

add_section({ -- 9-4-5 
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 137147-402+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138084, 1},
})

add_section({ -- 9-4-6
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 137147-402+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138218, 3},
})

add_section({ -- 9-4-7
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 137147-402+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138352, 1},
})

add_section({ -- 9-4-8
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 137147-402+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138486, 4},
})

add_section({ -- 9-4-9
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138620, 2},
})

add_section({ -- 9-4-10
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 137147-402+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138754, 4},
})

add_section({ -- 9-4-11
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 137147-402+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {138888, 1},
})

add_section({ -- 9-4-12
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 137147-402+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139022, 3},
})

add_section({ -- 9-4-13
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139155, 2},
})

add_section({ -- 9-4-14
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139289, 4},
})

add_section({ -- 9-4-15
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.a, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139423, 1},
})

add_section({ -- 9-4-16
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.c, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139557, 3},
})

add_section({ -- 9-4-17
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139691, 2},
})

add_section({ -- 9-4-18
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.d, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139825, 4},
})

add_section({ -- 9-4-19
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)

		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {139959, 2},
})

add_section({ -- 9-4-20 (Stop)
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	
		move_note(s.b1, Ln.c, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)

    s:draw_all()
end)
hide_objects({
    {140093, 3},
})

add_section({ -- 9-4-21
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	if time < 140093 then
		move_note(s.b1, Ln.a, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
    s:draw_all()
end)
hide_objects({
    {140227, 1},
})

add_section({ -- 9-4-22
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	if time < 140093 then
		move_note(s.b1, Ln.c, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
    s:draw_all()
end)
hide_objects({
    {140361, 3},
})

add_section({ -- 9-4-23
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	if time < 140093 then
		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
    s:draw_all()
end)
hide_objects({
    {140495, 2},
})

add_section({ -- 9-4-24
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	if time < 140093 then
		move_note(s.b1, Ln.d, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
    s:draw_all()
end)
hide_objects({
    {140629, 4},
})

add_section({ -- 9-4-25
    start_time = 137147-10,
    end_time   = 137548+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134-35,
    btn_count  = 1,
},

function(s, time)
	if time < 140093 then
		move_note(s.b1, Ln.b, 137147-402+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134+134, -1)
	end
    s:draw_all()
end)
hide_objects({
    {140763, 2},
})

add_section({ -- 10-1-1
    start_time = 158557-7000,
    end_time   = 159985,
    fx_count  = 16,
},
function(s, time)
	if time < 158557 then
		move_note(s.f1, Ln.l, 159985, 1)
		move_note(s.f2, Ln.r, 159985, 1)
		
		move_note(s.f3, Ln.l, 159807, 1)
		move_note(s.f4, Ln.r, 159807, 1)
		
		move_note(s.f5, Ln.l, 159628, 1)
		move_note(s.f6, Ln.r, 159628, 1)

		move_note(s.f7, Ln.l, 159449, 1)
		move_note(s.f8, Ln.r, 159449, 1)

		move_note(s.f9, Ln.l, 159271, 1)
		move_note(s.f10, Ln.r, 159271, 1)

		move_note(s.f11, Ln.l, 159092, 1)
		move_note(s.f12, Ln.r, 159092, 1)

		move_note(s.f13, Ln.l, 158914, 1)
		move_note(s.f14, Ln.r, 158914, 1)

		move_note(s.f15, Ln.l, 158735, 1)
		move_note(s.f16, Ln.r, 158735, 1)
		
	elseif time > 158735 and time < 158914 then 
		move_note(s.f1, Ln.l, 159985, 100)
		move_note(s.f2, Ln.r, 159985, 100)
		
	elseif time > 158914 and time < 159092 then 	
		move_note(s.f3, Ln.l, 159807, 100)
		move_note(s.f4, Ln.r, 159807, 100)
	
	elseif time > 159092 and time < 159271 then 	
		move_note(s.f5, Ln.l, 159628, 100)
		move_note(s.f6, Ln.r, 159628, 100)
	
	elseif time > 159271 and time < 159449 then 	
		move_note(s.f7, Ln.l, 159449+2000, 100)
		move_note(s.f8, Ln.r, 159449+2000, 100)
	
	elseif time > 159449 and time < 159628 then 	
		move_note(s.f9, Ln.l, 159271, 100)
		move_note(s.f10, Ln.r, 159271, 100)
	
	elseif time > 159628 and time < 159807 then 	
		move_note(s.f11, Ln.l, 159092, 100)
		move_note(s.f12, Ln.r, 159092, 100)
	
	elseif time > 159807 and time < 159985 then 	
		move_note(s.f13, Ln.l, 158914, 100)
		move_note(s.f14, Ln.r, 158914, 100)
	
	elseif time > 159985 then 	
		move_note(s.f15, Ln.l, 158735, 100)
		move_note(s.f16, Ln.r, 158735, 100)
	end
	s:draw_all()
end)
hide_objects({
    {159985, 5},
    {159807, 5},
    {159628, 5},
    {159449, 5},
    {159271, 5},
    {159092, 5},
    {158914, 5},
    {158735, 5},
	{159985, 6},
    {159807, 6},
    {159628, 6},
    {159449, 6},
    {159271, 6},
    {159092, 6},
    {158914, 6},
    {158735, 6},
	
})
--]]

--[[
add_section({
    start_time = 9230-7000,
    end_time   = 9230+2000,
    fx_long_count = 1,
    --btn_count = 1,
},
simple_buttons({
    --{2, 1, {9230}},
},
function(s, time)
    --move_note_z(s.b1, Ln.b, 9230, .25)
    --move_long_note_z(s.f2,time, Ln.l, 9230,461, .1)
    --move_long_note_with_cutoff(s.f1,time, Ln.r, 9230, 920, 2, 231)
    --move_note(s.b1, Ln.c, 9230, 1)
    move_long_note(s.fl1,time, Ln.l, 9230,461, 1)
    s:draw_all()
end))
--]]

init_sections()

end

function render_fg(deltaTime)
    bartime, offsync, time = foreground.GetTiming()

    time_m = time*1000
    for i,s in ipairs(_log) do
        gfx.Text(s, 100, 200+i*25)
    end
    do_sections(time_m)
end

