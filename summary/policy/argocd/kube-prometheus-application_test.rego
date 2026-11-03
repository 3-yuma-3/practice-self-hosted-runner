package argocd_test

import data.argocd

minikube_values_file := "$values/summary/helm/kube-prometheus-stack/environments/minikube.yaml"
wrong_values_file := "$values/summary/helm/kube-prometheus-stack/environments/minikube-wrong.yaml"
deny_message := "kube-prometheus-stack Application must reference the Minikube Helm values file"

application(kind, name, chart, value_files) := {
	"kind": kind,
	"metadata": {
		"name": name,
	},
	"spec": {
		"sources": [
			{
				"chart": chart,
				"helm": {
					"valueFiles": value_files,
				},
			},
		],
	},
}

test_minikube_values_file_is_allowed if {
	config := application(
		"Application",
		"kube-prometheus-stack",
		"kube-prometheus-stack",
		[minikube_values_file],
	)

	violations := argocd.deny with input as config
	count(violations) == 0
}

test_wrong_values_file_is_denied if {
	config := application(
		"Application",
		"kube-prometheus-stack",
		"kube-prometheus-stack",
		[wrong_values_file],
	)

	violations := argocd.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == deny_message
}
