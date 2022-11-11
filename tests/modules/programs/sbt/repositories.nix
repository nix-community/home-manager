{ pkgs, ... }:

let
  repositories = [
    "local"
    { my-maven-proxy = "http://repo.mavenproxy.io/a/b/c/d"; }
    "maven-local"
    {
      my-ivy-proxy =
        "http://repo.company.com/ivy-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]";
    }
    "maven-central"
  ];

  expectedRepositories = builtins.toFile "repositories" ''
    [repositories]
    local
    my-maven-proxy: http://repo.mavenproxy.io/a/b/c/d
    maven-local
    my-ivy-proxy: http://repo.company.com/ivy-releases/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]
    maven-central
  '';

  repositoriesSbtPath = ".sbt/repositories";
in {
  config = {
    programs.sbt = {
      enable = true;
      repositories = repositories;
      package = pkgs.writeScriptBin "sbt" "";
    };

    nmt.script = ''
      assertFileExists "home-files/${repositoriesSbtPath}"
      assertFileContent "home-files/${repositoriesSbtPath}" "${expectedRepositories}"
    '';
  };
}
