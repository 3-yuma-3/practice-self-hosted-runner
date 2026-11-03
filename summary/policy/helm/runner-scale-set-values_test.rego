package helm_test

import data.helm

test_min_runners_not_greater_than_max_runners_is_allowed if {
	values := {
		"minRunners": 0,
		"maxRunners": 1,
	}

	violations := helm.deny with input as values
	count(violations) == 0
}

test_min_runners_greater_than_max_runners_is_denied if {
	values := {
		"minRunners": 2,
		"maxRunners": 1,
	}

	violations := helm.deny with input as values
	some msg in violations
	msg == "minRunners (2) must not exeed maxRunners (1)"
}
