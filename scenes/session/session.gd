extends Node

## Keep the current voyage (a session) of the players and save it: its name,
## the crew (see the Crew autoload) and how far the crew came in the missions
## (see DESIGN.md, section 7).
##
## Every voyage is a JSON file in `user://saves/`. We save it after every
## step which matters (a new voyage, the captains, a finished mission), and
## whenever a player presses F5. F6 loads the last save of the voyage again.
##
## Which missions are unlocked is not stored: the first mission is always
## open, and every finished mission opens the next one. So the saves can never
## disagree with themselves.

## The voyage was loaded from its save (e.g., after F6).
signal loaded

## The format of the save files; bump it and convert the old files on load when
## the format changes (see [method upgrade]). Format 2 has no chest of the crew
## any more: the ducats of a mission in progress are all on board.
const FORMAT := 2

## The scene which F6 returns to after loading.
const MISSION_SELECT := "res://scenes/mission_select/mission_select.tscn"

## The longest name of a voyage.
const MAX_NAME_LENGTH := 24

## The directory of the save files, and the settings which remember the last
## voyage (the tests use others).
## A new voyage starts with this many ducats on board.
const STARTING_DUCATS := 40

## The yataks (the haiduks' secret friends, in Croatian "jataci") collect this
## many ducats for the crew in every mission, given at its end, once per
## mission (see DESIGN.md, section 10).
const YATAK_DUCATS := 20

var saves_dir := "user://saves"
var settings_path := "user://settings.cfg"

## The id of the current voyage (the name of its file), or "" before one.
var id := ""

## The name which the players gave the voyage.
var voyage_name := ""

var created := ""

## The missions by their id, each with "stars" (0 to 3) and "completed".
var missions := {}

## The mission which the crew chose last, for the mission screens.
var current_mission := ""

## The crew's ducats between the missions, carried over from mission to
## mission. There is no chest at home: a mission takes them all on board (see
## MissionRun.bring), where the corsairs and the patrols can take them, and
## brings back what is left when it is finished.
var ducats := 0

## The ids of the decorations which the crew bought in Master Ivan's
## shipyard; what is bought stays bought.
var owned: Array[String] = []

## The mission in progress, as plain data (see the mission screen): the state
## of its run, the boats and the visited ports; {} for none.
var mission_in_progress := {}

## The ids of the tips which the crew has seen (see the mission screen); every
## tip shows once per voyage.
var hints_seen: Array[String] = []

## Whether the mission screen should continue the mission in progress (the
## mission select asks the crew); not saved.
var resume_mission := false

var _toast: Label
var _toast_time := 0.0

@onready var _crew: Node = get_node("/root/Crew")


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _toast = Label.new()
    _toast.position = Vector2(1560, 30)
    _toast.size = Vector2(330, 60)
    _toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _toast.add_theme_font_size_override("font_size", 36)
    _toast.add_theme_color_override("font_color", Paper.INK)
    _toast.add_theme_color_override("font_outline_color", Paper.CARD)
    _toast.add_theme_constant_override("outline_size", 10)
    _toast.visible = false
    layer.add_child(_toast)


func _process(delta: float) -> void:
    if _toast.visible:
        _toast_time -= delta
        _toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
        _toast.visible = _toast_time > 0.0


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if id == "":
        return
    match event.keycode:
        KEY_F5:
            save()
            _show_toast(tr("Saved"))
        KEY_F6:
            if load_voyage(id):
                _show_toast(tr("Loaded"))
                get_tree().change_scene_to_file(MISSION_SELECT)


func _show_toast(text: String) -> void:
    _toast.text = text
    _toast_time = 2.0
    _toast.visible = true


## The name of a new voyage before the players change it: the date and the time.
static func default_name() -> String:
    var now := Time.get_datetime_dict_from_system()
    return (
        "%04d-%02d-%02d %02d:%02d"
        % [now["year"], now["month"], now["day"], now["hour"], now["minute"]]
    )


