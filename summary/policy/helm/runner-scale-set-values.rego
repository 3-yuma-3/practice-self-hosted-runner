package helm

# METADATA
# description: Require minRunners not to exeed maxRunners.
# entrypoint: true
deny contains msg if {
	input.minRunners > input.maxRunners
	msg := sprintf(
		"minRunners (%v) must not exeed maxRunners (%v)",
		[input.minRunners, input.maxRunners],
	)
}
