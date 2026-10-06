# Doom Generic · WebAssembly

Play Doom Generic in your browser, compiled to WebAssembly with sound effects and MIDI music. The demo uses the freely licensed [Freedoom Phase 1](https://freedoom.github.io/download.html) game data.

## Run

Install the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html), then run:

```sh
make wasm
make serve
```

Open <http://localhost:8000/demo/doom.html>. Game data, [GUS MIDI patches](https://github.com/redddcyclone/dgguspat), and WASM files are generated locally. Click the game and press Enter; browsers require a user interaction to enable audio. Headless Chrome confirmed the game loads and the audio context starts, but audible output remains unverified. Serve over HTTP; `file://` URLs will not work.

## Controls

- **Enter** — start
- **Arrow keys** or **W/S** — move
- **Left/right** — turn
- **Ctrl** — fire
- **Space** — use
