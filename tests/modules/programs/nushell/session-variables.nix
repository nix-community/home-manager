{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

let
  systemEnvironment = pkgs.writeText "set-environment" ''
    if [ -n "''${SKIP_SYSTEM-}" ]; then return; fi
    export __NIXOS_SET_ENVIRONMENT_DONE=1
    export SYSTEM_VALUE="$HOME/$USER"
    export PATH="/system/bin:$PATH"
    unset REMOVED_BY_SYSTEM
  '';
in
{
  _module.args.osConfig.system.build.setEnvironment = systemEnvironment;

  home = {
    stateVersion = "26.11";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      ALTERNATE_VALUE = "\${HOME:+home-is-set}";
      DEFAULT_VALUE = "\${UNSET_VARIABLE:-fallback}";
      EXPANDED_HOME = "$HOME/.config";
    };
  };

  programs.nushell = {
    enable = true;
    package = realPkgs.nushell;
    envFile.text = ''
      $env.USER_ENV_FILE = "env-file-loaded"
    '';
  };

  nmt.script =
    let
      homePrefix = "${config.home.homeDirectory}/";
      configDir = lib.removePrefix homePrefix config.programs.nushell.configDir;
      envFile = "home-files/${configDir}/env.nu";
    in
    ''
      assertFileRegex ${envFile} \
        '^source /nix/store/[^/]*-hm-session-vars.nu$'

      for ssh_client in "" "10.0.0.1 5000 22"; do
        env -i \
          HOME=/runtime/home \
          USER=runtime-user \
          PATH=/initial/bin \
          REMOVED_BY_SYSTEM=inherited \
          SSH_CLIENT="$ssh_client" \
          ${lib.getExe realPkgs.nushell} \
            --login \
            --no-history \
            --config /dev/null \
            --env-config "$(_abs ${envFile})" \
            --commands '
              use std/assert
              assert equal $env.SYSTEM_VALUE /runtime/home/runtime-user
              assert equal $env.EXPANDED_HOME /runtime/home/.config
              assert equal $env.DEFAULT_VALUE fallback
              assert equal $env.ALTERNATE_VALUE home-is-set
              assert equal $env.PATH [/runtime/home/.local/bin /system/bin /initial/bin]
              assert equal $env.USER_ENV_FILE env-file-loaded
              assert ("REMOVED_BY_SYSTEM" not-in $env)
            ' || fail "Nushell did not load the session environment."

        # tmux on nix-darwin clears the marker to request reinitialization.
        for marker in __NIX_DARWIN_SET_ENVIRONMENT_DONE \
          __NIXOS_SET_ENVIRONMENT_DONE; do
          env -i \
            HOME=/runtime/home \
            USER=runtime-user \
            PATH=/initial/bin \
            __HM_SESS_VARS_SOURCED=1 \
            "$marker=" \
            REMOVED_BY_SYSTEM=inherited \
            SSH_CLIENT="$ssh_client" \
            ${lib.getExe realPkgs.nushell} \
              --login \
              --no-history \
              --config /dev/null \
              --env-config "$(_abs ${envFile})" \
              --commands '
                use std/assert
                assert equal $env.SYSTEM_VALUE /runtime/home/runtime-user
                assert equal $env.PATH [/system/bin /initial/bin]
                assert ("EXPANDED_HOME" not-in $env)
                assert ("REMOVED_BY_SYSTEM" not-in $env)
              ' || fail "Nushell did not reload with an empty $marker."
        done

        # Reloading scripts that leave the environment unchanged is valid too.
        env -i \
          HOME=/runtime/home USER=runtime-user PATH=/initial/bin \
          __HM_SESS_VARS_SOURCED=1 SKIP_SYSTEM=1 \
          SSH_CLIENT="$ssh_client" \
          ${lib.getExe realPkgs.nushell} \
            --login --no-history --config /dev/null \
            --env-config "$(_abs ${envFile})" \
            --commands '
              use std/assert
              assert equal $env.PATH [/initial/bin]
              assert equal $env.USER_ENV_FILE env-file-loaded
            ' || fail "Nushell failed with an unchanged session environment."
      done
      # Model a remote Bash startup file that initializes the system first.
      mkdir -p ssh-home
      printf '%s\n' '. ${systemEnvironment}' > ssh-home/.bashrc
      for hm_marker in "" 1; do
        env -i \
          HOME="$PWD/ssh-home" USER=runtime-user PATH=/initial/bin \
          SSH_CLIENT="10.0.0.1 5000 22" \
          __HM_SESS_VARS_SOURCED="$hm_marker" \
          __NIX_DARWIN_SET_ENVIRONMENT_DONE= \
          ${lib.getExe realPkgs.nushell} \
            --login --no-history --config /dev/null \
            --env-config "$(_abs ${envFile})" \
            --commands '
              use std/assert
              assert equal $env.SYSTEM_VALUE ($env.HOME + "/runtime-user")
              assert equal $env.__NIXOS_SET_ENVIRONMENT_DONE "1"
            ' || fail "Nushell lost the system environment over SSH."
      done
    '';
}
