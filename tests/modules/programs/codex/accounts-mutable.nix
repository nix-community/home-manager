{
  config,
  lib,
  pkgs,
  ...
}:
let
  activate = pkgs.writeShellScript "activate-account-settings" ''
    set -eu
    set -o pipefail
    ${config.lib.bash.initHomeManagerLib}
    ${config.home.activation.codexMutableSettings.data}
    ${config.home.activation."codexMutableSettings-work".data}
  '';
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  programs.codex = {
    enable = true;
    package = null;
    mutableSettings = true;
    accounts.work.home = ".codex-work";
    settings.model = "shared";
  };
  nmt.script = ''
    set -eu
    set -o pipefail
    for account in .codex .codex-work; do
      account_home="$TMPDIR/hm-user/$account"
      mkdir -p "$account_home/sessions"
      printf 'model = "local"\nlocalOnly = "%s"\n' "$account" > "$account_home/config.toml"
      printf '%s\n' "$account" > "$account_home/auth.json"
      touch "$account_home/sessions/keep"
    done
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activate} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"
    for account in .codex .codex-work; do
      account_home="$TMPDIR/hm-user/$account"
      test ! -L "$account_home/config.toml"
      ${lib.getExe pkgs.jaq} --from toml --arg account "$account" -e \
        '.model == "shared" and .localOnly == $account' "$account_home/config.toml"
      test "$(cat "$account_home/auth.json")" = "$account"
      test -f "$account_home/sessions/keep"
    done
  '';
}
