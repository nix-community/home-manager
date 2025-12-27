{
  pkgs,
  config,
  ...
}:

{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    package = pkgs.stdenv.mkDerivation {
      pname = "fake-vicinae";
      version = "0.10.0";
      src = pkgs.emptyFile;
      buildCommand = "mkdir -p $out";
      meta = {
        mainProgram = "vicinae";
      };
    };

    settings = {
      faviconService = "twenty";
      font = {
        size = 10;
      };
      popToRootOnClose = false;
      rootSearch = {
        searchFiles = false;
      };
      theme = {
        name = "vicinae-dark";
      };
      window = {
        csd = true;
        opacity = 0.95;
        rounding = 10;
      };
    };
  };

  nmt.script = ''
    assertFileExists      "home-files/.config/vicinae/vicinae.json"
    assertFileExists      "home-files/.config/systemd/user/vicinae.service"
    assertFileContains     "home-files/.config/systemd/user/vicinae.service"  "EnvironmentFile"
  '';
}
