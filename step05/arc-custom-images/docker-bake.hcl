group "default" {
  targets = [ "debian", "setup-node", "setup-python" ]
}

variable "RUNNER_VERSION" {
  // https://github.com/actions/runner/releases/tag/v2.338.1
  default = "2.338.1"
}

variable "RUNNER_SHA256_AMD64" {
  default = "08e9ccb3604d2462c24b5e33604dc30810296ca15cc65f23cffd4317eb144c37"
}

variable "RUNNER_SHA256_ARM64" {
  default = "475e0c149fd3b611610127b9664ba5bacf5c6928795cc448ab520bb5f324bede"
}

// actions での push 時に metadata が付与される
target "metadata-debian" {}
target "metadata-setup-node" {}
target "metadata-setup-python" {}

target "debian" {
  inherits = [ "metadata-debian" ]
  context    = "step05/arc-custom-images"
  dockerfile = "debian.Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]

  args = {
    RUNNER_VERSION       = "${RUNNER_VERSION}"
    RUNNER_SHA256_AMD64  = "${RUNNER_SHA256_AMD64}"
    RUNNER_SHA256_ARM64  = "${RUNNER_SHA256_ARM64}"
  }
}

target "setup-node" {
  inherits = [ "metadata-setup-node" ]
  context = "step05/arc-custom-images"
  dockerfile = "setup-node.Dockerfile"
  platforms = [ "linux/amd64", "linux/arm64" ]
}

target "setup-python" {
  inherits = [ "metadata-setup-python" ]
  context = "step05/arc-custom-images"
  dockerfile = "setup-python.Dockerfile"
  platforms = [ "linux/amd64", "linux/arm64" ]
}
