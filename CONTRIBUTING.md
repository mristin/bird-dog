# Contributing

## Overview

The game is made with [Godot] 4.6 (.NET), in GDScript and C#, like [Splash 'n' Splat], from which we took over the hand and head tracking.

* **The vision is in C#** (`scenes/hand_tracker/`), taken over from Splash 'n' Splat: `YoloxHandDetector` finds the hands and the heads in one run, `MultiHandTracker` follows the hands, `FistClassifier` and `GestureStateMachine` recognize the fists, and `HandVisionService` (a Godot node) runs it all on a background thread.
  See the contributing guide of Splash 'n' Splat for the details and for how the models were obtained.
* **The bird-dog poses** (`scenes/pose/`):
  * `core/BirdDogPose.cs` (no Godot dependency) splits the picture between the players (`PlayerSplit`), recognizes the pose of each player as `Rest`, `Left`, `Right`, `Invalid` or `Absent`, debounces it, and steers by the height of the raised hand (`Steer` in [-1, 1]) (`BirdDogPoseClassifier`, `BirdDogPoseTracker`).
    All the thresholds are in head heights (`PoseConfig`).
  * `pose_service/PoseService.cs` (a Godot node) runs the recognition on every new snapshot of the vision, offers `GetPlayers()` to GDScript, and records the detections on request.
* **The language select** (`scenes/language_select/`, the first screen) lets the players choose the language (English, then the others alphabetically: German, Spanish, French, Croatian, Italian, Portuguese, Russian, Albanian and Turkish), with the hand cursor (`scenes/hand_cursor/`: point with an open hand, hold a fist for 1.5 s to click). The choice is saved in `user://settings.cfg` by the `Languages` autoload.
* **The player count and the captain creator** (`scenes/player_count/`, `scenes/captain_creator/`) come next; the `Crew` autoload (`scenes/crew/`) keeps the players and the looks of their captains (`CaptainOptions`). Try it in isolation with its test screens (below).
* **The menus** (the dialogues) extend `MenuScreen` (`scenes/menu/`), which brings the paper, the `HandCursor` on top, Esc to quit and `go_next()` to the `next_scene`. The screens build themselves from `HandButton`s (point, hold a fist, with the golden charge; optionally octagons), so the point-and-click is written once.
* **The voyages** (`scenes/session_select/`, `scenes/session_name/`) come right after the language; the `Session` autoload (`scenes/session/`) saves a voyage with its crew and its missions to `user://saves/` (F5 saves, F6 loads). The missions are described in `data/missions/<nn>_<id>/mission.tres` (`Mission`, loaded by `MissionCatalog`) from the building blocks of `scenes/missions/` and the world of `data/world/`, and the mission select (`scenes/mission_select/`) unlocks them one after the other.
* **A mission** (`scenes/mission/`) sails the chart (`sailing/`), shows the HUD (`hud/`: the days, the clue, the wind, the wheel and the minimap) and the port scenes (`StoryCard`), while `MissionRun` (`scenes/missions/`) follows the steps. Without a camera, A/D or the arrow keys steer. `tests/godot/test_missions.gd` checks the world and plays mission 1 headless.
* **The vision** runs for the whole game in the `Vision` autoload (`scenes/vision/`), so that the camera starts only once.
* **The instruction** (`scenes/instruction/`, after the language select) shows how to do the bird dog and how it steers, with a 3D captain built from shapes in code (`Captain3D`, posed by `BirdDogPoses`).
* **The wheel** (`scenes/wheel/ship_wheel.gd`) draws the ship's wheel of wood and brass on any canvas.
* **The test screens** (`scenes/tests/`) show every part of the game in isolation; see below.

[Godot]: https://godotengine.org
[Splash 'n' Splat]: https://github.com/mristin/splash-n-splat

## Setting up

You need [Git LFS] (the ONNX models and the test images are in LFS), the .NET 8 SDK, the **.NET** build of Godot 4.6.2, Python 3.10+ and a webcam which supports 640x480.

