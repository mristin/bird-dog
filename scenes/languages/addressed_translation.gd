class_name AddressedTranslation
extends Translation

## A translation which picks the forms for the addressed captains: it looks a
## message up in the translation of the .po file and replaces every
## [code]{crew|...}[/code] choice in it (see [method Grammar.address]), so
## that "Kapitän" turns into "Kapitänin" for a haidukess in every text of the
## game, wherever it is shown.

## The translation of the .po file.
var inner: Translation


func _init(the_inner: Translation = null) -> void:
    inner = the_inner
    if inner != null:
        locale = inner.locale


func _get_message(src_message: StringName, context: StringName) -> StringName:
    var text := String(inner.get_message(src_message, context))
    return StringName(Grammar.address(text)) if text != "" else &""


func _get_plural_message(
    src_message: StringName, src_plural_message: StringName, n: int, context: StringName
) -> StringName:
    var text := String(inner.get_plural_message(src_message, src_plural_message, n, context))
    return StringName(Grammar.address(text)) if text != "" else &""
