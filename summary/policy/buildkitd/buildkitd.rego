package buildkitd

registries := object.get(input, "registry", {})
ghcr_registry := object.get(registries, "ghcr.io", {})
ghcr_mirrors := object.get(ghcr_registry, "mirrors", [])

# METADATA
# description: Validate that GHCR mirrors are configured with HTTP enabled.
# entrypoint: true
deny contains msg if {
	not is_array(ghcr_mirrors)
	msg := "BuildKit ghcr.io mirrors must be an array"
}

deny contains msg if {
	is_array(ghcr_mirrors)
	count(ghcr_mirrors) == 0
	msg := "BuildKit ghcr.io must configure at least one mirror"
}

deny contains msg if {
	is_array(ghcr_mirrors)
	some mirror in ghcr_mirrors
	is_string(mirror)
	mirror_registry := object.get(registries, mirror, {})
	object.get(mirror_registry, "http", false) != true
	msg := $`BuildKit mirror "{mirror}" must set http = true`
}
