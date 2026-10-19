Config = {}

-- EXAKT EIN Meldesystem auswaehlen. Es gibt KEINEN "both"-Modus.
-- 'emergencydispatch' = LoveRP EmergencyDispatch (Standard wie in v1.2)
-- 'ox'                = ox_lib-Benachrichtigung mit E / ENTF
Config.NotificationSystem = 'emergencydispatch'

-- Serverseitig: Nach dem ersten Alarm sind weitere Schussmeldungen aus
-- derselben Zone fuer 60 Sekunden gesperrt (gemeinsam fuer alle Schuetzen).
-- Erst der naechste Schuss NACH Ablauf der Sperre loest wieder etwas aus.
Config.ZoneCooldownSeconds = 60

-- Technische Entprellung: ein Schussfeuer darf nicht mehrere Requests erzeugen.
Config.ClientShotDebounceMs = 1200
Config.ServerRequestDebounceMs = 1200

-- true = Schussmeldungen nur aus Routing Bucket 0 ausloesen.
Config.OnlyPublicBucket = true

-- Diese Jobs ERHALTEN den Alarm (gilt fuer BEIDE Meldesysteme).
Config.ReceiverJobs = {
    'police',
    'sheriff',
    -- 'statepolice',
}

-- Diese Jobs koennen durch eigene Schuesse KEINEN Alarm ausloesen.
-- Ein ausgeschlossener Schuetze darf selbst weiterhin Empfaenger sein.
Config.ExcludedShooterJobs = {
    'police',
    'admin',
    -- 'sheriff',
}

-- Fuer diese Waffen wird kein Alarm erzeugt.
Config.IgnoredWeapons = {
    'WEAPON_STUNGUN',
    'WEAPON_FLAREGUN',
}

-- Text in EmergencyDispatch und ox_lib; %s = Name der Zone.
Config.AlertMessage = 'Schüsse im Bereich %s gemeldet.'

-- Einsatzposition: 'shot' = Position des Schuetzen, 'center' = Zonenmitte.
Config.AlertPosition = 'shot'

-- NUR im ox-Modus relevant. Keine eigene HTML-/NUI-Oberflaeche.
Config.Ox = {
    DurationMs = 20000,  -- 20 Sekunden Reaktionszeit PRO Meldung
    Title = 'Schussmeldung',
    Position = 'top-right',
    Type = 'warning',
    Icon = 'gun',
    AcceptKey = 'E',      -- FiveM-Keymapping; E = Wegpunkt setzen
    RejectKey = 'DELETE', -- ENTF = ignorieren / ablehnen
}

-- Beliebig viele Zonen: echter 3D-Radius um vector3.
-- Bei Ueberlappung gewinnt die Zone mit dem kleineren Radius.
-- ID muss pro Zone eindeutig sein, da die Sperre daran gebunden ist.
Config.Zones = {
    {
        id = 'hauptplatz',
        label = 'Hauptplatz',
        coords = vector3(215.76, -925.00, 30.69), -- BEISPIEL, anpassen!
        radius = 50.0,
        enabled = true,
        -- Optionale abweichende Empfaenger NUR fuer diese Zone:
        -- receiverJobs = { 'police', 'sheriff' },
        -- Optionale ZUSAETZLICHE Job-Ausnahmen:
        -- excludedShooterJobs = { 'security' },
        -- Optionale abweichende Sperre:
        -- cooldownSeconds = 60,
    },
    -- {
    --     id = 'hafen',
    --     label = 'Hafen',
    --     coords = vector3(1200.0, -3000.0, 6.0),
    --     radius = 75.0,
    --     enabled = true,
    -- },
}