## Start a new voyage with the given name; the crew comes next.
func start(new_name: String) -> void:
    var now := Time.get_datetime_dict_from_system()
    id = (
        "%04d%02d%02d-%02d%02d%02d"
        % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]
    )
    voyage_name = new_name.strip_edges().substr(0, MAX_NAME_LENGTH)
    if voyage_name == "":
        voyage_name = default_name()
    created = Time.get_datetime_string_from_system()
    missions = {}
    current_mission = ""
    ducats = STARTING_DUCATS
    owned.clear()
    hints_seen.clear()
    mission_in_progress = {}
    save()


func _path(voyage_id: String) -> String:
    return "%s/%s.json" % [saves_dir, voyage_id]


func to_data() -> Dictionary:
    return {
        "format": FORMAT,
        "id": id,
        "name": voyage_name,
        "created": created,
        "updated": Time.get_datetime_string_from_system(),
        "crew": _crew.to_data(),
        "missions": missions.duplicate(true),
        "ducats": ducats,
        "owned": owned.duplicate(),
        "mission_in_progress": mission_in_progress.duplicate(true),
        "hints_seen": hints_seen.duplicate(),
    }


## Save the voyage. We write a temporary file first and then rename it, so that
## a crash while saving never destroys the last good save.
func save() -> void:
    if id == "":
        return
    DirAccess.make_dir_recursive_absolute(saves_dir)
    var path := _path(id)
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        push_error("Could not save the voyage to %s: %s" % [temporary, FileAccess.get_open_error()])
        return
    file.store_string(JSON.stringify(to_data(), "  "))
    file.close()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    DirAccess.rename_absolute(temporary, path)
    _remember_last()


func _remember_last() -> void:
    var settings := ConfigFile.new()
    settings.load(settings_path)
    settings.set_value("general", "last_voyage", id)
    settings.save(settings_path)


## Read the save of a voyage; null if it is missing or broken.
func read(voyage_id: String) -> Variant:
    var path := _path(voyage_id)
    if not FileAccess.file_exists(path):
        return null
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary or int(data.get("format", 0)) > FORMAT:
        return null
    return upgrade(data)


## Convert the save of an older format to the current one.
static func upgrade(data: Dictionary) -> Dictionary:
    if int(data.get("format", 1)) < 2:
        # NOTE (mristin):
        # Format 1 kept the ducats in a chest of the crew at home and only
        # what a mission earned on board (a boat could even spend more than it
        # carried, from the chest). Now all the ducats are on board: the chest
        # goes into the boats of the mission in progress, split as at the start
        # of a mission, and stays the ducats of the voyage between missions.
        var chest := int(data.get("ducats", 0))
        var run: Dictionary = data.get("mission_in_progress", {}).get("run", {})
        var holds: Array = run.get("holds", [])
        if not holds.is_empty():
            var total := chest
            for hold in holds:
                total += int(hold.get("ducats", 0)) - int(hold.get("spent", 0))
            total = maxi(0, total)
            var each := total / holds.size()
            for i in range(holds.size()):
                holds[i]["ducats"] = each + (total - each * holds.size() if i == 0 else 0)
                holds[i]["spent"] = 0
            run["brought"] = chest
        data["format"] = 2
    return data


## Load a voyage and its crew; return whether it worked.
func load_voyage(voyage_id: String) -> bool:
    var data: Variant = read(voyage_id)
    if data == null:
        return false
    id = voyage_id
    voyage_name = data.get("name", voyage_id)
    created = data.get("created", "")
    missions = data.get("missions", {})
    ducats = int(data.get("ducats", 0))
    owned.clear()
    for decoration_id in data.get("owned", []):
        owned.append(str(decoration_id))
    mission_in_progress = data.get("mission_in_progress", {})
    hints_seen.clear()
    for hint in data.get("hints_seen", []):
        hints_seen.append(str(hint))
    current_mission = ""
    _crew.from_data(data.get("crew", {}))
    _remember_last()
    loaded.emit()
    return true


