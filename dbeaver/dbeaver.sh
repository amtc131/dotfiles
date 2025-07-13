#!/bin/bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk use 21.0.6-oracle
exec dbeaver "$@"
