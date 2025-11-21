{ config, ... }:
{
  programs.foot = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      "regex:one" = {
        regex = "(some regex)";
        launch = "echo Regex one works";
      };
      "regex:two" = {
        regex = "(some other regex)";
        launch = "echo Second also works!";
      };

      key-bindings.regex-launch = [
        "[one] Shift+Control+1"
        "[two] Shift+Control+2"
      ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/foot/foot.ini \
      ${./regex-modes-expected.ini}
  '';
}
