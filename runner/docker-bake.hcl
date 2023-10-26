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

target "jammy" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "jammy"
  }
}

target "jammy-vm" {
  inherits = ["default"]
  target = "vm"
  args = {
    OS_CODENAME = "jammy"
  }
}

target "focal" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "focal"
  }
}

target "focal-vm" {
  inherits = ["default"]
  target = "vm"
  args = {
    OS_CODENAME = "focal"
  }
}
