{ config, lib, pkgs, ... }:

with lib;

let
  conf = builtins.toFile "config" ''
    [Auth]
    Password=password
    Username=username

    [General]
    Binary=calcurse
    Hostname=example.com
  '';
in {
  config = {
    programs.calcurse = {
      enable = true;
      caldav.settings = {
        General = {
          Binary = "calcurse";
          Hostname = "example.com";
        };
        Auth = {
          Username = "username";
          Password = "password";
        };
      };
    };

    test.stubs.calcurse = { };

    nmt.script = ''
      assertFileExists home-files/.config/calcurse/caldav/config
      assertFileContent home-files/.config/calcurse/caldav/config ${conf}
    '';
  };
}
