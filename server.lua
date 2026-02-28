local QBCore = exports['qb-core']:GetCoreObject() -- Hapus jika pake ESX

-- Usable Items Logic
local items = {"morphine", "bloodbag", "splint"}
for _, item in pairs(items) do
    QBCore.Functions.CreateUseableItem(item, function(source)
        TriggerClientEvent('vibe_med:startTreatment', source, item)
    end)
end

RegisterServerEvent('vibe_med:cprSuccess')
AddEventHandler('vibe_med:cprSuccess', function(targetId)
    -- Logika Framework lu buat revive/tambah darah di sini
    print("CPR Berhasil ke ID: " .. targetId)
end)
