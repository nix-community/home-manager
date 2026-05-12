{ pkgs, ... }:

{
  programs.uv = {
    enable = true;
    settings = {
      python-downloads = "never";
      python-preference = "only-system";
      pip.index-url = "https://test.pypi.org/simple";
    };
  };

  test.stubs.uv = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/uv/uv.toml";
      expectedConfigContent = pkgs.writeText "uv.config-custom.expected" ''
        python-downloads = "never"
        python-preference = "only-system"

        [pip]
        index-url = "https://test.pypi.org/simple"
      '';
    in
    ''
      assertFileExists "${expectedConfigPath}"
      assertFileContent "${expectedConfigPath}" "${expectedConfigContent}"
    '';
}
