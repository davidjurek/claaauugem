# Static Falls

A modern-day quirky RPG for iOS, built in **Godot 4** and inspired by *EarthBound* —
a psychic kid, a weird suburb, and the mundane bleeding into the surreal.

> Single playable character · turn-based combat with rolling-HP odometers ·
> visible overworld enemies · hub town + zones · side quests · EarthBound-flavored
> writing that's funny on top and quietly dark underneath.

## Status
Vertical slice in development (~1–3 hr polished experience, architected to scale to 10–12 hr).

## Built from open source
This game is assembled, wherever possible, from open-source code components and
freely-licensed (CC0 / CC-BY) art and audio. **100% of visual and audio assets are
sourced from open libraries — none are AI-generated.** Every component and asset is
credited in [`CREDITS.md`](CREDITS.md) with a per-file ledger in
[`ASSETS/manifest.csv`](ASSETS/manifest.csv).

Licensing policy: permissive code only (MIT/Apache/BSD/zlib/Unlicense, no GPL);
art/audio under CC0 (preferred) or CC-BY (no NC, share-alike avoided).

## Project layout
```
project.godot        Godot project config
art/                 sprites, tilesets, UI, portraits (third-party, see CREDITS)
audio/               bgm, battle, sfx (third-party, see CREDITS)
fonts/               fonts (third-party, see CREDITS)
addons/              third-party Godot plugins
scenes/              game scenes (world, battle, ui)
scripts/             original game code (MIT)
data/                story, dialogue, quests, enemy/stat data (MIT)
ASSETS/manifest.csv  machine-readable attribution ledger
```

## Engine
Godot 4.7 stable. Open in the Godot editor or run from CLI:
```
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## License
Original code, story, and data: MIT (see [`LICENSE`](LICENSE)).
Third-party assets and components: each under its own license — see [`CREDITS.md`](CREDITS.md).
