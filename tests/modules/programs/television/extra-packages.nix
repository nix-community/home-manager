{ pkgs, config, ... }:
let
  televisionPackage = config.lib.test.mkStubPackage {
    name = "television";
    buildScript = ''
      mkdir -p "$out/bin"
      touch "$out/bin/tv"
      chmod +x "$out/bin/tv"
    '';
  };
in
{
  programs.television = {
    enable = true;
    package = televisionPackage;
    extraPackages = with pkgs; [
      fd
      bat
      ripgrep
    ];
  };

  test.stubs = {
    fd = {
      name = "fd";
    };
    bat = {
      name = "bat";
    };
    ripgrep = {
      name = "ripgrep";
    };
  };

  nmt = {
    description = "Check if the television binary is correctly wrapped with extraPackages in PATH";
    script = ''
      tvWrapper="$TESTED/home-path/bin/tv"
      assertFileExists "$tvWrapper"
      assertFileRegex "$tvWrapper" "fd"
      assertFileRegex "$tvWrapper" "bat"
      assertFileRegex "$tvWrapper" "ripgrep"
    '';
  };
}
