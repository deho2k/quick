pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import "pills/main"
import "pills/osd"
import "pills/services"

PanelWindow {
  id: root
  implicitWidth: contentLoader.width
  implicitHeight: contentLoader.height
  color: "transparent"
  margins {top: Config.position.margins; bottom: Config.position.margins; right: Config.position.margins; left: Config.position.margins}
  anchors {top: Config.position.top; bottom: Config.position.bottom; right: Config.position.right; left: Config.position.left }
  exclusiveZone: ExclusionMode.Normal

  property Component mainPill: variants.bigPill
  property Component currentContent: mainPill
  property alias variant: variants

  Timer { id: timer; interval: 2500; onTriggered: root.currentContent = root.mainPill }
  function showVariant(variantContent) { if (!contentLoader.item.needsFocus) {root.currentContent = variantContent; timer.restart()}}
  function changePill(pill) { root.currentContent = (root.currentContent == pill) ? root.mainPill : pill }
  function togglePillSize() { root.mainPill = variants.bigPill == root.mainPill ? variants.smallPill : variants.bigPill; root.currentContent = root.mainPill }
  function returnToMainPill() { root.currentContent = root.mainPill }

  Item {
    id: variants
    property Component smallPill: SmallPill {}
    property Component bigPill: BigPill {}
    property Component volume: Volume {}
    property Component music: Music {}
    property Component submap: Submap {}
    property Component search: Search { needsFocus: true }
    property Component wallpaper: Wallpaper { needsFocus: true }
    property Component settings: Settings { needsFocus: true }
  }

  Loader {
    id: contentLoader
    clip: true
    sourceComponent: root.currentContent
    width: item ? item.implicitWidth : 0
    height: item ? item.implicitHeight : 0

    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on height {
      ParallelAnimation {
        NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        SequentialAnimation {
          NumberAnimation { target: root; property: "margins.top"; to: Config.position.margins - 5; duration: 250; easing.type: Easing.InCurve }
          NumberAnimation { target: root; property: "margins.top"; to: Config.position.margins; duration: 250; easing.type: Easing.InCurve }
        }
      }
    }

    onSourceComponentChanged: {
      root.WlrLayershell.keyboardFocus = item.needsFocus? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    }
  }

  Connections {
    target: contentLoader.item
    function onReturnToMainPill() { root.returnToMainPill() }
    function onGrapFocus() { root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive }
    function onRemoveFocus() { root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
  }
}
