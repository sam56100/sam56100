extends SceneTree
## Headless test runner (no addon needed).
##
## Usage (from the project folder):
##   godot --headless --path . --fixed-fps 60 -s res://tests/run_tests.gd
## Run only test files whose name contains a word:
##   godot --headless --path . --fixed-fps 60 -s res://tests/run_tests.gd -- movement
## Exit code is 0 when everything passes, 1 otherwise.

const TESTS_DIR := "res://tests"
## A test that has not finished after this many frames is considered stuck (30 s at 60 fps).
## This happens e.g. when a script error aborts a coroutine that the runner is awaiting.
const MAX_FRAMES_PER_TEST := 1800

var _frames_in_current_test := 0


func _initialize() -> void:
	_run_all()


## Watchdog, called every frame by the engine: returning true ends the main loop.
func _process(_delta: float) -> bool:
	_frames_in_current_test += 1
	if _frames_in_current_test > MAX_FRAMES_PER_TEST:
		printerr(
			(
				(
					"FAIL  TIMEOUT: a test did not finish within %d frames."
					+ " Probably a script error above aborted it."
				)
				% MAX_FRAMES_PER_TEST
			)
		)
		quit(1)
		return true
	return false


func _run_all() -> void:
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]

	var total := 0
	var failed := 0
	for file_name in _test_files(filter):
		var path := "%s/%s" % [TESTS_DIR, file_name]
		var script := load(path) as GDScript
		var suite: TestCase = null
		if script != null:
			suite = script.new() as TestCase
		if suite == null:
			printerr("FAIL  %s: could not load as a TestCase" % file_name)
			total += 1
			failed += 1
			continue
		suite.tree = self
		for method_name in _test_methods(suite):
			total += 1
			suite.failures.clear()
			_frames_in_current_test = 0
			await suite.before_each()
			await suite.call(method_name)
			await suite.after_each()
			if suite.failures.is_empty():
				print("PASS  %s::%s" % [file_name, method_name])
			else:
				failed += 1
				printerr("FAIL  %s::%s" % [file_name, method_name])
				for message in suite.failures:
					printerr("        %s" % message)

	print("---- %d tests, %d passed, %d failed ----" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)


func _test_files(filter: String) -> Array[String]:
	var result: Array[String] = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if (
			file_name.begins_with("test_")
			and file_name.ends_with(".gd")
			and file_name != "test_case.gd"
		):
			if filter.is_empty() or file_name.contains(filter):
				result.append(file_name)
	result.sort()
	return result


func _test_methods(suite: TestCase) -> Array[String]:
	var result: Array[String] = []
	for method in suite.get_method_list():
		var method_name := str(method["name"])
		if method_name.begins_with("test_"):
			result.append(method_name)
	result.sort()
	return result
