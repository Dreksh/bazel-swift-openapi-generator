# THIS IS AUTO-GENERATED BY bazel run //:update
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _load_code_impl(module_ctx):
    http_archive(
        name = "swift-openapi-generator-code",
        url = "https://github.com/apple/swift-openapi-generator/archive/refs/tags/1.0.0-alpha.1.tar.gz",
        sha256 = "dc79d7779357f387a94f59e55a64cb041c13828a6318b99931f154122f66d600",
        strip_prefix = "swift-openapi-generator-1.0.0-alpha.1",

        patches = ["//:internal/swift-openapi-generator.patch"],    # Add pre-calculated bazel files to the repo
        patch_args = ["-p1"],                                       # Using Git-diff requires stripping the first path
    )

load_code = module_extension(
    implementation = _load_code_impl,
    doc = "Fetches the source code from the swift-openapi-generator git repository.",
)
