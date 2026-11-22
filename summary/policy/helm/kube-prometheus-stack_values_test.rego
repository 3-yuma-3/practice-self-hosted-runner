package helm_test

import data.helm

test_pvc_request_storage_empty_string_is_denied if {
	values := {
		"alertmanager": {
			"enabled": false,
		},
		"prometheus": {
			"prometheusSpec": {
				"storageSpec": {
					"volumeClaimTemplate": {
						"spec": {
							"resources": {
								"requests": {
									"storage": "",
								},
							},
						},
					},
				},
			},
		},
	}

	violations := helm.deny with input as values
	some msg in violations
	msg == "Prometheus PVC storage request must be a non-empty string"
}

test_pvc_request_storage_non_empty_string_is_allowed if {
	values := {
		"alertmanager": {
			"enabled": false,
		},
		"prometheus": {
			"prometheusSpec": {
				"storageSpec": {
					"volumeClaimTemplate": {
						"spec": {
							"resources": {
								"requests": {
									"storage": "1Gi",
								},
							},
						},
					},
				},
			},
		},
	}

	violations := helm.deny with input as values
	count(violations) == 0
}
