# CC:Tweaked GPS Navigator

A simple ComputerCraft/CC:Tweaked navigator that uses **GPS only**. It does not connect to or require a server, wireless modem, or saved-point server.

## Installation

1. Place `navigator.lua` on the ComputerCraft computer (or download it with the installer).
2. Set up at least three GPS satellites: computers with wireless modems running `gps host` at different coordinates.
3. Run `navigator`.

GPS satellites are required because `gps.locate()` needs at least three hosts with wireless modems and radio visibility between them.

## Features

- Show the current GPS coordinates.
- Save named locations locally in `/navigator_points.db`.
- List and delete saved locations.
- Navigate to a saved location using live GPS coordinates, distance, and compass direction.

All saved points belong to the local computer. No server program is needed.

## Files

- `navigator.lua` — the GPS-only navigator.
- `nav.lua` — a standalone coordinate radar that also uses GPS only.
- `install.lua` — downloads the navigator.
- `server.lua` — legacy server-based version; it is not used by the GPS-only navigator.
