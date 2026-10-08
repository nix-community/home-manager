{
  pkgs,
  ...
}:
{
  home.enableNixpkgsReleaseCheck = false;
  programs.wallust = {
    enable = true;
    backend = "full";
    settings = {
      backend = "fastresize";
      color_space = "lchmixed";
    };
  };

  nmt.script =
    let
      path =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/wallust/wallust.toml"
        else
          "home-files/.config/wallust/wallust.toml";
    in
    ''
      assertFileExists '${path}'
      assertFileContent '${path}' ${./expected.toml}
    '';
}
