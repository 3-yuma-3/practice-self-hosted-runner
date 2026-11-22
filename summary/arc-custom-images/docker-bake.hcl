group "default" {
  targets = [ "debian", "setup-node", "setup-python", "ubuntu"]
}

variable "RUNNER_VERSION" {
  // https://github.com/actions/runner/releases
  default = "2.338.2"
}

variable "RUNNER_SHA256_AMD64" {
  default = "baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40"
}

variable "RUNNER_SHA256_ARM64" {
  default = "670adb2f268fe21dcbb58b3db0e0aa9d5b3bddfe2c651481336e561ff86de945"
}

// actions での push 時に metadata が付与される
target "metadata-debian" {}
target "metadata-setup-node" {}
target "metadata-setup-python" {}
target "metadata-ubuntu" {}

target "debian" {
  inherits = [ "metadata-debian" ]
  context    = "summary/arc-custom-images"
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
  context = "summary/arc-custom-images"
  dockerfile = "setup-node.Dockerfile"
  platforms = [ "linux/amd64", "linux/arm64" ]
}

target "setup-python" {
  inherits = [ "metadata-setup-python" ]
  context = "summary/arc-custom-images"
  dockerfile = "setup-python.Dockerfile"
  platforms = [ "linux/amd64", "linux/arm64" ]
}

target "ubuntu" {
  inherits = ["metadata-ubuntu"]
  context = "summary/arc-custom-images"
  dockerfile = "ubuntu.Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  
  args = {
    RUNNER_VERSION       = "${RUNNER_VERSION}"
    RUNNER_SHA256_AMD64  = "${RUNNER_SHA256_AMD64}"
    RUNNER_SHA256_ARM64  = "${RUNNER_SHA256_ARM64}"
  }
}
