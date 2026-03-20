{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.andcli = {
    enable = true;
    settings = {
      options = {
        show_usernames = false;
        show_tokens = true;
      };
    };
  };

  nmt.script =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/andcli"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/andcli";
    in
    ''
      assertFileExists "home-files/${configPath}/config.yaml"
      assertFileContent "home-files/${configPath}/config.yaml" \
        ${./config.yaml}
    '';
}
