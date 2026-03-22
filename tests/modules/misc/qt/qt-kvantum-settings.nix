{ pkgs, ... }:

{
  qt = {
    enable = true;
    kvantum = {
      settings = {
        general = {
          theme = "KvAdapta";
          hello = "world";
        };
        applications = {
          KvArc = [
            "app1"
            "app2"
          ];
          KvFlat = [ "app3" ];
        };
        somethingElse = {
          foo = "bar";
          baz = [
            "qux"
            123
            true
            null
          ];
        };
      };
    };
  };

  nmt.script =
    let
      configPath = "home-files/.config/Kvantum/kvantum.kvconfig";

      expectedContent = pkgs.writeText "expected.kvconfig" ''
        [Applications]
        KvArc=app1, app2
        KvFlat=app3

        [General]
        hello=world
        theme=KvAdapta

        [SomethingElse]
        baz=qux, 123, true, null
        foo=bar
      '';
    in
    ''
      assertFileExists "${configPath}"
      assertFileContent "${configPath}" "${expectedContent}"
    '';
}
