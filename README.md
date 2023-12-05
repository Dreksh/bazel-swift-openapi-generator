Swift OpenAPI Generator Bazel rules
===================================

A wrapper over the [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator/tree/main).

Usage
-----

For more examples, see [Examples](./examples).

Here are the instructions for quickly using the generator:
1. [Adding the module in your `MODULE.bazel`](#adding-the-module)
2. [Apply a rules\_swift\_package\_manager workaround](#common-swift-dependencies)
3. [Using the swift\_openapi\_generate rule](#using-the-rule)

### Adding the Module

There is a [known issue](#not-hosted-in-a-bazel-registry) where this module can't be manually added
into the `MODULE.bazel` file.
The current method is to follow modify the `WORKSPACE` file, not relying on Bazel's module system.

When the issue is resolved, and this module is added to a Bazel registry,
the dependency is added by inserting this line into `MODULE.bazel`:
```skylark
bazel_dep(name = "swift-openapi-generator", version = "1.0.0-alpha1")
```

### Using the Rule

In the Bazel package where you want to generate the Swift code from OpenAPI specs, add these lines:
```skylark
load("@swift-openapi-generator//:defs.bzl", "swift_openapi_generate")

swift_openapi_generate(
    name = "server_stub",
    spec = "openapi.yaml",
    config = "openapi-generator-config.yaml",
)
```

The name of the rule determines the directory where the files will be placed when it's generated.
`openapi.yaml` is the spec to generate code for, and `openapi-generator-config.yaml` configures
the generator (see [Configuring the generator](https://swiftpackageindex.com/apple/swift-openapi-generator/1.0.0-alpha.1/documentation/swift-openapi-generator/configuring-the-generator) )

Updating the Version
--------------------

Simply run `bazel run //:update -- <version>`, where the version is the tag in the Swift OpenAPI Generator repository.
This will run a script that updates the files in this repo to point to a different version.

This script currently requires the following tools installed:
- `bazel`
- `curl`
- `git`
- `swift` (or Xcode for macOS)

Issues and Their Workarounds
----------------------------

There are some known issues which require some workarounds.

### Common Swift Dependencies

The `swift_deps` extension from `rules_swift_package_manager` will attempt to add all dependencies specified
in each module's `swift_deps_index.json`. If multiple modules share some set of Swift libraries as their
depdency, it will attempt to create the same repository target causing Bazel to error.

To work around this, there is a `rules_swift_package_manager.patch` file in this repository, generated from
`v0.22.0`, that adds a simple deduplication of libraries. This allows each one to only be specified once.
The downside of this patch is that the deduplication does not take into account of the versions, and so either
version of the depdnency may be used.

Steps to apply the workaround:
1. Copy the `rules_swift_package_manager.patch` to your local repository (patches require to be local to the repo)
2. Add this in `MODULE.bazel`, under `bazel_dep(name = "rules_swift_package_manager",...)`:
```skylark
single_version_override(
    module_name = "rules_swift_package_manager",
    patches = ["//:rules_swift_package_manager.patch"],
    patch_strip = 1, # Remove 1 directory level, as it's a git diff
)
```

### Not Hosted in a Bazel Registry

Since this is not in the bazel registry yet, the module will need to be added via the WORKSPACE.
This is due to the `swift-openapi-generator` bazel module containing another repository dependency, which requires
Accessing the `@swift-openapi-generator//:extensions.bzl` file to load.

The steps to do this is:
1. Add this to the `WORKSPACE` file:
```skylark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "swift-openapi-generator",
    url = "https://github.com/Dreksh/bazel-swift-openapi-generator/archive/refs/tags/v1.0.0-alpha.1.tar.gz",
    # sha256 = "5ddbe9c50cb72017e93b83531af6dd5f580b04e3f2e922a093af4e609db35dfa", (SHA not known at time of writing)
    strip_prefix = "bazel-swift-openapi-generator-1.0.0-alpha.1",
)
load("@swift-openapi-generator//:extensions.bzl", swift_openapi_generator_deps = "deps")
swift_openapi_generator_deps(repository_name="@swift-openapi-generator")
```
