# Third-party notices

Bird Dog is licensed under the MIT License; see [LICENSE](LICENSE).
This covers the code, the scenes and everything the game draws in code.

The hand and head tracking (`scenes/hand_tracker/`) and the fist classifier were taken over from [Splash 'n' Splat](https://github.com/mristin/splash-n-splat) (MIT, same author).

The game includes, or is built with, the following third-party components.
Each keeps its own license.
The release packages carry all the license texts in the directory `licenses/`; the Windows package also the license text of CameraServerExtension.

## Distributed with the game

### Godot Engine

* Version: 4.6.2 (.NET)
* License: MIT
* Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur
* Source: https://godotengine.org
* License text: [licenses/godot/LICENSE.txt](licenses/godot/LICENSE.txt)

Godot Engine itself includes third-party components under their own licenses, e.g., FreeType, the fonts and the image libraries.
Their notices are in [licenses/godot/COPYRIGHT.txt](licenses/godot/COPYRIGHT.txt), generated from the Godot binary with `dev/write_godot_licenses.gd`.

### .NET runtime

* License: MIT
* Copyright (c) .NET Foundation and Contributors
* Source: https://github.com/dotnet/runtime
* Third-party notices: https://github.com/dotnet/runtime/blob/main/THIRD-PARTY-NOTICES.TXT

The .NET build of Godot bundles the .NET runtime with the exported game.

### ONNX Runtime

* Package: `Microsoft.ML.OnnxRuntime` 1.19.2
* License: MIT
* Copyright (c) Microsoft Corporation
* Source: https://github.com/microsoft/onnxruntime
* License text and third-party notices: included in the release packages as `licenses/onnxruntime/LICENSE` and `licenses/onnxruntime/ThirdPartyNotices.txt`

### CameraServerExtension (only in the Windows package)

* Version: 2026.03.27 (the prebuilt Windows x86_64 library of the release)
* License: MIT
* Copyright (c) 2024-present Jason Kuo
* Source: https://github.com/j20001970/godot-cameraserver-extension
* License text: [addons/CameraServerExtension/LICENSE](addons/CameraServerExtension/LICENSE)

Godot 4.6 implements no camera on Windows; the extension provides it there, with Media Foundation.

### YOLOX-Body-Head-Hand (hand detection)

* File: `scenes/hand_tracker/yolox/model/yolox_n_body_head_hand_Nx3xHxW.onnx`
* License: Apache License 2.0
* Copyright (c) PINTO0309 (Katsuya Hyodo); based on YOLOX by Megvii (https://github.com/Megvii-BaseDetection/YOLOX)
* Source: https://github.com/PINTO0309/PINTO_model_zoo/tree/main/426_YOLOX-Body-Head-Hand, downloaded from the archive in its `download_n.sh` (SHA-256 recorded in `dev/computer_vision/models_manifest.json` of Splash 'n' Splat)
* License text: [scenes/hand_tracker/yolox/model/LICENSE](scenes/hand_tracker/yolox/model/LICENSE)

We distribute the model unmodified.

### YuNet (face landmarks)

* File: `scenes/hand_tracker/yunet/model/face_detection_yunet_2023mar_dynamic.onnx`
* License: MIT
* Copyright (c) 2020 Shiqi Yu
* Source: https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet, file `face_detection_yunet_2023mar.onnx` (SHA-256 `8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4`)
* License text: [scenes/hand_tracker/yunet/model/LICENSE](scenes/hand_tracker/yunet/model/LICENSE)

**Altered:** we made the height and the width of the input dynamic with `dev/models/make_yunet_dynamic.py`, so that it runs on small head crops; the graph and the weights are unchanged.

### Silicon Labs MLTK rock_paper_scissors (gesture classification)

* File: `scenes/hand_tracker/gesture/model/rock_paper_scissors_float32.onnx`
* License: Zlib
* Copyright (c) Silicon Laboratories Inc.
* Source: https://github.com/SiliconLabs/mltk/blob/master/mltk/models/siliconlabs/rock_paper_scissors.py, pre-trained archive `rock_paper_scissors.mltk.zip`
* License text: [scenes/hand_tracker/gesture/model/LICENSE.md](scenes/hand_tracker/gesture/model/LICENSE.md)

**Altered:** we converted the original Keras model (`rock_paper_scissors.h5`) to ONNX with tf2onnx (`dev/computer_vision/download_and_convert_models.py` of Splash 'n' Splat); the weights are unchanged.

### Our fist classifier

* File: `scenes/hand_tracker/gesture/model/fist_classifier.onnx`
* License: MIT (ours), like the game
* Trained by `dev/computer_vision/train_fist_classifier.py` of Splash 'n' Splat on its recordings, starting from the ImageNet weights of MobileNetV3-Small from Keras Applications (Apache License 2.0, https://github.com/keras-team/keras-applications; the weights were published by the Keras team under the same license)

### Music

* Files: `assets/music/*.ogg`, rendered from the MIDI files in `assets/music/midi/` by `dev/assets/fetch_music.py`; the provenance of every piece is recorded in `assets/music/manifest.json`.
* The compositions are in the public domain: Adriano Banchieri, the six sonatas of *L'organo suonarino* (Venice, 1605), and Vincenzo Galilei, *Saltarello* (c. 1580).
* The MIDI files are from the Mutopia Project (https://www.mutopiaproject.org, pieces 31–36 and 110), each released as Public Domain ("no rights reserved").
* **Altered:** we set the instruments, fixed the tempo of the fifth and the sixth sonata (ten times too slow in the MIDI file), cut the silence at the end, and rendered and normalized the audio.

### Period pictures

* Files: `assets/period/**/*.jpg`, made by `dev/assets/fetch_period_art.py`; the provenance of every picture (the Wikimedia Commons page, the original and its SHA-256) is recorded in `assets/period/manifest.json`.
* The town views and maps: Giovanni Francesco Camocio, *Isole famose, porti, fortezze, e terre maritime* (Venice, 1574); Giuseppe Rosaccio, *Viaggio da Venetia a Costantinopoli* (Venice, 1598); Giacomo Franco, *Venetia* (Venice, about 1597); Francesco Valegio, *Segna* (Venice, 1616); Matthäus Merian, *S. Veit am Flaum* (1649); Georg Braun and Frans Hogenberg, *Civitates Orbis Terrarum* (1572); Vincenzo Coronelli, *Isolario* (Venice, 1688); and the charts of Piri Reis, *Kitab-ı Bahriye* (a copy of the 17th century, Walters Art Museum). The costumes: Cesare Vecellio, *Habiti antichi et moderni* (1590), from the edition of 1860.
* License: public domain (the works and the scans, as marked on Wikimedia Commons).
* **Altered:** cropped, tinted to ink on paper and shrunk.

### The friends on the deck and the figureheads

* Files: `assets/images/friends/*.png` (the cat, the parrot, the dog and the goat, seen from above) and `assets/images/figureheads/*.png` (the dolphin, the lion, the seagull, the mermaid and the goat, seen from above).
* Made for Bird Dog with an image generator (ChatGPT), from our prompts.
* License: part of the game, under its MIT license.
* **Altered:** trimmed and shrunk (the friends to 256 × 256 pixels, the figureheads to 256 pixels high).

### Natural Earth (the chart)

* File: `data/world/adriatic_map.json`, made by `dev/maps/make_adriatic_map.py` from the 1:10m land and minor islands, v5.1.2.
* License: public domain (https://www.naturalearthdata.com/about/terms-of-use/)
* **Altered:** clipped to the Adriatic, projected to kilometres and simplified.

### FluidR3 GM sound font (in the rendered music)

* The instrument samples in `assets/music/*.ogg` come from the FluidR3 General MIDI sound font by Frank Wen.
* License: MIT
* Source: the `fluid-soundfont-gm` package of Debian and Ubuntu (`/usr/share/sounds/sf2/FluidR3_GM.sf2`)

## Used only for development, not distributed

| Component | Version | License | Source |
|---|---|---|---|
| xUnit.net (`xunit`, `xunit.runner.visualstudio`) | 2.9.3, 4.0.1 | Apache-2.0 | https://xunit.net |
| Microsoft.NET.Test.Sdk | 18.11.0 | MIT | https://github.com/microsoft/vstest |
| StbImageSharp | 2.30.16 | Unlicense or MIT | https://github.com/StbSharp/StbImageSharp |
| gdtoolkit (`gdformat`, `gdlint`) | 4.5.0 | MIT | https://github.com/Scony/godot-gdscript-toolkit |
| black | 24.10.0 | MIT | https://github.com/psf/black |
| polib | 1.2.0 | MIT | https://github.com/izimobil/polib |
| mido | 1.3.3 | MIT | https://github.com/mido/mido |
| TiMidity++, ffmpeg (rendering the music) | system packages | GPL-2.0 / LGPL-2.1+ | https://timidity.sourceforge.net, https://ffmpeg.org |

The test images in `tests/BirdDog.Tests/data/`:

* `astronaut_640x480.png` and `crew_of_six_640x480.png` are public-domain NASA photos: the scikit-image "astronaut" (Eileen Collins) and "Expedition 38 crew members pose for an in-flight crew portrait" (ISS038-E-054970).
* `rps/*.png` are images of the Silicon Labs rock/paper/scissors dataset v2 (Zlib).
