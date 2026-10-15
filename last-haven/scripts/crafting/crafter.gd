class_name Crafter
extends Node
## Crafts items from components. Hold the craft key to open the menu, press 1-5 to start a recipe.
## Components are consumed when the craft completes, so an interrupted craft costs nothing.

signal craft_completed(recipe: Recipe)

var recipes: Array[Recipe] = []
var menu_open: bool = false
var current_recipe: Recipe = null

var _player: PlayerController
var _action := TimedAction.new()


func setup(player: PlayerController) -> void:
	_player = player
	recipes = RecipeBook.all()
	player.health.damaged.connect(_on_damaged)


func tick(frame: InputFrame, delta: float) -> void:
	menu_open = frame.craft_menu_held and not _player.is_dead()
	if _action.active:
		if _player.is_dead() or ActionInterrupts.breaks(frame):
			cancel()
		elif _action.tick(delta):
			_complete()
		return
	if menu_open and frame.craft_select > 0 and frame.craft_select <= recipes.size():
		begin(recipes[frame.craft_select - 1])


func can_craft(recipe: Recipe) -> bool:
	return _player.inventory.can_afford(recipe.cost())


## Starts crafting. Returns false if the components are missing or the player is busy.
func begin(recipe: Recipe) -> bool:
	if _action.active or _player.is_dead() or not can_craft(recipe):
		return false
	if not _player.try_begin_action(self):
		return false
	current_recipe = recipe
	_action.start(recipe.craft_seconds)
	return true


func cancel() -> void:
	if not _action.active:
		return
	_action.cancel()
	current_recipe = null
	_player.end_action(self)


func is_crafting() -> bool:
	return _action.active


func progress() -> float:
	return _action.progress()


func _complete() -> void:
	var recipe := current_recipe
	current_recipe = null
	_player.end_action(self)
	if recipe == null or not _player.inventory.spend(recipe.cost()):
		return
	_player.items.add(recipe.result)
	craft_completed.emit(recipe)


func _on_damaged(_amount: int) -> void:
	cancel()
