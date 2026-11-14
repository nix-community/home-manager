{
  config,
  lib,
  pkgs,
  ...
}:

let
  nightfallTheme = {
    name = "Nightfall";
    appearance = "dark";
    canvas = "#1a1b26";
    accent = "#7aa2f7";
    colors.terminalSelection = "#292e42";
  };

  expectedNightfall = pkgs.writeText "expected-nightfall.json" ''
    {
      "accent": "#7aa2f7",
      "appearance": "dark",
      "canvas": "#1a1b26",
      "colors": {
        "terminalSelection": "#292e42"
      },
      "name": "Nightfall"
    }
  '';

  fromFileTheme = pkgs.writeText "from-file-theme.json" ''
    {
      "name": "From file",
      "appearance": "light",
      "canvas": "#ffffff",
      "accent": "#000000"
    }
  '';

  preexistingSymlinkTarget = pkgs.writeText "preexisting-symlink-target.json" ''
    {
      "name": "Old",
      "appearance": "dark",
      "canvas": "#000000",
      "accent": "#ffffff"
    }
  '';

  unrelatedFile = pkgs.writeText "unrelated.json" "unrelated\n";

  jsonFormat = pkgs.formats.json { };

  # The default theme token is derived from the generated theme file, so it
  # changes when the theme content changes.
  nightfallToken = builtins.hashString "sha256" "nightfall:${toString (jsonFormat.generate "t3code-theme-nightfall" nightfallTheme)}";
in
{
  programs.t3code = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    defaultTheme = "nightfall";
    themes = {
      nightfall = nightfallTheme;
      from-file = fromFileTheme;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      activation = pkgs.writeScript "themes-activation" config.home.activation.t3codeThemes.data;
      themesPath = ".t3/userdata/themes";
    in
    assert config.home.activation.t3codeThemes.after == [ "writeBoundary" ];
    assert config.programs.t3code.userSettings.defaultTheme == "nightfall";
    assert config.programs.t3code.userSettings.defaultThemeSetAt == nightfallToken;
    ''
      assertFileExists ${activation}

      export HOME=$TMPDIR/hm-user
      mkdir -p "$HOME/${themesPath}"

      # A symlink left by an older configuration must be replaced, not followed.
      ln -s ${preexistingSymlinkTarget} "$HOME/${themesPath}/nightfall.json"
      cp ${unrelatedFile} "$HOME/${themesPath}/unrelated.json"

      substitute ${activation} $TMPDIR/themes-activate --subst-var TMPDIR
      chmod +x $TMPDIR/themes-activate
      $TMPDIR/themes-activate

      assertFileContent "$HOME/${themesPath}/nightfall.json" ${expectedNightfall}
      if [[ -L "$HOME/${themesPath}/nightfall.json" ]]; then
        fail "nightfall.json must be a regular file, not a symlink"
      fi
      assertFileContent "$HOME/${themesPath}/from-file.json" ${fromFileTheme}
      assertFileContent "$HOME/${themesPath}/unrelated.json" ${unrelatedFile}

      # The activation is idempotent and does not rewrite an unchanged file.
      $TMPDIR/themes-activate
      assertFileContent "$HOME/${themesPath}/nightfall.json" ${expectedNightfall}
    '';
}
