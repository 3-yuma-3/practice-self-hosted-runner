package argocd_test

import data.argocd

runner_chart_name := "gha-runner-scale-set"

runner_application(kind, name, chart) := {
	"kind": kind,
	"metadata": {
		"name": name,
	},
	"spec": {
		"sources": [
			{
				"chart": chart,
			},
		],
	},
}

test_runner_application_without_values_file_mapping_is_denied if {
	config := runner_application(
		"Application",
		"arc-runner-custom",
		runner_chart_name,
	)

	violations := argocd.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == sprintf(
		"Runner Application %q must have a runner-specific values-file mapping",
		["arc-runner-custom"],
	)
}

test_runner_application_with_wrong_chart_is_denied if {
	config := runner_application(
		"Application",
		"arc-runner-buildkit",
		"another-chart",
	)

	violations := argocd.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == sprintf(
		"Runner Application %q must use the %q Helm chart",
		["arc-runner-buildkit", runner_chart_name],
	)
}
