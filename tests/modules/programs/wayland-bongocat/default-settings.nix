{ config, pkgs, ... }:
{
  config = {
    programs.wayland-bongocat = {
      package = config.lib.test.mkStubPackage { name = "wayland-bongocat"; };
      enable = true;
    };

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.isDarwin then
            "home-files/Library/Application Support/wayland-bongocat"
          else
            "home-files/.config/wayland-bongocat";
      in
      ''
        assertPathNotExists "${configDir}/settings.conf"
      '';
  };
}
