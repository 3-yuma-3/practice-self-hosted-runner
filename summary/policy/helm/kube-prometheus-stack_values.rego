package helm

deny contains msg if {
	is_object(input.alertmanager)
	not is_string(input.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage)
	msg := "Prometheus PVC storage request must be string"
}

deny contains msg if {
	is_object(input.alertmanager)
	input.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage == ""
	msg := "Prometheus PVC storage request must be a non-empty string"
}
