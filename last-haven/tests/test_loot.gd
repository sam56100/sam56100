extends TestCase
## Pure loot rules: components, loot table, inventory, timed actions.

const TICK := 1.0 / 60.0

var _table: LootTable
var _rng: RandomNumberGenerator


func before_each() -> void:
	_table = preload("res://data/loot/crate_basic.tres") as LootTable
	_rng = RandomNumberGenerator.new()
	_rng.seed = 2024
	Localization.setup()


func test_there_are_exactly_six_components_with_unique_names_and_colors() -> void:
	var all := CraftComponent.all()
	assert_eq(all.size(), 6)
	var names := {}
	var colors := {}
	for type in all:
		names[CraftComponent.key(type)] = true
		colors[CraftComponent.color(type)] = true
	assert_eq(names.size(), 6)
	assert_eq(colors.size(), 6)


func test_component_names_are_translated_to_french() -> void:
	assert_eq(CraftComponent.display_name(CraftComponent.Type.ALCOHOL), "Alcool")
	assert_eq(CraftComponent.display_name(CraftComponent.Type.RAG), "Chiffon")
	assert_eq(CraftComponent.display_name(CraftComponent.Type.BLADE), "Lame")
	assert_eq(CraftComponent.display_name(CraftComponent.Type.ADHESIVE), "Adhésif")
	assert_eq(CraftComponent.display_name(CraftComponent.Type.EXPLOSIVE), "Explosif")
	assert_eq(CraftComponent.display_name(CraftComponent.Type.SUGAR), "Sucre")


func test_phase_one_crates_only_drop_the_three_phase_one_components() -> void:
	var allowed := [CraftComponent.Type.RAG, CraftComponent.Type.ALCOHOL, CraftComponent.Type.BLADE]
	for i in 300:
		for type: int in _table.roll(_rng):
			assert_true(type in allowed, "unexpected component %d" % type)


func test_a_crate_holds_between_min_and_max_items() -> void:
	for i in 300:
		var loot := _table.roll(_rng)
		var items := 0
		for type: int in loot:
			items += int(loot[type])
		assert_true(items >= _table.picks_min and items <= _table.picks_max, "%d items" % items)


func test_loot_is_reproducible_with_the_same_seed() -> void:
	var first := RandomNumberGenerator.new()
	first.seed = 99
	var second := RandomNumberGenerator.new()
	second.seed = 99
	for i in 20:
		assert_eq(_table.roll(first), _table.roll(second))


func test_drop_frequencies_follow_the_weights() -> void:
	var counts := {}
	for i in 2000:
		var loot := _table.roll(_rng)
		for type: int in loot:
			counts[type] = int(counts.get(type, 0)) + int(loot[type])
	var rag := int(counts[CraftComponent.Type.RAG])
	var alcohol := int(counts[CraftComponent.Type.ALCOHOL])
	var blade := int(counts[CraftComponent.Type.BLADE])
	assert_true(blade < rag and blade < alcohol, "the lighter-weighted blade is rarer")
	assert_true(absf(float(rag) / float(alcohol) - 1.0) < 0.15, "equal weights drop about equally")


func test_an_empty_table_drops_nothing() -> void:
	var empty := LootTable.new()
	assert_true(empty.roll(_rng).is_empty())


func test_inventory_counts_adds_and_notifies() -> void:
	var inventory := ComponentInventory.new()
	var notifications := [0]
	inventory.changed.connect(func() -> void: notifications[0] += 1)
	inventory.add(CraftComponent.Type.RAG, 2)
	inventory.add(CraftComponent.Type.RAG)
	assert_eq(inventory.count(CraftComponent.Type.RAG), 3)
	assert_eq(inventory.count(CraftComponent.Type.BLADE), 0)
	assert_eq(inventory.total(), 3)
	assert_eq(notifications[0], 2)
	inventory.add(CraftComponent.Type.RAG, 0)
	inventory.add(CraftComponent.Type.RAG, -4)
	assert_eq(inventory.count(CraftComponent.Type.RAG), 3, "non-positive amounts are ignored")


func test_inventory_add_all_notifies_once() -> void:
	var inventory := ComponentInventory.new()
	var notifications := [0]
	inventory.changed.connect(func() -> void: notifications[0] += 1)
	inventory.add_all({CraftComponent.Type.RAG: 2, CraftComponent.Type.ALCOHOL: 1})
	assert_eq(inventory.total(), 3)
	assert_eq(notifications[0], 1)


func test_inventory_spend_is_all_or_nothing() -> void:
	var inventory := ComponentInventory.new()
	inventory.add(CraftComponent.Type.RAG, 1)
	inventory.add(CraftComponent.Type.ALCOHOL, 1)
	var cost := {CraftComponent.Type.RAG: 1, CraftComponent.Type.ALCOHOL: 1}
	assert_true(inventory.can_afford(cost))
	assert_false(inventory.can_afford({CraftComponent.Type.RAG: 2}))
	assert_false(inventory.spend({CraftComponent.Type.RAG: 1, CraftComponent.Type.BLADE: 1}))
	assert_eq(inventory.total(), 2, "a failed spend changes nothing")
	assert_true(inventory.spend(cost))
	assert_eq(inventory.total(), 0)


func test_timed_action_completes_after_its_duration_only() -> void:
	var action := TimedAction.new()
	action.start(0.5)
	assert_true(action.active)
	var finished := false
	var ticks := 0
	while not finished and ticks < 100:
		finished = action.tick(TICK)
		ticks += 1
	assert_true(finished)
	assert_true(absf(ticks * TICK - 0.5) <= TICK * 1.5, "finished after %.3f s" % (ticks * TICK))
	assert_false(action.active)
	assert_false(action.tick(TICK), "a finished action does not complete twice")


func test_timed_action_progress_and_cancel() -> void:
	var action := TimedAction.new()
	assert_almost_eq(action.progress(), 0.0, 0.0001)
	action.start(1.0)
	for i in 30:
		action.tick(TICK)
	assert_almost_eq(action.progress(), 0.5, 0.03)
	action.cancel()
	assert_false(action.active)
	assert_almost_eq(action.progress(), 0.0, 0.0001)
	assert_false(action.tick(TICK))
