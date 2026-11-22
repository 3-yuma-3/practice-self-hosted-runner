package docker_bake_test

import data.docker_bake

test_ubuntu_with_only_arm64_is_allowed if {
	config := parse_config("hcl2", `
        group "default" {
            targets = ["ubuntu"]
        }

        target "ubuntu" {
            platforms = ["linux/arm64"]
        }
    `)

	violations := docker_bake.deny with input as config
	count(violations) == 0
}

test_ubuntu_requires_arm64 if {
	config := parse_config("hcl2", `
        group "default" {
            targets = ["ubuntu"]
        }

        target "ubuntu" {
            platforms = ["linux/amd64"]
        }
    `)

	violations := docker_bake.deny with input as config
	count(violations) == 1
	"Docker Bake default target \"ubuntu\" must include platform \"linux/arm64\"" in violations
}

test_other_target_requires_amd64 if {
	config := parse_config("hcl2", `
        group "default" {
            targets = ["debian"]
        }

        target "debian" {
            platforms = ["linux/arm64"]
        }
    `)

	violations := docker_bake.deny with input as config
	count(violations) == 1
	"Docker Bake default target \"debian\" must include platform \"linux/amd64\"" in violations
}

test_other_target_requires_arm64 if {
	config := parse_config("hcl2", `
        group "default" {
            targets = ["debian"]
        }

        target "debian" {
            platforms = ["linux/amd64"]
        }
    `)

	violations := docker_bake.deny with input as config
	count(violations) == 1
	"Docker Bake default target \"debian\" must include platform \"linux/arm64\"" in violations
}

test_other_target_with_both_platforms_is_allowed if {
	config := parse_config("hcl2", `
        group "default" {
            targets = ["debian"]
        }

        target "debian" {
            platforms = ["linux/amd64", "linux/arm64"]
        }
    `)

	violations := docker_bake.deny with input as config
	count(violations) == 0
}
