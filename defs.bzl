def _impl(ctx):
    # Temporary hack, knowing which files are generated with the plugin source specified
    # This also works around https://github.com/bazelbuild/rules_swift/issues/969
    output_files = [ ctx.actions.declare_file("{}/{}".format(ctx.label.name, name)) for name in ["Types.swift", "Server.swift", "Client.swift"] ]
    output_dir = output_files[0].dirname

    # I'm lazy so these are all the inputs this rule will use, and make config mandatory
    args = ctx.actions.args()
    args.add("generate")                            # Specify that it's to generate, rather than filter
    args.add("--plugin-source", "build")            # Produce all files (So we don't need to guess which files exist, and which don't)
    args.add("--output-directory", output_dir)      # Into the output location
    args.add("--config", ctx.file.config)           # With config defined in this file
    args.add(ctx.file.spec)                         # For this spec

    ctx.actions.run(
        outputs = output_files,
        inputs = depset([ctx.file.spec, ctx.file.config]),
        executable = ctx.executable._generator,
        arguments = [args],
    )
    return [
        DefaultInfo(files=depset(output_files)),
    ]

swift_openapi_generate = rule(
    implementation = _impl,
    attrs = {
        "spec": attr.label(
            doc = "The OpenAPI spec to convert to Swift code.",
            allow_single_file = True,
            mandatory = True,
        ),
        "config": attr.label(
            doc = "The configuration for the conversion.",
            allow_single_file = True,
            mandatory = True,
        ),
        "_generator": attr.label(
            doc = "The generator the performs the conversion.",
            executable = True,
            default = "@swift-openapi-generator-code//Sources/swift-openapi-generator",
            cfg = "exec",
        ), 
    },
    doc = "Converts OpenAPI spec into Swift code configured by the config file. See https://swiftpackageindex.com/apple/swift-openapi-generator/0.3.5/documentation/swift-openapi-generator/configuring-the-generator",
    provides = [DefaultInfo],
)
