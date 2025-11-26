set -o errexit -o noclobber -o nounset -o pipefail
shopt -s failglob inherit_errexit

cleanup() {
  git restore --staged flake.lock
  git checkout flake.lock
}

afterUpdateCommands() {
  @afterUpdateCommandLine@
}

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
    echo "${0}: Could not update input ${input} in directory ${PWD}!" >&2
    cleanup
    return 64
  fi

  if git diff --quiet flake.lock; then
    # Already up to date
    return 0
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

  if ! "${nix_build_command[@]}"; then
    echo "${0}: Could not update input ${input} in directory ${PWD}!"
    cleanup
    return 65
  fi

  # shellcheck disable=SC2310
  if ! afterUpdateCommands; then
    echo "$0: After update commands failed!" >&2
    cleanup
    return 66
  fi

  git commit --message="build: Update Nix flake input '${input}'" -- flake.lock
}

for directory; do
  cd "${directory}"

  if ! git diff --cached --quiet; then
    echo "$0: ${PWD} has staged changes; skipping!" >&2
    exit_code=64
    continue
  fi

  if ! git diff --quiet flake.lock; then
    echo "$0: ${PWD}/flake.lock has changes; skipping!" >&2
    exit_code=65
    continue
  fi

  inputs_raw="$(nix flake metadata --json | jq --raw-output '.locks.nodes.root.inputs | keys[]')"
  readarray -t inputs <<<"${inputs_raw}"

  broken_inputs=()
  for input in "${inputs[@]}"; do
    # shellcheck disable=SC2310
    if ! direnv exec . update_flake_input "${input}"; then
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
