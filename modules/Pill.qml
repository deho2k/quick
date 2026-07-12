pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "components"

PanelWindow {
  id: root
  margins.top: 5; margins.bottom: 5
  implicitWidth: contentLoader.width
  implicitHeight: contentLoader.height
  color: "transparent"
  anchors { top: true }
  exclusiveZone: ExclusionMode.Ignore

  property Component mainPill: variants.smallPill
  property Component currentContent: variants.smallPill
  property alias variant: variants

  Timer { id: timer; interval: 2500; onTriggered: root.currentContent = root.mainPill }
  function showVariant(variantContent) { root.currentContent = variantContent; timer.restart(); }
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
  }

  Loader {
    id: contentLoader
    clip: true
    sourceComponent: root.currentContent
    width: item ? item.implicitWidth : 0
    height: item ? item.implicitHeight : 0

    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

    onSourceComponentChanged: {
      if (item.needsFocus) {
        root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
      } else {
        root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
      }
    }
  }

  Connections {
    target: contentLoader.item
    function onReturnToMainPill() { root.returnToMainPill() }
    function onGrapFocus() { root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive }
    function onRemoveFocus() { root.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
  }
}
