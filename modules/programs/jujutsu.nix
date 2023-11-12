{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.jujutsu;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.shikanime ];

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

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Bash integration.";
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Zsh integration.";
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Fish integration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".jjconfig.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "jujutsu-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      source <(${pkgs.jujutsu}/bin/jj util completion)
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      source <(${pkgs.jujutsu}/bin/jj util completion --zsh)
      compdef _jj ${pkgs.jujutsu}/bin/jj
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      ${pkgs.jujutsu}/bin/jj util completion --fish | source
    '';
  };
}
