{ config, lib, pkgs, ... }:

with lib;

let
  expectedConfig = pkgs.writeText "i3blocks-expected-config" ''
    [block1first]
    command=echo first
    interval=1

    [block3second]
    command=echo second
    interval=2

    [block2third]
    command=echo third
    interval=3
  '';
in {
  config = {
    programs.i3blocks = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      bars = with lib; {
        bar1 = {
          block1first = {
            command = "echo first";
            interval = 1;
          };
          block2third = hm.dag.entryAfter [ "block3second" ] {
            command = "echo third";
            interval = 3;
          };
          block3second = hm.dag.entryAfter [ "block1first" ] {
            command = "echo second";
            interval = 2;
          };
        };
        bar2 = {
          block1first = {
            command = "echo first";
            interval = 1;
          };
          block2third = hm.dag.entryAfter [ "block3second" ] {
            command = "echo third";
            interval = 3;
          };
          block3second = hm.dag.entryAfter [ "block1first" ] {
            command = "echo second";
            interval = 2;
          };
        };
      };
    };

    test.stubs.i3blocks = { };

    nmt.script = ''
      assertFileExists home-files/.config/i3blocks/bar1
      assertFileExists home-files/.config/i3blocks/bar2
      assertFileContent home-files/.config/i3blocks/bar1 ${expectedConfig}
      assertFileContent home-files/.config/i3blocks/bar2 ${expectedConfig}
    '';
  };
}
