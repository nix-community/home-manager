{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.jujutsu;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.shikanime ];

  imports = let
    mkRemovedShellIntegration = name:
      mkRemovedOptionModule [ "programs" "jujutsu" "enable${name}Integration" ]
      "This option is no longer necessary.";
  in map mkRemovedShellIntegration [ "Bash" "Fish" "Zsh" ];

  options.programs.jujutsu = {
    enable =
      mkEnableOption "a Git-compatible DVCS that is both simple and powerful";

    package = mkPackageOption pkgs "jujutsu" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          user = {
            name = "John Doe";
            email = "jdoe@example.org";
          };
        }
      '';
      description = ''
        Options to add to the {file}`.jjconfig.toml` file. See
        <https://github.com/martinvonz/jj/blob/main/docs/config.md>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".jjconfig.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "jujutsu-config" cfg.settings;
    };
  };
}
