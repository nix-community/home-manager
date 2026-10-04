{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.andcli = {
    enable = true;
    package = null;
    settings = {
      options = {
        show_usernames = false;
        show_tokens = true;
      };
    };
  };

  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = !config.programs.andcli.mutableSettings;
      message = "andcli settings must default to immutable settings.";
    }
    {
      assertion = !(config.home.activation ? andcliMutableSettings);
      message = "andcli settings must not create mutable activation.";
    }
  ];

  nmt.script =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/andcli"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/andcli";
    in
    ''
      assertFileContent "home-files/${configPath}/config.yaml" \
        ${./config.yaml}
    '';
}
