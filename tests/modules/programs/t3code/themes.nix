{
  config,
  lib,
  pkgs,
  ...
}:
let
  nightfall = {
    name = "Nightfall";
    appearance = "dark";
    canvas = "#1a1b26";
    accent = "#7aa2f7";
  };
  expected = (pkgs.formats.json { }).generate "t3code-theme-nightfall" nightfall;
  fromFile = pkgs.writeText "from-file.json" ''
    {"name":"From file","appearance":"light","canvas":"#fff","accent":"#000"}
  '';
  themesDir = ".t3/userdata/themes";
  activation = pkgs.writeScript "t3code-themes-activation" config.home.activation.t3codeThemes.data;
in
{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userSettings.defaultTheme = "nightfall";
    themes = {
      inherit nightfall;
      from-file = fromFile;
      source-path = ./source-path-theme.json;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    assert config.home.activation.t3codeThemes.after == [ "writeBoundary" ];
    ''
      themes="$TMPDIR/hm-user/${themesDir}"
      mkdir -p "$themes"
      ln -s ${fromFile} "$themes/nightfall.json"
      printf 'leave me alone\n' > "$themes/unmanaged.json"

      substitute ${activation} "$TMPDIR/run-themes" --subst-var TMPDIR
      chmod +x "$TMPDIR/run-themes"
      "$TMPDIR/run-themes"

      assertFileContent "$themes/nightfall.json" ${expected}
      assertFileContent "$themes/from-file.json" ${fromFile}
      assertFileContent "$themes/source-path.json" ${./source-path-theme.json}
      test ! -L "$themes/nightfall.json" || fail "theme must be a regular file"
      test "$(cat "$themes/unmanaged.json")" = "leave me alone" || fail "unmanaged file changed"

      inode=$(stat -c %i "$themes/nightfall.json")
      "$TMPDIR/run-themes"
      test "$(stat -c %i "$themes/nightfall.json")" = "$inode" || fail "unchanged theme rewritten"
    '';
}
