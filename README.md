# Doom Generic · WebAssembly

Play Doom Generic in your browser, compiled to WebAssembly with freely licensed Freedoom game data.

## Run

Install the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html), then run:

```sh
make wasm
make serve
```

Open <http://localhost:8000/demo/doom.html>. First-time visitors choose Phase 1, Phase 2, or FreeDM and press Play to download that WAD. Returning visitors automatically load their last game, using the browser cache when available. Switching games restarts the run; save slots stay in browser local storage, separately for each game. Game data, [GUS MIDI patches](https://github.com/redddcyclone/dgguspat), and WASM files are generated locally. Serve over HTTP; `file://` URLs will not work.

## Controls

- **Enter** — start
- **Arrow keys** or **W/S** — move
- **Left/right** — turn
- **Ctrl** — fire
- **Space** — use
