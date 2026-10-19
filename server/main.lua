local ESX = exports['es_extended']:getSharedObject()
local lastZoneAlert = {}
local lastPlayerRequest = {}
local outputMissingWarned = false

local function log(msg)
    print(('[aeth_shotalerts] %s'):format(msg))
end

local function mode()
    return Config.NotificationSystem
end

local function contains(list, value)
    if type(list) ~= 'table' then return false end
    for _, entry in ipairs(list) do
        if entry == value then return true end
    end
    return false
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

local function getReceiverJobs(zone)
    local jobs = {}
    local fromConfig = zone.receiverJobs or Config.ReceiverJobs or {}
    for _, job in ipairs(fromConfig) do
        if type(job) == 'string' and job ~= '' and not contains(jobs, job) then
            jobs[#jobs + 1] = job
        end
    end
    return jobs
end

local function outputReady()
    local required
    if mode() == 'ox' then
        required = 'ox_lib'
    elseif mode() == 'emergencydispatch' then
        required = 'emergencydispatch'
    else
        if not outputMissingWarned then
            log('FEHLER: Config.NotificationSystem muss "ox" oder "emergencydispatch" sein.')
            outputMissingWarned = true
        end
        return false
    end

    if GetResourceState(required) == 'started' then
        outputMissingWarned = false
        return true
    end

    if not outputMissingWarned then
        log(('Meldesystem "%s" nicht gestartet! Keine Meldungen, bis es gestartet ist.'):format(required))
        outputMissingWarned = true
    end
    return false
end

local function formatMessage(zone)
    local name = tostring(zone.label or zone.id)
    local pattern = Config.AlertMessage or 'Schüsse im Bereich %s gemeldet.'
    local ok, formatted = pcall(string.format, pattern, name)
    return ok and formatted or ('Schüsse im Bereich ' .. name .. ' gemeldet.')
end

local function sendDispatch(jobs, message, coords)
    local sent = 0
    -- Offizielle LoveRP-Server-API. Jeder Job erhaelt einen eigenen Notruf.
    -- https://docs.loverp-scripts.de/love-rp-de/emergencydispatch/developer
    for _, job in ipairs(jobs) do
        local ok, err = pcall(function()
            TriggerEvent('emergencydispatch:emergencycall:new', job, message, coords, true)
        end)
        if ok then
            sent = sent + 1
        else
            log(('EmergencyDispatch-Fehler fuer Job "%s": %s'):format(job, tostring(err)))
        end
    end
    return sent > 0
end

local function sendOx(jobs, zone, message, coords)
    -- Nur Spieler mit einem passenden, aktuellen ESX-Job bekommen
    -- die Meldung. Jeder Client fuehrt eine unabhaengige FIFO-Warteschlange.
    local payload = {
        zoneId = zone.id,
        zoneLabel = tostring(zone.label or zone.id),
        message = message,
        coords = { x = coords.x, y = coords.y, z = coords.z },
    }

    local sent = 0
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target then
            local xPlayer = ESX.GetPlayerFromId(target)
            if xPlayer and xPlayer.job and contains(jobs, xPlayer.job.name) then
                TriggerClientEvent('aeth_shotalerts:client:queueAlert', target, payload)
                sent = sent + 1
            end
        end
    end
    return sent > 0
end

RegisterNetEvent('aeth_shotalerts:server:shot', function()
    local src = source
    if not src or src <= 0 then return end

    -- Der Client liefert KEINEN Job, KEINE Koordinaten, KEINE Zonen-ID.
    -- Die Entscheidungsgrundlage wird ausschliesslich serverseitig ermittelt.
    local nowMs = GetGameTimer()
    local minGap = tonumber(Config.ServerRequestDebounceMs) or 1200
    local previousRequest = lastPlayerRequest[src]
    if previousRequest and (nowMs - previousRequest) < minGap then return end
    lastPlayerRequest[src] = nowMs

    local shooter = ESX.GetPlayerFromId(src)
    if not shooter or not shooter.job or not shooter.job.name then return end
    if contains(Config.ExcludedShooterJobs, shooter.job.name) then return end
    if Config.OnlyPublicBucket and GetPlayerRoutingBucket(src) ~= 0 then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if not coords then return end

    local zone = findZoneAt(coords)
    if not zone or contains(zone.excludedShooterJobs, shooter.job.name) then return end

    local jobs = getReceiverJobs(zone)
    if #jobs == 0 or not outputReady() then return end

    local now = os.time()
    local seconds = math.max(0, tonumber(zone.cooldownSeconds)
        or tonumber(Config.ZoneCooldownSeconds) or 60)
    local last = lastZoneAlert[zone.id]
    if last and (now - last) < seconds then return end

    -- Gemeinsamer Zone-Cooldown, wird VOR der Ausgabe gesetzt.
    lastZoneAlert[zone.id] = now
    local reportCoords = Config.AlertPosition == 'center' and zone.coords or coords
    local message = formatMessage(zone)

    local sent
    if mode() == 'ox' then
        sent = sendOx(jobs, zone, message, reportCoords)
    else
        sent = sendDispatch(jobs, message, reportCoords)
    end

    -- Bei fehlenden Empfaengern (OX) oder ausschliesslich fehlgeschlagenen
    -- Dispatch-Events kein nutzloser Cooldown fuer die Zone.
    if not sent then lastZoneAlert[zone.id] = last end
end)

AddEventHandler('playerDropped', function()
    lastPlayerRequest[source] = nil
end)

CreateThread(function()
    if outputReady() then
        log(('Bereit | Meldesystem: %s | Sperrzeit: %ss'):format(
            mode(), tostring(Config.ZoneCooldownSeconds or 60)))
    end
end)
