#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
exec "$DIR/../regtest/regtest.py" -v inspect "$@"
