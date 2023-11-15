{ ... }:

{
  programs = {
    nushell.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  test.stubs = {
    oh-my-posh = { };
    nushell = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/nushell/env.nu
    assertFileRegex \
      home-files/.config/nushell/env.nu \
      '/bin/oh-my-posh init nu --config .*--print \| save --force /.*/home-files/\.cache/oh-my-posh/init\.nu'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileRegex \
      home-files/.config/nushell/config.nu \
      'source /.*/\.cache/oh-my-posh/init\.nu'
  '';
}
