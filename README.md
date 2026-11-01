# Gloss Bar

Aqua-era glossy capsules behind the groups of widgets on the Omarchy 4 bar, drawn
only when the theme asks for them.

It is a bar widget that takes no room. It reads where the bar's widget slots sit
(geometry only), joins adjacent slots into groups, and draws one capsule per group on
its own click-through layer (`omarchy-gloss-bar`, Hyprland's bottom layer) just under
the bar. The bar stays Omarchy's trusted built-in one, so widgets keep their plugin
services. (Version 0.1 was a replacement bar, and Omarchy only gives a replacement
bar service-less widgets, which froze Omarchywell and the like.)

A theme opts in by shipping `shell.gloss-bar.toml`. Theme switches already push
`shell.toml` to the shell over IPC, so the capsules come and go live; under a theme
without the file the widget draws nothing. Horizontal bars only.

## Install

```bash
./deploy.sh            # validates, copies plugin/ into ~/.config/omarchy/plugins, adds the widget
./deploy.sh --no-enable
```

The shell does not follow a symlinked plugin folder, so `deploy.sh` copies the plugin.
QML changes take effect after `omarchy restart shell`.

The capsules sit under the bar, so the bar strip must be clear: a theme using Gloss Bar
sets `[bar] background-alpha = 0`. With `omarchy bar transparent true` the bar picks
its text color from the wallpaper and may choose a dark one; `omarchy bar transparent
false` keeps the theme's bar text color.

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
shadow       = "#3a1000"
shadow-alpha = 0.25
shine-alpha  = 0.8         # white highlight band across the top half
glow-alpha   = 0.4         # white glow pooled at the bottom
inset        = 4           # capsule gap from the bar's top and bottom edges
padding      = 8           # horizontal padding around each group
join-gap     = 24          # slots closer than this share a capsule
```

For real glass, blur the layer in the theme's `hyprland.lua`:

```lua
hl.layer_rule({ match = { namespace = "omarchy-gloss-bar" }, blur = true, ignore_alpha = 0.2 })
```

## License

MIT, with Omarchy's copyright kept: the widget borrows the capsule drawing from, and
version 0.1 was a clone of, Omarchy's built-in bar (© David Heinemeier Hansson).
