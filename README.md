# AETHRALETH Shot Alerts

**Zonenbasierte Schussmeldungen für FiveM / ESX Legacy**

![Version](https://img.shields.io/badge/Version-1.3.0-blue)
![Framework](https://img.shields.io/badge/Framework-ESX%20Legacy-informational)
![Sprache](https://img.shields.io/badge/Sprache-Deutsch-success)

`aeth_shotalerts` erkennt Schüsse von Spielern in frei definierten Zonen und meldet sie an ausgewählte Einsatzkräfte. Die Meldungen laufen **entweder über LoveRP EmergencyDispatch oder über ox_lib** – es gibt bewusst keinen Modus für beide Systeme gleichzeitig.

## Funktionen

- Frei konfigurierbare Schussmeldezonen mit `vector3` und Radius.
- Mehrere Empfängerjobs (z. B. Polizei und Sheriff).
- Ausnahmen für Schützenjobs (z. B. Polizei und Admin).
- Serverseitige Meldepause pro Zone – standardmäßig **60 Sekunden**, unabhängig von der Anzahl der Schützen.
- **Ein** Meldesystem pro Server: `emergencydispatch` **oder** `ox`.
- Im OX-Modus: **20 Sekunden** Benachrichtigungsdauer, **E** zum Setzen eines Wegpunkts und **ENTF** zum Ablehnen.
- FIFO-Warteschlange **pro Empfänger** im OX-Modus: Die erste Meldung wird zuerst angezeigt; weitere folgen nacheinander.
- Individuelle Empfänger, zusätzliche Job-Ausnahmen und Meldepausen pro Zone.
- Konfigurierbare Waffen-Ausnahmen und Alarmposition.
- Keine eigene HTML-/NUI-Oberfläche, keine zusätzliche Datenbank, keine Versionsprüfung.

> **Hinweis:** Das Skript verarbeitet Schüsse von Spielern, nicht von NPCs. Außerhalb der eingetragenen Zonen wird keine Meldung erzeugt.

## Voraussetzungen

- FiveM-Server mit **ESX Legacy** (`es_extended`).
- Je nach Einstellung **eines** der folgenden Systeme:
  - **LoveRP EmergencyDispatch** (Ressourcenname `emergencydispatch`), **oder**
  - **ox_lib** (Ressourcenname `ox_lib`).

Das jeweils andere Meldesystem ist **nicht erforderlich**.

## Installation

1. Repository herunterladen und den Ordner als `aeth_shotalerts` in dein FiveM-`resources`-Verzeichnis kopieren.
2. Die `config.lua` bearbeiten: Meldesystem, Empfängerjobs, Job-Ausnahmen und Zonen festlegen.
3. Das ausgewählte Meldesystem **vor** `aeth_shotalerts` starten.

**Mit EmergencyDispatch:**

```cfg
ensure es_extended
ensure emergencydispatch
ensure aeth_shotalerts
```

**Mit OX-Lib:**

```cfg
ensure es_extended
ensure ox_lib
ensure aeth_shotalerts
```

## Meldesystem konfigurieren

In der `config.lua` **genau eine** Option auswählen:

```lua
Config.NotificationSystem = 'emergencydispatch'
-- oder
Config.NotificationSystem = 'ox'
```

| Einstellung | Verhalten |
| --- | --- |
| `emergencydispatch` | Erstellt über die LoveRP-EmergencyDispatch-Schnittstelle einen Einsatz pro eingetragenem Empfängerjob. |
| `ox` | Sendet OX-Lib-Benachrichtigungen mit Wegpunkt-Funktion und Warteschlange an berechtigte Spieler. |

**Ein `both`-Modus existiert nicht.** Die EmergencyDispatch-Integration ist für **LoveRP EmergencyDispatch** vorgesehen; gleichnamige andere Dispatch-Systeme sind nicht automatisch kompatibel.

## Zonen einrichten

Die folgenden Koordinaten sind **Beispiele** und müssen für deinen Server angepasst werden.

```lua
Config.ZoneCooldownSeconds = 60
Config.OnlyPublicBucket = true

Config.Zones = {
    {
        id = 'hauptplatz',
        label = 'Hauptplatz',
        coords = vector3(215.76, -925.00, 30.69),
        radius = 50.0,
        enabled = true,
    },
    {
        id = 'hafen',
        label = 'Hafen',
        coords = vector3(1200.0, -3000.0, 6.0),
        radius = 75.0,
        enabled = true,
        receiverJobs = { 'police', 'sheriff' },
        excludedShooterJobs = { 'security' },
        cooldownSeconds = 90,
    },
}
```

- `id`: Eindeutiger Zonenname für die interne Verwaltung der Meldepause.
- `label`: Name, der in der Schussmeldung erscheint.
- `coords`: Mittelpunkt der Zone als `vector3`.
- `radius`: Radius in Metern; es wird ein **3D-Abstand** berücksichtigt.
- `enabled`: `true` oder `false`.
- `receiverJobs`: Optional eigene Empfängerliste für diese Zone **anstelle** der globalen Liste.
- `excludedShooterJobs`: Optional zusätzliche Ausnahmen für diese Zone.
- `cooldownSeconds`: Optional eigene Meldepause in Sekunden.

Wenn sich zwei Zonen überschneiden, wird die passende Zone mit dem **kleineren Radius** verwendet. Jede Zone hat ihre eigene gemeinsame Meldepause. Nach Ablauf dieser Pause löst erst ein **neuer Schuss** wieder eine Meldung aus. Die Meldepausen werden nicht dauerhaft in einer Datenbank gespeichert.

## Jobs und Waffen konfigurieren

```lua
-- Welche ESX-Jobs erhalten Meldungen?
Config.ReceiverJobs = {
    'police',
    'sheriff',
}

-- Welche Jobs lösen durch eigene Schüsse keine Meldung aus?
Config.ExcludedShooterJobs = {
    'police',
    'admin',
}

-- Diese Waffen werden bei der Erkennung ignoriert:
Config.IgnoredWeapons = {
    'WEAPON_STUNGUN',
    'WEAPON_FLAREGUN',
}

Config.AlertMessage = 'Schüsse im Bereich %s gemeldet.'
Config.AlertPosition = 'shot' -- 'shot' oder 'center'
```

Die Jobnamen müssen mit den tatsächlichen **ESX-Jobnamen** übereinstimmen. Ausgeschlossene Schützen können weiterhin selbst Meldungen empfangen, sofern ihr Job als Empfänger eingetragen ist.

Mit `Config.AlertPosition = 'shot'` wird die Position des Schützen gemeldet; mit `'center'` der Mittelpunkt der betroffenen Zone.

## OX-Lib-Modus: Meldungen und Bedienung

```lua
Config.Ox = {
    DurationMs = 20000,       -- 20 Sekunden
    Title = 'Schussmeldung',
    Position = 'top-right',
    Type = 'warning',
    Icon = 'gun',
    AcceptKey = 'E',
    RejectKey = 'DELETE',     -- ENTF
}
```

**Beispiel einer Meldung:**

> **Schussmeldung**  
> Schüsse im Bereich Hauptplatz gemeldet.  
> **E:** Wegpunkt setzen | **ENTF:** Ablehnen

**Verhalten der Warteschlange:**

1. Die zuerst eingetroffene Meldung wird angezeigt und erhält ihre vollen **20 Sekunden**.
2. Während dieser Zeit setzt **E** einen Wegpunkt zur gemeldeten Position; **ENTF** lehnt die Meldung ab.
3. Nach einer Entscheidung kann dieselbe Meldung nicht erneut bearbeitet werden.
4. Neue Meldungen aus anderen Zonen werden pro Empfänger in einer **FIFO-Warteschlange** gesammelt.
5. Die nächste Meldung erscheint erst nach Ende der **vollständigen Anzeigedauer** der vorherigen Meldung und erhält ebenfalls ihre vollen 20 Sekunden.

**Wichtig:** Da OX-Lib für diese Benachrichtigungen keine vorzeitige Schließen-Funktion bereitstellt, bleibt die Anzeige auch nach **E** oder **ENTF** bis zum Ablauf ihrer Dauer sichtbar. Die Aktion selbst wird sofort ausgeführt. Die Tastenbelegung erfolgt über **FiveM-Keymapping** und kann in den FiveM-Tastatureinstellungen angepasst werden.

Die **60-Sekunden-Zonensperre** gilt unabhängig von den **20 Sekunden Anzeigedauer**.

## Weitere Einstellungen

```lua
-- Zusätzliche Entprellung, damit nicht pro Schuss mehrere Anfragen entstehen:
Config.ClientShotDebounceMs = 1200
Config.ServerRequestDebounceMs = 1200

-- Optional: Nur Spieler in Routing Bucket 0 können Alarme auslösen.
Config.OnlyPublicBucket = true
```

## Fehlerbehebung

| Problem | Prüfen |
| --- | --- |
| Keine Meldung beim Schießen | Ist der Spieler in einer aktivierten Zone? Ist sein Job ausgeschlossen? Ist `OnlyPublicBucket` aktiv? |
| Keine Meldung an die Polizei | Sind die ESX-Empfängerjobs richtig eingetragen? |
| Meldung erst später | Die Zone kann noch in ihrer Meldepause sein. Im OX-Modus können außerdem vorherige Meldungen in der Warteschlange stehen. |
| OX-Tasten reagieren nicht | Ist eine aktive und unbearbeitete Meldung vorhanden? Stimmen die FiveM-Tastenbelegungen? |
| EmergencyDispatch erhält keine Einsätze | Handelt es sich um **LoveRP EmergencyDispatch**? Ist `emergencydispatch` gestartet? |
| Fehlermeldung zum Meldesystem | In `Config.NotificationSystem` ausschließlich `ox` oder `emergencydispatch` eintragen. |

## Projekt und Urheber

**AETHRALETH** – FiveM-Skripte und Ressourcen.

- [GitHub-Repository](https://github.com/Aethraleth/aeth_shotalerts)
- [Fehler melden / Vorschläge](https://github.com/Aethraleth/aeth_shotalerts/issues)

© 2026 AETHRALETH. Weiterverkauf und die Ausgabe des Skripts als eigene Entwicklung sind nicht gestattet. **Die vollständigen Nutzungsbedingungen sollten zusätzlich in einer separaten `LICENSE`-Datei geregelt werden.**
