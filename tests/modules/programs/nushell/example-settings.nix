{ pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    configFile.text = ''
      let $config = {
        filesize_metric: false
        table_mode: rounded
        use_ls_colors: true
      }
    '';

    envFile.text = ''
      $env.FOO = 'BAR'
    '';

    loginFile.text = ''
      # Prints "Hello, World" upon logging into tty1
      if (tty) == "/dev/tty1" {
        echo "Hello, World"
      }
    '';

    shellAliases = {
      "lsname" = "(ls | get name)";
      "ll" = "ls -a";
    };

    environmentVariables = { BAR = "$'(echo BAZ)'"; };
  };

  test.stubs.nushell = { };

  nmt.script = let
    configDir = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell"
    else
      "home-files/.config/nushell";
  in ''
    assertFileContent \
      "${configDir}/config.nu" \
      ${./config-expected.nu}
    assertFileContent \
      "${configDir}/env.nu" \
      ${./env-expected.nu}
    assertFileContent \
      "${configDir}/login.nu" \
      ${./login-expected.nu}
  '';
}
