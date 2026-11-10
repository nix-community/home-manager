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
    ${config.home.activation.claudeCodeSettings.data}
    ${config.home.activation."claudeCodeSettings-work".data}
  '';
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  programs.claude-code = {
    enable = true;
    package = null;
    mutableSettings = true;
    accounts.work.home = ".claude-work";
    settings.theme = "dark";
  };
  nmt.script = ''
    set -eu
    set -o pipefail
    for account in .claude .claude-work; do
      account_home="$TMPDIR/hm-user/$account"
      mkdir -p "$account_home/sessions"
      printf '{"theme":"local","localOnly":"%s"}\n' "$account" > "$account_home/settings.json"
      printf '%s\n' "$account" > "$account_home/auth.json"
      touch "$account_home/sessions/keep"
    done
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activate} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"
    for account in .claude .claude-work; do
      account_home="$TMPDIR/hm-user/$account"
      test ! -L "$account_home/settings.json"
      ${lib.getExe pkgs.jaq} --arg account "$account" -e \
        '.theme == "dark" and .localOnly == $account' "$account_home/settings.json"
      test "$(cat "$account_home/auth.json")" = "$account"
      test -f "$account_home/sessions/keep"
    done
  '';
}
