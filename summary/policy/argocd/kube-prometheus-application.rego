package argocd

has_minikube_values_file if {
	some source in input.spec.sources
	source.chart == "kube-prometheus-stack"
	some value_file in source.helm.valueFiles
	value_file == "$values/summary/helm/kube-prometheus-stack/environments/minikube.yaml"
}

# METADATA
# description: Require the kube-prometheus-stack Application to reference Minikube values.
# entrypoint: true
deny contains msg if {
	input.kind == "Application"
	input.metadata.name == "kube-prometheus-stack"
	not has_minikube_values_file
	msg := "kube-prometheus-stack Application must reference the Minikube Helm values file"
}
