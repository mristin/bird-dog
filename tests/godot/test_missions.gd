extends SceneTree
## Check the world and the missions (see DESIGN.md, "Checking the missions"):
## the ports lie on the coast and their facts are unique, one load of
## provisions crosses the Adriatic, and every mission plays from the briefing
## to the stars with many seeds, the way a good crew plays it: sailing to the
## nearest port the chart points to, and answering right. A good crew must be
## able to earn three stars, and every line-up must single out exactly one
## candidate by the hallmarks revealed before it.

## How many seeds every mission is played with.
const SEEDS := 40

## Sailing between two ports is longer than the straight line by this factor.
const DETOUR := 1.3

var _failures: Array[String] = []
var _km_per_day := 100.0


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _km_per_day = load("res://scenes/mission/mission.gd").KM_PER_DAY
    _check_ports()
    _check_facts()
    for mission in MissionCatalog.all():
        _check(mission.is_playable(), "%s is playable" % mission.id)
        if mission.is_playable():
            _check_mission(mission)
    _check_wrong_answers()
    _check_rival()
    _check_merchant()
    _check_ships()

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Every port lies on the coast, with open sea nearby, so that the boats can
## reach it, and has a local and facts.
func _check_ports() -> void:
    var chart := ChartView.new()
    root.add_child(chart)
    for port in World.ports():
        var at := World.port_km(port)
        var sea := false
        for step in range(24):
            var probe := at + Vector2.RIGHT.rotated(step * TAU / 24) * 4.0
            sea = sea or not chart.is_land(probe)
        _check(sea, "the port %s has the sea within 4 km" % port.id)
        _check(not port.locals.is_empty(), "the port %s has a local to talk to" % port.id)
        _check(not port.facts.is_empty(), "the port %s has facts for the clues" % port.id)
        _check(PortIcons.NAMES.has(port.icon), "the port %s has an icon of its own" % port.id)
    for field in World.reef_fields():
        var center := World.to_km(field.latitude, field.longitude)
        var rocks := 0
        for reef in chart.reefs:
            rocks += 1 if reef.distance_to(center) <= field.radius_km + 0.01 else 0
        _check(rocks >= 3, "the reefs %s have rocks in the sea" % field.id)
    chart.free()

    var run := MissionRun.new(MissionCatalog.all()[0], 1)
    run.hold().add_damage(150.0)
    _check(run.hold().is_wrecked(), "a hull can break on the reefs")
    _check(run.hold().repair() > 0.0, "repairing a broken hull takes time")
    _check(run.hold().damage == 0.0, "a port repairs the hull")

    var two := MissionRun.new(MissionCatalog.all()[1], 1, 2)
    two.hold(0).cargo.append("bell")
    two.hold(0).ducats = 30
    two.hold(0).give_item(two.hold(1), "bell")
    _check(
        two.hold(1).cargo.has("bell") and not two.hold(0).cargo.has("bell"), "boats hand over cargo"
    )
    two.hold(1).provisions = 0.0
    two.hold(0).give_provisions(two.hold(1))
    _check(two.hold(1).provisions > 0.0, "boats hand over food and water")
    two.hold(0).give_provisions(two.hold(1))
    _check(
        two.hold(1).provisions <= two.hold(1).max_provisions,
        "a boat takes only the food and water which fit its hold"
    )
    _check(two.hold(0).give_ducats(two.hold(1), 10) == 10, "boats hand over ducats")
    _check(two.ducats_total() == 30, "handing over keeps the ducats of the crew")


## Every fact points to exactly one port.
func _check_facts() -> void:
    var seen := {}
    for port in World.ports():
        for fact in port.facts:
            _check(not seen.has(fact.phrase), "the fact '%s' is unique" % fact.phrase)
            seen[fact.phrase] = port.id


func _check_mission(mission: Mission) -> void:
    var ids := {}
    for step in mission.steps:
        _check(
            step.id != "" and not ids.has(step.id), "%s: step %s is unique" % [mission.id, step.id]
        )
        ids[step.id] = true
        if step is LineupStep:
            _check_lineup(mission, step)

    _check(
        mission.provisions_days * _km_per_day >= 1.2 * _crossing_km(),
        "%s: one load of provisions crosses the Adriatic 1.2 times" % mission.id
    )

    var worst := 0.0
    for seed_value in range(SEEDS):
        worst = maxf(worst, _play(mission, seed_value))
    var three_stars := mission.clock_days * (1.0 - mission.three_stars_share)
    print(
        "%s: a good crew needs at most %.1f of %.1f days" % [mission.id, worst, mission.clock_days]
    )
    _check(
        worst <= three_stars,
        (
            "%s: a good crew can earn three stars (needs %.1f days, three stars allow %.1f)"
            % [mission.id, worst, three_stars]
        )
    )


