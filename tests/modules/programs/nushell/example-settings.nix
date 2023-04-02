{ pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;

    settings = {
      filesize.metric = false;
      table.mode = "rounded";
      ls.colors = true;
      completions.external = {
        enable = true;
        max_results = 100;
        completer.__nu = ''
          {|spans|
            carapace $spans.0 nushell $spans | from json
          }
        '';
      };
    };

    configFile.text = ''
      source $HOME/file_a.nu
    '';

    extraConfig = ''
      source $HOME/file_b.nu
    '';

    envFile.text = ''
      let-env FOO = 'BAR'
    '';
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
