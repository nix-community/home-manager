{ lib, ... }:
{
  services.xsuspender = {
    enable = true;
    settings = lib.mkDefault {
      Default.suspend_delay = 12;
      Browser = {
        match_wm_class_contains = "browser";
        future_setting = "freeform";
        exec_suspend = null;
        ignored_setting = lib.mkIf false "ignored";
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./settings-only.conf}
  '';
}
