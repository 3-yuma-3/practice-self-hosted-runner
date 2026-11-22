package docker_bake

required_platforms := {"linux/amd64", "linux/arm64"}

required_platforms_for_target("ubuntu") := {"linux/arm64"}

required_platforms_for_target(target) := required_platforms if {
	target != "ubuntu"
}

has_value(values, expected) if {
	some value in values
	value == expected
}

default_group_blocks := object.get(
	object.get(input, "group", {}),
	"default",
	[],
)

default_targets := object.get(default_group_blocks[0], "targets", []) if {
	count(default_group_blocks) == 1
}

target_blocks_by_name := object.get(input, "target", {})

# METADATA
# description: Validate Docker Bake targets in the default group.
# entrypoint: true
deny contains msg if {
	count(default_group_blocks) != 1
	msg := "Docker Bake must define exactly one group named \"default\""
}

deny contains msg if {
	some target in default_targets

	target_blocks := object.get(target_blocks_by_name, target, [])
	count(target_blocks) == 1

	platforms := object.get(target_blocks[0], "platforms", [])
	some platform in required_platforms_for_target(target)
	not has_value(platforms, platform)

	msg := $`Docker Bake default target "{target}" must include platform "{platform}"`
}
