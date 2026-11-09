extends MenuScreen

## Let the players continue their last voyage, start a new one, or go on with
## one of their other voyages (see DESIGN.md, section 7).
##
## A new voyage goes on to [member next_scene] (naming the voyage, then the
## captains); a voyage which goes on skips straight to the missions. Every
## voyage has a Delete button below it, which asks before it deletes.

## Show at most this many other voyages.
const _MAX_OTHERS := 4

## The scene of the missions, where a continued voyage goes on.
@export_file("*.tscn") var missions_scene := "res://scenes/mission_select/mission_select.tscn"

var _busy := false

@onready var _session: Node = get_node("/root/Session")


func _build() -> void:
    var voyages: Array[Dictionary] = _session.list()
    var last_id: String = _session.last_id()

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 80)
    top.alignment = BoxContainer.ALIGNMENT_CENTER
    top.position = Vector2(0, 200)
    top.size = Vector2(1920, 430)
    add_child(top)

    for voyage in voyages:
        if voyage["id"] == last_id:
            var resume := _card(tr("Continue"), _describe(voyage), Vector2(640, 330), 64)
            resume.selected = true
            resume.pressed.connect(_continue.bind(voyage["id"]))
            top.add_child(_with_delete(resume, voyage))

    var start := _card(tr("New voyage"), "", Vector2(520, 330), 64)
    start.pressed.connect(_new)
    top.add_child(start)

    var others := HBoxContainer.new()
    others.add_theme_constant_override("separation", 30)
    others.alignment = BoxContainer.ALIGNMENT_CENTER
    others.position = Vector2(0, 690)
    others.size = Vector2(1920, 290)
    add_child(others)
    var shown := 0
    for voyage in voyages:
        if voyage["id"] == last_id or shown >= _MAX_OTHERS:
            continue
        var card := _card(voyage["name"], _describe(voyage, false), Vector2(400, 200), 36)
        card.pressed.connect(_continue.bind(voyage["id"]))
        others.add_child(_with_delete(card, voyage))
        shown += 1


func _card(title: String, text: String, minimum: Vector2, title_size: int) -> HandButton:
    var card := HandButton.new()
    card.custom_minimum_size = minimum
    card.title = title
    card.title_size = title_size
    card.text = text
    card.text_size = 30
    return card


## Put a voyage's card above its Delete button.
func _with_delete(card: HandButton, voyage: Dictionary) -> VBoxContainer:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    column.add_child(card)
    var delete := HandButton.new()
    delete.custom_minimum_size = Vector2(card.custom_minimum_size.x, 70)
    delete.text = tr("Delete")
    delete.text_size = 28
    delete.symbol = "trash"
    delete.pressed.connect(_ask_delete.bind(voyage))
    column.add_child(delete)
    return column


func _ask_delete(voyage: Dictionary) -> void:
    if _busy:
        return
    var question := tr('Delete the voyage "{name}"? This can not be undone.').format(
        {"name": voyage["name"]}
    )
    var dialog := ConfirmDialog.ask(self, question, tr("Yes, delete"), tr("No, keep it"))
    dialog.confirmed.connect(_delete.bind(voyage["id"]))


func _delete(voyage_id: String) -> void:
    _session.delete_voyage(voyage_id)
    get_tree().reload_current_scene()


## Describe a voyage on its card: the name (unless it is the title), the
## captains and the stars.
func _describe(voyage: Dictionary, with_name := true) -> String:
    var parts: Array[String] = []
    if with_name:
        parts.append(voyage["name"])
    var captains: Array = voyage["captains"]
    if not captains.is_empty():
        parts.append(" & ".join(PackedStringArray(captains)))
    parts.append(tr("Stars: {stars}").format({"stars": voyage["stars"]}))
    return "  ·  ".join(PackedStringArray(parts))


func _continue(voyage_id: String) -> void:
    if _busy:
        return
    if not _session.load_voyage(voyage_id):
        push_warning("Could not load the voyage %s." % voyage_id)
        return
    _busy = true
    next_scene = missions_scene
    go_next(0.4)


func _new() -> void:
    if _busy:
        return
    _busy = true
    go_next(0.4)


func _draw_screen() -> void:
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 150),
        tr("Your voyages"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        64,
        Paper.RED
    )
