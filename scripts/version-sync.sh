#!/usr/bin/env bash
set -euo pipefail

# This script can run from anywhere, but assumes it's executed from the repo root
# where version.txt is located, or we can use $GITHUB_WORKSPACE if available, otherwise $PWD.
root="${GITHUB_WORKSPACE:-$PWD}"
version_file="$root/version.txt"
package_json="$root/package.json"
package_lock="$root/package-lock.json"

usage() {
	echo "usage: ${0##*/} [check|bump <version>]" >&2
	exit 1
}

semver_ok() {
	[[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+-.*$ ]]
}

check_sync() {
    # If version.txt does not exist, fail
    if [[ ! -f "$version_file" ]]; then
        echo "version.txt not found" >&2
        exit 1
    fi

    # Only check package.json if it exists
    if [[ -f "$package_json" && -f "$package_lock" ]]; then
        python3 - "$version_file" "$package_json" "$package_lock" <<'PY'
from pathlib import Path
import json
import sys

version = Path(sys.argv[1]).read_text().strip()
package = json.loads(Path(sys.argv[2]).read_text())
lock = json.loads(Path(sys.argv[3]).read_text())

errors = []
if package.get("version") != version:
    errors.append(f'package.json version {package.get("version")!r} does not match version.txt {version!r}')
if lock.get("version") != version:
    errors.append(f'package-lock.json version {lock.get("version")!r} does not match version.txt {version!r}')
root_package = lock.get("packages", {}).get("", {})
if root_package.get("version") != version:
    errors.append(f'package-lock.json packages[""] version {root_package.get("version")!r} does not match version.txt {version!r}')

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
PY
    fi
}

bump_sync() {
	local new_version="$1"
	if ! semver_ok "$new_version"; then
		echo "invalid semantic version: $new_version" >&2
		exit 1
	fi

	printf '%s\n' "$new_version" > "$version_file"
    
    if [[ -f "$package_json" && -f "$package_lock" ]]; then
        python3 - "$package_json" "$package_lock" "$new_version" <<'PY'
from pathlib import Path
import json
import sys

package_json = Path(sys.argv[1])
package_lock = Path(sys.argv[2])
version = sys.argv[3]

package = json.loads(package_json.read_text())
package["version"] = version
package_json.write_text(json.dumps(package, indent=2) + "\n")

lock = json.loads(package_lock.read_text())
lock["version"] = version
if "packages" in lock and "" in lock["packages"]:
    lock["packages"][""]["version"] = version
package_lock.write_text(json.dumps(lock, indent=2) + "\n")
PY
    fi
}

case "${1:-}" in
	check)
		check_sync
		;;
	bump)
		[[ $# -eq 2 ]] || usage
		bump_sync "$2"
		;;
	*)
		usage
		;;
esac
