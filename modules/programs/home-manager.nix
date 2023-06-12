{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.home-manager;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.home-manager = {
      enable = mkEnableOption "Home Manager";

      paths = mkOption {
        type = types.listOf types.str;
        default = [
          "\${XDG_CONFIG_HOME:-$HOME/.config}/nixpkgs/home-manager"
          "$HOME/.nixpkgs/home-manager"
        ];
        example = [ "$HOME/devel/home-manager" ];
        description = ''
          The default path to use for Home Manager. When
          <literal>null</literal>, then the <filename>home-manager</filename>
          channel, <filename>$HOME/.config/nixpkgs/home-manager</filename>, and
          <filename>$HOME/.nixpkgs/home-manager</filename> will be attempted.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && !config.submoduleSupport.enable) {
    home.packages =
      [ (pkgs.callPackage ../../home-manager { inherit (cfg) paths; }) ];
  };
}
