# https://docs.docker.com/build/bake/file-definition/

variable "OS_CODENAME" {
  default = "jammy"
}

variable "GITHUB_TOKEN" {
  default = ""
}

target "default" {
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64"
  ]
  args = {
    OS_CODENAME = OS_CODENAME
    GITHUB_TOKEN = GITHUB_TOKEN
  }
}

target "jammy" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "jammy"
    GITHUB_TOKEN = GITHUB_TOKEN
  }
}

target "focal" {
  inherits = ["default"]
  args = {
    OS_CODENAME = "focal"
    GITHUB_TOKEN = GITHUB_TOKEN
  }
}
