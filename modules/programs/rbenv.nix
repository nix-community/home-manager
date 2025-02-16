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
  meta.maintainers = [ ];

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
        rbenv plugins to install in {file}`$HOME/.rbenv/plugins/`.

        See <https://github.com/rbenv/rbenv/wiki/Plugins>
        for the full list of plugins.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
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
