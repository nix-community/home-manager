{ ... }:

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
  };

  test.stubs.nushell = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/nushell/config.nu \
      ${./config-expected.nu}
    assertFileContent \
      home-files/.config/nushell/env.nu \
      ${./env-expected.nu}
  '';
}
