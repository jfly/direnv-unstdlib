# shellcheck shell=bash

# This is a collection of direnv utilities that are basically simplified
# versions of nixpkgs's `makeWrapper`.

# Wrap the given executable file and add it to the PATH.
# Usage: wrap_program EXECUTABLE ARGS
#
# See `make_wrapper` for supported ARGS.
wrap_program() {
	local wrap_me=$1
	shift # skip past first argument

	local basename
	basename=$(basename "$wrap_me")
	wrapper=$(direnv_layout_dir)/wrappers/$basename-wrapper/$basename
	wrapper_dir=$(dirname "$wrapper")

	mkdir -p "$wrapper_dir"
	make_wrapper "$wrap_me" "$wrapper" "$@"

	PATH_add "$wrapper_dir"
}

# Wrap the given executable file.
# Usage: make_wrapper EXECUTABLE OUT_PATH ARGS
#
# This only supports a small subset of the features in [the original]. Feel free to duplicate functionality over as needed.
#
# [the original]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
#
# ARGS:
# --run       COMMAND : run COMMAND before EXECUTABLE
make_wrapper() {
	local wrap_me=$1
	local wrapper=$2

	if ! [[ -f $wrap_me && -x $wrap_me ]]; then
		log_error "wrap_program: Cannot wrap '$wrap_me' as it is not an executable file"
		exit 1
	fi

	echo "#!/usr/bin/env bash" >"$wrapper"

	params=("$@")
	for ((n = 2; n < ${#params[*]}; n += 1)); do
		p="${params[$n]}"

		if [[ $p == "--run" ]]; then
			command="${params[$((n + 1))]}"
			n=$((n + 1))
			echo "$command" >>"$wrapper"
		else
			die "make_wrapper doesn't understand the arg $p"
		fi
	done

	echo exec "'$wrap_me'" '"$@"' >>"$wrapper"
	chmod +x "$wrapper"
}
