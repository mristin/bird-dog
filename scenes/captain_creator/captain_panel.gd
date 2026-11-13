class_name CaptainPanel
extends Control

## Let one player create their captain: the name, haiduk or haidukess, and the
## looks, with a 3D preview which changes at once (see DESIGN.md, "Creating a
## captain").
##
## Every choice is a row of big buttons: ◀ and ▶ step through the choices, and
## the middle shows the current one. "Random" mixes new looks, and "Ready!"
## finishes; "Change" goes back to editing, until all the players are ready and
## the panel is locked.
##
## The preview stands on the left and the rows on the right. With one player,
## the panel is wide; with two players, it is narrow, with a slimmer preview and
## smaller rows.

## The player is ready (or not any more).
signal ready_changed(is_ready: bool)

var player := 0
var looks: Dictionary = {}
var wide := true

var _layout: HBoxContainer
var _preview: CaptainPreview
var _rows: VBoxContainer
var _keyboard: NameKeyboard
var _ready_button: HandButton
var _random_button: HandButton
var _is_ready := false
var _locked := false

var _values := {}
var _gender_buttons := {}

var _row_height := 64.0
var _font_size := 30


func _ready() -> void:
    # NOTE (mristin):
    # The captains of older voyages have no eye patch yet.
    if not looks.has("eye_patch"):
        looks["eye_patch"] = "none"

    _row_height = 64.0 if wide else 62.0
    _font_size = 30 if wide else 26

    var layout := HBoxContainer.new()
    layout.set_anchors_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 30 if wide else 16)
    add_child(layout)
    _layout = layout

    _preview = CaptainPreview.new()
    _preview.custom_minimum_size = Vector2(620 if wide else 220, 0)
    _preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(_preview)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(right)

    _rows = VBoxContainer.new()
    _rows.add_theme_constant_override("separation", 8 if wide else 5)
    right.add_child(_rows)
    _build_rows()

    # NOTE (mristin):
    # While typing the name, the keyboard takes the whole panel, so that its
    # keys are as big as possible.
    _keyboard = NameKeyboard.new()
    _keyboard.visible = false
    _keyboard.finished.connect(_on_name_finished)
    add_child(_keyboard)

    _preview.set_looks(looks)
    _refresh()


## The names of the choices, translated.
func _choice_name(key: String, value: Variant) -> String:
    match key:
        "hair":
            return {
                "short": tr("Short"),
                "curly": tr("Curly"),
                "ponytail": tr("Ponytail"),
                "long": tr("Long"),
                "braid": tr("Braid"),
                "bun": tr("Bun"),
            }[value]
        "cap":
            return {
                "lika": tr("Lika cap"),
                "kalpak": tr("Kalpak"),
                "headscarf": tr("Headscarf"),
                "feather": tr("Feathered cap"),
                "none": tr("No cap"),
            }[value]
        "face":
            return {
                "moustache": tr("Moustache"),
                "plain": tr("Plain"),
                "freckles": tr("Freckles"),
                "moustache_freckles": tr("Moustache and freckles"),
            }[value]
        "eye_patch":
            return {
                "none": tr("No eye patch"),
                "left": tr("Left eye"),
                "right": tr("Right eye"),
            }[value]
    return str(value)


func _build_rows() -> void:
    _add_name_row()
    _add_gender_row()
    _add_choice_row("skin", tr("Skin"))
    _add_choice_row("hair", tr("Hair"))
    _add_choice_row("hair_color", tr("Hair colour"))
    _add_choice_row("cap", tr("Cap"))
    _add_choice_row("vest", tr("Vest"))
    _add_choice_row("sash", tr("Sash"))
    _add_choice_row("face", tr("Face"))
    _add_choice_row("eye_patch", tr("Eye patch"))

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 20)
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    _rows.add_child(actions)
    _random_button = _button(tr("Random"), Vector2(220 if wide else 180, _row_height * 1.2))
    _random_button.pressed.connect(_randomize)
    actions.add_child(_random_button)
    _ready_button = _button(_said("Ready!"), Vector2(260 if wide else 200, _row_height * 1.2))
    _ready_button.pressed.connect(_toggle_ready)
    actions.add_child(_ready_button)


func _button(text: String, minimum: Vector2) -> HandButton:
    var button := HandButton.new()
    button.text = text
    button.text_size = _font_size
    button.custom_minimum_size = minimum
    return button


func _row(label_text: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    var label := Label.new()
    label.text = label_text
    var width := 190.0 if wide else 150.0
    label.custom_minimum_size = Vector2(width, _row_height)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var font_size := HandButton.fit_size(ThemeDB.fallback_font, label_text, _font_size, width)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Paper.INK)
    row.add_child(label)
    _rows.add_child(row)
    return row


