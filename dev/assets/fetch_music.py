#!/usr/bin/env python3

"""
Download the music of the game and render it for Godot.

The pieces are from the Adriatic around 1600, as public-domain MIDI files of
the Mutopia Project (each marked "Public Domain", i.e., no rights reserved).
See DESIGN.md, "Music". For every piece, we:

1. download the MIDI file into .cache/music/ and check its SHA-256,
2. copy it to assets/music/midi/ (the source, kept in the repository),
3. give the parts the instruments of the time (organ, harpsichord, recorders,
   a plucked string for the lute) and end the piece at its last note,
4. render it with TiMidity++ and the FluidR3 General MIDI sound font (MIT) to a
   WAV, and encode it with ffmpeg as Ogg Vorbis into assets/music/,
5. and write assets/music/manifest.json with the provenance of every piece.

Godot cannot play MIDI, so the game plays the rendered .ogg files. Run this
script again after changing the list; it skips nothing, so the output always
matches the list.
"""

import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from typing import List, Optional

import mido

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
CACHE_DIR = REPO_ROOT / ".cache" / "music"
MUSIC_DIR = REPO_ROOT / "assets" / "music"
MIDI_DIR = MUSIC_DIR / "midi"

DEFAULT_SOUND_FONT = pathlib.Path("/usr/share/sounds/sf2/FluidR3_GM.sf2")

MUTOPIA = "https://www.mutopiaproject.org"
LICENSE = "Public Domain (Mutopia Project: no rights reserved)"

#: General MIDI programs of the instruments of the time.
ORGAN = 19
HARPSICHORD = 6
RECORDER = 74
NYLON_GUITAR = 24

#: The pieces: the file name in the game, the title, the composer, the year, the
#: original edition, the Mutopia piece id, the path of the MIDI file on Mutopia,
#: its SHA-256, and the General MIDI program for each MIDI channel.
PIECES = [
    {
        "id": "banchieri_sonata_1",
        "title": "Sonata prima (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        "mutopia_id": 31,
        "path": "/ftp/BanchieriA/Reg1_Suon1/Reg1_Suon1.mid",
        "sha256": "4323ab0dcef62bc0bb721ba1ae15a4f824e4d56d31501114a22517bd37269888",
        "programs": {0: ORGAN, 1: ORGAN},
    },
    {
        "id": "banchieri_sonata_2",
        "title": "Sonata seconda (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        "mutopia_id": 32,
        "path": "/ftp/BanchieriA/Reg1_Suon2/Reg1_Suon2.mid",
        "sha256": "8efd8ae28c12ff81d9ab639a13bd76d73e1fbef93313f0f419e69557ee334374",
        "programs": {0: HARPSICHORD, 1: HARPSICHORD},
    },
    {
        "id": "banchieri_sonata_3",
        "title": "Sonata terza (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        "mutopia_id": 33,
        "path": "/ftp/BanchieriA/Reg1_Suon3/Reg1_Suon3.mid",
        "sha256": "3443038bb7c5eb050eb176385c8104ce446eb178a1f51e7903f3578bed782b51",
        "programs": {0: RECORDER, 1: RECORDER},
    },
    {
        "id": "banchieri_sonata_4",
        "title": "Sonata quarta (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        "mutopia_id": 34,
        "path": "/ftp/BanchieriA/Reg1_Suon4/Reg1_Suon4.mid",
        "sha256": "f01ef81cbeb2fe66338e3de463455e4c36fecc04bddc9c2603b9f4c51728026d",
        "programs": {0: ORGAN, 1: ORGAN},
    },
    {
        "id": "banchieri_sonata_5",
        "title": "Sonata quinta (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        # NOTE (mristin):
        # The MIDI file of Mutopia sets a tempo ten times too slow (14 instead of
        # 140 beats per minute, unlike the other sonatas of the set), so we fix it.
        "tempo": 428571,
        "mutopia_id": 35,
        "path": "/ftp/BanchieriA/Reg1_Suon5/Reg1_Suon5.mid",
        "sha256": "2b2b93267ea9fbd114e21b2fbfc7441d26a832cb6371299446e5e3aa73c18ffe",
        "programs": {0: HARPSICHORD, 1: HARPSICHORD},
    },
    {
        "id": "banchieri_sonata_6",
        "title": "Sonata sesta (L'organo suonarino)",
        "composer": "Adriano Banchieri (1568–1634)",
        "year": 1605,
        "edition": "L'organo suonarino, Ricciardo Amadino, Venezia, 1605",
        # NOTE (mristin):
        # The MIDI file of Mutopia sets a tempo ten times too slow (14 instead of
        # 140 beats per minute, unlike the other sonatas of the set), so we fix it.
        "tempo": 428571,
        "mutopia_id": 36,
        "path": "/ftp/BanchieriA/Reg1_Suon6/Reg1_Suon6.mid",
        "sha256": "d6c69f8ab0f0a4c98fc2ddde6ff493eab62557fa7b8700a6f6b3a0e173694610",
        "programs": {0: RECORDER, 1: RECORDER},
    },
    {
        "id": "galilei_saltarello",
        "title": "Saltarello",
        "composer": "Vincenzo Galilei (c. 1520–1591)",
        "year": 1584,
        "edition": "Lute music of the late 16th century (source of the edition unknown)",
        "mutopia_id": 110,
        "path": "/ftp/GalileiV/saltarello/saltarello.mid",
        "sha256": "5d934a2d4e4fb86e7173997c063d447d36cb1d7ec461ed80a80a9764aacf410b",
        "programs": {0: NYLON_GUITAR},
    },
]


