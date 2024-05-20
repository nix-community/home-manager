{ pkgs, ... }:

{
  programs.qutebrowser = {
    enable = true;

    domainSettings = {
      "https://teams.microsoft.com".content.notifications.enabled = true;
      "https://www.netflix.com".content.notifications.enabled = false;
      "https://www.facebook.com".content.notifications.enabled = false;
      "https://mail.google.com".content.register_protocol_handler = true;
    };
  };

  test.stubs.qutebrowser = { };

  nmt.script = let
    qutebrowserConfig = if pkgs.stdenv.hostPlatform.isDarwin then
      ".qutebrowser/config.py"
    else
      ".config/qutebrowser/config.py";
  in ''
    assertFileContent \
      home-files/${qutebrowserConfig} \
      ${
        pkgs.writeText "qutebrowser-expected-config.py" ''
          config.load_autoconfig(False)
          config.set("content.register_protocol_handler", True, "https://mail.google.com")
          config.set("content.notifications.enabled", True, "https://teams.microsoft.com")
          config.set("content.notifications.enabled", False, "https://www.facebook.com")
          config.set("content.notifications.enabled", False, "https://www.netflix.com")''
      }
  '';
}
