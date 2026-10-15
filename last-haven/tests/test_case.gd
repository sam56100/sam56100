class_name TestCase
extends RefCounted
## Minimal dependency-free test base class.
##
## Subclass it in tests/test_*.gd and add `func test_*()` methods (they may use `await`).
## Run everything with: python tools/check.py   (or tests/run_tests.gd directly, see README).

## Set by the runner; use it to add nodes and await frames.
var tree: SceneTree
var failures: Array[String] = []


## Called before each test method.
func before_each() -> void:
	pass


## Called after each test method.
func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail("expected true. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail("expected false. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail("expected %s, got %s. %s" % [str(expected), str(actual), message])


func assert_almost_eq(
	actual: float, expected: float, tolerance: float, message: String = ""
) -> void:
	if absf(actual - expected) > tolerance:
		fail("expected %s ± %s, got %s. %s" % [expected, tolerance, actual, message])


func fail(message: String) -> void:
	failures.append(message)