def _sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def download(piece: dict) -> pathlib.Path:
    """Download the MIDI file of the piece (once) and check its hash."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    target = CACHE_DIR / f"{piece['id']}.mid"
    if not target.exists():
        url = MUTOPIA + piece["path"]
        print(f"Downloading {url}")
        with urllib.request.urlopen(url, timeout=60) as response:
            target.write_bytes(response.read())

    digest = _sha256(target)
    if digest != piece["sha256"]:
        target.unlink()
        raise RuntimeError(
            f"The SHA-256 of {piece['id']} is {digest}, but we expected {piece['sha256']}"
        )
    return target


def arrange(
    source: pathlib.Path, programs: dict, target: pathlib.Path, tempo: Optional[int] = None
) -> float:
    """
    Set the instruments of the channels and end the piece at its last note.

    Return the length of the arranged piece in seconds.
    """
    midi = mido.MidiFile(str(source))

    # NOTE (mristin):
    # Some files carry an event long after the last note (e.g., a late end of
    # track), which would add minutes of silence.
    last_note = 0
    for track in midi.tracks:
        tick = 0
        for message in track:
            tick += message.time
            if message.type in ("note_on", "note_off"):
                last_note = max(last_note, tick)

    arranged = mido.MidiFile(type=midi.type, ticks_per_beat=midi.ticks_per_beat)
    for track in midi.tracks:
        new_track = mido.MidiTrack()
        tick = 0
        seen_channels = set()
        for message in track:
            tick += message.time
            if tick > last_note and not message.is_meta:
                continue
            if message.type == "program_change":
                message = message.copy(program=programs.get(message.channel, message.program))
            if message.type == "set_tempo" and tempo is not None:
                message = message.copy(tempo=tempo)
            if hasattr(message, "channel") and message.channel not in seen_channels:
                seen_channels.add(message.channel)
                if message.type != "program_change" and message.channel in programs:
                    new_track.append(
                        mido.Message(
                            "program_change",
                            channel=message.channel,
                            program=programs[message.channel],
                            time=0,
                        )
                    )
            if message.is_meta and message.type == "end_of_track":
                continue
            new_track.append(message)

        # NOTE (mristin):
        # We recompute the delta times from the absolute ticks, cut at the last
        # note, so that the end of the track comes right after the music.
        new_track.append(mido.MetaMessage("end_of_track", time=0))
        arranged.tracks.append(_retime(new_track, last_note))

    arranged.save(str(target))
    return mido.MidiFile(str(target)).length


def _retime(track: mido.MidiTrack, last_tick: int) -> mido.MidiTrack:
    """Clamp the absolute times of the messages to the last tick."""
    result = mido.MidiTrack()
    absolute = 0
    previous = 0
    for message in track:
        absolute += message.time
        clamped = min(absolute, last_tick)
        result.append(message.copy(time=clamped - previous))
        previous = clamped
    return result


def render(midi_path: pathlib.Path, sound_font: pathlib.Path, target: pathlib.Path) -> None:
    """Render the MIDI file to Ogg Vorbis, with a short fade at the end."""
    # NOTE (mristin):
    # The temporary files live in the cache, not in /tmp, since ffmpeg from a
    # snap package can not see the /tmp of the system.
    with tempfile.TemporaryDirectory(dir=CACHE_DIR) as tmp:
        wav = pathlib.Path(tmp) / "piece.wav"
        subprocess.run(
            [
                "timidity",
                "--quiet=2",
                "-x",
                f"soundfont {sound_font}",
                "-s",
                "44100",
                "-Ow",
                "-o",
                str(wav),
                str(midi_path),
            ],
            check=True,
        )
        subprocess.run(
            [
                "ffmpeg",
                "-loglevel",
                "error",
                "-y",
                "-i",
                str(wav),
                "-af",
                "silenceremove=stop_periods=-1:stop_duration=1.5:stop_threshold=-60dB,"
                "loudnorm=I=-20:TP=-2:LRA=11",
                "-ar",
                "44100",
                "-ac",
                "2",
                "-c:a",
                "libvorbis",
                "-q:a",
                "4",
                str(target),
            ],
            check=True,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sound-font",
        type=pathlib.Path,
        default=DEFAULT_SOUND_FONT,
        help=f"The General MIDI sound font for the rendering (default: {DEFAULT_SOUND_FONT})",
    )
    args = parser.parse_args()

    for tool in ("timidity", "ffmpeg"):
        if shutil.which(tool) is None:
            print(f"{tool} is missing; please install it (see CONTRIBUTING.md).", file=sys.stderr)
            return 1
    if not args.sound_font.exists():
        print(f"The sound font {args.sound_font} does not exist.", file=sys.stderr)
        return 1

    MIDI_DIR.mkdir(parents=True, exist_ok=True)
    manifest: List[dict] = []
    for piece in PIECES:
        source = download(piece)
        shutil.copyfile(source, MIDI_DIR / f"{piece['id']}.mid")

        with tempfile.TemporaryDirectory(dir=CACHE_DIR) as tmp:
            arranged = pathlib.Path(tmp) / "arranged.mid"
            length = arrange(source, piece["programs"], arranged, piece.get("tempo"))
            ogg = MUSIC_DIR / f"{piece['id']}.ogg"
            render(arranged, args.sound_font, ogg)
        print(f"Rendered {ogg.relative_to(REPO_ROOT)} ({length:.0f} s)")

        manifest.append(
            {
                "id": piece["id"],
                "file": f"{piece['id']}.ogg",
                "midi": f"midi/{piece['id']}.mid",
                "title": piece["title"],
                "composer": piece["composer"],
                "year": piece["year"],
                "edition": piece["edition"],
                "source": f"{MUTOPIA}/cgibin/piece-info.cgi?id={piece['mutopia_id']}",
                "license": LICENSE,
                "midi_sha256": piece["sha256"],
                "rendered_with": "TiMidity++ and the FluidR3 GM sound font (MIT)",
            }
        )

    (MUSIC_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=4, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(manifest)} piece(s) and assets/music/manifest.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
