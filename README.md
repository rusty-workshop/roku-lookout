# roku-lookout

**Lookout**: a wall-display channel for the Family room Roku Express 4K+ (192.168.1.78), which sits behind the receiver on the Sony's HDMI 1.
Three screens, fed by [latitude-lookout](../latitude-lookout)'s
`http://192.168.1.158:8473/api/feed`:

1. **Clock + weather**: big clock and date, Jacksonville conditions,
   high/low, feels-like, humidity, wind, rain chance, sunrise/sunset, air
   quality and UV, the next visible space station pass, and the next 12 hours.
2. **Homelab**: green/red status for the Latitude's services, last backup,
   and what the DVD ripper is doing (with a progress bar).
3. **Chess**: Lichess correspondence games from Gambit with board images,
   whose move it is, ratings, and the Lichess daily puzzle's position.

Active National Weather Service alerts show as a banner across the top of
every screen (red for severe, amber for moderate).

The screens rotate every 30 seconds. Left/right on the remote flips by hand
and pauses rotation for 5 minutes. The same scene is the channel's
**screensaver** (`RunScreenSaver`), so pick "Lookout" under Settings → Theme →
Screensaver to have it come back on its own.

Roku allows only one sideloaded channel per device, which is why the three
ideas live in one channel.

## Install

1. On the Roku remote: Home ×3, Up ×2, Right, Left, Right, Left, Right.
   Enable the installer, accept the license, set a password. The Roku reboots.
2. `zip -r dist/lookout.zip manifest source components images`
3. Open `http://192.168.1.78` in a browser, log in as `rokudev` with that
   password, upload `dist/lookout.zip`, Install.

Errors and `print` output show on the Roku's debug console:
`nc 192.168.1.78 8085`.

## License

AGPL-3.0-or-later
