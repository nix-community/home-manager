{ pkgs, ... }:

{
  programs.go = {
    enable = true;
    telemetry = {
      mode = "on";
      date = "2006-01-02";
    };
  };

  test.stubs = {
    go = { };
    systemd = { };
  };

  nm.script = let
    modeFileDir = if !pkgs.stdenv.isDarwin then
      ".config/go/telemetry"
    else
      "Library/Application Support/go/telemetry";
  in ''
    assertFileExists "home-files/${modeFileDir}/mode"
    assertFileContent \
      "home-files/${modeFileDir}/mode" \
      "on 2006-01-02"
  '';
}
