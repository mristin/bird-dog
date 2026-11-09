class_name MissionCatalog
extends RefCounted

## Load all the missions from `res://data/missions/<nn>_<id>/mission.tres`.

const DIRECTORY := "res://data/missions"

static var _missions: Array[Mission] = []


## All the missions, in their order.
static func all() -> Array[Mission]:
    if _missions.is_empty():
        for folder in ResourceLoader.list_directory(DIRECTORY):
            var path := "%s/%smission.tres" % [DIRECTORY, folder]
            if folder.ends_with("/") and ResourceLoader.exists(path):
                var mission: Mission = load(path)
                if mission != null:
                    _missions.append(mission)
        _missions.sort_custom(func(a, b): return a.number < b.number)
    return _missions


static func by_id(mission_id: String) -> Mission:
    for mission in all():
        if mission.id == mission_id:
            return mission
    return null