## The saved voyages, the most recently played first, each with "id", "name",
## "updated", "captains" (the names) and "stars".
func list() -> Array[Dictionary]:
    var voyages: Array[Dictionary] = []
    # NOTE (mristin):
    # At the very first start, nothing is saved yet, not even the directory.
    if not DirAccess.dir_exists_absolute(saves_dir):
        return voyages
    for file in DirAccess.get_files_at(saves_dir):
        if not file.ends_with(".json"):
            continue
        var voyage_id := file.get_basename()
        var data: Variant = read(voyage_id)
        if data == null:
            continue
        var names: Array[String] = []
        for captain in data.get("crew", {}).get("captains", []):
            names.append(str(captain.get("name", "")))
        var stars := 0
        for state in data.get("missions", {}).values():
            stars += int(state.get("stars", 0))
        (
            voyages
            . append(
                {
                    "id": voyage_id,
                    "name": data.get("name", voyage_id),
                    "updated": data.get("updated", ""),
                    "captains": names,
                    "stars": stars,
                }
            )
        )
    voyages.sort_custom(func(a, b): return a["updated"] > b["updated"])
    return voyages


## The id of the voyage played last, if its save still exists, else "".
func last_id() -> String:
    var settings := ConfigFile.new()
    if settings.load(settings_path) != OK:
        return ""
    var voyage_id: String = settings.get_value("general", "last_voyage", "")
    if voyage_id == "" or read(voyage_id) == null:
        return ""
    return voyage_id


## Delete the save of a voyage; forget it as the last voyage, and as the
## current one, if it was.
func delete_voyage(voyage_id: String) -> void:
    var path := _path(voyage_id)
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    var settings := ConfigFile.new()
    if settings.load(settings_path) == OK:
        if settings.get_value("general", "last_voyage", "") == voyage_id:
            settings.set_value("general", "last_voyage", "")
            settings.save(settings_path)
    if id == voyage_id:
        id = ""
        voyage_name = ""
        missions = {}


func stars(mission_id: String) -> int:
    return int(missions.get(mission_id, {}).get("stars", 0))


func is_completed(mission_id: String) -> bool:
    return bool(missions.get(mission_id, {}).get("completed", false))


## Whether the crew may play the mission: the first one always, every other
## one once the mission before it is completed.
func is_unlocked(mission: Mission) -> bool:
    if mission.number <= 1:
        return true
    for other in MissionCatalog.all():
        if other.number == mission.number - 1:
            return is_completed(other.id)
    return false


## Buy a decoration with the ducats of the crew; return whether it worked.
func buy_decoration(decoration: Decoration) -> bool:
    if owned.has(decoration.id) or ducats < decoration.price:
        return false
    ducats -= decoration.price
    owned.append(decoration.id)
    save()
    return true


## The id of the mission in progress, or "".
func progress_of() -> String:
    return str(mission_in_progress.get("run", {}).get("mission", ""))


## Whether the mission in progress was played by as many players as the crew
## has now: a mission of two boats never continues with one, and vice versa.
func progress_fits(players: int) -> bool:
    return mission_in_progress.get("boats", []).size() == players


## Buy a ship with the ducats of the crew; return whether it worked.
func buy_ship(ship: Ship) -> bool:
    if owned.has(ship.id) or ducats < ship.price:
        return false
    ducats -= ship.price
    owned.append(ship.id)
    save()
    return true


## Whether the crew may visit Master Ivan's shipyard: after mission 2.
func has_shipyard() -> bool:
    for mission in MissionCatalog.all():
        if mission.number == 2:
            return is_completed(mission.id)
    return false


## The gift of the yataks at the end of a mission, only the first time the
## mission is finished in the voyage (so that playing it again is no farm of
## ducats); return how many ducats they collected. They count for the voyage
## at once, and the mission puts them on board.
func yatak_gift(mission_id: String) -> int:
    var state: Dictionary = missions.get(mission_id, {})
    if state.get("gifted", false):
        return 0
    state["gifted"] = true
    missions[mission_id] = state
    ducats += YATAK_DUCATS
    save()
    return YATAK_DUCATS


## Record a finished mission with its stars (keeping the best stars) and the
## ducats left on board of its boats (-1 keeps the ducats as they are), and
## save.
func complete(mission_id: String, earned_stars: int, on_board := -1) -> void:
    if on_board >= 0:
        ducats = on_board
    if progress_of() == mission_id:
        mission_in_progress = {}
    var state: Dictionary = missions.get(mission_id, {})
    state["completed"] = true
    state["stars"] = maxi(int(state.get("stars", 0)), clampi(earned_stars, 0, 3))
    missions[mission_id] = state
    save()
