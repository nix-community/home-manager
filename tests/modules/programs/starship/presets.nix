{ pkgs, ... }:
let
  starshipPackage =
    pkgs.runCommand "starship-test-package"
      {
        passthru.jsonschema = {
          config = ./config-schema.json;
        };
      }
      ''
        mkdir -p "$out/share/starship/presets"
        cat > "$out/share/starship/presets/nerd-font-symbols.toml" <<'EOF'
        format = "$all"
        [directory]
        style = "blue"
        EOF
      '';
in
{
  imports = [ ./starship-stubs.nix ];

  programs.starship = {
    enable = true;
    package = starshipPackage;
    presets = [ "nerd-font-symbols" ];
    settings = {
      add_newline = false;
      scan_timeout = 10;
    };
    validateFiles.config = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/starship.toml
    assertFileContains home-files/.config/starship.toml 'format = "$all"'
    assertFileContains home-files/.config/starship.toml 'style = "blue"'
    assertFileContains home-files/.config/starship.toml "add_newline = false"
    assertFileContains home-files/.config/starship.toml "scan_timeout = 10"
  '';
}