## The widest crossing of the Adriatic, from Bari to Dubrovnik.
func _crossing_km() -> float:
    return _km(World.port("bari"), World.port("dubrovnik"))


## The target of a line-up has every hallmark the trail reveals; every decoy
## lacks at least one of them.
func _check_lineup(mission: Mission, lineup: LineupStep) -> void:
    var revealed: Array[Hallmark] = []
    for step in mission.steps:
        if step is TrailStep:
            revealed.append_array(step.reveal)
    _check(not revealed.is_empty(), "%s: the line-up has hallmarks to go by" % mission.id)
    for hallmark in revealed:
        _check(
            lineup.target.hallmarks.has(hallmark),
            "%s: the target has %s" % [mission.id, hallmark.id]
        )
    for decoy in lineup.decoys:
        var all := true
        for hallmark in revealed:
            all = all and decoy.hallmarks.has(hallmark)
        _check(not all, "%s: the decoy %s differs from the target" % [mission.id, decoy.id])


## Play a mission as a good crew; return the days used.
func _play(mission: Mission, seed_value: int) -> float:
    var run := MissionRun.new(mission, seed_value)
    var stars := [0]
    run.finished.connect(func(given: int) -> void: stars[0] = given)
    run.begin()
    var port := mission.start_port
    var label := "%s (seed %d)" % [mission.id, seed_value]

    for turn in range(100):
        if run.is_done():
            break
        var step := run.step()
        var scene: Variant = step.opening(run)
        if scene == null:
            scene = step.arrive(run, port)
        if scene == null:
            var next := _nearest(port, step.target_ports(run))
            _check(next != null, "%s: step %s points somewhere" % [label, step.id])
            if next == null:
                return INF
            if step is RaceStep and step.is_racing(run) and not World.ports().has(next):
                # NOTE (mristin):
                # A buoy of a race is rounded, never entered (see
                # test_race.gd for the race against the rival itself).
                run.pass_days(_km(port, next) * DETOUR / _km_per_day)
                var at: Array[Vector2] = [World.port_km(next)]
                var rounded: Dictionary = step.update(run, at, 0.0, 0.0)
                _check(rounded["rounded"] > 0, "%s: the buoy is rounded" % label)
                port = next
                continue
            run.pass_days(_km(port, next) * DETOUR / _km_per_day + MissionRun.PORT_DAYS)
            port = next
            scene = step.arrive(run, port)
            _check(scene != null, "%s: step %s has a scene in %s" % [label, step.id, port.id])
        _answer(run, scene)
        run.advance()

    _check(run.is_done(), "%s: the mission ends" % label)
    _check(stars[0] >= 1, "%s: the mission gives stars" % label)
    var tasks := 0
    for step in run.mission.steps:
        tasks += 0 if step is BriefingStep or step is CelebrationStep else 1
    _check(
        run.ducats_total() >= tasks * MissionRun.TASK_DUCATS,
        "%s: every task pays %d ducats" % [label, MissionRun.TASK_DUCATS]
    )
    return run.days


func _nearest(from: Port, targets: Array[Port]) -> Port:
    var best: Port = null
    for target in targets:
        if best == null or _km(from, target) < _km(from, best):
            best = target
    return best


func _km(a: Port, b: Port) -> float:
    return World.port_km(a).distance_to(World.port_km(b))


## Answer the scenes of a step right, until it closes.
func _answer(run: MissionRun, scene: Variant) -> void:
    for turn in range(20):
        if scene == null:
            return
        var action: String
        if scene["kind"] == "lineup" or scene["buttons"].size() > 1:
            action = run.step().solution(run)
        else:
            action = scene["buttons"][0]["action"]
        if action == "leave":
            return
        scene = run.step().act(run, action)


