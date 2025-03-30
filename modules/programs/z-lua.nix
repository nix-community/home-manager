{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf types;

  cfg = config.programs.z-lua;

  aliases = {
    zz = "z -c"; # restrict matches to subdirs of $PWD
    zi = "z -i"; # cd with interactive selection
    zf = "z -I"; # use fzf to select in multiple matches
    zb = "z -b"; # quickly cd to the parent directory
    zh = "z -I -t ."; # fzf
  };

in {
  meta.maintainers = [ ];

  options.programs.z-lua = {
    enable = lib.mkEnableOption "z.lua";

    package = lib.mkPackageOption pkgs "z-lua" { };

    options = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "enhanced" "once" "fzf" ];
      description = ''
        List of options to pass to z.lua.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableAliases = lib.mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended z.lua aliases.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/z --init bash ${
        lib.concatStringsSep " " cfg.options
      })"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/z --init zsh ${
        lib.concatStringsSep " " cfg.options
      })"
    '';

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish = lib.mkMerge [
      {
        shellInit = mkIf cfg.enableFishIntegration ''
          source (${cfg.package}/bin/z --init fish ${
            lib.concatStringsSep " " cfg.options
          } | psub)
        '';
      }

      (mkIf (!config.programs.fish.preferAbbrs) {
        shellAliases = mkIf cfg.enableAliases aliases;
      })

      (mkIf config.programs.fish.preferAbbrs {
        shellAbbrs = mkIf cfg.enableAliases aliases;
      })
    ];
  };
}
