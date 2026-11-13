class_name MissionCatalog
extends RefCounted

## Load all the missions from `res://data/missions/<nn>_<id>/mission.tres`.

const DIRECTORY := "res://data/missions"
const CHAPTERS := "res://data/chapters"

static var _missions: Array[Mission] = []
static var _chapters: Array[Chapter] = []


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


## All the chapters, in their order.
static func chapters() -> Array[Chapter]:
    if _chapters.is_empty():
        for file in ResourceLoader.list_directory(CHAPTERS):
            if file.ends_with(".tres"):
                var chapter: Chapter = load("%s/%s" % [CHAPTERS, file])
                if chapter != null:
                    _chapters.append(chapter)
        _chapters.sort_custom(func(a, b): return a.number < b.number)
    return _chapters


static func chapter(number: int) -> Chapter:
    for candidate in chapters():
        if candidate.number == number:
            return candidate
    return null


## The missions of a chapter, in their order.
static func of_chapter(number: int) -> Array[Mission]:
    var result: Array[Mission] = []
    for mission in all():
        if mission.chapter == number:
            result.append(mission)
    return result


## The number of the mission within its chapter (mission 16 is the first of
## chapter 2).
static func number_in_chapter(mission: Mission) -> int:
    return of_chapter(mission.chapter).find(mission) + 1