## A wrong port says nothing, a wrong pick lets the target flee to another
## port (the trail goes on, and the line-up comes again there), a wrong answer
## only asks again, and a crew out of time still gets a star.
func _check_wrong_answers() -> void:
    var mission: Mission = MissionCatalog.all()[0]
    var run := MissionRun.new(mission, 7)
    run.begin()
    _answer(run, run.step().opening(run))
    run.advance()
    _check(
        run.step().arrive(run, World.port("venice")) == null, "a wrong port does not move the trail"
    )
    while run.step() is TrailStep:
        _answer(run, run.step().arrive(run, run.step().target_ports(run)[0]))
        run.advance()
    var lineup: LineupStep = run.step()
    var right := int(lineup.solution(run).get_slice(":", 1))
    var hidden_in: Port = (run.mission.steps[1] as TrailStep).route_ports(run)[-1]
    var fled: Variant = lineup.act(run, "pick:%d" % ((right + 1) % (lineup.decoys.size() + 1)))
    _check(fled != null and fled["kind"] == "talk", "a wrong pick tells that the target fled")
    _check(run.step() is TrailStep, "after a wrong pick, the trail goes on")
    var targets: Array[Port] = run.step().target_ports(run)
    _check(
        targets.size() == 1 and targets[0] != hidden_in,
        "the target fled to another port, and the chart points there"
    )
    run.advance()
    _check(run.step() is TrailStep, "the trail is not done before the crew gets there")
    _answer(run, run.step().arrive(run, targets[0]))
    run.advance()
    _check(run.step() == lineup, "in the new port, the line-up comes again")
    _check(lineup.opening(run)["kind"] == "lineup", "the line-up shows the candidates again")
    run.pass_days(mission.clock_days)
    _check(run.stars() == 1, "a crew out of time still gets one star")

    var finale: Mission = MissionCatalog.all()[-1]
    for step in finale.steps:
        if step is HearingStep:
            var hearing_run := MissionRun.new(finale, 1)
            var question: Dictionary = step.opening(hearing_run)
            _check(question["buttons"].size() == 3, "the kadı offers three answers")
            var wrong := "answer:%d" % ((step.questions[0].correct + 1) % 3)
            var asked: Variant = step.act(hearing_run, wrong)
            _check(asked != null and asked["buttons"].size() == 3, "a wrong answer asks again")
            _check(not step.is_done(hearing_run), "a wrong answer does not end the hearing")
            for asked_question in step.questions:
                step.act(hearing_run, "answer:%d" % asked_question.correct)
            # NOTE (mristin):
            # With two crews, the other one may still answer an old question,
            # or come in after the last one.
            var late: Variant = step.act(hearing_run, "answer:0")
            _check(
                late != null and late["buttons"][0]["action"] == "done",
                "an answer after the last question only gets the thanks"
            )
            var again: Variant = step.opening(hearing_run)
            _check(
                again != null and again["buttons"][0]["action"] == "done",
                "after the last question, the hearing opens with the thanks"
            )


## The merchant sells what the crew can pay, at most two boosters for a leg,
## and the boosters do what they say (see DESIGN.md, section 10).
func _check_merchant() -> void:
    for power in ["venice", "ragusa", "ottomans", "habsburgs", "papal_states", "naples"]:
        var loaded: Power = load("res://data/world/powers/%s.tres" % power)
        _check(loaded.offers.size() >= 3, "the merchants of %s sell boosters" % power)

    var boosters := {}
    for id in ["new_sails", "fisherman", "pilot", "right_flag", "figs", "bread_water"]:
        boosters[id] = load("res://data/world/boosters/%s.tres" % id)
    var run := MissionRun.new(MissionCatalog.all()[0], 1)
    _check(run.bag.why_not(boosters["new_sails"]) == "ducats", "no ducats, no sails")
    run.bring(40)
    run.earn(60)
    _check(run.bag.buy(boosters["new_sails"]), "the crew buys new sails with the ducats on board")
    _check(
        run.bag.purse() == 70 and run.bag.has_effect("speed"), "the sails cost 30 ducats and work"
    )
    _check(run.bag.why_not(boosters["new_sails"]) == "held", "the crew has the sails already")
    _check(run.bag.buy(boosters["pilot"]), "the crew buys a pilot, too")
    _check(run.bag.why_not(boosters["right_flag"]) == "full", "at most two boosters for a leg")
    _check(run.bag.buy(boosters["figs"]), "the figs last until they are used, so they fit")
    _check(
        run.bag.use_effect("figs") and not run.bag.has_effect("figs"),
        "the corsairs take the figs once"
    )
    run.bag.end_leg()
    _check(run.bag.boosters.is_empty(), "the boosters for a leg end in the next port")
    run.pass_days(1.0)
    run.hold().ducats = run.hold().spent + 100
    var bribe := run.hold().steal(SeaHazards.BRIBE)
    _check(bribe == 10, "a Venetian patrol takes 10 ducats as a bribe")
    _check(run.hold().on_board() == 90, "the bribe is gone")
    var stolen := run.hold().steal(SeaHazards.CORSAIR_LOOT)
    _check(stolen == 20 and run.hold().on_board() == 70, "the corsairs take 20 ducats")
    run.hold().ducats = run.hold().spent + 15
    stolen = run.hold().steal(SeaHazards.CORSAIR_LOOT)
    _check(stolen == 15 and run.hold().on_board() == 0, "or all the ducats on board, if fewer")

    run.hold().ducats = run.hold().spent + 100
    _check(not run.hold().has_room_for(run.ration_days()), "the barrels of a new boat are full")
    _check(
        not Merchant.offers(boosters["bread_water"], run),
        "the merchant offers no food which does not fit"
    )
    _check(run.bag.why_not(boosters["bread_water"]) == "full", "nor sells it")
    var galleon := MissionRun.new(MissionCatalog.all()[0], 1, 1, [World.ship("galleon")])
    galleon.bring(100)
    galleon.pass_days(galleon.ration_days() * 3.0)
    _check(Merchant.offers(boosters["bread_water"], galleon), "with room, the merchant has food")
    _check(galleon.bag.buy(boosters["bread_water"]), "the crew buys bread and water")
    _check(is_equal_approx(galleon.rations_left(), 3.0), "bread and water are one more ration")
    _check(is_equal_approx(galleon.days, galleon.ration_days() * 3.0), "and give no time back")


