# https://docs.docker.com/build/bake/file-definition/

variable "OS_CODENAME" {
  default = "jammy"
}

target "default" {
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
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

target "focal" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "focal"
  }
}

target "jammy-amd64" {
  inherits = ["jammy"]
  platforms = [
    "linux/amd64"
  ]
}

target "jammy-arm64v8" {
  inherits = ["jammy"]
  platforms = [
    "linux/arm64"
  ]
}

target "jammy-arm32v7" {
  inherits = ["jammy"]
  platforms = [
    "linux/arm/v7"
  ]
}

target "focal-amd64" {
  inherits = ["focal"]
  platforms = [
    "linux/amd64"
  ]
}

target "focal-arm64v8" {
  inherits = ["focal"]
  platforms = [
    "linux/arm64"
  ]
}

target "focal-arm32v7" {
  inherits = ["focal"]
  platforms = [
    "linux/arm/v7"
  ]
}
