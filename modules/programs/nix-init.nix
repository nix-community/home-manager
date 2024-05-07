{ config, lib, pkgs, ... }:
let tomlFormat = pkgs.formats.toml { };
in with lib; {
  meta.maintainers = [ maintainers.uncenter ];

  options.programs.nix-init = {
    enable = mkEnableOption
      "nix-init - Generate Nix packages from URLs with hash prefetching, dependency inference, license detection, and more";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          maintainers = [
            "figsoda"
          ];
          nixpkgs = "<nixpkgs>";
          commit = true;
          access-tokens = {
            github.com = "ghp_blahblahblah...";
            gitlab.com = {
              command = [
                "secret-tool"
                "or"
                "whatever"
                "you"
                "use"
              ];
            };
            gitlab.gnome.org = {
              file = "/path/to/api/token";
            };
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/nix-init/config.toml`.

        See <https://github.com/nix-community/nix-init#configuration> for the full list
        of options.
      '';
    };

    package = lib.mkPackageOption pkgs "nix-init" { };
  };

  config = let cfg = config.programs.nix-init;
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."nix-init/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
