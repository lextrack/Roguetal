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

Dialogues: Includes texts for instructions, menus, and dialogues in JSON format.

Entities: Contains scripts and scenes for the player, bullets, enemies, and some effects.

Fonts: The font used by the game.

GlobalScripts: Contains scripts that handle global events (translations, porwer ups, etc).

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
- Android 8.0 or higher
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

¡Claro! Aquí te dejo una sección que puedes agregar al final del README, justo antes de la despedida. Está explicada de forma clara y directa para que cualquier persona que quiera exportar entienda qué hacer, tanto en Android como en PC:

---

## ⚠️ Export Notes

### 📱 Android Export (Release)
If you want to export the game as a **release APK**, make sure to:

1. Go to **Project > Export > Android**.
2. Scroll to the **"Keystore"** section.
3. Select the keystore file:  
   `CredentialsExport/c2roguelite.keystore`
4. Enter the keystore **user** and **password**, both of which are found in the file:  
   `CredentialsExport/credentials.txt`

Without this configuration, the release export won't be properly signed and may not install on devices. You can create your own keystore if you want.

---

### 💻 PC Export (Windows Icon Issue)
To correctly use the **custom icon** included in the project when exporting for Windows:

1. Open **Editor Settings** in Godot.
2. Go to **Export > Windows**.
3. In the **rcedit path**, set the correct path. For example:  
   `C:/Roguetal/PC/Roguetal/rcedit-x64.exe`

> Note: `rcedit-x64.exe` is located in the root of the project. Make sure the path is correct or the icon won’t apply on exported builds.

---

## Contact & Social
- Developer: Lextrack Studios
- Twitter: [@lextrack12](https://twitter.com/lextrack12)
- Email: [lextrackstudios@gmail.com](mailto:lextrackstudios@gmail.com)

---

Thank you for your interest in this project. I hope you enjoy playing it as much as I enjoyed creating it!
