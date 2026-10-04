{ config, pkgs, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.algia = {
    enable = true;
    mutableSettings = false;
  };
  assertions = [
    {
      assertion = !(config.home.activation ? algiaMutableSettings);
      message = "Inactive algia settings must not create mutable activation.";
    }
    {
      assertion = !(config.home.activation ? algiaImmutableSettings);
      message = "Inactive algia settings must not create immutable cleanup.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/${
      if pkgs.stdenv.hostPlatform.isDarwin then ".config" else "custom-config"
    }/algia/config.json"
  '';
}