func _add_name_row() -> void:
    var row := _row(tr("Name"))
    var name_button := _button("", Vector2(400 if wide else 360, _row_height))
    name_button.text_size = int(_font_size * 1.2)
    name_button.pressed.connect(open_keyboard)
    row.add_child(name_button)
    _values["name"] = name_button


func _add_gender_row() -> void:
    var row := _row(tr("Captain"))
    for entry in [["hajduk", tr("Haiduk")], ["hajducica", tr("Haidukess")]]:
        var button := _button(entry[1], Vector2(195 if wide else 170, _row_height))
        button.pressed.connect(_set_gender.bind(entry[0]))
        row.add_child(button)
        _gender_buttons[entry[0]] = button


func _add_choice_row(key: String, label_text: String) -> void:
    var row := _row(label_text)
    var arrow_size := Vector2(_row_height * 1.1, _row_height)

    var previous := _button("", arrow_size)
    previous.arrow = -1
    previous.pressed.connect(_step.bind(key, -1))
    row.add_child(previous)

    var value := _button("", Vector2(260 if wide else 240, _row_height))
    row.add_child(value)
    _values[key] = value

    var next := _button("", arrow_size)
    next.arrow = 1
    next.pressed.connect(_step.bind(key, 1))
    row.add_child(next)


## The choices of the key for the gender of the captain.
func _choices(key: String) -> Array:
    var gender: String = looks["gender"]
    var choices := {
        "skin": range(CaptainOptions.SKINS.size()),
        "hair_color": range(CaptainOptions.HAIR_COLORS.size()),
        "vest": range(CaptainOptions.CLOTHS.size()),
        "sash": range(CaptainOptions.CLOTHS.size()),
        "hair": CaptainOptions.HAIR_STYLES[gender],
        "cap": CaptainOptions.CAPS,
        "face": CaptainOptions.FACES[gender],
        "eye_patch": CaptainOptions.EYE_PATCHES,
    }
    return choices.get(key, [])


func _step(key: String, direction: int) -> void:
    if _is_ready:
        return
    var choices := _choices(key)
    var index := choices.find(looks[key])
    looks[key] = choices[posmod(index + direction, choices.size())]
    _changed()


func _set_gender(gender: String) -> void:
    if _is_ready or looks["gender"] == gender:
        return
    looks = CaptainOptions.with_gender(looks, gender)
    _changed()


func _randomize() -> void:
    if _is_ready:
        return
    looks = CaptainOptions.random_looks(looks)
    _changed()


func _changed() -> void:
    _preview.set_looks(looks)
    _refresh()


func _refresh() -> void:
    _values["name"].text = looks["name"]
    for gender in _gender_buttons:
        _gender_buttons[gender].selected = looks["gender"] == gender

    var swatches := {
        "skin": CaptainOptions.SKINS,
        "hair_color": CaptainOptions.HAIR_COLORS,
        "vest": CaptainOptions.CLOTHS,
        "sash": CaptainOptions.CLOTHS,
    }
    for key in swatches:
        _values[key].swatch = swatches[key][int(looks[key])]
    for key in ["hair", "cap", "face", "eye_patch"]:
        _values[key].text = _choice_name(key, looks[key])

    _ready_button.text = _said("Change") if _is_ready else _said("Ready!")
    _ready_button.selected = _is_ready
    _random_button.visible = not _is_ready
    _ready_button.visible = not _locked


## Open the keyboard to type the name of the captain.
func open_keyboard() -> void:
    if _is_ready:
        return
    _layout.visible = false
    _keyboard.position = Vector2.ZERO
    _keyboard.size = size
    _keyboard.visible = true
    _keyboard.start(looks["name"])


func _on_name_finished(new_name: String) -> void:
    looks["name"] = new_name
    _keyboard.visible = false
    _layout.visible = true
    _refresh()


## Translate a text which addresses this captain alone, with the gender chosen
## right now (the crew learns the captains only when everybody is ready).
func _said(text: String) -> String:
    var before := Grammar.genders
    Grammar.genders = [str(looks.get("gender", "hajduk"))]
    var said := tr(text)
    Grammar.genders = before
    return said


func _toggle_ready() -> void:
    if _locked:
        return
    _is_ready = not _is_ready
    _refresh()
    ready_changed.emit(_is_ready)


func is_ready() -> bool:
    return _is_ready


## Lock the panel once all the players are ready: the crew sets off, so there is
## no going back to editing.
func lock() -> void:
    _locked = true
    _refresh()
