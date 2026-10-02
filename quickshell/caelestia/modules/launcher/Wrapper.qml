pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property bool hasLoaded: false
    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            hasLoaded = true;
            implicitHeight = Qt.binding(() => content.implicitHeight);
        } else {
            implicitHeight = implicitHeight; // Break binding during close anim
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: root.hasLoaded = true
    }

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: Math.max(content.implicitHeight, 440)
    implicitWidth: Math.max(content.implicitWidth, 630)
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        asynchronous: true
        active: root.hasLoaded || root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
