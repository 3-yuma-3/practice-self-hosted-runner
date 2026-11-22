group "export-images" {
  targets = ["debian-export", "setup-node-export", "setup-python-export"]
}

target "debian-export" {
  inherits = ["debian"]

  matrix = {
    arch = ["amd64", "arm64"]
  }
  name = "debian-export-${arch}"

  platforms = ["linux/${arch}"]
  tags = ["arc-runner-debian:${arch}"]

  output = [
    {
      type = "docker"
      dest = "arc-images/debian-${arch}.tar"
    }
  ]
}

target "setup-node-export" {
  inherits = ["setup-node"]

  matrix = {
    arch = ["amd64", "arm64"]
  }
  name = "setup-node-export-${arch}"

  platforms = ["linux/${arch}"]
  tags      = ["arc-runner-setup-node:${arch}"]

  output = [
    {
      type = "docker"
      dest = "arc-images/setup-node-${arch}.tar"
    }
  ]
}

target "setup-python-export" {
  inherits = ["setup-python"]

  matrix = {
    arch = ["amd64", "arm64"]
  }
  name = "setup-python-export-${arch}"

  platforms = ["linux/${arch}"]
  tags      = ["arc-runner-setup-python:${arch}"]

  output = [
    {
      type = "docker"
      dest = "arc-images/setup-python-${arch}.tar"
    }
  ]
}
