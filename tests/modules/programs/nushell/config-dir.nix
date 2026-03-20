{ config, ... }:
{
  programs.nushell = {
    enable = true;
    configDir = "${config.xdg.configHome}/nushell-alt-path";
    extraConfig = ''
      # extra config
    '';
    extraEnv = ''
      # extra env
    '';
    extraLogin = ''
      # extra login
    '';
  };

  nmt.script = ''
    assertDirectoryExists home-files/.config/nushell-alt-path

    assertFileExists home-files/.config/nushell-alt-path/config.nu
    assertFileRegex home-files/.config/nushell-alt-path/config.nu '# extra config'

    assertFileExists home-files/.config/nushell-alt-path/env.nu
    assertFileRegex home-files/.config/nushell-alt-path/env.nu "# extra env"

    assertFileExists home-files/.config/nushell-alt-path/login.nu
    assertFileRegex home-files/.config/nushell-alt-path/login.nu '# extra login'

  '';
}
