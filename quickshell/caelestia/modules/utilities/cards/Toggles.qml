pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    property bool wifiExpanded: false
    property bool btExpanded: false

    readonly property var activeMonitor: Brightness.getMonitor("active") ?? (Brightness.monitors.length > 0 ? Brightness.monitors[0] : null)

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Process {
        id: sunsetProc
        command: ["bash", "-c", "$HOME/.config/hypr/scripts/Hyprsunset.sh"]
    }

    Process {
        id: frostyProc
        command: ["frosty-settings"]
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Header: Title and Quick Launchers
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "tune"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Control Center")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            Item { Layout.fillWidth: true }

            IconButton {
                icon: "settings"
                inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: {
                    root.screenState.utilities = false;
                    WindowFactory.create();
                }
            }

            IconButton {
                icon: "palette"
                inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: {
                    root.screenState.utilities = false;
                    frostyProc.running = true;
                }
            }

            IconButton {
                icon: "power_settings_new"
                inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                inactiveOnColour: Colours.palette.m3error
                onClicked: {
                    root.screenState.utilities = false;
                    root.screenState.session = true;
                }
            }
        }

        // ================= Wi-Fi Card =================
        StyledRect {
            id: wifiCard
            Layout.fillWidth: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh
            border.width: 1
            border.color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    // Wi-Fi Power Circle Button
                    StyledRect {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Tokens.rounding.full
                        color: Nmcli.wifiEnabled ? (Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer) : Colours.palette.m3surfaceContainerHighest

                        StateLayer {
                            radius: Tokens.rounding.full
                            onClicked: Nmcli.toggleWifi()
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: !Nmcli.wifiEnabled ? "wifi_off" : (Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength) : "wifi_find")
                            color: Nmcli.wifiEnabled ? (Nmcli.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer) : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    // Network Info & Status (Clickable to toggle expansion)
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: wifiInfoCol.implicitHeight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiExpanded = !root.wifiExpanded
                        }

                        ColumnLayout {
                            id: wifiInfoCol
                            anchors.fill: parent
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.extraSmall
                                StyledText {
                                    text: Tr.tr("Wi-Fi")
                                    font: Tokens.font.body.medium
                                    color: Colours.palette.m3onSurface
                                }
                                MaterialIcon {
                                    visible: Nmcli.active?.isSecure ?? false
                                    text: "lock"
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3outline
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: {
                                    if (!Nmcli.wifiEnabled) return Tr.tr("Disabled");
                                    if (Nmcli.active) return Nmcli.active.ssid || Nmcli.active.name || Tr.tr("Connected");
                                    if (Nmcli.activeEthernet) return Nmcli.activeEthernet.name || Tr.tr("Ethernet");
                                    if (Nmcli.scanning) return Tr.tr("Scanning...");
                                    return Tr.tr("Disconnected");
                                }
                                font: Tokens.font.label.medium
                                color: Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    // Expand Arrow Button
                    IconButton {
                        icon: root.wifiExpanded ? "expand_less" : "expand_more"
                        inactiveColour: root.wifiExpanded ? Colours.palette.m3secondaryContainer : "transparent"
                        inactiveOnColour: root.wifiExpanded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        onClicked: root.wifiExpanded = !root.wifiExpanded
                    }
                }

                // Inline Expandable Networks Drawer
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.wifiExpanded
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.4
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Nearby Networks")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        IconButton {
                            icon: Nmcli.scanning ? "sync" : "refresh"
                            onClicked: Nmcli.rescanWifi()
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: {
                                if (!Nmcli.wifiEnabled) return [];
                                const seen = new Set();
                                return [...Nmcli.networks].filter(n => {
                                    if (!n.ssid || seen.has(n.ssid)) return false;
                                    seen.add(n.ssid);
                                    return true;
                                }).sort((a, b) => (b.active - a.active) || (b.strength - a.strength)).slice(0, 5);
                            }
                        }

                        delegate: RowLayout {
                            id: netRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: Icons.getNetworkIcon(netRow.modelData.strength)
                                color: netRow.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: netRow.modelData.ssid
                                elide: Text.ElideRight
                                font: Tokens.font.body.small
                                color: netRow.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }

                            MaterialIcon {
                                visible: netRow.modelData.isSecure
                                text: "lock"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3outline
                            }

                            StyledRect {
                                implicitWidth: connectTxt.implicitWidth + Tokens.padding.medium
                                implicitHeight: 26
                                radius: Tokens.rounding.full
                                color: netRow.modelData.active ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

                                StateLayer {
                                    radius: Tokens.rounding.full
                                    onClicked: {
                                        if (netRow.modelData.active) {
                                            Nmcli.disconnectFromNetwork();
                                        } else {
                                            NetworkConnection.handleConnect(netRow.modelData, null, null);
                                        }
                                    }
                                }

                                StyledText {
                                    id: connectTxt
                                    anchors.centerIn: parent
                                    text: netRow.modelData.active ? Tr.tr("Disconnect") : Tr.tr("Connect")
                                    font: Tokens.font.label.small
                                    color: netRow.modelData.active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                                }
                            }
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        text: Tr.tr("Network Settings")
                        icon: "settings"
                        inactiveColour: "transparent"
                        inactiveOnColour: Colours.palette.m3primary
                        onClicked: {
                            root.screenState.utilities = false;
                            root.popouts.detachRequested("network");
                        }
                    }
                }
            }
        }

        // ================= Bluetooth Card =================
        StyledRect {
            id: btCard
            Layout.fillWidth: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh
            border.width: 1
            border.color: (btCard.activeDevice !== null) ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            clip: true

            readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
            readonly property bool btDiscovering: Bluetooth.defaultAdapter?.discovering ?? false
            readonly property var activeDevice: Bluetooth.devices.values.find(d => d.connected) ?? null

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    // Bluetooth Power Circle Button
                    StyledRect {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Tokens.rounding.full
                        color: btCard.btEnabled ? (btCard.activeDevice ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer) : Colours.palette.m3surfaceContainerHighest

                        StateLayer {
                            radius: Tokens.rounding.full
                            onClicked: {
                                const adapter = Bluetooth.defaultAdapter;
                                if (adapter)
                                    adapter.enabled = !adapter.enabled;
                            }
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: btCard.btEnabled ? "bluetooth" : "bluetooth_disabled"
                            color: btCard.btEnabled ? (btCard.activeDevice ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer) : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    // Bluetooth Info & Status (Clickable to toggle expansion)
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: btInfoCol.implicitHeight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.btExpanded = !root.btExpanded
                        }

                        ColumnLayout {
                            id: btInfoCol
                            anchors.fill: parent
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.extraSmall
                                StyledText {
                                    text: Tr.tr("Bluetooth")
                                    font: Tokens.font.body.medium
                                    color: Colours.palette.m3onSurface
                                }
                                MaterialIcon {
                                    visible: btCard.activeDevice?.batteryAvailable ?? false
                                    text: Icons.getBatteryIcon(btCard.activeDevice?.battery ?? 1)
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3outline
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: {
                                    if (!btCard.btEnabled) return Tr.tr("Disabled");
                                    if (btCard.activeDevice) return btCard.activeDevice.name || Tr.tr("Connected");
                                    if (btCard.btDiscovering) return Tr.tr("Searching...");
                                    return Tr.tr("Ready / No devices");
                                }
                                font: Tokens.font.label.medium
                                color: btCard.activeDevice ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    // Expand Arrow Button
                    IconButton {
                        icon: root.btExpanded ? "expand_less" : "expand_more"
                        inactiveColour: root.btExpanded ? Colours.palette.m3secondaryContainer : "transparent"
                        inactiveOnColour: root.btExpanded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        onClicked: root.btExpanded = !root.btExpanded
                    }
                }

                // Inline Expandable Bluetooth Devices Drawer
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.btExpanded
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.4
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Paired & Nearby Devices")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        IconButton {
                            icon: btCard.btDiscovering ? "radar" : "search"
                            onClicked: {
                                const adapter = Bluetooth.defaultAdapter;
                                if (adapter)
                                    adapter.discovering = !adapter.discovering;
                            }
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: {
                                if (!btCard.btEnabled) return [];
                                return [...Bluetooth.devices.values].filter(d => d.name && d.name.length > 0).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 5);
                            }
                        }

                        delegate: RowLayout {
                            id: devRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: Icons.getBluetoothIcon(devRow.modelData.icon)
                                color: devRow.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: devRow.modelData.name
                                elide: Text.ElideRight
                                font: Tokens.font.body.small
                                color: devRow.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }

                            StyledText {
                                visible: devRow.modelData.batteryAvailable ?? false
                                text: Math.round((devRow.modelData.battery ?? 0) * 100) + "%"
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }

                            StyledRect {
                                implicitWidth: devConnectTxt.implicitWidth + Tokens.padding.medium
                                implicitHeight: 26
                                radius: Tokens.rounding.full
                                color: devRow.modelData.connected ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

                                StateLayer {
                                    radius: Tokens.rounding.full
                                    onClicked: devRow.modelData.connected = !devRow.modelData.connected
                                }

                                StyledText {
                                    id: devConnectTxt
                                    anchors.centerIn: parent
                                    text: devRow.modelData.connected ? Tr.tr("Disconnect") : Tr.tr("Connect")
                                    font: Tokens.font.label.small
                                    color: devRow.modelData.connected ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                                }
                            }
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        text: Tr.tr("Bluetooth Settings")
                        icon: "settings"
                        inactiveColour: "transparent"
                        inactiveOnColour: Colours.palette.m3primary
                        onClicked: {
                            root.screenState.utilities = false;
                            root.popouts.detachRequested("bluetooth");
                        }
                    }
                }
            }
        }

        // ================= Sliders Section =================
        StyledRect {
            Layout.fillWidth: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                // Volume Slider Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconButton {
                        icon: Icons.getVolumeIcon(Audio.sink?.audio?.volume ?? 0, Audio.sink?.audio?.muted ?? false)
                        inactiveColour: (Audio.sink?.audio?.muted ?? false) ? Colours.palette.m3errorContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                        inactiveOnColour: (Audio.sink?.audio?.muted ?? false) ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                        onClicked: {
                            const sink = Audio.sink;
                            if (sink)
                                Audio.setStreamMuted(sink, !sink.audio?.muted);
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 24

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            implicitHeight: parent.implicitHeight

                            radius: Tokens.rounding.full
                            value: Audio.sink?.audio?.volume ?? 0
                            to: GlobalConfig.services.maxVolume
                            onInteraction: v => Audio.setVolume(v)
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // Brightness Slider Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconButton {
                        icon: `brightness_${Math.min(7, Math.max(1, Math.round(((root.activeMonitor?.brightness ?? 0.5)) * 6) + 1))}`
                        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
                        inactiveOnColour: Colours.palette.m3onSurface
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 24

                        StyledSlider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            implicitHeight: parent.implicitHeight

                            radius: Tokens.rounding.full
                            value: root.activeMonitor?.brightness ?? 0.5
                            from: 0.05
                            to: 1.0
                            onInteraction: v => root.activeMonitor?.setBrightness(v)
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Math.round((root.activeMonitor?.brightness ?? 0.5) * 100) + "%"
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        // ================= Quick Action Pills =================
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            // Do Not Disturb
            ActionPill {
                icon: Notifs.dnd ? "notifications_off" : "notifications"
                label: Tr.tr("DND")
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            // Night Light
            ActionPill {
                icon: "nightlight"
                label: Tr.tr("Night")
                checked: false
                onClicked: sunsetProc.running = true
            }

            // Game Mode
            ActionPill {
                icon: "sports_esports"
                label: Tr.tr("Game")
                checked: GameMode.enabled
                onClicked: GameMode.enabled = !GameMode.enabled
            }

            // Mic Mute
            ActionPill {
                icon: (Audio.source?.audio?.muted ?? false) ? "mic_off" : "mic"
                label: Tr.tr("Mic")
                checked: !(Audio.source?.audio?.muted ?? false)
                onClicked: {
                    const source = Audio.source;
                    if (source)
                        Audio.setStreamMuted(source, !source.audio?.muted);
                }
            }
        }
    }

    component ActionPill: StyledRect {
        id: pill
        required property string icon
        required property string label
        property bool checked: false
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 46
        radius: Tokens.rounding.medium
        color: checked ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
        border.width: 1
        border.color: checked ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

        StateLayer {
            radius: pill.radius
            onClicked: pill.clicked()
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: pill.icon
                fontStyle: Tokens.font.icon.small
                color: pill.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: pill.label
                font: Tokens.font.label.small
                color: pill.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }
        }
    }
}
