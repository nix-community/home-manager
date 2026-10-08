{
  flake-edit-basic-settings =
    {
      lib,
      pkgs,
      ...
    }:
    let
      configDir = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
      configFile = "home-files/${configDir}/flake-edit/config.toml";
    in
    {
      programs.flake-edit = {
        enable = true;
        settings = {
          follow = {
            ignore = [
              "systems"
              "crane.flake-utils"
            ];
            transitive_min = 2;
            aliases = {
              nixpkgs = [ "nixpkgs-lib" ];
            };
            max_depth = 1;
          };
        };
      };

      nmt.script = ''
        assertFileExists ${lib.escapeShellArg configFile}
        assertFileContent ${lib.escapeShellArg configFile} \
          ${pkgs.writeText "flake-edit-expected.toml" ''
            [follow]
            ignore = ["systems", "crane.flake-utils"]
            max_depth = 1
            transitive_min = 2

            [follow.aliases]
            nixpkgs = ["nixpkgs-lib"]
          ''}
      '';
    };
}
