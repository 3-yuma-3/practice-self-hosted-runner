package argocd

runner_minikube_values_file := "$values/summary/helm/runner-scale-set/environments/minikube.yaml"
runner_values_file_by_application := {
	"arc-runner-buildkit": "$values/summary/helm/runner-scale-set/runners/buildkit.yaml",
	"arc-runner-debian": "$values/summary/helm/runner-scale-set/runners/debian.yaml",
	"arc-runner-setup-node": "$values/summary/helm/runner-scale-set/runners/setup-node.yaml",
	"arc-runner-setup-python": "$values/summary/helm/runner-scale-set/runners/setup-python.yaml",
}

is_runner_scale_set_application if {
	input.kind == "Application"
	startswith(input.metadata.name, "arc-runner-")
}

has_runner_values_file_mapping if {
	object.get(runner_values_file_by_application, input.metadata.name, "") != ""
}

has_runner_scale_set_chart if {
	some source in input.spec.sources
	source.chart == "gha-runner-scale-set"
}

deny contains msg if {
	is_runner_scale_set_application
	not has_runner_values_file_mapping
	msg := sprintf(
		"Runner Application %q must have a runner-specific values-file mapping",
		[input.metadata.name],
	)
}

deny contains msg if {
	is_runner_scale_set_application
	not has_runner_scale_set_chart
	msg := sprintf(
		"Runner Application %q must use the %q Helm chart",
		[input.metadata.name, "gha-runner-scale-set"],
	)
}
