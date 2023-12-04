#!/bin/bash

set -euo pipefail

if [[ -n "${DEBUG+set}" ]]; then set -x ; fi

if [[ -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
    COMMAND="$0"
    BUILD_WORKSPACE_DIRECTORY="$(cd "$(dirname "$COMMAND")/.." && pwd)"
else
    COMMAND="bazel run //:update --"
fi

help() {
    if [[ -n "${1:-}" ]]; then
    cat >&2 <<EOF

Error: "$1"

EOF
    fi;

cat >&2 <<EOF
Help:

  ${COMMAND} <version>

Descirption:

  Updates the bazel module to the newer version of swift-openapi-generator.
  This requires \`bazel\`, \`curl\`, \`git\` and \`swift\` to be installed.

Arguments:

  version - The version of swift-openapi-generator to use (and subsequently, the version of this module)

EOF
}

###
### Error Check
###

if [ $# -eq 0 ]; then help "Missing version."; exit 1; fi
if [ $# -ne 1 ]; then help "Unexpected arguments found."; exit 1; fi
case "$1" in
  -h|--help|help) help; exit 0;;
esac

###
### Fetch archive
###

VERSION="$1"
URL="https://github.com/apple/swift-openapi-generator/archive/refs/tags/${VERSION}.tar.gz"
TEMP_DIR="$(mktemp -d)"
if [[ -n "${KEEP+set}" ]]; then
    echo "Storing temporary data in: ${TEMP_DIR}" >&2
else
    trap 'rm -rf "${TEMP_DIR}"' EXIT
fi

cd "${TEMP_DIR}" &>/dev/null # Experienced places where cd ended up printing to stdout
HTTP_CODE="$(curl -sSL -o archive.tar.gz -w '%{http_code}' "${URL}")"
RESULT=$?
if [ $RESULT -ne 0 ]; then help "Failed to fetch repository."; exit $RESULT; fi
if [[ "200" -ne "${HTTP_CODE}" ]]; then help "Failed to fetch repository."; exit 1; fi
SHASUM="$(shasum -a 256 archive.tar.gz | cut -d" " -f 1)"

###
### Setup the repo
###

tar -xzf archive.tar.gz
rm archive.tar.gz
cd "swift-openapi-generator-${VERSION}"
git init &>/dev/null                    # git init usually prints a message
git add .
git commit -m "Base commit" &>/dev/null
touch WORKSPACE
for file in BUILD.bazel MODULE.bazel .bazelrc .gitignore ; do cp "${BUILD_WORKSPACE_DIRECTORY}/internal/${file}.copy" "${file}" ; done
bazel run //:update_deps_to_latest
bazel run //:create_build_files

###
### Update repo's pre-calculated files
###

for file in MODULE.bazel extensions.bzl; do
    echo "# THIS IS AUTO-GENERATED BY bazel run //:update" > "${BUILD_WORKSPACE_DIRECTORY}/${file}"
    sed 's#{VERSION}#'"${VERSION}"'#;s#{URL}#'"${URL}"'#;s#{SHASUM}#'"${SHASUM}"'#;' "${BUILD_WORKSPACE_DIRECTORY}/internal/${file}.template" >> "${BUILD_WORKSPACE_DIRECTORY}/${file}"
done
cat MODULE.bazel >> "${BUILD_WORKSPACE_DIRECTORY}/MODULE.bazel"
mv -f swift_deps_index.json "${BUILD_WORKSPACE_DIRECTORY}/swift_deps_index.json"
rm MODULE.bazel .bazelrc # These aren't needed in the patch

# Remove swift-openapi-generator's module_name (as it's not a valid identifier)
sed -i '' '/module_name =/d' Sources/swift-openapi-generator/BUILD.bazel
# Add dependency on _OpenAPIGeneratorCore
sed -i '' '/deps =/a\
        "//Sources/_OpenAPIGeneratorCore",
' Sources/swift-openapi-generator/BUILD.bazel

git add .
git diff HEAD > "${BUILD_WORKSPACE_DIRECTORY}/internal/swift-openapi-generator.patch"