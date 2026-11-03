package k8s_test

import data.k8s

empty(value) if {
	count(value) == 0
}

no_violations if {
	empty(k8s.deny)
}

test_deployment_registry_cache_with_digest_is_allowed if {
	config := {
		"apiVersion": "apps/v1",
		"kind": "Deployment",
		"metadata": {
			"name": "sample",
			"namespace": "sample",
		},
		"spec": {
			"template": {
				"spec": {
					"containers": [
						{
							"name": "app",
							"image": "example/app:1.0@sha256:d4032d4cc323c1731c707931ecada07a53076eac38e3b61ae57533f170f2c6c3",
						},
					],
				},
			},
		},
	}

	no_violations with input as config
}

test_deployment_with_tag_only_image_is_denied if {
	config := {
		"kind": "Deployment",
		"metadata": {"name": "sample"},
		"spec": {
			"template": {
				"spec": {
					"containers": [
						{
							"name": "app",
							"image": "example/app:1.0",
						},
					],
				},
			},
		},
	}

	violations := k8s.deny with input as config
	some msg in violations
}
