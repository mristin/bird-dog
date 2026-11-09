class_name CaptainOptions
extends RefCounted

## The choices for the looks of a captain (see DESIGN.md, "Creating a captain").
##
## The looks of a captain are a plain dictionary (so that they can be saved as
## they are), with the keys:
##
## * "name": the name, 1 to [constant MAX_NAME_LENGTH] letters,
## * "gender": "hajduk" or "hajducica" (a haiduk or a haidukess; the keys stay
##   as they are, since the voyages save them),
## * "skin", "hair_color", "vest", "sash": indices into the colours below,
## * "hair": a hair style of [constant HAIR_STYLES] for the gender,
## * "cap": one of [constant CAPS],
## * "face": one of [constant FACES] for the gender,
## * "eye_patch": one of [constant EYE_PATCHES] (which eye of the captain it
##   covers, if any).
##
## The names of the choices are translated by the screens which show them.

const MAX_NAME_LENGTH := 12

const GENDERS := ["hajduk", "hajducica"]

const SKINS := [
    Color(0.98, 0.85, 0.74),
    Color(0.93, 0.74, 0.58),
    Color(0.8, 0.6, 0.43),
    Color(0.62, 0.43, 0.3),
    Color(0.42, 0.28, 0.2),
]

const HAIR_COLORS := [
    Color(0.1, 0.07, 0.05),
    Color(0.32, 0.19, 0.09),
    Color(0.55, 0.35, 0.17),
    Color(0.86, 0.68, 0.38),
    Color(0.68, 0.26, 0.11),
]

const HAIR_STYLES := {
    "hajduk": ["short", "curly", "ponytail", "long"],
    "hajducica": ["braid", "bun", "long", "curly"],
}

const CAPS := ["lika", "kalpak", "headscarf", "feather", "none"]

const EYE_PATCHES := ["none", "left", "right"]

## The colours of the vest (jačerma) and the sash, from the dyes of the time:
## madder red, indigo, verdigris, black, ochre and undyed wool.
const CLOTHS := [
    Color(0.72, 0.1, 0.1),
    Color(0.12, 0.22, 0.45),
    Color(0.18, 0.45, 0.35),
    Color(0.12, 0.1, 0.1),
    Color(0.78, 0.58, 0.2),
    Color(0.9, 0.86, 0.76),
]

const FACES := {
    "hajduk": ["moustache", "plain", "freckles", "moustache_freckles"],
    "hajducica": ["plain", "freckles"],
}


## The looks of the captain of a player before anybody changes them.
static func default_looks(player: int) -> Dictionary:
    if player == 0:
        return {
            "name": "Liso",
            "gender": "hajduk",
            "skin": 1,
            "hair": "short",
            "hair_color": 0,
            "cap": "lika",
            "vest": 1,
            "sash": 0,
            "face": "moustache",
            "eye_patch": "none",
        }
    return {
        "name": "Mare",
        "gender": "hajducica",
        "skin": 1,
        "hair": "braid",
        "hair_color": 1,
        "cap": "headscarf",
        "vest": 2,
        "sash": 0,
        "face": "freckles",
        "eye_patch": "none",
    }


## Random looks of the given gender, keeping the name.
static func random_looks(looks: Dictionary) -> Dictionary:
    var result := looks.duplicate()
    var gender: String = looks["gender"]
    result["skin"] = randi() % SKINS.size()
    result["hair"] = HAIR_STYLES[gender].pick_random()
    result["hair_color"] = randi() % HAIR_COLORS.size()
    result["cap"] = CAPS.pick_random()
    result["vest"] = randi() % CLOTHS.size()
    result["sash"] = randi() % CLOTHS.size()
    while result["sash"] == result["vest"]:
        result["sash"] = randi() % CLOTHS.size()
    result["face"] = FACES[gender].pick_random()

    # NOTE (mristin):
    # An eye patch is for the bold; most random captains see with both eyes.
    result["eye_patch"] = "none" if randf() < 0.6 else ["left", "right"].pick_random()
    return result


## Switch the gender, and adapt the hair and the face to the choices of it.
static func with_gender(looks: Dictionary, gender: String) -> Dictionary:
    var result := looks.duplicate()
    result["gender"] = gender
    if result["hair"] not in HAIR_STYLES[gender]:
        result["hair"] = HAIR_STYLES[gender][0]
    if result["face"] not in FACES[gender]:
        result["face"] = "plain" if gender == "hajducica" else "moustache"
    return result
