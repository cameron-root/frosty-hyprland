pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    readonly property Props props: Props {}

    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property bool hasLoaded: false
    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            hasLoaded = true;
    }

    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: root.hasLoaded = true
    }

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.large
        anchors.margins: CUtils.clamp(anchors.leftMargin - Config.border.thickness, 0, anchors.leftMargin)
        anchors.bottomMargin: 0

        asynchronous: true
        active: root.hasLoaded || root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - content.anchors.leftMargin - content.anchors.margins
            props: root.props
            screenState: root.screenState
        }
    }
}
