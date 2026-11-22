package k8s

deployment_containers contains container if {
	input.kind == "Deployment"
	some container in input.spec.template.spec.containers
}

# METADATA
# description: Require Deployment container images to be pinned by SHA-256 digest.
# entrypoint: true
deny contains msg if {
	some container in deployment_containers
	not regex.match(`.*@sha256:[a-f0-9]{64}$`, object.get(container, "image", ""))
	msg := sprintf(
		"Deployment %q container %q image must be pinned by SHA-256 digest",
		[input.metadata.name, container.name],
	)
}
