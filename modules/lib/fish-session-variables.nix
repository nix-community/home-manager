{
  config,
  lib,
  pkgs,
}:

let
  inherit (config.lib) shell;

  inherit (import ./session-search-shell.nix { inherit lib; }) assignDoubleQuoted;

  sessionVarsFile = "etc/profile.d/hm-session-vars.fish";

  mkMerges =
    operation: attrs:
    lib.mapAttrsToList (env: values: {
      inherit env operation;
      candidates = lib.imap0 (index: value: {
        name = "__hm_candidate_${operation}_${env}_${toString index}";
        inherit value;
      }) (lib.filter (value: value != "") values);
    }) attrs;

  # Prepends first, then appends, matching the POSIX generator.
  merges =
    mkMerges "prepend" config.home.sessionSearchVariables
    ++ mkMerges "append" config.home.sessionSearchVariablesAppend;

  candidateNames = lib.concatMap (merge: map (candidate: candidate.name) merge.candidates) merges;

  prelude = pkgs.writeText "hm-session-vars-fish-prelude.sh" ''
    ${shell.exportAll config.home.sessionVariables}
  '';

  extra = pkgs.writeText "hm-session-vars-fish-extra.sh" ''
    if [ -n "''${__HM_SESS_VARS_SOURCED-}" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

    ${config.home.sessionVariablesExtra}
  '';

  # Translate assignments and calls together so an entry can observe earlier
  # search-variable merges. The helper itself remains native Fish.
  mergeScript = pkgs.writeText "hm-session-vars-fish-merges.sh" (
    lib.concatLines (
      map (
        merge:
        lib.concatLines [
          (lib.concatMapStringsSep "\n" (
            candidate: assignDoubleQuoted candidate.name candidate.value
          ) merge.candidates)
          (
            "__hm_merge ${merge.operation} ${merge.env} :"
            + lib.optionalString (merge.candidates != [ ]) (
              " " + lib.concatMapStringsSep " " (candidate: "\"\$${candidate.name}\"") merge.candidates
            )
          )
        ]
      ) merges
      ++ [ "export __HM_SESS_VARS_MERGED=1" ]
    )
  );

  hasMerges = merges != [ ];
in
pkgs.runCommandLocal "hm-session-vars.fish" { } ''
  mkdir -p "$(dirname "$out/${sessionVarsFile}")"
  {
    ${lib.optionalString hasMerges "cat ${./session-search-merge.fish}"}

    echo "function setup_hm_session_vars"
    ${
      # One declaration per name: `set -l a b c` declares only `a`, with the
      # rest as its value.
      lib.concatMapStringsSep "\n" (name: ''echo "  set -l ${name}"'') candidateNames
    }
    ${pkgs.buildPackages.babelfish}/bin/babelfish < ${prelude}
    ${lib.optionalString hasMerges "${pkgs.buildPackages.babelfish}/bin/babelfish < ${mergeScript}"}
    ${pkgs.buildPackages.babelfish}/bin/babelfish < ${extra}
    echo "end"

    echo "setup_hm_session_vars"
    echo "functions -e setup_hm_session_vars${lib.optionalString hasMerges " __hm_merge"}"
  } > "$out/${sessionVarsFile}"
''
