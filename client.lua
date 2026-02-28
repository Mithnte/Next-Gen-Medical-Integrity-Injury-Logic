local isBleeding, bleedLevel, isKnockedOut, isPushing = false, 0, false, false
local injuries = { ["legs"] = false, ["arms"] = false, ["head"] = false }
local activeStretcher = nil

-- 1. DETEKSI TRAUMA & BONE ID
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        if HasEntityBeenDamagedByAnyPed(ped) then
            local _, bone = GetPedLastDamageBone(ped)
            if (bone == 11816 or bone == 58271) and not injuries["legs"] then 
                injuries["legs"] = true
                RequestAnimSet("move_m@injured")
                while not HasAnimSetLoaded("move_m@injured") do Wait(1) end
                SetPedMovementClipset(ped, "move_m@injured", 1.0)
                lib.notify({title = 'Trauma Kaki', description = 'Kaki lu patah!', type = 'error'})
            elseif bone == 31086 then TriggerKnockout(20) end
            if GetEntityHealth(ped) < 150 then isBleeding, bleedLevel = true, math.random(2, 5) end
            ClearEntityLastDamageEntity(ped)
        end
        Wait(sleep)
    end
end)

-- 2. KNOCKOUT & TINNITUS (Denging Telinga)
function TriggerKnockout(seconds)
    if isKnockedOut then return end
    isKnockedOut = true
    PlaySoundFrontend(-1, "FocusIn", "HintCamSounds", true) 
    StartAudioScene("PROLOGUE_MUTE_PARTY") 
    SetTimecycleModifier("fbi_filter")
    AnimpostfxPlay("Dont_Tapa_Me_Line", 0, true)
    CreateThread(function()
        local timer = seconds
        while timer > 0 do
            SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
            Wait(1000)
            timer = timer - 1
        end
        isKnockedOut, isBleeding = false, false
        StopAudioScene("PROLOGUE_MUTE_PARTY")
        AnimpostfxStopAll()
        ClearTimecycleModifier()
    end)
end

-- 3. ARTERIAL BLEEDING (Darah di Lantai)
CreateThread(function()
    while true do
        if isBleeding then
            local p = PlayerPedId()
            SetEntityHealth(p, GetEntityHealth(p) - bleedLevel)
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do Wait(1) end
            UseParticleFxAssetNextCall("core")
            StartNetworkedParticleFxNonLoopedAtCoord("ent_brk_blood_raster", GetEntityCoords(p), 0.0, 0.0, 0.0, 1.0, false, false, false)
        end
        Wait(4000)
    end
end)

-- 4. TREATMENT & CPR LOGIC
RegisterNetEvent('vibe_med:startTreatment')
AddEventHandler('vibe_med:startTreatment', function(type, targetId)
    local label = "Mengobati..."
    local anim = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", clip = "weed_stand_check_v2_inspector" }
    
    if type == "cpr" then label = "Melakukan CPR..."; anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' } end

    if lib.progressCircle({
        duration = 5000,
        label = label,
        position = 'bottom',
        disable = { move = true, combat = true },
        anim = anim,
    }) then 
        if type == "cpr" then TriggerServerEvent('vibe_med:cprSuccess', targetId) else ApplyEffect(type) end
    end
end)

function ApplyEffect(type)
    local p = PlayerPedId()
    if type == "morphine" then ClearTimecycleModifier() injuries["head"] = false
    elseif type == "splint" then injuries["legs"] = false ResetPedMovementClipset(p, 0.0)
    elseif type == "bloodbag" then SetEntityHealth(p, GetEntityHealth(p) + 50) isBleeding = false end
    lib.notify({title = 'Sukses', description = 'Pengobatan selesai!', type = 'success'})
end

-- 5. STRETCHER & LIE DOWN SYSTEM
RegisterCommand("spawnstretcher", function()
    local p = PlayerPedId()
    local model = `v_med_bed1`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
    activeStretcher = CreateObject(model, GetOffsetFromEntityInWorldCoords(p, 0.0, 1.5, 0.0), true, true, true)
    PlaceObjectOnGroundProperly(activeStretcher)
end)

RegisterCommand("putonstretcher", function()
    local target, dist = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 2.0)
    if target and activeStretcher then
        local tPed = GetPlayerPed(target)
        AttachEntityToEntity(tPed, activeStretcher, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
        RequestAnimDict("nm")
        while not HasAnimDictLoaded("nm") do Wait(1) end
        TaskPlayAnim(tPed, "nm", "firemans_carry", 8.0, 8.0, -1, 1, 0, false, false, false)
    end
end)
