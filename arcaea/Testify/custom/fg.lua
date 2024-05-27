local logging = true;

local difficulty_names = { "nov", "adv", "exh", "mxm" }
local chart_file = string.format("chart_%s.lua", difficulty_names[gameplay.difficulty + 1])

dofile(foreground.GetPath() .. chart_file)
dofile(foreground.GetPath() .. 'common.lua');
dofile(foreground.GetPath() .. 'effectKeyTimes.lua')

local share_tex = gfx.LoadSharedSkinTexture ~= nil

if share_tex then
    log("Testing shared textures", game.LOGGER_NORMAL);
    gfx.LoadSharedSkinTexture("fxbuttonhold", "fxbuttonhold.png")
    gfx.LoadSharedSkinTexture("fxbutton", "fxbutton.png")
    gfx.LoadSharedSkinTexture("buttonhold", "buttonhold.png")
    gfx.LoadSharedSkinTexture("button", "button.png")

    local sanity = pcall(function()
        local test = gfx.CreateShadedMesh();
        test:AddSharedTexture("mainTex", "button");
    end)
    if not sanity then
        log("AddSharedTexture sanity check failed", game.LOGGER_WARNING);
        share_tex = false
    else
        log("AddSharedTexture sanity check success", game.LOGGER_NORMAL);
    end
else
    log("Not using shared textures", game.LOGGER_WARNING)
end
share_tex = false

function long_glow(note, time)
    if time < note.t then
        note.m:SetParam("hitState", 1)
    elseif gameplay.noteHeld[note.nl + 1] then
        local s;
        if time % 100 < 50 then
            s = 0
        else
            s = 1
        end
        note.m:SetParam("hitState", math.floor(2 + s))
    else
        note.m:SetParam("hitState", 0)
    end
end

function make_note(lane, length, ntime)
    local note;
    local fx = lane > 3;
    local long = length > 0

    if long then
        note = track.CreateShadedMeshOnTrack("holdbutton");
    else
        note = track.CreateShadedMeshOnTrack("button");
    end

    if share_tex then
        if fx and long then
            note:AddSharedTexture("mainTex", "fxbuttonhold");
        elseif fx then
            note:AddSharedTexture("mainTex", "fxbutton");
        elseif long then
            note:AddSharedTexture("mainTex", "buttonhold");
        else
            note:AddSharedTexture("mainTex", "button");
        end
    else
        if fx and long then
            note:AddSkinTexture("mainTex", "fxbuttonhold.png");
        elseif fx then
            note:AddSkinTexture("mainTex", "fxbutton.png");
        elseif long then
            note:AddSkinTexture("mainTex", "buttonhold.png");
        else
            note:AddSkinTexture("mainTex", "button.png");
        end
    end
    note:SetPrimitiveType(note.PRIM_TRIFAN)
    if long then
        note:SetBlendMode(note.BLEND_NORM)
    else
        note:SetBlendMode(note.BLEND_NORM)
    end

    if fx then
        note:UseGameMesh("fxbutton")
    else
        note:UseGameMesh("button")
    end
    note:SetClipWithTrack(true)

    note:SetParam("hasSample", 0.0);
    note:SetParam("hiddenCutoff", 0.0);
    note:SetParam("hiddenFadeWindow", 0.1);
    note:SetParam("suddenCutoff", 1.0);
    note:SetParam("suddenFadeWindow", 0.1);
    note:SetParam("trackPos", 0.0);
    note:SetParam("trackScale", 1.0);

    return
    {
        m = note;
        l = length,
        t = ntime,
        nl = lane;
        Hide = function(self)
            self.m:SetPosition(-100, -100)
        end,
        Update = function(self, time, notePos)
            local _, _, z = self.m:GetPosition();
            local y = track.GetYPosForTime(self.t);
            local timeLimit = self.t + self.l + 100;

            if time <= timeLimit and time > self.t - 2700 / gameplay.hispeed then
                if length > 0 then
                    self.m:SetPosition(notePos, y, z);
                    local l = track.GetLengthForDuration(math.floor(self.t), math.floor(self.l));
                    self.m:ScaleToLength(l);
                    long_glow(self, time)
                else
                    self.m:SetPosition(notePos, y, z)
                end
                self.m:Draw();
            end
        end
    }
