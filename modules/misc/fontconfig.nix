{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.fonts.fontconfig;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    fonts.fontconfig = {
      enableProfileFonts = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Configure fontconfig to discover fonts installed through
          <varname>home.packages</varname> and
          <command>nix-env</command>.
          </para><para>
          Note, this is only necessary on non-NixOS systems.
        '';
      };
    };
  };

  config = mkIf cfg.enableProfileFonts {
    xdg.configFile."fontconfig/conf.d/10-nix-profile-fonts.conf".text = ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <dir>${config.home.profileDirectory}/lib/X11/fonts</dir>
        <dir>${config.home.profileDirectory}/share/fonts</dir>
      </fontconfig>
    '';
  };
}
