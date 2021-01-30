{ config, lib, pkgs, ... }:

with lib;

let
  dependencyGraph = {
    org = "net.virtual-void";
    artifact = "sbt-dependency-graph";
    version = "0.10.0-RC1";
  };
  projectGraph = {
    org = "com.dwijnand";
    artifact = "sbt-project-graph";
    version = "0.4.0";
  };

  plugins = [ dependencyGraph projectGraph ];

  pluginsSbtPath = ".sbt/1.0/plugins/plugins.sbt";

  expectedPluginsSbt = pkgs.writeText "plugins.sbt" ''
    addSbtPlugin("net.virtual-void" % "sbt-dependency-graph" % "0.10.0-RC1")
    addSbtPlugin("com.dwijnand" % "sbt-project-graph" % "0.4.0")
  '';

in {
  config = {
    programs.sbt = {
      enable = true;
      plugins = plugins;
      package = pkgs.writeScriptBin "sbt" "";
    };

    nmt.script = ''
      assertFileExists "home-files/${pluginsSbtPath}"
      assertFileContent "home-files/${pluginsSbtPath}" "${expectedPluginsSbt}"
    '';
  };
}
