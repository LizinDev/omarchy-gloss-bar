# Gloss Bar

The Omarchy 4 bar, cloned from `omarchy.bar`, plus Aqua-era glossy capsules behind the
left, center and right sections. A theme asks for them by shipping
`shell.gloss-bar.toml`. Under any theme without that file it renders exactly like the
stock bar, so it can stay selected permanently.

Theme switches already push `shell.toml` to the shell over IPC, so the capsules appear
and disappear live with the theme. Horizontal bars only; vertical bars stay stock.

## Install

```bash
./deploy.sh            # validates, copies plugin/ into ~/.config/omarchy/plugins, selects it
./deploy.sh --no-enable
```

The shell does not follow a symlinked plugin folder, so `deploy.sh` copies the plugin.
QML changes take effect after `omarchy-restart-shell`. To go back:
`omarchy plugin enable omarchy.bar`.

## Theme keys

`shell.gloss-bar.toml` becomes a `[gloss-bar]` section that Omarchy appends to
`shell.toml`. All keys are optional except `enabled`:

```toml
enabled      = "true"
fill-top     = "#ff8a2a"   # body gradient, top → middle → bottom
fill         = "#e2600a"   # defaults to the theme accent
fill-bottom  = "#ffb066"
fill-alpha   = 0.62        # < 1 lets Hyprland blur show through (add a layer blur rule)
rim          = "#ffd2a6"   # 1 px outline
text         = "#ffffff"   # bar label color while capsules are on
shadow       = "#3a1000"
shadow-alpha = 0.25
shine-alpha  = 0.8         # white highlight band across the top half
glow-alpha   = 0.4         # white glow pooled at the bottom
font         = "Nimbus Sans"   # bar font while capsules are on (default: system font)
inset        = 4           # capsule gap from the bar's top and bottom edges
padding      = 8           # horizontal padding around each section
```

For real glass, blur the bar layer in the theme's `hyprland.lua`:

```lua
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = 0.2 })
```

## Upstream

`plugin/` is `omarchy.bar` from Omarchy 4.0.5 (MIT, © Basecamp/37signals). The
changes are confined to `Bar.qml`: the `gloss*` properties, `GlossCapsule`, and the
bindings that use them. Re-clone and re-apply them after an Omarchy update changes the
bar.
