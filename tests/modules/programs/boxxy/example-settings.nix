{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.boxxy.enable = true;
    programs.boxxy.rules = [{
      name = "example rule";
      target = "~/Arduino";
      rewrite = "~/.local/share/boxxy";
      mode = "directory";
      only = [ "arduino" "Arduino" ];
      env = { "ENVIRONMENT_THING" = "some value"; };
      context = [ "/home/test_user/your_project_repo" ];
    }];

    test.stubs.boxxy = { };

    nmt.script = ''
      boxxyyaml=home-files/.config/boxxy/boxxy.yaml
      assertFileExists $boxxyyaml
      assertFileContent $boxxyyaml ${./example-boxxy.yaml}
    '';
  };
}
