{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsPath = "$HOME/.config/tea/config.yml";

  activation = pkgs.writeShellScript "activate-tea-token" ''
    set -eu
    set -o pipefail
    ${config.lib.bash.initHomeManagerLib}
    ${config.home.activation.teaToken.data}
  '';
in
{
  programs.tea = {
    enable = true;

    logins = [
      {
        name = "gitea.com";
        tokenFile = "/@TMPDIR@/tea-token";
        url = "https://gitea.com";
        user = "opdavies";
      }
    ];
  };

  home.preferXdgDirectories = true;
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    set -eu
    set -o pipefail
    export HOME="$TMPDIR/hm-user"


    assertFileExists home-files/.config/tea/config.yml

    # Stage the generated configuration like `writeBoundary` does, then
    # run the token substitution in isolation.
    mkdir -p "$HOME/.config/tea"
    cp "$TESTED/home-files/.config/tea/config.yml" ${settingsPath}

    printf 'secret-token' > "$TMPDIR/tea-token"
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"

    test ! -L ${settingsPath}
    ${lib.getExe pkgs.gnugrep} -F 'token: secret-token' ${settingsPath}
  '';
}
