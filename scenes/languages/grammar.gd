class_name Grammar
extends RefCounted

## Fill the placeholders of a translated sentence with the right grammatical
## forms (see DESIGN.md, "Texts: what a translator sees" and CONTRIBUTING.md).
##
## Russian and Croatian decline the names and agree the nouns with the
## numbers, so a translation may ask for:
##
## * a form of an inserted word: [code]{port@to}[/code] takes the form of the
##   port's name with the context "to" from the .po file, e.g., "в Пулу" or
##   "na Hvar" (the form carries its preposition, since it differs between
##   the places: "в город", but "на остров"). Without such a form, the plain
##   name stands.
## * a noun which agrees with a number: [code]{ducats|дукат|дуката|дукатов}[/code]
##   picks the form for the number of [code]{ducats}[/code] by the plural rule
##   of the language (English: one, other; Russian and Croatian: one, few, many).
##
## The values of the arguments are English message IDs (translated here, with
## the asked form), lists of them (joined with commas) or numbers.
##
## The words which depend on who is addressed (e.g., "Kapitän" or
## "Kapitänin", "došao" or "došla") are a choice in the translation itself:
## [code]{crew|došao si|došla si|došli ste|došle ste}[/code] picks the form for
## one haiduk, one haidukess, several captains (or a man among them) and
## several haidukesses. A third or fourth form may be left out: several
## haidukesses then take the third form, and several captains the first. The
## choice is made when the message is translated (see AddressedTranslation),
## so it works in every text, not only in those with placeholders.

## The forms which the translations may ask for, by the kind of the value (see
## dev/translations/extract.py, which collects them).
const CONTEXTS := {
    "port": ["to", "in"],
    "fact": ["to", "about"],
    "item": ["acc"],
    "hallmark": ["acc"],
    "name": ["acc"],
}

## Who is addressed by the texts: -1 for the whole crew, or the index of the
## player whose captain alone is addressed (e.g., on the card of their boat).
static var addressed := -1

## The genders of the addressed captains, when they are not in the crew yet
## (e.g., the captain being created); empty to take them from the crew.
static var genders: Array[String] = []

## Pick the longest form of every [code]{crew|...}[/code] choice instead, so
## that a test can check that every form fits (see test_text_fit.gd).
static var longest_crew_forms := false

static var _crew_choice := RegEx.create_from_string("\\{crew\\|([^{}]*)\\}")

static var _placeholder := RegEx.create_from_string("\\{([a-z_]+)(@[a-z_]+|\\|[^{}]*)?\\}")


static func format(text: String, args: Dictionary) -> String:
    text = address(text)
    var result := ""
    var at := 0
    for match in _placeholder.search_all(text):
        result += text.substr(at, match.get_start() - at)
        at = match.get_end()
        var key := match.get_string(1)
        if not args.has(key):
            result += match.get_string()
            continue
        result += _fill(args[key], match.get_string(2))
    return result + text.substr(at)


static func _fill(value: Variant, how: String) -> String:
    if how.begins_with("|"):
        var forms := how.substr(1).split("|")
        return forms[mini(plural_index(int(value)), forms.size() - 1)]
    if value is Array:
        # NOTE (mristin):
        # A list of names, e.g., the ports where the loads wait.
        var names: Array[String] = []
        for each in value:
            names.append(_fill(each, how))
        return ", ".join(names)
    if not value is String:
        return str(value)
    if how.begins_with("@"):
        var form := String(TranslationServer.translate(value, how.substr(1)))
        if form != value:
            return form
    return String(TranslationServer.translate(value))


## Replace every [code]{crew|...}[/code] choice of a translated text with the
## form for the captains who are addressed.
static func address(text: String) -> String:
    if not "{crew|" in text:
        return text
    var result := ""
    var at := 0
    for match in _crew_choice.search_all(text):
        result += text.substr(at, match.get_start() - at)
        at = match.get_end()
        result += _crew_form(match.get_string(1).split("|"))
    return result + text.substr(at)


static func _crew_form(forms: PackedStringArray) -> String:
    if longest_crew_forms:
        var longest := ""
        for form in forms:
            if form.length() > longest.length():
                longest = form
        return longest
    var index := crew_index()
    if index == 3 and forms.size() < 4:
        index = 2
    if index == 2 and forms.size() < 3:
        index = 0
    return forms[mini(index, forms.size() - 1)]


## Which form of a [code]{crew|...}[/code] choice the addressed captains take:
## 0 for one haiduk, 1 for one haidukess, 2 for several captains with a haiduk
## among them, 3 for several haidukesses.
static func crew_index() -> int:
    var genders := _addressed_genders()
    if genders.size() == 1:
        return 1 if genders[0] == "hajducica" else 0
    return 2 if "hajduk" in genders else 3


## The genders ("hajduk" or "hajducica") of the addressed captains, from the
## Crew autoload (one haiduk without it, e.g., in a test of a single scene).
static func _addressed_genders() -> Array[String]:
    if not genders.is_empty():
        return genders.duplicate()
    var result: Array[String] = []
    var tree := Engine.get_main_loop() as SceneTree
    var crew: Node = tree.root.get_node_or_null("/root/Crew") if tree != null else null
    if crew == null:
        result.append("hajduk")
        return result
    var captains: Array = crew.captains
    if addressed >= 0 and addressed < captains.size():
        result.append(str(captains[addressed].get("gender", "hajduk")))
        return result
    for looks in captains:
        result.append(str(looks.get("gender", "hajduk")))
    if result.is_empty():
        result.append("hajduk")
    return result


## Which form of a noun goes with the number in the current language: 0 for
## one, 1 for a few (Russian and Croatian: 2 to 4), 2 for many. French counts
## zero as one ("0 ducat"); the other languages have one and other.
static func plural_index(count: int) -> int:
    var language := TranslationServer.get_locale().left(2)
    if language == "fr":
        return 0 if absi(count) <= 1 else 1
    if language in ["ru", "hr", "sr", "bs", "uk"]:
        var last := absi(count) % 10
        var last_two := absi(count) % 100
        if last == 1 and last_two != 11:
            return 0
        if last >= 2 and last <= 4 and (last_two < 12 or last_two > 14):
            return 1
        return 2
    return 0 if count == 1 else 1
