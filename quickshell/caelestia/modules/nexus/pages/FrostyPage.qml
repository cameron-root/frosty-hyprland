pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Frosty Hyprland")

    readonly property string homeDir: Quickshell.env("HOME")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        // ── 1. Accent Theme Colors Section ─────────────────────────────
        SectionHeader {
            first: true
            text: Tr.tr("Accent Theme Colors")
        }

        GridLayout {
            columns: 3
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small
            Layout.fillWidth: true

            Repeater {
                model: [
                    { id: "blue", name: "Electric Blue", color: "#388bfd", icon: "water_drop" },
                    { id: "red", name: "Crimson Red", color: "#ff3b30", icon: "local_fire_department" },
                    { id: "green", name: "Emerald Green", color: "#28c840", icon: "eco" },
                    { id: "grey", name: "Frosted Grey", color: "#cdd6f4", icon: "blur_on" },
                    { id: "purple", name: "Liquid Purple", color: "#9a5bdd", icon: "auto_awesome" },
                    { id: "amber", name: "Solar Amber", color: "#febc2e", icon: "wb_sunny" }
                ]

                StyledRect {
                    id: swatchCard

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 68
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainer

                    StateLayer {
                        radius: parent.radius
                        onClicked: {
                            Quickshell.execDetached([root.homeDir + "/.config/hypr/scripts/SetAccent.sh", modelData.id]);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 18
                            color: modelData.color
                            border.color: Qt.alpha("#ffffff", 0.35)
                            border.width: 1

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: modelData.id === "grey" ? "#0d1018" : "#ffffff"
                                fontStyle: Tokens.font.icon.small
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                text: modelData.name
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: Tr.tr("Apply everywhere")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        // ── 2. Window Transparency & Squircles ─────────────────────────
        SectionHeader {
            text: Tr.tr("Window Transparency & Squircles")
        }

        SliderRow {
            first: true
            label: Tr.tr("Corner Rounding (Squircles)")
            icon: "rounded_corner"
            value: 0.56
            valueLabel: `${Math.round(value * 32)}px`
            onMoved: v => {
                value = v;
                const px = Math.round(v * 32);
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", px.toString()]);
                Quickshell.execDetached(["sed", "-i", `s/rounding = .*/rounding = ${px}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        SliderRow {
            label: Tr.tr("Active Window Opacity")
            icon: "opacity"
            value: 0.94
            valueLabel: `${Math.round(value * 100)}%`
            onMoved: v => {
                value = v;
                const op = (Math.max(0.5, v)).toFixed(2);
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", op]);
                Quickshell.execDetached(["sed", "-i", `s/active_opacity = .*/active_opacity = ${op}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        SliderRow {
            last: true
            label: Tr.tr("Inactive Window Opacity")
            icon: "contrast"
            value: 0.85
            valueLabel: `${Math.round(value * 100)}%`
            onMoved: v => {
                value = v;
                const op = (Math.max(0.4, v)).toFixed(2);
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:inactive_opacity", op]);
                Quickshell.execDetached(["sed", "-i", `s/inactive_opacity = .*/inactive_opacity = ${op}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        // ── 3. Frosty Glass Blur ───────────────────────────────────────
        SectionHeader {
            text: Tr.tr("Frosty Glass Blur")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enable Hardware Glass Blur")
            checked: true
            onToggled: {
                const val = checked ? "1" : "0";
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", val]);
            }
        }

        SliderRow {
            label: Tr.tr("Blur Size / Radius")
            icon: "blur_on"
            value: 0.44
            valueLabel: `${Math.max(1, Math.round(value * 16))}`
            onMoved: v => {
                value = v;
                const s = Math.max(1, Math.round(v * 16));
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:size", s.toString()]);
                Quickshell.execDetached(["sed", "-i", `s/size = .*/size = ${s}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        SliderRow {
            last: true
            label: Tr.tr("Blur Quality Passes")
            icon: "layers"
            value: 0.50
            valueLabel: `${Math.max(1, Math.round(value * 6))}`
            onMoved: v => {
                value = v;
                const p = Math.max(1, Math.round(v * 6));
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:passes", p.toString()]);
                Quickshell.execDetached(["sed", "-i", `s/passes = .*/passes = ${p}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        // ── 4. Windows & Gaps ──────────────────────────────────────────
        SectionHeader {
            text: Tr.tr("Tiling & Spacing")
        }

        SliderRow {
            first: true
            label: Tr.tr("Inner Window Gaps")
            icon: "grid_view"
            value: 0.25
            valueLabel: `${Math.round(value * 24)}px`
            onMoved: v => {
                value = v;
                const g = Math.round(v * 24);
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", g.toString()]);
                Quickshell.execDetached(["sed", "-i", `s/gaps_in = .*/gaps_in = ${g}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        SliderRow {
            last: true
            label: Tr.tr("Outer Screen Gaps")
            icon: "fullscreen"
            value: 0.22
            valueLabel: `${Math.round(value * 36)}px`
            onMoved: v => {
                value = v;
                const g = Math.round(v * 36);
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", g.toString()]);
                Quickshell.execDetached(["sed", "-i", `s/gaps_out = .*/gaps_out = ${g}/`, root.homeDir + "/.config/hypr/UserConfigs/UserDecorations.conf"]);
            }
        }

        // ── 5. Snapshots & Backups ─────────────────────────────────────
        SectionHeader {
            text: Tr.tr("Snapshots & Backups")
        }

        RowButton {
            first: true
            icon: "restore"
            text: Tr.tr("Restore 'Frosty Hyprland' Baseline")
            subtext: Tr.tr("Reset all settings to saved baseline snapshot")
            onClicked: {
                Quickshell.execDetached([root.homeDir + "/.local/bin/frosty-restore"]);
            }
        }

        RowButton {
            last: true
            icon: "save"
            text: Tr.tr("Take New System Snapshot")
            subtext: Tr.tr("Backup current configuration to ~/.snapshots")
            onClicked: {
                Quickshell.execDetached([root.homeDir + "/.local/bin/frosty-backup"]);
                Quickshell.execDetached(["notify-send", "Frosty Hyprland", "Snapshot saved successfully!"]);
            }
        }

        Item {
            implicitHeight: Tokens.padding.large
        }
    }
}
