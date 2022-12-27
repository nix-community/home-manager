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
      let-env FOO = 'BAR'
    '';

    shellAliases = {
      "lsname" = "(ls | get name)";
      "ll" = "ls -a";
    };
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
  '';
}
