class_name TestCase
extends RefCounted
## Minimal dependency-free test base class.
##
## Subclass it in tests/test_*.gd and add `func test_*()` methods (they may use `await`).
## Run everything with: python tools/check.py   (or tests/run_tests.gd directly, see README).

## Set by the runner; use it to add nodes and await frames.
var tree: SceneTree
var failures: Array[String] = []
## Number of assertions executed by the current test. The runner fails a test that ran none:
## that is what a script error in the middle of a test looks like from the outside.
var assertions: int = 0


## Called before each test method.
func before_each() -> void:
	pass


## Called after each test method.
func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	assertions += 1
	if not condition:
		fail("expected true. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	assertions += 1
	if condition:
		fail("expected false. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if actual != expected:
		fail("expected %s, got %s. %s" % [str(expected), str(actual), message])


func assert_almost_eq(
	actual: float, expected: float, tolerance: float, message: String = ""
) -> void:
	assertions += 1
	if absf(actual - expected) > tolerance:
		fail("expected %s ± %s, got %s. %s" % [expected, tolerance, actual, message])


func fail(message: String) -> void:
	failures.append(message)
