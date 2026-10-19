local activeZone = nil
local lastShotRequestAt = -100000
local ignoredWeaponHashes = {}

for _, name in ipairs(Config.IgnoredWeapons or {}) do
    ignoredWeaponHashes[GetHashKey(name)] = true
end

local function findZoneAt(coords)
    local best
    for _, zone in ipairs(Config.Zones or {}) do
        if zone.enabled ~= false
            and type(zone.id) == 'string' and zone.id ~= ''
            and zone.coords and type(zone.radius) == 'number' and zone.radius > 0
            and #(coords - zone.coords) <= zone.radius
        then
            if not best or zone.radius < best.radius then best = zone end
        end
    end
    return best
end

-- Zone in kleinen Abstaenden ermitteln; kein permanenter Frame-Loop
-- ausser beim Waffenfuehren innerhalb einer Zone.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        activeZone = (ped ~= 0 and DoesEntityExist(ped))
            and findZoneAt(GetEntityCoords(ped)) or nil
        Wait(750)
    end
end)

-- GTA-Schusserkennung (Spieler, keine NPCs). Server prueft Zone/Job selbst.
CreateThread(function()
    while true do
        local waitMs = 750
        if activeZone then
            local ped = PlayerPedId()
            if ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) then
                if IsPedArmed(ped, 4) then
                    waitMs = 0
                    if IsPedShooting(ped)
                        and not ignoredWeaponHashes[GetSelectedPedWeapon(ped)]
                    then
                        local now = GetGameTimer()
                        if (now - lastShotRequestAt) >= (Config.ClientShotDebounceMs or 1200)
                            and findZoneAt(GetEntityCoords(ped))
                        then
                            lastShotRequestAt = now
                            TriggerServerEvent('aeth_shotalerts:server:shot')
                        end
                    end
                else
                    waitMs = 250
                end
            end
        end
        Wait(waitMs)
    end
end)

-- OX-Modus: keine eigene NUI, kein HTML und keine ox_lib-Init-Pflicht
-- im EmergencyDispatch-Modus. ox_lib wird ueber sein offizielles
-- Benachrichtigungs-Event verwendet; Keybinds sind FiveM-eigen.
if Config.NotificationSystem ~= 'ox' then return end

local options = Config.Ox or {}
local durationMs = math.max(1000, math.floor(tonumber(options.DurationMs) or 20000))
local pending = {}
local current = nil
local nextId = 0

local function oxAvailable()
    return GetResourceState('ox_lib') == 'started'
end

local function keyCaption(key)
    key = tostring(key):upper()
    if key == 'DELETE' then return 'ENTF' end
    return key
end

local function displayNext()
    if current or #pending == 0 or not oxAvailable() then return end

    local item = table.remove(pending, 1)
    nextId = nextId + 1
    local id = nextId
    current = {
        id = id,
        coords = item.coords,
        started = GetGameTimer(),
        handled = false,
    }

    TriggerEvent('ox_lib:notify', {
        id = ('aeth_shotalerts_%s_%s'):format(GetGameTimer(), id),
        title = options.Title or 'Schussmeldung',
        description = ('%s\n\n**%s:** Wegpunkt setzen  |  **%s:** Ablehnen'):format(
            item.message, keyCaption(options.AcceptKey or 'E'),
            keyCaption(options.RejectKey or 'DELETE')), 
        duration = durationMs,
        position = options.Position or 'top-right',
        type = options.Type or 'warning',
        icon = options.Icon or 'gun',
        showDuration = true,
    })

    -- OX-Lib-Notify bietet keine dokumentierte "Schliessen"-API.
    -- Auch nach E/ENTF laeuft die Anzeige bis zum Ende ihrer 20s,
    -- damit nie zwei Benachrichtigungen dieses Skripts ueberlappen.
    SetTimeout(durationMs, function()
        if current and current.id == id then
            current = nil
            displayNext()
        end
    end)
end

local function actOnCurrent(accept)
    local item = current
    if not item or item.handled then return end
    if (GetGameTimer() - item.started) >= durationMs then return end
    item.handled = true
    if accept then
        SetNewWaypoint(item.coords.x, item.coords.y)
    end
    -- Die Aktion wirkt sofort, die naechste Meldung folgt nach dem
    -- vollstaendigen Anzeigeintervall, siehe displayNext().
end

-- RegisterKeyMapping legt Tasten in FiveM an. Ohne aktive Meldung
-- bewirken diese Commands NICHTS. Keine laufende Key-Abfrage noetig.
RegisterCommand('+aeth_shotalerts_accept', function()
    actOnCurrent(true)
end, false)
RegisterCommand('-aeth_shotalerts_accept', function() end, false)
RegisterKeyMapping('+aeth_shotalerts_accept',
    'AETHRALETH Schussmeldung: Wegpunkt setzen', 'keyboard', options.AcceptKey or 'E')

RegisterCommand('+aeth_shotalerts_reject', function()
    actOnCurrent(false)
end, false)
RegisterCommand('-aeth_shotalerts_reject', function() end, false)
RegisterKeyMapping('+aeth_shotalerts_reject',
    'AETHRALETH Schussmeldung: Ablehnen', 'keyboard', options.RejectKey or 'DELETE')

RegisterNetEvent('aeth_shotalerts:client:queueAlert', function(alert)
    if type(alert) ~= 'table' or type(alert.message) ~= 'string'
        or type(alert.coords) ~= 'table' then return end

    local coords = alert.coords
    if type(coords.x) ~= 'number' or type(coords.y) ~= 'number'
        or type(coords.z) ~= 'number' then return end
    if not oxAvailable() then return end

    -- FIFO pro Spieler: die zuerst eingegangene Meldung behaelt Vorrang.
    pending[#pending + 1] = {
        coords = coords,
        message = alert.message,
    }
    displayNext()
end)

-- Bei Jobwechsel alte Einsaetze nicht mehr annehmen; eine bereits
-- eingeblendete OX-Nachricht kann erst nach ihrer Restdauer verschwinden.
RegisterNetEvent('esx:setJob', function()
    pending = {}
    if current then current.handled = true end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'ox_lib' then
        pending = {}
        if current then current.handled = true end
    end
end)
