package buildkitd_test

import data.buildkitd

# METADATA
# description: Verify Buildkit TOML policy rules.
# entrypoint: true
test_buildkitd_accepts_any_configured_mirror_with_http_enabled if {
	config := parse_config("toml", `
		[registry."ghcr.io"]
		mirrors = ["mirror.example:5000"]

		[registry."mirror.example:5000"]
		http = true
	`)

	violations := buildkitd.deny with input as config
	count(violations) == 0
}

test_buildkitd_requires_at_least_one_ghcr_mirror if {
	config := parse_config("toml", `
		[registry."ghcr.io"]
		mirrors = []
	`)

	violations := buildkitd.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == "BuildKit ghcr.io must configure at least one mirror"
}

test_buildkitd_requires_http_for_each_mirror if {
	config := parse_config("toml", `
		[registry."ghcr.io"]
		mirrors = ["mirror.example:5000"]

		[registry."mirror.example:5000"]
		http = false
	`)

	violations := buildkitd.deny with input as config
	count(violations) == 1

	some msg in violations
	msg == "BuildKit mirror \"mirror.example:5000\" must set http = true"
}
