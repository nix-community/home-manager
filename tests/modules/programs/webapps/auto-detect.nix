{
  config,
  pkgs,
  ...
}:

{
  config = {
    test.stubs.brave = {
      name = "brave";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/brave
        chmod +x $out/bin/brave
      '';
    };

    # Enable brave browser program to test auto-detection
    programs.brave = {
      enable = true;
      package = pkgs.brave;
    };

    programs.webApps = {
      enable = true;
      # browser = null; (let it auto-detect from brave)

      apps = {
        discord = {
          url = "https://discord.com/channels/@me";
          name = "Discord";
        };
      };
    };

    nmt.script = ''
      # Check that the desktop entry was created
      assertFileExists home-path/share/applications/webapp-discord.desktop

      # Check that it detected brave and used --app mode
      assertFileRegex home-path/share/applications/webapp-discord.desktop \
        'Exec=.*brave.*--app=https://discord.com/channels/@me'

      # Check StartupWMClass uses brave
      assertFileRegex home-path/share/applications/webapp-discord.desktop \
        'StartupWMClass=brave-webapp-discord'
    '';
  };
}
