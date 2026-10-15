extends SceneTree
## Loads every script, scene and resource of the project and fails if any of them is broken.
##
## Usage: godot --headless --path . -s res://tests/smoke_load.gd
## Exit code is 0 when everything loads, 1 otherwise.

const SKIPPED_DIRS: Array[String] = [".godot", "addons", "export", "build"]
const CHECKED_EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]


func _initialize() -> void:
	var failures: Array[String] = []
	var checked := 0
	for path in _collect("res://"):
		checked += 1
		var problem := _check(path)
		if problem != "":
			failures.append("%s: %s" % [path, problem])
	for failure in failures:
		printerr("FAIL  %s" % failure)
	print("---- smoke load: %d files checked, %d broken ----" % [checked, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _collect(directory: String) -> Array[String]:
	var result: Array[String] = []
	for sub_directory in DirAccess.get_directories_at(directory):
		if sub_directory in SKIPPED_DIRS:
			continue
		result.append_array(_collect(directory.path_join(sub_directory)))
	for file_name in DirAccess.get_files_at(directory):
		if file_name.get_extension() in CHECKED_EXTENSIONS:
			result.append(directory.path_join(file_name))
	result.sort()
	return result


## Returns an empty string when the file is fine, otherwise a description of the problem.
func _check(path: String) -> String:
	# Default cache mode on purpose: this script is itself one of the files being checked, and
	# force-reloading a script while it runs crashes the engine (the process is fresh each run, so
	# there is no stale cache to bypass).
	var resource := ResourceLoader.load(path)
	if resource == null:
		return "failed to load"
	if resource is GDScript:
		if not (resource as GDScript).can_instantiate():
			return "script has errors (cannot be instantiated)"
	elif resource is PackedScene:
		var instance := (resource as PackedScene).instantiate()
		if instance == null:
			return "scene cannot be instantiated"
		instance.free()
	return ""
