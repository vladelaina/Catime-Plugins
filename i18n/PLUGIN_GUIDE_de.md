# Catime Plugin-Anleitung

## Was ist ein Plugin?

Ein Plugin ist eine Skriptdatei, die benutzerdefinierte Inhalte im Catime-Fenster anzeigt. Zum Beispiel:

- 📺 Ihre Bilibili/YouTube-Videostatistiken
- 📈 Echtzeit-NASDAQ- und S&P 500-Indizes
- 🌤️ Lokale Wettervorhersage
- 🌐 Ihre Website-Besucherstatistiken
- 💻 Serverstatus
- ……

**Kernkonzept: Alle Daten, die Ihr Skript abrufen kann, können im Catime-Fenster angezeigt werden!**

Außerdem können diese Daten überall auf Ihrem Bildschirm platziert und beliebig skaliert werden, genau wie die Zeitanzeige von Catime — immer sichtbar, ohne andere Fenster zu verdecken.

**So funktioniert es:** Ihr Skript schreibt in `output.txt` → Catime liest es → Zeigt es im Fenster an. So einfach!

> **Tipp:** Stellen Sie sicher, dass die erforderliche Laufzeitumgebung installiert ist (z.B. Python, Node.js usw.)

---

## 30-Sekunden-Schnellstart

Möchten Sie keinen Code schreiben? Probieren Sie es zuerst manuell aus:

### Schritt 1: Plugin-Ordner öffnen

Rechtsklick auf Catime-Tray-Symbol → `Plugins` → `Plugin-Ordner öffnen`

### Schritt 2: output.txt bearbeiten

Finden (oder erstellen) Sie `output.txt` im Ordner und schreiben Sie etwas:

```
Hallo, Catime!
Das ist meine erste Nachricht 🎉
```

### Schritt 3: Dateiinhalt anzeigen

Rechtsklick auf Catime-Tray-Symbol → `Plugins` → `Plugin-Datei anzeigen`

**Fertig!** Das Catime-Fenster zeigt jetzt Ihren Inhalt.

> Das ist das Wesentliche von Plugins: **Was Sie in output.txt schreiben, erscheint im Fenster**.
> Plugin-Skripte automatisieren nur diesen Prozess.

---

## Erstellen Sie Ihr erstes Plugin in 3 Schritten

### Schritt 1: Plugin-Ordner öffnen

Rechtsklick auf Catime-Tray-Symbol → `Plugins` → `Plugin-Ordner öffnen`

### Schritt 2: Skriptdatei erstellen

Erstellen Sie eine neue Datei in diesem Ordner, z.B. `hello.py`:

```python
with open('output.txt', 'w', encoding='utf-8') as f:
    f.write('Hallo, Catime!')
```

**Nur ein paar Zeilen!**

### Schritt 3: Plugin ausführen

1. Rechtsklick auf Catime-Tray-Symbol
2. `Plugins` → Klicken Sie auf `hello.py`
3. Beim ersten Mal werden Sie gefragt, ob Sie vertrauen, klicken Sie auf "Vertrauen und Ausführen"

**Fertig!** Das Fenster zeigt jetzt "Hallo, Catime!"

---

## Kernpunkt

Was auch immer Ihr Skript in `output.txt` schreibt, Catime zeigt es an. Die Anzeige aktualisiert sich automatisch, wenn die Datei aktualisiert wird.

---

## Spezielle Tags (Optional)

Verwenden Sie diese Tags bei Bedarf:

| Tag | Funktion | Beispiel |
|-----|----------|----------|
| `<md></md>` | Markdown-Formatierung aktivieren | `<md>**fett** *kursiv*</md>` |
| `<catime></catime>` | Timer-Zeit anzeigen | `Läuft <catime></catime>` → `Läuft 00:05:30` |
| `<exit>N</exit>` | Plugin nach N Sekunden automatisch schließen | `<exit>5</exit>` → schließt nach 5 Sekunden |
| `<fps:N>` | N-mal pro Sekunde aktualisieren (Standard 2, Bereich 1-100) | `<fps:10>` → 10 Aktualisierungen pro Sekunde |
| `<color:Wert></color>` | Textfarbe festlegen (unterstützt Farbverläufe) | `<color:#FF0000>rot</color>` |
| `<font:Pfad></font>` | Schriftart festlegen (Schriftdateipfad) | `<font:C:\Windows\Fonts\comic.ttf>lustig</font>` |
| `![](Pfad)` | Bild anzeigen (lokaler Pfad oder URL) | `![](wetter.png)` oder `![](https://example.com/img.png)` |
| `![BxH](Pfad)` | Bild mit bestimmter Größe anzeigen | `![100x50](logo.png)` oder `![200](logo.png)` (nur Breite) |

> **Über `<fps:N>`:** Standard-Aktualisierung ist alle 500ms (2-mal pro Sekunde). Für schnell aktualisierende Daten erhöhen Sie die Rate bis zu `<fps:100>` (100-mal pro Sekunde).

> **Über Farbe und Schriftart:** Diese Tags funktionieren eigenständig (kein `<md>` erforderlich) und können verschachtelt werden. Schriftpfade unterstützen absolute Pfade (z.B. `C:\Windows\Fonts\arial.ttf`), Umgebungsvariablen (z.B. `%WINDIR%\Fonts\arial.ttf`) oder Pfade relativ zum Plugin-Verzeichnis.

---

## Unterstützte Sprachen

Python, PowerShell, Batch, JavaScript... sogar Shell, Ruby, PHP, Lua und **90+ Sprachen** werden unterstützt! Solange Sie den Interpreter installiert haben, funktioniert jede Sprache.

> **Empfohlen:** Verwenden Sie **PowerShell (.ps1)** oder **Batch (.bat)** — in Windows integriert, keine Installation erforderlich, geringerer Ressourcenverbrauch.

---

## Ist es sicher?

Beim ersten Ausführen eines Plugins fragt Catime:

- **Abbrechen** = Nicht ausführen
- **Einmal ausführen** = Nur dieses Mal ausführen, wird beim nächsten Mal erneut fragen
- **Vertrauen und Ausführen** = Immer automatisch ausführen

Wenn Sie eine Plugin-Datei ändern, fragt Catime erneut, um Manipulation zu verhindern.

---

## FAQ

### Plugin zeigt keinen Inhalt?

Überprüfen Sie:
- Dateipfad ist korrekt (Skript sollte in `output.txt` im selben Verzeichnis schreiben)
- Interpreter ist installiert (z.B. Python-Skripte benötigen Python)

### Wie stoppt man ein Plugin?

Rechtsklick auf Tray-Symbol → Plugins → Klicken Sie erneut auf das laufende Plugin (markiert mit ✓)

### Neustart nach Bearbeitung erforderlich?

Nein! Catime erkennt Änderungen automatisch und führt das Plugin erneut aus (Hot Reload).

### Kann ich mehrere Plugins ausführen?

Nein, nur eines gleichzeitig. Klicken Sie auf ein anderes Plugin zum Wechseln; das aktuelle stoppt automatisch.

### Laufen Plugins weiter nach dem Schließen von Catime?

Nein. Catime stoppt alle Plugin-Prozesse beim Schließen.

---

## Hinweise

⚠️ **Vermeiden Sie verschachtelte Unterprozesse**

Verwenden Sie einen einzelnen Prozess, um Aufgaben abzuschließen. Wenn Ihr Skript Unterprozesse startet (z.B. mit `start` in `.bat`), werden diese möglicherweise nicht ordnungsgemäß bereinigt.

---

**Das war's! Erstellen Sie jetzt Ihr erstes Plugin!** 🚀