```
export GODOT=~/apps/Godot_v4.6.2-stable_mono_linux_x86_64/Godot_v4.6.2-stable_mono_linux.x86_64
python3 -m venv venv && touch venv/.gdignore
venv/bin/pip install -r dev/requirements.txt
dotnet build BirdDog.sln
$GODOT --path .
```

[Git LFS]: https://git-lfs.com

## The test screens

Every screen of the game can be tried in isolation, without going through the screens before it. The test menu lists them all and starts each in a window of its own (Esc there comes back to the menu):

```
$GODOT --path . scenes/tests/test_menu/test_menu.tscn
```

The test screens are small scenes in `scenes/tests/`, which instance the real scene with the settings of the test (e.g., `next_scene = ""`, so that a menu starts over instead of going on, or `first_part = 2` and `only_one_part = true` for the second part of the instruction). Add a test screen for every new screen, and list it in `scenes/tests/test_menu/test_menu.gd`. The pre-commit checks start every test screen headless (`smoke-scenes`).

`$GODOT --path .` starts the whole game from the language select. The options for every start: `--lang=<code>`, `--no-camera` (A/D and the arrow keys steer then) and `--no-music`.

In the instruction, Space skips it, Esc quits.

To look at the animation frame by frame without showing the webcam, render it to PNGs with Godot's movie maker:

```
$GODOT --path . scenes/tests/intro_test/intro_bird_dog_test.tscn --windowed --resolution 960x540 --fixed-fps 2 --write-movie /tmp/instruction/f.png --quit-after 130 -- --no-camera
```

## The pose test

The pose test checks that the camera set-up works (DESIGN.md, "The pose test"):

```
$GODOT --path . scenes/tests/pose_test/pose_test.tscn -- [--record[=DIR]] [--no-thumbnails] [--distance=2.0] [--note=TEXT]
```

* Put the laptop on a table or a chair, 1.5 to 2.5 m from the player, a bit higher than the player's back.
* The screen shows the mirrored camera, the head (yellow), the head line (dashed), the hands (green when raised, grey when down), the wheel pinned to the head, and the recognized pose. The higher the raised hand is above the head line, the harder the wheel turns (full at 1.5 head heights above the line).
* The keys:
  * **1** or **2**: one or two players (the picture is split in the middle),
  * **Up** and **Down**: move the head line (by default low, 5% above the bottom of the face, at the chin),
  * **P**: start or stop the recording protocol (rest, 5 left holds, 5 right holds, alternate, slowly raise each arm higher and higher, kneel up and wave, closer and farther; about 3 minutes),
  * **S**: save the tuned settings to `user://pose.json`, which the game loads at start,
  * **Esc**: quit.
* **Recording** happens only with `--record`. The detections (the boxes, the poses and the protocol step) go to `detections.jsonl`, and a small thumbnail (160x120) every 2 s, unless `--no-thumbnails`. The default directory is `user://pose_recordings/<session>/`, e.g., `~/.local/share/godot/app_userdata/Bird Dog/pose_recordings/` on Linux, outside of the repository.
  Record children only with their and their parents' consent, and do not commit the thumbnails.

Run the protocol at 1.5 m, 2 m and 2.5 m (pass `--distance=`), and once with two children side by side (`pose_test_two_players.tscn`).

## Translations

The game is written in English and translated to Russian (`ru`), Croatian in the Dalmatian ikavian dialect (`hr`), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Portuguese (`pt`), Albanian (`sq`) and Turkish (`tr`); see DESIGN.md, "Translations from the start".

* **In the code,** every text a player sees goes through `tr("...")` with the whole sentence and named placeholders (`tr("Ahoy, {captain}!").format({"captain": name})`). Never glue a sentence together from pieces. A comment `# TRANSLATORS: ...` right above the call reaches the translators, e.g., `# TRANSLATORS: caption, at most 80 characters` (the check enforces the limit).
* **Collect the messages** after changing texts:

  ```
  venv/bin/python dev/translations/extract.py
  ```

  This updates `translations/messages.pot` and merges it into every `translations/<code>.po`, keeping the existing translations.
