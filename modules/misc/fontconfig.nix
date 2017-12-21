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

  config = mkMerge [
    (mkIf cfg.enableProfileFonts {
      xdg.configFile."fontconfig/conf.d/10-nix-profile-fonts.conf".text = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          <dir>~/.nix-profile/lib/X11/fonts</dir>
          <dir>~/.nix-profile/share/fonts</dir>
        </fontconfig>
      '';
    })

    # If we are inside a NixOS system configuration then packages are
    # installed through the NixOS `users.users.<name?>.packages`
    # option. Unfortunately fontconfig does not know about the
    # per-user installation directory so we have to add that directory
    # in a extra configuration file.
    (mkIf config.nixosSubmodule {
      xdg.configFile."fontconfig/conf.d/10-nix-per-user-fonts.conf".text = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          <dir>/etc/per-user-pkgs/${config.home.username}/lib/X11/fonts</dir>
          <dir>/etc/per-user-pkgs/${config.home.username}/share/fonts</dir>
        </fontconfig>
      '';
    })
  ];
}