## The recruiter of mission 2 follows the trail; if the crew dawdles, he gets
## to the last port first, and the trail gets one port longer, once.
func _check_rival() -> void:
    var mission: Mission = MissionCatalog.all()[1]
    var run := MissionRun.new(mission, 3)
    run.begin()
    run.step().act(run, "done")
    run.advance()
    var trail: TrailStep = run.step()
    _check(trail.rival, "mission 2 has a rival on the trail")
    var length: int = run.plan[trail.id]["route"].size()
    var first: Port = null
    for frame in range(20000):
        var arrived := Rival.update(run, trail, 0.1, 3.0)
        if arrived != null:
            first = arrived
            break
    _check(first != null, "the rival reaches the last port first")
    _check(run.plan[trail.id]["route"].size() == length + 1, "the trail gets one port longer")
    for frame in range(20000):
        _check(Rival.update(run, trail, 0.1, 3.0) == null, "the rival does that only once")
        if Rival.position(run, trail) == null:
            break


## The merchants sell twenty boosters, ten of them decorations; the ships
## stow their rations and sail as they say (see Ship).
func _check_ships() -> void:
    var all := World.boosters()
    _check(all.size() == 20, "the merchants sell twenty boosters in all (%d)" % all.size())
    var decorations := all.filter(func(booster: Booster) -> bool: return booster.decoration != null)
    _check(decorations.size() == 10, "ten of the boosters are decorations")
    for booster in all:
        _check(
            booster.effect != "decoration" or booster.decoration != null,
            "the booster %s puts a decoration on the boat" % booster.id
        )

    var ships := World.ships()
    _check(ships[0].id == "gajeta" and ships[0].price == 0, "every captain starts with a gajeta")
    for ship in ships.slice(1):
        _check(ship.price >= 300 and ship.price <= 1000, "the %s is expensive" % ship.id)
    var newcomer := MissionRun.new(MissionCatalog.all()[0], 1)
    _check(is_equal_approx(newcomer.rations_left(), 1.0), "a new captain's gajeta stows one ration")
    var mission: Mission = MissionCatalog.all()[0]
    var run := MissionRun.new(mission, 1, 2, [World.ship("gajeta"), World.ship("galleon")])
    _check(is_equal_approx(run.rations_left(0), 1.0), "a gajeta stows one ration")
    _check(is_equal_approx(run.rations_left(1), 5.0), "a galleon stows five rations")
    run.pass_days(run.ration_days() * 0.5)
    _check(is_equal_approx(run.rations_left(0), 0.5), "the crew eats the rations day by day")
    run.hold(0).add_ration(run.ration_days())
    _check(is_equal_approx(run.rations_left(0), 1.0), "a port fills the ration again")
    run.pass_days(run.ration_days() * 3.0)
    run.hold(1).add_ration(run.ration_days())
    _check(is_equal_approx(run.rations_left(1), 2.5), "a port gives only one ration for free")
    run.hold(1).add_ration(run.ration_days())
    _check(is_equal_approx(run.rations_left(1), 3.5), "every visit one more")
