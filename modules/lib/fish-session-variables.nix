{
  config,
  lib,
  pkgs,
}:

let
  normalize = values: lib.unique (lib.filter (value: value != "") values);
  mkMerge = operation: env: values: {
    inherit env operation;
    candidates = lib.imap0 (index: value: {
      name = "__HM_FISH_${lib.toUpper operation}_${env}_${toString index}";
      inherit value;
    }) (normalize values);
  };
  merges =
    lib.mapAttrsToList (mkMerge "prepend") config.home.sessionSearchVariables
    ++ lib.mapAttrsToList (mkMerge "append") config.home.sessionSearchVariablesAppend;
  candidates = lib.concatMap (merge: merge.candidates) merges;
  candidateNames = map (candidate: candidate.name) candidates;
  candidateAssignments = lib.concatMapStringsSep "\n" (
    candidate: lib.removePrefix "export " (config.lib.shell.export candidate.name candidate.value)
  ) candidates;

  mkFishMerge =
    {
      candidates,
      env,
      operation,
    }:
    let
      isPath = lib.hasSuffix "PATH" env;
      addCandidates = lib.concatMapStringsSep "\n" (
        candidate:
        let
          membership =
            if isPath then
              ''contains -- "$__hm_entry" $__hm_current $__hm_add''
            else
              ''string replace -q -- ":$__hm_entry:" "" "$__hm_seen" >/dev/null'';
          add =
            if isPath then
              ''set -a __hm_add "$__hm_entry"''
            else
              ''
                if test -n "$__hm_add"
                  set __hm_add "$__hm_add:$__hm_entry"
                else
                  set __hm_add "$__hm_entry"
                end
                set __hm_seen "$__hm_seen$__hm_entry:"
              '';
        in
        ''
          set __hm_entry "${"$" + candidate.name}"
          if test -n "$__hm_entry"
            ${membership}
            or begin
              ${add}
            end
          end
        ''
      ) candidates;
      combine =
        if isPath then
          if operation == "prepend" then
            "set -gx ${env} $__hm_add $__hm_current"
          else
            "set -gx ${env} $__hm_current $__hm_add"
        else if operation == "prepend" then
          ''set -gx ${env} "$__hm_add$__hm_separator$__hm_current"''
        else
          ''set -gx ${env} "$__hm_current$__hm_separator$__hm_add"'';
    in
    ''
      set -l __hm_current ${lib.optionalString (!isPath) ''"''}${"$" + env}${
        lib.optionalString (!isPath) ''"''
      }
      set -l __hm_add
      set -l __hm_entry
      ${lib.optionalString (!isPath) ''set -l __hm_seen ":$__hm_current:"''}
      ${addCandidates}
      set -l __hm_separator
      test -z "$__hm_current"; or test -z "$__hm_add"; or set __hm_separator :
      ${combine}
    '';
  nativeMerges = lib.concatMapStringsSep "\n" mkFishMerge merges;

  baseScript = pkgs.writeText "hm-session-vars-fish-base.sh" ''
    ${config.lib.shell.exportAll config.home.sessionVariables}
    ${candidateAssignments}
  '';
  extraScript = pkgs.writeText "hm-session-vars-fish-extra.sh" ''
    if [ -z "''${__HM_SESS_VARS_SOURCED-}" ]; then
      export __HM_SESS_VARS_SOURCED=1
      ${config.home.sessionVariablesExtra}
    fi
  '';
  sessionVarsFile = "etc/profile.d/hm-session-vars.fish";
in
pkgs.runCommandLocal "hm-session-vars.fish"
  {
    inherit nativeMerges;
    passAsFile = [ "nativeMerges" ];
  }
  ''
    mkdir -p "$(dirname "$out/${sessionVarsFile}")"
    {
      echo "function setup_hm_session_vars"
      ${lib.optionalString (candidateNames != [ ]) ''
        echo "  set -l ${lib.concatStringsSep " " candidateNames}"
      ''}
      ${pkgs.buildPackages.babelfish}/bin/babelfish < ${baseScript}
      cat "$nativeMergesPath"
      ${pkgs.buildPackages.babelfish}/bin/babelfish < ${extraScript}
      echo "end"
      echo "setup_hm_session_vars"
    } > "$out/${sessionVarsFile}"
  ''
