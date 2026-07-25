{
  flake-edit-basic-settings =
    { pkgs, ... }:
    let
      configFile = "home-files/.config/flake-edit/config.toml";
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
        assertFileExists ${configFile}
        assertFileContent ${configFile} \
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
