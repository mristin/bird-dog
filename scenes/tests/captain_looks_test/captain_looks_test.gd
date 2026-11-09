extends MenuScreen

## Show many looks of the captain side by side, to check the 3D figure: the hair
## styles, the caps, the faces, the skins and the colours. "Random" mixes new
## looks; Esc quits.

const _COUNT := 6

var _previews: Array[CaptainPreview] = []


func _build() -> void:
    for i in range(_COUNT):
        var preview := CaptainPreview.new()
        preview.position = Vector2(70 + i * 300, 150)
        preview.size = Vector2(280, 760)
        add_child(preview)
        _previews.append(preview)

    var button := HandButton.new()
    button.text = "Random"
    button.position = Vector2(810, 950)
    button.size = Vector2(300, 80)
    button.pressed.connect(_randomize)
    add_child(button)
    _randomize.call_deferred()


func _randomize() -> void:
    for i in range(_previews.size()):
        var looks := CaptainOptions.default_looks(i % 2)
        looks = CaptainOptions.with_gender(looks, CaptainOptions.GENDERS[i % 2])
        _previews[i].set_looks(CaptainOptions.random_looks(looks))


func _draw_screen() -> void:
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 110),
        "Captain looks   (Esc: quit)",
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        48,
        Paper.INK
    )
