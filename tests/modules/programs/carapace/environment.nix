{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.carapace = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
    package =
      pkgs.writeShellScriptBin "carapace" ''
        command -v inshellisense >/dev/null
        command -v fish >/dev/null
        printf '%s\n' "$CARAPACE_BRIDGES" "$CARAPACE_DESCRIPTION_LENGTH" "$CARAPACE_HIDDEN" "$CARAPACE_LENIENT" "$CARAPACE_MATCH"
      ''
      // {
        meta.mainProgram = "carapace";
      };
    extraPackages = lib.map (name: pkgs.writeShellScriptBin name "") [
      "inshellisense"
      "fish"
    ];
    environment = {
      CARAPACE_BRIDGES = "inshellisense,fish";
      CARAPACE_DESCRIPTION_LENGTH = 100;
      CARAPACE_HIDDEN = 2;
      CARAPACE_LENIENT = false;
      CARAPACE_MATCH = true;
    };
  };

  nmt.script = ''
    package=${config.programs.carapace.package}
    finalPackage=${config.programs.carapace.finalPackage}
    if [[ "$package" == "$finalPackage" ]]; then
      fail "Expected finalPackage ($finalPackage) to differ from package ($package)"
    fi

    if [[ ${lib.boolToString config.programs.carapace.environment.CARAPACE_MATCH} != true ]]; then
      fail "Expected CARAPACE_MATCH to read back as a Boolean"
    fi

    "$TESTED/home-path/bin/carapace" > "$TMPDIR/environment.actual"
    assertFileContent "$TMPDIR/environment.actual" ${pkgs.writeText "environment.expected" ''
      inshellisense,fish
      100
      2
      0
      1
    ''}
  '';
}
