// docker bake configuration

// Variables used in this file, docker-compose and Dockerfile
// See following references:
// https://docs.docker.com/engine/reference/commandline/buildx_bake/#hcl-variables-and-functions
// https://github.com/docker/buildx/blob/master/bake/hclparser/stdlib.go
// https://github.com/zclconf/go-cty/tree/main/cty/function/stdlib

variable "OSimage" {
    default = "Debian-10"
}

// Defaults
group "default" {
    targets = ["dual_build"]
}

// All the build targets
target "root_build" {
    args = {
        OSimage = OSimage
    }
    target = "unibuild-image"
    context = "../"
    dockerfile = "docker-envs/Dockerfile-${OSimage}"
    output = ["type=cacheonly"]
}
target "single_build" {
    inherits = ["root_build"]
    output = ["type=docker"]
    tags = ["unibuild/${OSimage}:latest"]
}
target "dual_build" {
    inherits = ["root_build"]
    platforms = ["linux/amd64", "linux/arm64"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/unibuild.${OSimage}:latest"]
}
target "full_build" {
    inherits = ["root_build"]
    platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/unibuild.${OSimage}:latest"]
}

