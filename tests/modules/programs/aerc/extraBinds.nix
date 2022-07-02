{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nmt.script = let dir = "home-files/.config/aerc";
    in ''
      assertPathNotExists ${dir}/accounts.conf
      assertFileContent   ${dir}/binds.conf ${./extraBinds.expected}
      assertPathNotExists ${dir}/aerc.conf
      assertPathNotExists ${dir}/stylesets
      assertPathNotExists ${dir}/templates
    '';

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;

      extraBinds = {
        global = {
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "<C-t>" = ":term<Enter>";
        };
        messages = {
          q = ":quit<Enter>";
          j = ":next<Enter>";
        };
        "compose::editor" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-k>" = ":prev-field<Enter>";
        };
      };
    };
  };
}
