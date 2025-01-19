{ pkgs, config, lib, ... }:

{
  programs.nushell = {
    enable = true;

    configFile.text = ''
      let config = {
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

    plugins = [ pkgs.nushellPlugins.formats ];

    shellAliases = {
      "ll" = "ls -a";
      "multi word alias" = "cd -";
      "z" = "__zoxide_z";
    };

    settings = {
      show_banner = false;
      display_errors.exit_code = false;
      hooks.pre_execution =
        [ (lib.hm.nushell.mkNushellInline ''{|| "pre_execution hook"}'') ];
    };

    environmentVariables = {
      FOO = "BAR";
      LIST_VALUE = [ "foo" "bar" ];
      PROMPT_COMMAND = lib.hm.nushell.mkNushellInline ''{|| "> "}'';
      ENV_CONVERSIONS.PATH = {
        from_string =
          lib.hm.nushell.mkNushellInline "{|s| $s | split row (char esep) }";
        to_string =
          lib.hm.nushell.mkNushellInline "{|v| $v | str join (char esep) }";
      };
    };
  };

  nmt.script = let
    configDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
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
    assertFileExists \
      "${configDir}/plugin.msgpackz"
  '';
}
