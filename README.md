# bird-dog

Sail your bird-dog-powered ships through treacherous waters.

![Bird Dog: the bird-dog instruction, sailing to Pag and a port](docs/bird-dog.gif)

**Bird Dog is a sailing and detective game for children, played by doing the "bird dog" exercise in front of a webcam.**
Around the year 1600, a haiduk rows out of Pula across the Adriatic, follows clues from port to port, and spoils the plans of the greedy Aga Grdan.
One or two players play together; nobody fights.

See [DESIGN.md](DESIGN.md) for the design, and [CONTRIBUTING.md](CONTRIBUTING.md) for how to run the pose test, the first part that works.

**No network access.**
The game runs entirely on your computer and works offline.
The webcam images are processed locally, in memory, and are never sent anywhere.

## Supported systems

You need a webcam which supports 640x480.

| System | The webcam | Without the webcam |
|---|---|---|
| **Linux** (x86_64) | ✅ | ✅ |
| **macOS 11 or later** (Apple Silicon and Intel) | ✅ (macOS asks for the permission on the first start) | ✅ |
| **macOS 10.15** | ❌ (the hand tracking needs macOS 11) | ✅ |
| **Windows** (x86_64) | ❌ (Godot 4.6 does not support cameras on Windows yet) | ✅ |

Without the webcam, the players steer with A/D or the arrow keys.

The macOS app is not notarized: open it the first time with a right click and Open.

The packages for Windows and macOS are built, but not yet tested on those systems; please report any problems.

## License

Bird Dog is licensed under the [MIT License](LICENSE).
The third-party components, e.g., Godot Engine, ONNX Runtime and the models, keep their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
