extends SceneTree
## Check the grammar of the translations (see Grammar): the nouns agree with
## the numbers by the plural rules of English, Russian and Croatian, and a
## translation gets the declined forms of the inserted names, or the plain
## name where a form is missing.

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var before := TranslationServer.get_locale()

    TranslationServer.set_locale("en")
    var english := "{ducats} {ducats|ducat|ducats}"
    _check(Grammar.format(english, {"ducats": 1}) == "1 ducat", "one ducat")
    _check(Grammar.format(english, {"ducats": 2}) == "2 ducats", "two ducats")

    TranslationServer.set_locale("ru")
    var russian := "{n} {n|дукат|дуката|дукатов}"
    var expected := {
        1: "дукат",
        2: "дуката",
        4: "дуката",
        5: "дукатов",
        11: "дукатов",
        12: "дукатов",
        14: "дукатов",
        21: "дукат",
        22: "дуката",
        25: "дукатов",
        101: "дукат",
        111: "дукатов",
    }
    for count in expected:
        var said := Grammar.format(russian, {"n": count})
        _check(said == "%d %s" % [count, expected[count]], "ru: %s" % said)

    TranslationServer.set_locale("hr")
    var croatian := "{n} {n|dukat|dukata|dukata}"
    _check(Grammar.format(croatian, {"n": 21}) == "21 dukat", "hr: 21 dukat")
    _check(Grammar.format(croatian, {"n": 13}) == "13 dukata", "hr: 13 dukata")

    TranslationServer.set_locale("fr")
    var french := "{n} {n|ducat|ducats}"
    _check(Grammar.format(french, {"n": 0}) == "0 ducat", "fr: 0 ducat")
    _check(Grammar.format(french, {"n": 1}) == "1 ducat", "fr: 1 ducat")
    _check(Grammar.format(french, {"n": 2}) == "2 ducats", "fr: 2 ducats")

    TranslationServer.set_locale("de")
    var german := "{n} {n|Dukat|Dukaten}"
    _check(Grammar.format(german, {"n": 0}) == "0 Dukaten", "de: 0 Dukaten")
    _check(Grammar.format(german, {"n": 1}) == "1 Dukat", "de: 1 Dukat")

    # NOTE (mristin):
    # A translation of our own, with a form of a port's name in a context.
    TranslationServer.set_locale("hr")
    var translation := Translation.new()
    translation.locale = "hr"
    translation.add_message("Pula", "Pula")
    translation.add_message("Pula", "u Pulu", "to")
    # NOTE (mristin):
    # A message of the test alone, so that the game's own translation of
    # Croatian does not answer it instead.
    translation.add_message("Test: sail to {port}!", "Jidrite {port@to}!")
    TranslationServer.add_translation(translation)
    var sail := TranslationServer.translate("Test: sail to {port}!")
    _check(Grammar.format(sail, {"port": "Pula"}) == "Jidrite u Pulu!", "the form of the port")
    _check(
        Grammar.format("Jidrite {port@to}!", {"port": "Atlantis"}) == "Jidrite Atlantis!",
        "without a form, the plain name"
    )
    _check(
        Grammar.format("{port}, {port@in}", {"port": "Atlantis"}) == "Atlantis, Atlantis",
        "plain forms"
    )
    _check(Grammar.format("{missing}", {}) == "{missing}", "an unknown placeholder stays")
    TranslationServer.remove_translation(translation)

    _check_crew()

    TranslationServer.set_locale(before)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## The forms for the addressed captains: one haiduk, one haidukess, several
## captains, several haidukesses, with the missing forms falling back.
func _check_crew() -> void:
    var crew: Node = root.get_node("/root/Crew")
    var saved: Array[Dictionary] = crew.captains.duplicate(true)
    var saved_players: int = crew.players
    var choice := "{crew|Kapitän|Kapitänin|Kapitäne|Kapitäninnen}"
    var cases := [
        [["hajduk"], "Kapitän"],
        [["hajducica"], "Kapitänin"],
        [["hajduk", "hajducica"], "Kapitäne"],
        [["hajducica", "hajducica"], "Kapitäninnen"],
    ]
    for case in cases:
        _set_crew(crew, case[0])
        var said := Grammar.address("Ahoi, %s!" % choice)
        _check(said == "Ahoi, %s!" % case[1], "crew %s: %s" % [case[0], said])

    _set_crew(crew, ["hajducica", "hajducica"])
    _check(Grammar.address("{crew|a|b|c}") == "c", "several haidukesses fall back to several")
    _check(Grammar.address("{crew|a|b}") == "a", "several fall back to the first form")

    _set_crew(crew, ["hajduk", "hajducica"])
    Grammar.addressed = 1
    _check(Grammar.address(choice) == "Kapitänin", "the captain of player 2 alone")
    Grammar.addressed = -1

    Grammar.genders.assign(["hajducica"])
    _check(Grammar.address(choice) == "Kapitänin", "the genders given before the crew knows them")
    Grammar.genders.clear()

    Grammar.longest_crew_forms = true
    _check(Grammar.address(choice) == "Kapitäninnen", "the longest form for the tests")
    Grammar.longest_crew_forms = false

    # NOTE (mristin):
    # A translation of our own, wrapped as the game wraps the .po files.
    _set_crew(crew, ["hajducica"])
    TranslationServer.set_locale("de")
    var translation := Translation.new()
    translation.locale = "de"
    translation.add_message("Test: ahoy, captain!", "Ahoi, {crew|Kapitän|Kapitänin}!")
    var addressed := AddressedTranslation.new(translation)
    TranslationServer.add_translation(addressed)
    _check(tr("Test: ahoy, captain!") == "Ahoi, Kapitänin!", "the translation picks the form")
    TranslationServer.remove_translation(addressed)

    crew.captains.assign(saved)
    crew.players = saved_players


func _set_crew(crew: Node, genders: Array) -> void:
    var captains: Array[Dictionary] = []
    for gender in genders:
        captains.append({"gender": gender})
    crew.captains.assign(captains)
    crew.players = genders.size()
