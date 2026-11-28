{ config, pkgs, ... }:

{
  programs.jujutsu = {
    enable = true;
    mutableSettings = true;
    package = config.lib.test.mkStubPackage {
      name = "jujutsu";
      version = if pkgs.stdenv.hostPlatform.isDarwin then "0.28.0" else "0.27.0";
    };
    settings.user.name = "Declarative";
  };

  test.asserts.assertions.expected = [
    "programs.jujutsu.mutableSettings requires programs.jujutsu.package version ${
      if pkgs.stdenv.hostPlatform.isDarwin then "0.29.0" else "0.28.0"
    } or later."
  ];
}
