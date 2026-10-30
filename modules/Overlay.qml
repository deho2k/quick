import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    property real cpuPercent: 0
    property real ramPercent: 0
    property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")
    property bool isFullscreen: false

    property real prevTotal: 0
    property real prevIdle: 0

    // --- MEDIA & LYRICS STATE ---
    property MprisPlayer activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property string trackTitle: (activePlayer && activePlayer.trackTitle) ? activePlayer.trackTitle : "No Media Playing"
    property string trackArtist: (activePlayer && activePlayer.trackArtist) ? activePlayer.trackArtist : "Waiting for audio..."
    property string trackArt: (activePlayer && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl : ""

    property real currentPosSec: 0
    property real trackLengthSec: {
        if (!activePlayer || activePlayer.length <= 0) return 0
        // Handle players reporting microseconds vs seconds
        return activePlayer.length > 100000 ? activePlayer.length / 1000000.0 : activePlayer.length
    }
    property real trackProgress: trackLengthSec > 0
                                 ? root.clamp(currentPosSec / trackLengthSec, 0.0, 1.0)
                                 : 0.0

    property var lyricsList: []       // Array of { time: seconds, text: "lyric line" }
    property string prevLyric: ""
    property string currentLyric: ""
    property string nextLyric: ""
    property string lastFetchedTrack: ""

    function clamp(val, min, max) {
        return Math.max(min, Math.min(max, val))
    }

    // Parse "[mm:ss.xx] lyric text" from LRCLIB into sorted array
    function parseLrc(lrcText) {
        let lines = lrcText.split("\n")
        let parsed = []
        let regex = /\[(\d{2}):(\d{2}(?:\.\d+)?)\](.*)/

        for (let i = 0; i < lines.length; i++) {
            let match = regex.exec(lines[i])
            if (match) {
                let mins = parseInt(match[1], 10)
                let secs = parseFloat(match[2])
                let txt = match[3].trim()
                if (txt.length > 0) {
                    parsed.push({ time: mins * 60 + secs, text: txt })
                }
            }
        }
        parsed.sort((a, b) => a.time - b.time)
        root.lyricsList = parsed
        updateCurrentLyric()
    }

    // Binary/linear scan for the active lyric at currentPosSec
    function updateCurrentLyric() {
        if (!root.lyricsList || root.lyricsList.length === 0) {
            return
        }
        let idx = -1
        for (let i = 0; i < root.lyricsList.length; i++) {
            if (root.currentPosSec >= root.lyricsList[i].time - 0.15) {
                idx = i
            } else {
                break
            }
        }
        if (idx >= 0) {
            root.prevLyric = idx > 0 ? root.lyricsList[idx - 1].text : ""
            root.currentLyric = root.lyricsList[idx].text
            root.nextLyric = (idx + 1 < root.lyricsList.length) ? root.lyricsList[idx + 1].text : ""
        } else {
            root.prevLyric = ""
            root.currentLyric = "♪  • • •"
            root.nextLyric = root.lyricsList[0].text
        }
    }

    // Trigger lyrics fetch whenever song changes
    onTrackTitleChanged: checkAndFetchLyrics()
    onTrackArtistChanged: checkAndFetchLyrics()

    function checkAndFetchLyrics() {
        let key = root.trackTitle.trim() + "||" + root.trackArtist.trim()
        if (root.trackTitle === "No Media Playing" || root.trackTitle.trim() === "") {
            root.lyricsList = []
            root.prevLyric = ""
            root.currentLyric = ""
            root.nextLyric = ""
            root.lastFetchedTrack = ""
            return
        }
        if (key !== root.lastFetchedTrack) {
            root.lastFetchedTrack = key
            root.lyricsList = []
            root.prevLyric = ""
            root.currentLyric = "Searching lyrics..."
            root.nextLyric = ""
            lyricsProc.running = false
            lyricsProc.running = true
        }
    }

    // Helper to draw circular CPU/RAM rings
    function drawRing(canvas, percent, arcColor) {
        var ctx = canvas.getContext("2d")
        ctx.reset()

        var w = canvas.width
        var h = canvas.height
        if (w <= 0 || h <= 0) return

        var cx = w / 2
        var cy = h / 2
        var stroke = Math.max(2.2, w * 0.12)
        var r = (Math.min(w, h) / 2) - (stroke / 2) - 0.5
        var startAngle = -Math.PI / 2
        var endAngle = startAngle + (Math.PI * 2 * (root.clamp(percent, 0, 100) / 100.0))

        ctx.beginPath()
        ctx.arc(cx, cy, Math.max(1, r - stroke * 0.4), 0, Math.PI * 2)
        ctx.fillStyle = "#99181825"
        ctx.fill()

        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.lineWidth = stroke
        ctx.strokeStyle = "#313244"
        ctx.stroke()

        if (percent > 0.5) {
            ctx.beginPath()
            ctx.arc(cx, cy, r, startAngle, endAngle, false)
            ctx.lineWidth = stroke
            ctx.lineCap = "round"
            ctx.strokeStyle = arcColor
            ctx.stroke()
        }
    }

    // 1. System stats & fullscreen check (every 1s)
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentTime = Qt.formatDateTime(new Date(), "HH:mm")
            stateProc.running = true
        }
    }

    // 2. High-frequency playback position & lyric sync timer (every 400ms)
    Timer {
        interval: 400
        running: root.isFullscreen && root.activePlayer !== null
        repeat: true
        onTriggered: {
            posProc.running = true
        }
    }

    Process {
        id: stateProc
        command: [
            "sh", "-c",
            "FS=$(hyprctl activewindow -j | grep -q '\"fullscreen\": [123]' && echo 1 || echo 0); " +
            "CPU=$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat); " +
            "RAM=$(free | awk '/Mem:/ {printf \"%.0f\", $3*100/$2}'); " +
            "echo \"$FS|$CPU|$RAM\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("|")
                if (parts.length === 3) {
                    root.isFullscreen = (parts[0] === "1")

                    let cpuParts = parts[1].trim().split(" ")
                    if (cpuParts.length === 2) {
                        let total = parseFloat(cpuParts[0])
                        let idle = parseFloat(cpuParts[1])
                        let dTotal = total - root.prevTotal
                        let dIdle = idle - root.prevIdle
                        if (dTotal > 0 && root.prevTotal > 0) {
                            root.cpuPercent = root.clamp(((dTotal - dIdle) / dTotal) * 100.0, 0, 100)
                        }
                        root.prevTotal = total
                        root.prevIdle = idle
                    }

                    root.ramPercent = root.clamp(parseFloat(parts[2]) || 0, 0, 100)
                }
            }
        }
    }

    // Poll accurate track position in seconds
    Process {
        id: posProc
        command: ["sh", "-c", "playerctl position 2>/dev/null || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = parseFloat(this.text.trim())
                if (!isNaN(p) && p >= 0) {
                    root.currentPosSec = p
                } else if (root.activePlayer) {
                    let raw = root.activePlayer.position
                    root.currentPosSec = raw > 100000 ? raw / 1000000.0 : raw
                }
                root.updateCurrentLyric()
            }
        }
    }

    // Fetch synced lyrics from LRCLIB API using curl + jq
    Process {
        id: lyricsProc
        command: [
            "sh", "-c",
            "T=\"$1\"; A=\"$2\"; " +
            "RES=$(curl -sG 'https://lrclib.net/api/search' --data-urlencode \"track_name=$T\" --data-urlencode \"artist_name=$A\" | jq -r '[.[] | select(.syncedLyrics != null and .syncedLyrics != \"\")][0].syncedLyrics // empty' 2>/dev/null); " +
            "if [ -z \"$RES\" ]; then " +
            "  RES=$(curl -sG 'https://lrclib.net/api/search' --data-urlencode \"q=$T $A\" | jq -r '[.[] | select(.syncedLyrics != null and .syncedLyrics != \"\")][0].syncedLyrics // empty' 2>/dev/null); " +
            "fi; " +
            "printf \"%s\" \"$RES\"",
            "--",
            root.trackTitle,
            root.trackArtist === "Waiting for audio..." ? "" : root.trackArtist
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lrc = this.text.trim()
                if (lrc.length > 0 && lrc !== "null") {
                    root.parseLrc(lrc)
                } else {
                    root.lyricsList = []
                    root.prevLyric = ""
                    root.currentLyric = "No synced lyrics found"
                    root.nextLyric = ""
                }
            }
        }
    }

    PanelWindow {
        id: overlayWindow

        visible: root.isFullscreen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-game-overlay"
        exclusionMode: ExclusionMode.Ignore

        mask: Region {
            item: hudCard
        }

        property bool initializedPos: false
        onWidthChanged: {
            if (!initializedPos && width > 0) {
                hudCard.x = width - hudCard.width - 24
                hudCard.y = 24
                initializedPos = true
            }
        }

        Rectangle {
            id: hudCard

            x: 24
            y: 24
            width: 380
            height: 124

            readonly property int minWidth: 220
            readonly property int minHeight: 40

            readonly property string layoutMode: {
                if (height < 72) return "compact"
                if (height > width * 0.85 && height >= 170) return "vertical"
                return "standard"
            }

            readonly property real baseScale: Math.min(width / 360.0, height / 120.0)
            readonly property real vertScale: Math.min(width / 230.0, height / 320.0)

            radius: layoutMode === "compact"
                    ? Math.round(root.clamp(height * 0.28, 10, 18))
                    : Math.round(root.clamp(Math.min(width, height) * 0.14, 12, 24))

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#F211111B" }
                GradientStop { position: 1.0; color: "#E61E1E2E" }
            }

            border.color: (dragArea.pressed || resizeArea.pressed)
                          ? "#CBA6F7"
                          : (dragArea.containsMouse ? "#585B70" : "#45475A")
            border.width: (dragArea.pressed || resizeArea.pressed) ? 2 : 1

            // --- 1. DRAG AREA ---
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: hudCard
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: overlayWindow.width - hudCard.width
                drag.minimumY: 0
                drag.maximumY: overlayWindow.height - hudCard.height
            }

            // =========================================================================
            // MODE A: SUPER SHORT HORIZONTAL BAR MODE (height < 72)
            // =========================================================================
            RowLayout {
                id: compactLayout
                visible: hudCard.layoutMode === "compact"
                anchors.fill: parent

                readonly property int pad: Math.max(5, Math.round(hudCard.height * 0.12))
                readonly property int innerRadius: Math.max(4, hudCard.radius - pad)
                readonly property int innerHeight: hudCard.height - (pad * 2)

                anchors.topMargin: pad
                anchors.bottomMargin: pad
                anchors.leftMargin: pad
                anchors.rightMargin: Math.max(pad + 14, Math.round(hudCard.height * 0.34))
                spacing: Math.round(root.clamp(hudCard.height * 0.18, 8, 14))

                // Rounded Album Thumbnail matching outer border curve
                ClippingRectangle {
                    Layout.preferredWidth: compactLayout.innerHeight
                    Layout.preferredHeight: compactLayout.innerHeight
                    Layout.alignment: Qt.AlignVCenter
                    radius: compactLayout.innerRadius
                    color: "#181825"
                    border.color: hudCard.border.color
                    border.width: 1

                    Image {
                        id: compactArtImg
                        anchors.fill: parent
                        source: root.trackArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !compactArtImg.visible
                        text: "♫"
                        font.pixelSize: Math.round(parent.height * 0.46)
                        color: "#CBA6F7"
                    }
                }

                // Vertically Centered Track Title + Live Lyric Line
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackArtist !== "Waiting for audio..."
                              ? (root.trackTitle + "  —  " + root.trackArtist)
                              : root.trackTitle
                        color: "#CDD6F4"
                        font.pixelSize: Math.round(root.clamp(hudCard.height * 0.25, 10, 16))
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.currentLyric !== "" && hudCard.height >= 44
                        text: "♪ " + root.currentLyric
                        color: "#CBA6F7"
                        font.pixelSize: Math.round(root.clamp(hudCard.height * 0.22, 9, 14))
                        font.italic: true
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }
                }

                // Right-Side Circular CPU/RAM Gauges + Time
                RowLayout {
                    visible: hudCard.width >= 260
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Math.round(root.clamp(hudCard.height * 0.14, 6, 12))

                    readonly property int ringDiam: Math.max(22, Math.round(compactLayout.innerHeight * 0.90))

                    Item {
                        Layout.preferredWidth: parent.ringDiam
                        Layout.preferredHeight: parent.ringDiam
                        width: parent.ringDiam
                        height: parent.ringDiam

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            property real val: root.cpuPercent
                            onValChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onPaint: root.drawRing(this, val, "#89DCEB")
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: "#CDD6F4"
                            font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                            font.bold: true
                        }
                    }

                    Item {
                        Layout.preferredWidth: parent.ringDiam
                        Layout.preferredHeight: parent.ringDiam
                        width: parent.ringDiam
                        height: parent.ringDiam

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            property real val: root.ramPercent
                            onValChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onPaint: root.drawRing(this, val, "#F9E2AF")
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "☰"
                            color: "#CDD6F4"
                            font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                            font.bold: true
                        }
                    }

                    Text {
                        visible: hudCard.width >= 320
                        text: root.currentTime
                        color: "#BAC2DE"
                        font.pixelSize: Math.round(root.clamp(hudCard.height * 0.24, 10, 15))
                        font.family: "monospace"
                        font.bold: true
                    }
                }
            }

            // =========================================================================
            // MODE B: STANDARD HORIZONTAL HUD MODE
            // =========================================================================
            RowLayout {
                id: stdLayout
                visible: hudCard.layoutMode === "standard"
                anchors.fill: parent

                readonly property int pad: Math.round(root.clamp(Math.min(hudCard.width, hudCard.height) * 0.10, 10, 22))
                anchors.topMargin: pad
                anchors.bottomMargin: pad
                anchors.leftMargin: pad
                anchors.rightMargin: pad + 6
                spacing: Math.round(pad * 1.1)

                ClippingRectangle {
                    readonly property int artSize: Math.round(Math.min(hudCard.height - (stdLayout.pad * 2), hudCard.width * 0.36))
                    Layout.preferredWidth: artSize
                    Layout.preferredHeight: artSize
                    Layout.alignment: Qt.AlignVCenter
                    radius: Math.max(6, hudCard.radius - stdLayout.pad)
                    color: "#181825"
                    border.color: hudCard.border.color
                    border.width: 1

                    Image {
                        id: stdArtImg
                        anchors.fill: parent
                        source: root.trackArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !stdArtImg.visible
                        text: "♫"
                        font.pixelSize: Math.round(parent.height * 0.46)
                        color: "#CBA6F7"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(root.clamp(hudCard.height * 0.03, 2, 6))

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Math.round(root.clamp(hudCard.height * 0.015, 1, 4))

                        Item { Layout.fillHeight: true }

                        // Track Title
                        Text {
                            Layout.fillWidth: true
                            text: root.trackTitle
                            color: "#CDD6F4"
                            font.pixelSize: Math.round(root.clamp(15 * hudCard.baseScale, 12, 30))
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        // Artist Name
                        Text {
                            Layout.fillWidth: true
                            text: root.trackArtist
                            color: "#7F849C"
                            font.pixelSize: Math.round(root.clamp(11.5 * hudCard.baseScale, 9, 20))
                            elide: Text.ElideRight
                        }

                        // Active Synced Lyric Line (Highlighted)
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            visible: root.currentLyric !== ""
                            text: "♪ " + root.currentLyric
                            color: "#CBA6F7"
                            font.pixelSize: Math.round(root.clamp(13 * hudCard.baseScale, 10, 24))
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // Track Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: Math.round(root.clamp(3.5 * hudCard.baseScale, 2, 6))
                        radius: height / 2
                        color: "#313244"
                        visible: hudCard.height >= 92

                        Rectangle {
                            width: parent.width * root.trackProgress
                            height: parent.height
                            radius: parent.radius
                            color: "#CBA6F7"
                        }
                    }

                    // Secondary Row: Circular CPU/RAM Gauges + Clock
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(root.clamp(8 * hudCard.baseScale, 6, 14))

                        readonly property int ringDiam: Math.round(root.clamp(24 * hudCard.baseScale, 18, 40))

                        Item {
                            Layout.preferredWidth: parent.ringDiam
                            Layout.preferredHeight: parent.ringDiam
                            width: parent.ringDiam
                            height: parent.ringDiam

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                property real val: root.cpuPercent
                                onValChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: root.drawRing(this, val, "#89DCEB")
                            }
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#CDD6F4"
                                font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                                font.bold: true
                            }
                        }

                        Item {
                            Layout.preferredWidth: parent.ringDiam
                            Layout.preferredHeight: parent.ringDiam
                            width: parent.ringDiam
                            height: parent.ringDiam

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                property real val: root.ramPercent
                                onValChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: root.drawRing(this, val, "#F9E2AF")
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "☰"
                                color: "#CDD6F4"
                                font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: Math.round(parent.ringDiam * 0.82)
                            Layout.preferredWidth: stdTimeTxt.implicitWidth + Math.round(parent.ringDiam * 0.6)
                            radius: height / 2
                            color: "#80181825"
                            border.color: "#313244"
                            border.width: 1

                            Text {
                                id: stdTimeTxt
                                anchors.centerIn: parent
                                text: root.currentTime
                                color: "#BAC2DE"
                                font.pixelSize: Math.round(root.clamp(10.5 * hudCard.baseScale, 9, 17))
                                font.family: "monospace"
                                font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // =========================================================================
            // MODE C: LONG VERTICAL / KARAOKE CARD MODE
            // =========================================================================
            ColumnLayout {
                id: vertLayout
                visible: hudCard.layoutMode === "vertical"
                anchors.fill: parent

                readonly property int pad: Math.round(root.clamp(hudCard.width * 0.07, 12, 24))
                anchors.margins: pad
                spacing: Math.round(root.clamp(hudCard.height * 0.02, 4, 12))

                // Rounded Album Thumbnail
                ClippingRectangle {
                    readonly property int maxArtH: Math.round(hudCard.height * 0.38)
                    readonly property int maxArtW: hudCard.width - (vertLayout.pad * 2)
                    readonly property int artBoxSize: Math.min(maxArtW, maxArtH)

                    Layout.preferredWidth: artBoxSize
                    Layout.preferredHeight: artBoxSize
                    Layout.alignment: Qt.AlignHCenter
                    radius: Math.max(8, hudCard.radius - Math.round(vertLayout.pad * 0.5))
                    color: "#181825"
                    border.color: hudCard.border.color
                    border.width: 1

                    Image {
                        id: vertArtImg
                        anchors.fill: parent
                        source: root.trackArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !vertArtImg.visible
                        text: "♫"
                        font.pixelSize: Math.round(parent.height * 0.46)
                        color: "#CBA6F7"
                    }
                }

                // Track Title & Artist Header
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle
                        color: "#CDD6F4"
                        font.pixelSize: Math.round(root.clamp(15 * hudCard.vertScale, 12, 24))
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackArtist
                        color: "#7F849C"
                        font.pixelSize: Math.round(root.clamp(11.5 * hudCard.vertScale, 10, 18))
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                // 3-Line Karaoke Lyrics Box (Prev, Current, Next)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: "#66181825"
                    border.color: "#313244"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Item { Layout.fillHeight: true }

                        // Previous Lyric (Dimmed)
                        Text {
                            Layout.fillWidth: true
                            visible: root.prevLyric !== ""
                            text: root.prevLyric
                            color: "#585B70"
                            font.pixelSize: Math.round(root.clamp(11 * hudCard.vertScale, 9, 16))
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // Active Lyric (Bright & Bold, wraps up to 2 lines)
                        Text {
                            Layout.fillWidth: true
                            text: root.currentLyric !== "" ? root.currentLyric : "♪ • • •"
                            color: "#CBA6F7"
                            font.pixelSize: Math.round(root.clamp(13.5 * hudCard.vertScale, 11, 22))
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Next Lyric (Preview)
                        Text {
                            Layout.fillWidth: true
                            visible: root.nextLyric !== ""
                            text: root.nextLyric
                            color: "#6C7086"
                            font.pixelSize: Math.round(root.clamp(11 * hudCard.vertScale, 9, 16))
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(vertLayout.pad * 0.3)
                    Layout.rightMargin: Math.round(vertLayout.pad * 0.3)
                    height: Math.round(root.clamp(3.5 * hudCard.vertScale, 3, 6))
                    radius: height / 2
                    color: "#313244"

                    Rectangle {
                        width: parent.width * root.trackProgress
                        height: parent.height
                        radius: parent.radius
                        color: "#CBA6F7"
                    }
                }

                // Bottom Circular Gauges + Time Row
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(root.clamp(12 * hudCard.vertScale, 8, 18))

                    readonly property int ringDiam: Math.round(root.clamp(26 * hudCard.vertScale, 22, 38))

                    Item {
                        Layout.preferredWidth: parent.ringDiam
                        Layout.preferredHeight: parent.ringDiam
                        width: parent.ringDiam
                        height: parent.ringDiam

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            property real val: root.cpuPercent
                            onValChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onPaint: root.drawRing(this, val, "#89DCEB")
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: "#CDD6F4"
                            font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: Math.round(parent.ringDiam * 0.82)
                        Layout.preferredWidth: vertTimeTxt.implicitWidth + Math.round(parent.ringDiam * 0.7)
                        radius: height / 2
                        color: "#80181825"
                        border.color: "#313244"
                        border.width: 1

                        Text {
                            id: vertTimeTxt
                            anchors.centerIn: parent
                            text: root.currentTime
                            color: "#BAC2DE"
                            font.pixelSize: Math.round(root.clamp(11 * hudCard.vertScale, 9, 17))
                            font.family: "monospace"
                            font.bold: true
                        }
                    }

                    Item {
                        Layout.preferredWidth: parent.ringDiam
                        Layout.preferredHeight: parent.ringDiam
                        width: parent.ringDiam
                        height: parent.ringDiam

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            property real val: root.ramPercent
                            onValChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onPaint: root.drawRing(this, val, "#F9E2AF")
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "☰"
                            color: "#CDD6F4"
                            font.pixelSize: Math.max(8, Math.round(parent.width * 0.38))
                            font.bold: true
                        }
                    }
                }
            }

            // --- 3. RESIZE GRIP (Bottom-Right Corner) ---
            Item {
                width: 24
                height: 24
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: hudCard.layoutMode === "compact" ? 7 : 5
                    anchors.bottomMargin: hudCard.layoutMode === "compact" ? 3 : 2
                    text: "◢"
                    font.pixelSize: 10
                    color: resizeArea.containsMouse || resizeArea.pressed ? "#CBA6F7" : "#585B70"
                }

                MouseArea {
                    id: resizeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeFDiagCursor

                    property real startMouseX: 0
                    property real startMouseY: 0
                    property real startWidth: 0
                    property real startHeight: 0

                    onPressed: (mouse) => {
                        let globalPos = resizeArea.mapToItem(overlayWindow.contentItem, mouse.x, mouse.y)
                        startMouseX = globalPos.x
                        startMouseY = globalPos.y
                        startWidth = hudCard.width
                        startHeight = hudCard.height
                    }

                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            let globalPos = resizeArea.mapToItem(overlayWindow.contentItem, mouse.x, mouse.y)
                            let dx = globalPos.x - startMouseX
                            let dy = globalPos.y - startMouseY

                            hudCard.width = Math.max(hudCard.minWidth, Math.min(overlayWindow.width - hudCard.x, startWidth + dx))
                            hudCard.height = Math.max(hudCard.minHeight, Math.min(overlayWindow.height - hudCard.y, startHeight + dy))
                        }
                    }
                }
            }
        }
    }
}
