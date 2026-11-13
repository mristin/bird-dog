# Saved voyages of older versions

The test `tests/godot/test_old_voyages.gd` loads these voyages (copies of them, in a directory of its own) and checks that they are still playable.

* `latest_played.json`: a copy of the voyage played last with the game of chapter 1 only (missions 1 to 13 completed, 682 ducats, the streamers bought).
* `latest_played_mission_in_progress.json`: the same voyage, saved by that game (commit 51076df) in the middle of mission 14: the briefing done and two of the three witnesses on board.

Never change these files: they are what the players have on their disks.
