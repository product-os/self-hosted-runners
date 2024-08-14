# https://docs.docker.com/build/bake/file-definition/

variable "OS_CODENAME" {
  default = "jammy"
}

target "default" {
  target = "runtime"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  args = {
    OS_CODENAME = OS_CODENAME
  }
}

target "focal" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "focal"
  }
}

target "jammy" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "jammy"
  }
}

target "noble" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "noble"
  }
}
