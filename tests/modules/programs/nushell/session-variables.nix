{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

let
  systemEnvironment = realPkgs.writeText "set-environment" ''
    export __NIXOS_SET_ENVIRONMENT_DONE=1
    export SYSTEM_VALUE="$HOME/$USER"
    export PATH="/system/bin:$PATH"
  '';
  expected = pkgs.writeText "expected-session-variables" ''
    /runtime/home/runtime-user
    /runtime/home/.config
    fallback
    home-is-set
    /runtime/home/.local/bin:/system/bin
    env-file-loaded
  '';
in
{
  _module.args.osConfig.system.build.setEnvironment = systemEnvironment;

  nixpkgs.overlays = [
    (_final: _prev: { runtimeShell = "/bin/sh"; })
  ];

  home = {
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

      actual="$PWD/actual"
      env -i \
        HOME=/runtime/home \
        USER=runtime-user \
        PATH=/initial/bin \
        ${lib.getExe realPkgs.nushell} \
          --no-history \
          --config /dev/null \
          --env-config "$(_abs ${envFile})" \
          --commands '
            print ([
              $env.SYSTEM_VALUE
              $env.EXPANDED_HOME
              $env.DEFAULT_VALUE
              $env.ALTERNATE_VALUE
              ($env.PATH | first 2 | str join (char esep))
              $env.USER_ENV_FILE
            ] | str join (char newline))
          ' > "$actual"

      assertFileContent "$actual" ${expected}
    '';
}
