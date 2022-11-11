{ config, lib, pkgs, ... }:

with lib;

let
  plugins = [{
    org = "a";
    artifact = "b";
    version = "c";
  }];

  credentials = [{
    realm = "a";
    host = "b";
    user = "c";
    passwordCommand = "d";
  }];

  repositories = [ "local" ];

  baseSbtPath = ".config/sbt";
in {
  config = {
    programs.sbt = {
      enable = true;
      plugins = plugins;
      credentials = credentials;
      repositories = repositories;
      baseUserConfigPath = ".config/sbt";
      package = pkgs.writeScriptBin "sbt" "";
    };

    nmt.script = ''
      assertFileExists "home-files/${baseSbtPath}/1.0/plugins/plugins.sbt"
      assertFileExists "home-files/${baseSbtPath}/1.0/credentials.sbt"
      assertFileExists "home-files/${baseSbtPath}/repositories"
    '';
  };
}
