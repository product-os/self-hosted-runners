# https://docs.docker.com/build/bake/file-definition/

# https://releases.ubuntu.com/
variable "UBUNTU_LTS" {
  default = "7.0.2-jammy"
}

target "default" {
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64"
  ]
  args = {
    UBUNTU_LTS = UBUNTU_LTS
  }
}

target "focal" {
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64"
  ]
  args = {
    UBUNTU_LTS = "6.0.13-focal"
  }
}