end

local any_six_laners = {};

for _, segment in ipairs(sixLaneSegments) do
    local startTime, endTime = table.unpack(segment);

    for _, note in ipairs(chart_notes) do
        local lane, time, length = table.unpack(note);

        if time >= startTime and time < endTime then
            track.HideObject(time, lane + 1);
            table.insert(any_six_laners, make_note(lane, length, time));
        end
    end
end

function get_lane_position(lane)
    local _, _, real = foreground.GetTiming();
    local real_ms = real * 1000;
    local animProgress;

    for _, segment in ipairs(sixLaneSegments) do
        local startTime, endTime, animIn, animOut = table.unpack(segment);
        local bps = 120 / gameplay.bpm * 1000;
        local animDurationOut = bps * animOut;

        if real_ms >= startTime and real_ms < endTime + animDurationOut then
            local animDurationIn = bps * animIn;

            if real_ms < startTime + animDurationIn then
                animProgress = inverseLerp(startTime, startTime + animDurationIn, real_ms);
                break ;
            elseif real_ms >= endTime then
                animProgress = inverseLerp(endTime, endTime + animDurationOut, real_ms);
                break ;
            else
                animProgress = 1;
                break ;
            end
        else
            animProgress = 0;
        end
    end

    local notePos = 0;
    if lane == 0 then
        notePos = inOutQuad(animProgress, track.GetCurrentLaneXPos(1), track.GetCurrentLaneXPos(2) * 2, 1);
    elseif lane == 1 then
        notePos = track.GetCurrentLaneXPos(2)
    elseif lane == 2 then
        notePos = track.GetCurrentLaneXPos(3)
    elseif lane == 3 then
        notePos = inOutQuad(animProgress, track.GetCurrentLaneXPos(4), -track.GetCurrentLaneXPos(2) * 2, 1);
    elseif lane == 4 then
        notePos = inOutQuad(animProgress, track.GetCurrentLaneXPos(5), track.GetCurrentLaneXPos(2), 1);
    elseif lane == 5 then
        notePos = inOutQuad(animProgress, track.GetCurrentLaneXPos(6), -track.GetCurrentLaneXPos(2), 1);
    end

    return notePos;
end

function draw_notes()
    local _, _, real = foreground.GetTiming();
    local real_ms = real * 1000;

    for _, note in ipairs(any_six_laners) do
        note.Update(note, real_ms, get_lane_position(note.nl));
    end
end

local effectIndex = 1;
foreground.SetParamf("EffectStrength", 0);

render_fg = function(dt)
    bartime, offsync, real = foreground.GetTiming();
    local gameTime = tonumber(real * 1000);
    local effectStrength, time, interp = table.unpack(keyTimes[effectIndex]);

    if gameTime < time and not (effectIndex == 1) then
        effectIndex = effectIndex - 1;
        effectIndex = math.max(effectIndex, 1);
    end

    local ntime;
    local nstrength = effectStrength;

    if not (effectIndex == #keyTimes) then
        nstrength, ntime = table.unpack(keyTimes[effectIndex + 1]);
        if gameTime >= ntime then
            effectIndex = effectIndex + 1;
        end
    end

    local outStrength = effectStrength;

    if interp > 0 and not (effectIndex == #keyTimes) then
        local segmentProgress = clamp(inverseLerp(time, ntime, gameTime), 0, 1);

        if interp == 2 then
            outStrength = inQuad(segmentProgress, effectStrength, nstrength - effectStrength, 1);
        elseif interp == 3 then
            outStrength = outQuad(segmentProgress, effectStrength, nstrength - effectStrength, 1);
        elseif interp == 4 then
            outStrength = inOutQuad(segmentProgress, effectStrength, nstrength - effectStrength, 1);
        else
            outStrength = lerp(effectStrength, nstrength, segmentProgress);
        end
    end

    foreground.SetParamf("EffectStrength", outStrength);
    foreground.DrawShader();
    draw_notes();
end
