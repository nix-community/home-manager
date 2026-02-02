{ config, ... }:
{
  programs = {
    fish.enable = true;
    password-store = {
      enable = true;
      package = config.lib.test.mkStubPackage {
        outPath = "@pass@";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      "source @pass@/share/fish/vendor_completions.d/pass.fish"
  '';
}
