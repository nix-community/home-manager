{ pkgs, ... }:

{
  config = {
    test.stubs.chromium = {
      name = "chromium";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/chromium
        chmod +x $out/bin/chromium
      '';
    };

    programs.webapps = {
      enable = true;
      browser = pkgs.chromium;
      apps.search = {
        # Reserved Exec characters ("?" and "&") plus a percent-encoded
        # sequence ("%20") would fail desktop-file-validate -- and therefore
        # the build -- unless the argument is double-quoted and "%" is doubled.
        # This test gates that escaping.
        url = "https://example.com/search?q=a&b=c%20d";
      };
    };

    nmt.script = ''
      assertFileExists home-path/share/applications/webapp-search.desktop
      # nmt's assertFileRegex uses basic regex (BRE), where "?" is already a
      # literal; the reserved chars sit inside the double-quoted argument and
      # "%" is doubled.
      assertFileRegex home-path/share/applications/webapp-search.desktop \
        'Exec=.*"--app=https://example.com/search?q=a&b=c%%20d"'
    '';
  };
}
