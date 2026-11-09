extends Node

## Play the music of the Adriatic around 1600 for the whole game.
##
## The pieces and their provenance are listed in `res://assets/music/manifest.json`
## (see dev/assets/fetch_music.py and DESIGN.md, "Music"). We play them in a
## shuffled order, never the same piece twice in a row, and fade each one in.
##
## M mutes and unmutes the music; the choice is remembered. Start the game with
## `-- --no-music` to switch the music off, e.g., for the tests and the renders.

const _MANIFEST_PATH := "res://assets/music/manifest.json"
const _SETTINGS_PATH := "user://settings.cfg"

## The volume of the music, in decibels; the music stays in the background.
const VOLUME_DB := -9.0

const _FADE_SECONDS := 2.0
const _PAUSE_SECONDS := 1.5

var _paths: Array[String] = []
var _order: Array[String] = []
var _last := ""
var _muted := false
var _enabled := true

var _player: AudioStreamPlayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _enabled = "--no-music" not in OS.get_cmdline_user_args()

    var settings := ConfigFile.new()
    if settings.load(_SETTINGS_PATH) == OK:
        _muted = settings.get_value("general", "music_muted", false)

    var manifest: JSON = load(_MANIFEST_PATH)
    if manifest != null:
        for piece in manifest.data:
            _paths.append("res://assets/music/" + str(piece["file"]))

    _player = AudioStreamPlayer.new()
    _player.volume_db = VOLUME_DB
    _player.finished.connect(_on_finished)
    add_child(_player)

    if _enabled and not _paths.is_empty():
        _play_next()


# NOTE (mristin):
# Let go of the piece at the exit.
func _exit_tree() -> void:
    _player.stop()
    _player.stream = null


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
        set_muted(not _muted)


func is_muted() -> bool:
    return _muted


func set_muted(muted: bool) -> void:
    _muted = muted
    _player.stream_paused = muted

    var settings := ConfigFile.new()
    settings.load(_SETTINGS_PATH)
    settings.set_value("general", "music_muted", muted)
    settings.save(_SETTINGS_PATH)


func _play_next() -> void:
    if _order.is_empty():
        _order = _paths.duplicate()
        _order.shuffle()
        if _order.size() > 1 and _order[0] == _last:
            _order.push_back(_order.pop_front())

    _last = _order.pop_front()
    # NOTE (mristin):
    # A piece is loaded past the cache of the resources: the audio thread lets
    # go of the playing piece only some time after it stops, which may be after
    # the engine clears the cache at the exit ("2 resources still in use at
    # exit"). Nothing else shares the pieces, so the cache brings nothing.
    _player.stream = ResourceLoader.load(_last, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
    _player.volume_db = -60.0
    _player.play()
    _player.stream_paused = _muted
    create_tween().tween_property(_player, "volume_db", VOLUME_DB, _FADE_SECONDS)


func _on_finished() -> void:
    await get_tree().create_timer(_PAUSE_SECONDS).timeout
    _play_next()
