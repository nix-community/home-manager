{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.rbenv;

  pluginModule = types.submodule {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.
        '';
      };
      name = mkOption {
        type = types.str;
        description = ''
          Name of the plugin.
        '';
      };
    };
  };

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.rbenv = {
    enable = mkEnableOption "rbenv";

    package = mkPackageOption pkgs "rbenv" { };

    plugins = mkOption {
      type = types.listOf pluginModule;
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "ruby-build";
            src = pkgs.fetchFromGitHub {
              owner = "rbenv";
              repo = "ruby-build";
              rev = "v20221225";
              hash = "sha256-Kuq0Z1kh2mvq7rHEgwVG9XwzR5ZUtU/h8SQ7W4/mBU0=";
            };
          }
        ]
      '';
      description = ''
        rbenv plugins to install in <filename>$HOME/.rbenv/plugins/</filename>.
        </para><para>
        See <link xlink:href="https://github.com/rbenv/rbenv/wiki/Plugins" />
        for the full list of plugins.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".rbenv/plugins" = mkIf (cfg.plugins != [ ]) {
      source = pkgs.linkFarm "rbenv-plugins" (builtins.map (p: {
        name = p.name;
        path = p.src;
      }) cfg.plugins);
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/rbenv init - bash)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/rbenv init - zsh)"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/rbenv init - fish | source
    '';
  };
}