* **Cases and numbers:** a translation may ask for a declined form of an inserted name, e.g., `Jidrite {port@to}!` gives "Jidrite u Pulu!" (the form of "Pula" with the context `to` in the same `.po` file), and a noun may agree with a number, e.g., `{ducats} {ducats|дукат|дуката|дукатов}`. The forms of the ports (`to`, `in`), the facts (`to`, `about`), the items, the hallmarks and the decorations (`acc`) are their own messages with that context; see `scenes/languages/grammar.gd`.
* **The captain's gender:** where a word depends on the addressed captains, write the forms in the translation: `{crew|Kapitän|Kapitänin|Kapitäne|Kapitäninnen}` (one haiduk, one haidukess, several captains, several haidukesses; the last two may be left out). The game picks the form for the captains in play.
* **Translate** the `.po` files with any PO editor (e.g., Poedit) or a text editor. A new translation stays marked as *fuzzy* until a native speaker has reviewed it in the game; the game shows it anyway (see `scenes/languages/languages.gd`).
* **Review in the game:** the game always shows the whole translation, the messages marked as *fuzzy* included (the mark only tells the translators what is not reviewed yet). Start with the language, then remove the fuzzy mark of the messages which read well:

  ```
  $GODOT --path . -- --lang=ru
  $GODOT --path . -- --lang=hr
  $GODOT --path . -- --lang=de   # or es, fr, it, pt, sq, tr
  ```

* **Add a language** with one entry in `translations/languages.json` (the code, e.g., `nl`, its name in itself, an optional second line, "Choose your language" in itself and its alphabet for the name keyboard; keep English first and the rest sorted by the code), then run `extract.py`, which creates `translations/nl.po`; set its `Plural-Forms` header, and add its plural rule to `Grammar.plural_index` if it is not "one and other" (as French and Russian). The game and the language select pick it up from the list.
* **Check** the coverage and the placeholders (`--verbose` lists the open messages):

  ```
  venv/bin/python dev/translations/check.py --verbose
  ```

The pre-commit checks run both scripts: they fail if the translation files are out of date or a translation breaks a placeholder.

## Music

The music is rendered from public-domain MIDI files (see DESIGN.md, "Music"). The rendered `.ogg` files are in the repository (in Git LFS), so you only need this when you change the list of pieces in `dev/assets/fetch_music.py`:

```
sudo apt install timidity fluid-soundfont-gm ffmpeg
venv/bin/python dev/assets/fetch_music.py
```

Start the game with `-- --no-music` to switch the music off; M mutes it while playing.

## Checks before a pull request

```
venv/bin/python dev/continuous_integration/precommit.py --overwrite
```

This re-formats the code, lints it, checks the translations, runs the .NET tests and the Godot tests (`tests/godot/`), starts every test screen (`tests/BirdDog.Tests/`), builds the game, imports the project and type-checks the scripts.

**The soak test** (`tests/soak/`) is too long for every commit: run it now and then, e.g., before a release. Every mission sails for minutes of game time with one and with two players, with wandering steering, and the test checks that no boat gets stuck, that the hazards do not pile up and that the objects in memory do not keep growing:

```
$GODOT --headless --path . -s tests/soak/soak_missions.gd -- --no-camera --no-music
```

**The soak test of the towing** tows boats from many random points at sea to the nearest port and checks that neither the towed boat nor the fishing boat goes onto the land, and that every tow ends with the fishing boat in the port. It prints its random seed, so that a failure can be repeated with `--seed=N`; `--towings=N` sets how many, and `--snapshots=DIR` saves pictures of the first four (run it in a window then, without `--headless`):

```
$GODOT --headless --path . -s tests/soak/soak_towing.gd -- --no-camera --no-music
```

### Commit messages

We follow Chris Beams' [guidelines on commit messages](https://chris.beams.io/posts/git-commit/).
