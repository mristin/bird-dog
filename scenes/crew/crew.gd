extends Node

## Hold the crew of the game: how many players play, and the looks of their
## captains (see CaptainOptions).
##
## For now the crew lives in memory; saving it into the slots of
## DESIGN.md, section 7, will build on [method to_data] and [method from_data].

## How many players play together: 1 or 2.
var players := 1

## The looks of the captain of every player.
var captains: Array[Dictionary] = [CaptainOptions.default_looks(0)]


## Start a new crew with the given number of players and the default captains.
func start(player_count: int) -> void:
    players = clampi(player_count, 1, 2)
    captains.clear()
    for i in range(players):
        var looks := CaptainOptions.default_looks(i)

        # NOTE (mristin):
        # The default names are written in the language of the game, so that
        # they match the letters of the keyboard on the screen.
        looks["name"] = tr("Liso") if i == 0 else tr("Mare")
        captains.append(looks)


func to_data() -> Dictionary:
    return {"players": players, "captains": captains.duplicate(true)}


func from_data(data: Dictionary) -> void:
    players = clampi(int(data.get("players", 1)), 1, 2)
    captains.clear()
    var saved: Array = data.get("captains", [])
    for i in range(players):
        var looks := CaptainOptions.default_looks(i)
        if i < saved.size():
            looks.merge(saved[i], true)
        captains.append(looks)
