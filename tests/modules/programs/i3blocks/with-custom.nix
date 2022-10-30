{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.i3blocks = {
      enable = true;
      globalVars = {
        a = "foo";
        zz = "bar";
      };
      blocks = {
        time = {
          command = "date '+%d.%m.%4Y %T'";
          interval = 2;
          value1 = 2.5;
        };
        asdf = { command = "fdsa"; };
      };
    };

    test.stubs.i3blocks = { };

    nmt.script = ''
      assertFileExists home-files/.config/i3blocks/config
      assertFileContent home-files/.config/i3blocks/config \
        ${
          pkgs.writeText "i3blocks-expected-config" ''
            a=foo
            zz=bar
            [asdf]
            command=fdsa
            [time]
            command=date '+%d.%m.%4Y %T'
            interval=2
            value1=2.500000''
        }'';
  };
}
