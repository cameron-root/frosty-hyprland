pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    readonly property bool isBatteryLow: UPower.onBattery && UPower.displayDevice.percentage <= 0.20

    function checkBatteryLevel(): void {
        if (props.enabled && root.isBatteryLow) {
            props.enabled = false;
            Toaster.toast(
                Tr.tr("Keep Awake Disabled"),
                Tr.tr("Battery dropped to 20%. Power saving restored."),
                "battery_alert",
                Toast.Warning
            );
        }
    }

    onEnabledChanged: {
        if (enabled) {
            if (root.isBatteryLow) {
                props.enabled = false;
                Toaster.toast(
                    Tr.tr("Cannot Keep Awake"),
                    Tr.tr("Battery is at or below 20%. Connect charger first."),
                    "battery_alert",
                    Toast.Warning
                );
                return;
            }
            props.enabledSince = new Date();
            Toaster.toast(
                Tr.tr("Keep Awake Active"),
                Tr.tr("System will stay awake until battery reaches 20%."),
                "coffee"
            );
        } else {
            Toaster.toast(
                Tr.tr("Keep Awake Turned Off"),
                Tr.tr("Normal power management and screen lock restored."),
                "coffee"
            );
        }
    }

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged(): void {
            root.checkBatteryLevel();
        }
    }

    Connections {
        target: UPower
        function onOnBatteryChanged(): void {
            root.checkBatteryLevel();
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    // 1. Systemd and hypridle inhibition via caelestia-keepawake
    Process {
        id: inhibitProc
        command: ["caelestia-keepawake"]
        running: props.enabled
    }

    // 2. Wayland protocol idle inhibitor
    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "idleInhibitor"
    }
}
