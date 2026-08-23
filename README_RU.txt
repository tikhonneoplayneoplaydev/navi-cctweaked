CC:TWEAKED GPS NAVIGATOR

This project uses GPS only for navigation. It does not communicate with a server.

Files:
- navigator.lua — run this on the player's ComputerCraft computer.
- nav.lua — standalone GPS coordinate radar.
- install.lua — optional installer.
- server.lua — legacy server-based version; not required or used.

Setup:
1. Set up at least three GPS satellites: computers with wireless modems running `gps host`.
2. Place navigator.lua on the player's computer.
3. Run: navigator

Navigator commands:
1 — list locally saved points
2 — save the current GPS position
3 — select a saved point and show live distance and direction
4 — delete a saved point
5 — show current GPS coordinates

GPS requirements:
`gps.locate()` needs at least three GPS hosts at different coordinates. They need wireless
radio visibility. Saved points are stored locally in `/navigator_points.db`.

The navigator polls GPS directly and never sends navigation requests to a server.
