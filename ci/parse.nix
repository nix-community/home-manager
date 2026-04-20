{
  lib,
  nix,
  runCommand,
}:
let
  home-manager =
    with lib.fileset;
    toSource {
      root = ../.;
      fileset = (fileFilter (file: file.hasExt "nix") ../.);
    };
  parseLog = "$TMPDIR/nix-parse.log";
in
runCommand "nix-parse-${nix.name}"
  {
    nativeBuildInputs = [
      nix
    ];
  }
  ''
    export NIX_STORE_DIR=$TMPDIR/store
    export NIX_STATE_DIR=$TMPDIR/state
    nix-store --init

    cd "${home-manager}"

    # This will only show the first parse error, not all of them. That's fine, because
    # the other CI jobs will report in more detail. This job is about checking parsing
    # across different implementations / versions, not about providing the best DX.
    # Returning all parse errors requires significantly more resources.
    if ! find . -type f -iname '*.nix' | xargs -P $(nproc) nix-instantiate --parse 2> "${parseLog}" > /dev/null; then
      cat "${parseLog}" >&2
      echo "Parse failed in nix-instantiate." >&2
      exit 1
    fi

    if grep "warning" "${parseLog}"; then
      cat "${parseLog}" >&2
      echo "Failing due to warnings in stderr" >&2
      exit 1
    fi

    touch $out
  ''
