extends MenuScreen

## List all the test screens, which show the parts of the game in isolation,
## and start the chosen one in a window of its own (with the same command-line
## options, e.g., --lang=ru), so that Esc there comes back here.
##
## Start with:
##
##   $GODOT --path . scenes/tests/test_menu/test_menu.tscn

## The test screens: the title, what they show, and the scene.
const TESTS := [
    ["Language", "The first screen", "language_select_test/language_select_test.tscn"],
    ["Voyages", "Continue or start anew", "session_select_test/session_select_test.tscn"],
    ["Voyage name", "Name a new voyage", "session_name_test/session_name_test.tscn"],
    ["Dialog", "Ask before deleting", "confirm_dialog_test/confirm_dialog_test.tscn"],
    ["Captains", "How many captains sail?", "player_count_test/player_count_test.tscn"],
    ["Creator", "One captain", "captain_creator_test/captain_creator_test.tscn"],
    ["Creator 2", "Two captains", "captain_creator_test/captain_creator_two_players_test.tscn"],
    ["Keyboard", "The name, one player", "keyboard_test/keyboard_test.tscn"],
    ["Keyboard 2", "The name, two players", "keyboard_test/keyboard_two_players_test.tscn"],
    ["Looks", "Many captains at once", "captain_looks_test/captain_looks_test.tscn"],
    ["Bird dog", "Intro, part 1", "intro_test/intro_bird_dog_test.tscn"],
    ["Steering", "Intro, part 2", "intro_test/intro_steering_test.tscn"],
    ["Poses", "The pose recognition", "pose_test/pose_test.tscn"],
    ["Poses 2", "The poses of two players", "pose_test/pose_test_two_players.tscn"],
    ["Missions", "Choose a mission", "mission_select_test/mission_select_test.tscn"],
    ["Mission 1", "The Bell of Grebaštica", "mission_test/mission_bell_test.tscn"],
    ["Mission 1", "Two boats", "mission_test/mission_bell_two_players_test.tscn"],
    ["Islands", "Zoom in among the islands", "mission_test/mission_islands_test.tscn"],
    ["Mission 2", "The Shipwright of Korčula", "mission_test/mission_2_test.tscn"],
    ["Mission 3", "Salt for the Winter", "mission_test/mission_3_test.tscn"],
    ["Mission 4", "Oak for Master Ivan", "mission_test/mission_4_test.tscn"],
    ["Mission 5", "The Uskok and the Doge", "mission_test/mission_5_test.tscn"],
    ["Mission 6", "The Doctor of Ragusa", "mission_test/mission_6_test.tscn"],
    ["Mission 7", "The Theatre of Hvar", "mission_test/mission_7_test.tscn"],
    ["Mission 8", "Across the Sea", "mission_test/mission_8_test.tscn"],
    ["Mission 9", "The Pilgrims of St. Nicholas", "mission_test/mission_9_test.tscn"],
    ["Mission 10", "The Corsairs of Ulcinj", "mission_test/mission_10_test.tscn"],
    ["Mission 11", "The Oranges of Parga", "mission_test/mission_11_test.tscn"],
    ["Mission 12", "The Forged Ledger", "mission_test/mission_12_test.tscn"],
    ["Mission 13", "The Secret Script", "mission_test/mission_13_test.tscn"],
    ["Mission 14", "The Witnesses", "mission_test/mission_14_test.tscn"],
    ["Mission 15", "The Kadı of Preveza", "mission_test/mission_15_test.tscn"],
    ["Mission 16", "Nets of Comacchio", "mission_test/mission_16_test.tscn"],
    ["Mission 17", "The Wind Seller", "mission_test/mission_17_test.tscn"],
    ["Mission 18", "The Pilgrims of Loreto", "mission_test/mission_18_test.tscn"],
    ["Mission 19", "The Paper with a Secret", "mission_test/mission_19_test.tscn"],
    ["Mission 20", "The Seal-Maker of Ortona", "mission_test/mission_20_test.tscn"],
    ["Mission 21", "The White Rock", "mission_test/mission_21_test.tscn"],
    ["Mission 22", "The Challenge of Barletta", "mission_test/mission_22_test.tscn"],
    ["Mission 23", "Oil for Monopoli", "mission_test/mission_23_test.tscn"],
    ["Mission 24", "The Count Flees", "mission_test/mission_24_test.tscn"],
    ["Mission 25", "The Royal Audience of Trani", "mission_test/mission_25_test.tscn"],
    ["Mission 26", "Caps Too New", "mission_test/mission_26_test.tscn"],
    ["Mission 27", "The Doge's Ten Days", "mission_test/mission_27_test.tscn"],
    ["Mission 28", "The Salt of Piran", "mission_test/mission_28_test.tscn"],
    ["Mission 29", "Fresh Oak", "mission_test/mission_29_test.tscn"],
    ["Mission 30", "The Friars of Košljun", "mission_test/mission_30_test.tscn"],
    ["Mission 31", "The Hidden Cove", "mission_test/mission_31_test.tscn"],
    ["Mission 32", "The Steward's Ledger", "mission_test/mission_32_test.tscn"],
    ["Mission 33", "Two Flags", "mission_test/mission_33_test.tscn"],
    ["Mission 34", "Through the Bura", "mission_test/mission_34_test.tscn"],
    ["Mission 35", "The Peace of Rijeka", "mission_test/mission_35_test.tscn"],
    ["The end", "Every mission complete", "mission_complete_test/mission_complete_test.tscn"],
    ["Shipyard", "Decorate the boats", "shipyard_test/shipyard_test.tscn"],
    ["Mission", "The placeholder", "mission_test/mission_placeholder_test.tscn"],
]

const _COLUMNS := 8
const _BUTTON := Vector2(222, 100)
const _GAP := Vector2(14, 14)


func _build() -> void:
    var grid := GridContainer.new()
    grid.columns = _COLUMNS
    grid.add_theme_constant_override("h_separation", int(_GAP.x))
    grid.add_theme_constant_override("v_separation", int(_GAP.y))
    var width := _COLUMNS * _BUTTON.x + (_COLUMNS - 1) * _GAP.x
    grid.position = Vector2((1920 - width) * 0.5, 170)
    add_child(grid)

    for test in TESTS:
        var button := HandButton.new()
        button.custom_minimum_size = _BUTTON
        button.title = test[0]
        button.title_size = 36
        button.text = test[1]
        button.text_size = 20
        button.pressed.connect(_start.bind("res://scenes/tests/" + test[2]))
        grid.add_child(button)


func _start(scene: String) -> void:
    var arguments := PackedStringArray(
        ["--path", ProjectSettings.globalize_path("res://"), scene, "--"]
    )
    arguments.append_array(OS.get_cmdline_user_args())
    var pid := OS.create_process(OS.get_executable_path(), arguments)
    print("Started %s (process %d)" % [scene, pid])


func _draw_screen() -> void:
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 120),
        "Bird Dog: test screens   (Esc: quit)",
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        52,
        Paper.RED
    )
