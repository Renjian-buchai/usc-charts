dofile(background.GetPath() .. 'common.lua');
dofile(background.GetPath() .. 'effectKeyTimes.lua')

background.LoadTexture('bgTex', 'textures/BG_testify.png');

--Make lane extensions
local lEx = track.CreateShadedMeshOnTrack("track");
lEx:UseGameMesh("track")
lEx:AddTexture("mainTex", background.GetPath() .. 'textures/exL.png');
local x, y, z = lEx:GetScale();
lEx:SetScale(x * 1.5, y, z);
lEx:SetPrimitiveType(lEx.PRIM_TRIFAN);
lEx:SetBlendMode(lEx.BLEND_NORM);

local xp, lExSP, zp = lEx:GetPosition();
local lExHP = -10.5;

function draw_extension_lanes()
    local _, _, real = background.GetTiming();
    local real_ms = real * 1000;
    
    for _, segment in ipairs(sixLaneSegments) do
        local startTime, endTime, animIn, animOut = table.unpack(segment);
        local bps = 120 / gameplay.bpm * 1000;
        local animDurationOut = bps * animOut;
        
        if real_ms >= startTime and real_ms < endTime + animDurationOut then
            local animDurationIn = bps * animIn;
            
            if real_ms < startTime + animDurationIn then
                local animProgress = inverseLerp(startTime, startTime + animDurationIn, real_ms);
                lEx:SetPosition(xp, lerp(lExHP, lExSP, animProgress), zp);
                break;
            elseif real_ms >= endTime then
                local animProgress = inverseLerp(endTime, endTime + animDurationOut, real_ms);
                lEx:SetPosition(xp, lerp(lExSP, lExHP, animProgress), zp);
                break;
            else
                lEx:SetPosition(xp, lExSP, zp);
                break;
            end
        else
            lEx:SetPosition(xp, lExHP, zp);
        end
    end
    
    lEx:Draw();
end

render_bg = function(dt)
    background.DrawShader();
    draw_extension_lanes();
end