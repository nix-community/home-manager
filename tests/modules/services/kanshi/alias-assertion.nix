{ config, pkgs, ... }: {
  config = {
    services.kanshi = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = [{
        profile.name = "nomad";
        profile.outputs = [{
          criteria = "eDP-1";
          alias = "test";
        }];
      }];
    };

    test.asserts.assertions.expected =
      [ "Output kanshi.*.output.alias can only be defined on global scope" ];
  };
}
