package docker_bake_test

import data.docker_bake

# METADATA
# description: Validate Docker Bake targets in the default group.
# entrypoint: true
test_default_target_must_support_both_architectures if {
	config := parse_config("hcl2", `
		group "default" {
			targets = ["futuer-image"]
		}

		target "futuer-image" {
			platforms = ["linux/amd64"]
		}
	`)

	violations := docker_bake.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == "Docker Bake default target \"futuer-image\" must include platform \"linux/arm64\""
}
