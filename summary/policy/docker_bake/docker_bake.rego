package docker_bake

required_platforms := {"linux/amd64", "linux/arm64"}

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

target_blokcs_by_name := object.get(input, "target", {})

deny contains msg if {
	count(default_group_blocks) != 1
	msg := "Docker Bake must define exactly one group named \"default\""
}

deny contains msg if {
	some target in default_targets
	target_blocks := object.get(target_blokcs_by_name, target, [])
	count(target_blocks) == 1
	platforms := object.get(target_blocks[0], "platforms", [])
	some platform in required_platforms
	not has_value(platforms, platform)
	msg := $`Docker Bake default target "{target}" must include platform "{platform}"`
}
