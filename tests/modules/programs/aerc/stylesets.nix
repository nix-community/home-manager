{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertPathNotExists ${dir}/accounts.conf
      assertPathNotExists ${dir}/binds.conf
      assertPathNotExists ${dir}/aerc.conf
      assertFileContent   ${dir}/stylesets/default ${./stylesets.expected}
      assertFileContent   ${dir}/stylesets/asLines ${./stylesets.expected}
      assertPathNotExists ${dir}/templates
    '';

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;
      stylesets = {
        asLines = ''
          *.default = true
          *.selected.reverse = toggle
          *error.bold = true
          error.fg = red
          header.bold = true
          title.reverse = true


        '';
        default = {
          "*.default" = "true";
          "*error.bold" = "true";
          "error.fg" = "red";
          "header.bold" = "true";
          "*.selected.reverse" = "toggle";
          "title.reverse" = "true";
        };
      };
    };
  };
}
