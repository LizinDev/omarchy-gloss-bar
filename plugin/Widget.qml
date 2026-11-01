import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Gloss Bar: Aqua-era glossy capsules behind the bar's widget groups.
//
// The widget itself takes no room. It reads where the bar's widget slots sit
// (geometry only), joins adjacent slots into groups, and draws one capsule per
// group on its own click-through layer just under the bar. The bar stays the
// trusted built-in one, so widgets that need their plugin service keep it —
// a replacement bar only gets service-less widgets.
//
// A theme opts in by shipping shell.gloss-bar.toml; Omarchy appends it to
// shell.toml as a [gloss-bar] section, and theme switches push shell.toml over
// IPC, so the capsules come and go live with the theme.
BarWidget {
  id: root
  moduleName: "io.github.lizindev.gloss-bar"
  implicitWidth: 0
  implicitHeight: 0

  readonly property var values: Color.shellValues || ({})
  function value(key, fallback) {
    var v = values["gloss-bar." + key]
    return v === undefined || v === "" ? fallback : v
  }
  function num(key, fallback) {
    var n = Number(value(key, fallback))
    return isFinite(n) ? n : fallback
  }

  readonly property bool enabled: String(value("enabled", "false")) === "true" && !vertical
  readonly property color fill: value("fill", Color.accent)
  readonly property color fillTop: value("fill-top", Qt.darker(fill, 1.12))
  readonly property color fillBottom: value("fill-bottom", Qt.lighter(fill, 1.22))
  readonly property real fillAlpha: num("fill-alpha", 1.0)
  readonly property color rim: value("rim", Qt.darker(fill, 1.45))
  readonly property real rimAlpha: num("rim-alpha", 1.0)
  readonly property color shadow: value("shadow", "#000000")
  readonly property real shadowAlpha: num("shadow-alpha", 0.18)
  readonly property real shadowOffset: num("shadow-offset", 2)
  readonly property real shine: num("shine-alpha", 0.7)
  // "band": an inset pill-shaped highlight (Aqua gel). "glare": the top half
  // of the capsule itself catches the light, cut straight across (glass).
  readonly property string shineStyle: String(value("shine-style", "band"))
  readonly property real glow: num("glow-alpha", 0.35)
  // Hairlines just inside the edge: a specular line along the top and a
  // colored glow line along the bottom, both fading out toward the ends.
  readonly property real edgeLight: num("edge-light-alpha", 0)
  readonly property color edgeGlow: value("edge-glow", Color.accent)
  readonly property real edgeGlowAlpha: num("edge-glow-alpha", 0)
  readonly property int inset: Math.round(num("inset", 3))
  readonly property int padding: Math.round(num("padding", 6))
  // Slots closer than this belong to the same capsule.
  readonly property int joinGap: Math.round(num("join-gap", 24))

  readonly property var hostWindow: QsWindow.window
  readonly property Item host: hostWindow ? hostWindow.contentItem : null
  // The bar hides by parking its window past the screen edge.
  readonly property bool barParked: !!hostWindow && !!hostWindow.margins
    && (hostWindow.margins.top < 0 || hostWindow.margins.bottom < 0)
  readonly property string position: bar ? bar.position : "top"

  property var capsules: []
  property string capsulesKey: ""

  // A slot is the host's per-entry wrapper: it carries the entry, its region
  // and the widget id. Stop there; the widget inside is the slot's business.
  function isSlot(item) {
    return typeof item.moduleName === "string" && item.region !== undefined && item.entry !== undefined
  }

  function collectSlots(item, out) {
    var kids = item.children
    for (var i = 0; i < kids.length; i++) {
      var child = kids[i]
      if (!child || !child.visible) continue
      if (isSlot(child)) {
        if (child.width >= 1 && child.moduleName !== root.moduleName) out.push(child)
      } else {
        collectSlots(child, out)
      }
    }
  }

  function measure() {
    if (!enabled || !host) {
      if (capsulesKey !== "") { capsules = []; capsulesKey = "" }
      return
    }
    var slots = []
    collectSlots(host, slots)
    var spans = []
    for (var i = 0; i < slots.length; i++) {
      var p = slots[i].mapToItem(host, 0, 0)
      spans.push({ x: p.x, right: p.x + slots[i].width })
    }
    spans.sort(function(a, b) { return a.x - b.x })
    var groups = []
    for (var j = 0; j < spans.length; j++) {
      var last = groups.length ? groups[groups.length - 1] : null
      if (last && spans[j].x - last.right <= joinGap) last.right = Math.max(last.right, spans[j].right)
      else groups.push({ x: spans[j].x, right: spans[j].right })
    }
    var next = []
    // A group that starts near the screen edge gets less padding rather
    // than a capsule cut off by the edge.
    var edge = inset
    var limit = host.width - inset
    for (var k = 0; k < groups.length; k++) {
      var x = Math.max(edge, Math.round(groups[k].x - padding))
      var right = Math.min(limit, Math.round(groups[k].right + padding))
      next.push({ x: x, width: right - x })
    }
    var key = JSON.stringify(next)
    if (key !== capsulesKey) { capsulesKey = key; capsules = next }
  }

  Timer {
    interval: 250
    repeat: true
    running: root.enabled && !root.barParked
    triggeredOnStart: true
    onTriggered: root.measure()
  }
  onEnabledChanged: root.measure()

  PanelWindow {
    id: glossLayer

    screen: root.hostWindow ? root.hostWindow.screen : null
    visible: root.enabled && !root.barParked && root.capsules.length > 0
    color: "transparent"
    anchors {
      top: root.position !== "bottom"
      bottom: root.position === "bottom"
      left: true
      right: true
    }
    implicitHeight: root.barSize
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "omarchy-gloss-bar"
    mask: Region {}

    Repeater {
      model: root.capsules

      Item {
        id: capsule
        required property var modelData

        x: modelData.x
        width: modelData.width
        y: root.inset
        height: Math.max(0, glossLayer.height - root.inset * 2)
        readonly property real radius: height / 2

        Rectangle {
          y: root.shadowOffset
          width: parent.width
          height: parent.height
          radius: capsule.radius
          color: Util.alpha(root.shadow, root.shadowAlpha)
          visible: root.shadowAlpha > 0
        }

        Rectangle {
          anchors.fill: parent
          radius: capsule.radius
          border.width: 1
          border.color: Util.alpha(root.rim, root.rimAlpha)
          gradient: Gradient {
            GradientStop { position: 0.0; color: Util.alpha(root.fillTop, root.fillAlpha) }
            GradientStop { position: 0.5; color: Util.alpha(root.fill, root.fillAlpha) }
            GradientStop { position: 1.0; color: Util.alpha(root.fillBottom, root.fillAlpha) }
          }
        }

        // glow pooled at the bottom, light bouncing up through the plastic
        Rectangle {
          visible: root.glow > 0
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 2
          height: parent.height * 0.45
          radius: height / 2
          gradient: Gradient {
            GradientStop { position: 0.0; color: Util.alpha("#ffffff", 0) }
            GradientStop { position: 1.0; color: Util.alpha("#ffffff", root.glow) }
          }
        }

        // highlight band across the top half
        Rectangle {
          visible: root.shineStyle !== "glare" && root.shine > 0
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: Math.max(1, Math.round(parent.height * 0.07))
          width: parent.width - Math.round(parent.height * 0.5)
          height: Math.round(parent.height * 0.46)
          radius: height / 2
          gradient: Gradient {
            GradientStop { position: 0.0; color: Util.alpha("#ffffff", root.shine) }
            GradientStop { position: 1.0; color: Util.alpha("#ffffff", root.shine * 0.08) }
          }
        }

        // glare: the capsule's own shape, lit on its top half only
        Item {
          visible: root.shineStyle === "glare" && root.shine > 0
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 1
          height: Math.round(parent.height * 0.5)
          clip: true

          Rectangle {
            width: parent.width
            height: capsule.height - 2
            radius: height / 2
            gradient: Gradient {
              GradientStop { position: 0.0; color: Util.alpha("#ffffff", root.shine) }
              GradientStop { position: 0.5; color: Util.alpha("#ffffff", root.shine * 0.15) }
            }
          }
        }

        // specular hairline along the top edge
        Rectangle {
          visible: root.edgeLight > 0
          anchors.top: parent.top
          anchors.topMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width - capsule.radius * 1.4
          height: 1
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Util.alpha("#ffffff", 0) }
            GradientStop { position: 0.3; color: Util.alpha("#ffffff", root.edgeLight) }
            GradientStop { position: 0.7; color: Util.alpha("#ffffff", root.edgeLight) }
            GradientStop { position: 1.0; color: Util.alpha("#ffffff", 0) }
          }
        }

        // colored glow hairline along the bottom edge
        Rectangle {
          visible: root.edgeGlowAlpha > 0
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width - capsule.radius * 2
          height: 1
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Util.alpha(root.edgeGlow, 0) }
            GradientStop { position: 0.5; color: Util.alpha(root.edgeGlow, root.edgeGlowAlpha) }
            GradientStop { position: 1.0; color: Util.alpha(root.edgeGlow, 0) }
          }
        }
      }
    }
  }
}
