# NXFS Mod Manager Companion

A small Farming Simulator 25 mod that plays a video over the map loading screen.

It is installed and removed by [NXFS Mod Manager](https://nxmodding.com) — you do not need to
build it or edit it by hand. This repository exists so you can read what the app is putting in
your mods folder, because a mod manager that installs mods you cannot inspect is asking for a
level of trust it has not earned.

## What it does

Farming Simulator has two loading screens, and they work very differently:

| | What it is | How it can be changed |
|---|---|---|
| **Startup splash** | `shared/splash.dds`, shown before the game has looked at the mods folder | only by replacing that file in the game's install |
| **Map loading screen** | the one with the tips and the **Start** button, after you pick a savegame | **by a mod** — it is drawn by the game's own Lua GUI, after mods load |

This mod changes the second one. Because it is a mod, nothing is written inside the game folder,
nothing needs backing up, and a game update cannot undo it.

## How it works

The engine exposes a video overlay API to Lua — `createVideoOverlay`, `playVideoOverlay`,
`renderVideoOverlay`, `isVideoOverlayReadyToPlay`, `stopVideoOverlay`. The mod wraps the current
GUI's `draw` so the video is rendered over whatever the loading screen already shows.

The interesting part is not starting the video, it is stopping it. A video overlay that outlives
the loading screen keeps playing its **audio over the game**, which is the one way this could
genuinely annoy somebody. So it stops from four independent directions:

1. The **Start** button is pressed (also `onClickOk` and `onClickBack`)
2. `g_currentMission.isRunning` becomes true — the map is up
3. `g_gui.currentGui` is gone — the screen has closed
4. A ten-minute backstop, in case none of the above ever happens

Any one of them is enough.

## Video format

Ogg Theora (`.ogv`) only. The engine carries Theora and Vorbis decoders and nothing else — there
is no H.264 in it — so an MP4 would produce a loading screen that silently stays black. The mod
manager converts other formats with `ffmpeg` where it is available.

The video lives beside the script as `loadingVideo.ogv` and is **stored, not deflated**, inside
the mod zip: Theora is already compressed, so deflating it costs seconds per install and saves
almost nothing.

## Multiplayer

`<multiplayer supported="true"/>`, and it is cosmetic — it draws on a local loading screen and
touches no game state, so it cannot desync anything.

Worth knowing: **everyone joining a server downloads the mod**, video and all. The mod manager
caps the video at 250 MB for that reason, and shows you the total before installing.

## Layout

```
src/modDesc.xml          the mod descriptor
src/NXFSCompanion.lua    the whole thing, about 150 lines
```

There is no build step. The mod manager assembles these plus your video into
`FS25_NXFSModManagerCompanion.zip` and copies it into every one of your collections, so the
loading screen survives switching between them.

## Building it by hand

Zip the contents of `src/` together with your own `loadingVideo.ogv` and an `icon.dds`, and drop
the zip in your mods folder:

```
FS25_NXFSModManagerCompanion.zip
├── modDesc.xml
├── NXFSCompanion.lua
├── loadingVideo.ogv
└── icon.dds
```

## Credit

The video overlay functions are GIANTS Software's engine API. The implementation here is NX
Modding's own.

The canonical copy of this script lives in the mod manager's source, in
`CompanionMod.cs`, so that the app can never ship without it. What is here is published from
there.

## Licence

MIT. See [LICENSE](LICENSE).
