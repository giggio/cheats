#!/usr/bin/env bash

set -euo pipefail

find "$(pwd)" -name '*.sh' -exec shellcheck --shell bash {} +
