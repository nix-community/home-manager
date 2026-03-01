set -o errexit -o noclobber -o nounset -o pipefail
shopt -s failglob inherit_errexit

# shellcheck disable=SC2329
cleanup() {
  git checkout flake.lock
}

# shellcheck disable=SC2329
update_flake_input() {
  local \
    dev_shell_name \
    input \
    machine_type \
    nix_build_command \
    nixos_configuration \
    raw_dev_shell_names \
    raw_nixos_configurations

  input="$1"

  if ! nix flake update "${input}"; then
    cat <<EOF >&2
${0}: Could not update input ${input} in directory ${PWD}!

Please check the output for tips how to fix it.
EOF
    cleanup
    return 82
  fi

  if git diff --quiet flake.lock; then
    # Already up to date; nothing to do
    return 0
  fi

  update_check_command=(nix flake check)
  if ! "${update_check_command[@]}"; then
    cat <<EOF >&2
${0}: Flake check failed for updated input ${input} in directory ${PWD}; reverting!

Make sure \`"${update_check_command[*]}"\` is working
EOF
    cleanup
    return 83
  fi

  nix_build_command=(nix build --no-link --print-out-paths)

  if raw_nixos_configurations="$(
    nix eval --apply 'attrSet: builtins.toString (builtins.attrNames attrSet)' --raw \
      .#.nixosConfigurations
  )"; then
    readarray -d ' ' -t nixos_configurations <<<"${raw_nixos_configurations}"
    for nixos_configuration in "${nixos_configurations[@]}"; do
      nix_build_command+=(".#.nixosConfigurations.${nixos_configuration%%$'\n'}.config.system.build.toplevel")
    done
  fi

  machine_type="$(uname --machine)-linux"

  if raw_dev_shell_names="$(
    nix eval --apply 'attrSet: builtins.toString (builtins.attrNames attrSet)' --raw \
      ".#.devShells.${machine_type}"
  )"; then
    readarray -d ' ' -t dev_shell_names <<<"${raw_dev_shell_names}"
    for dev_shell_name in "${dev_shell_names[@]}"; do
      nix_build_command+=(".#.devShells.${machine_type}.${dev_shell_name%%$'\n'}")
    done
  fi

  if raw_package_names="$(
    nix eval --apply 'attrSet: builtins.toString (builtins.attrNames attrSet)' --raw \
      ".#.packages.${machine_type}"
  )"; then
    readarray -d ' ' -t package_names <<<"${raw_package_names}"
    for package_name in "${package_names[@]}"; do
      nix_build_command+=(".#.packages.${machine_type}.${package_name%%$'\n'}")
    done
  fi

  if ! "${nix_build_command[@]}"; then
    echo "${0}: Could not build after updating input ${input} in directory ${PWD}!"
    cleanup
    return 84
  fi

  if ! nix fmt; then
    echo "$0: Formatting failed!" >&2
    cleanup
    return 85
  fi

  if ! git commit --message="build: Update Nix flake input '${input}'" --no-verify -- flake.lock; then
    echo "$0: Committing failed!" >&2
    cleanup
    return 86
  fi
}

for directory; do
  cd "${directory}"

  if ! git diff --quiet flake.lock; then
    echo "$0: ${PWD}/flake.lock has changes; skipping!" >&2
    exit_code=80
    continue
  fi

  if ! git diff --cached --quiet; then
    echo "$0: ${PWD} has staged changes; skipping!" >&2
    exit_code=81
    continue
  fi

  inputs_raw="$(nix flake metadata --json | jq --raw-output '.locks.nodes.root.inputs | keys[]')"
  readarray -t inputs <<<"${inputs_raw}"

  broken_inputs=()
  for input in "${inputs[@]}"; do
    # shellcheck disable=SC2310
    if ! update_flake_input "${input}"; then
      exit_code="$?"
      broken_inputs+=("${input}")
    fi
  done

  # Summarize at the end, to avoid mixing with the rest of the output
  if ((${#broken_inputs[@]} != 0)); then
    echo "Some flake inputs in ${PWD} can't be updated automatically:" >&2
  fi
  for broken_input in "${broken_inputs[@]}"; do
    echo "- ${broken_input}" >&2
  done
done

exit "${exit_code-0}"
