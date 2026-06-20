# Asura Caelestia Quickshell Profile

This is a local experimental Caelestia-derived Quickshell profile for the
normal `Noctalia + Hyprland` session. It is packaged by:

```text
/etc/nixos/asura-xs15/quickshell/default.nix
```

Runtime path after rebuild:

```text
/etc/xdg/quickshell/caelestia
```

Switch to it with:

```bash
asura-quickshell-switch caelestia
```

Return to the stable shell with:

```bash
asura-quickshell-switch noctalia
```

Status: experimental. The profile now uses `Quickshell.Hyprland` through
`services/Hypr.qml` and is packaged as an optional Hyprland shell profile.
