# Roguetal

<div align="center">
  <img src="Captures\portada.png" alt="Android version" width="400"/>
</div>

## About the Game
A beat 'em up with roguelike elements set in randomly generated dungeons!


## Why does this exist?
I just wanted to make a game using Godot and this is the poor result.

## Play Now
The game is completely free to play and available on:

<a href="https://lextrack.itch.io/roguetal" target="_blank">
  <img src="https://static.itch.io/images/badge-color.svg" width="200" />
</a>

<a href="https://play.google.com/store/apps/details?id=com.lextrack.roguetal" target="_blank">
  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" width="200" />
</a>


## Screenshots
<div align="center">
  <img src="Captures\1.png" alt="Android version" width="400"/>
  <img src="Captures\2.png" alt="Android version" width="400"/>
  <img src="Captures\3.png" alt="PC Version" width="400"/>
  <img src="Captures\4.png" alt="PC Version" width="400"/>
</div>

## Repository Structure
This repository contains the complete source code for the game:
- **`main` branch**: PC version (Windows and Linux)
- **`android` branch**: The same game but using virtual joysticks for Android and minor changes in the UI and sprites

```
Dialogues: Includes texts for instructions, menus, and dialogues in JSON format

Entities: Contains scripts and scenes for the player, bullets, enemies, and some effects.

Fonts: The font used by the game.

Interactables: Contains scripts and scenes for power-ups, ammo, and portals.

Levels: Contains scripts and scenes related to the game levels.

Shaders: Contains shaders used for visual effects, such as changes when taking damage.

SoundEffects: Contains scripts and scenes for sound effects and music.

Sprites: Contains the game's sprites (some may be unused).

UI: Contains scripts and scenes related to the game's HUD.

```

## System Requirements

### To Play
**PC Version:**
- OS: Windows 10/11 or Linux (Ubuntu 20.04+)
- Processor: Intel i3-4160 or similar
- Memory: 4 GB RAM
- Graphics: Intel HD Graphics 4400
- Storage: 200 MB available space

**Android Version:**
- Android 7.0 or higher
- 200 MB free storage

## For the development I used
- [Godot Engine 4.4+](https://godotengine.org/download/)
- Gimp
- Paint.NET
- And of course, the assets of so much people from itch.io, flaticon, Craftpix, freesound, etc.

## Development Setup
1. Clone the repository in the folder of your choice.

    Clone the PC version (master branch)
    ```bash
    git clone https://github.com/lextrack/Roguetal.git
    ```
    Clone the Android branch:
    ```bash
    git clone -b android --single-branch https://github.com/lextrack/Roguetal.git
    ```

2. Open Godot Engine
3. Import the project by selecting the folder where you cloned the repository
4. You're ready to explore and modify the game!

## Contact & Social
- Developer: Lextrack Studios
- Twitter: [@lextrack12](https://twitter.com/lextrack12)
- Email: [lextrackstudios@gmail.com](mailto:lextrackstudios@gmail.com)

---

Thank you for your interest in this project. I hope you enjoy playing it as much as I enjoyed creating it!