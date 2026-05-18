{
  lib,
  options,
  pkgs,
  ...
}:

let
  mockZshPluginSrc = pkgs.runCommand "mock-zsh-plugin-src" { } ''
    mkdir -p "$out/share/mockPlugin" "$out/share/zsh/site-functions"
    touch "$out/share/mockPlugin/mockPlugin.plugin.zsh"
  '';
in
{
  programs.zsh = {
    enable = true;
    plugins = [
      {
        name = "mockPlugin";
        file = "share/mockPlugin/mockPlugin.plugin.zsh";
        src = mockZshPluginSrc;
        completions = [ "share/zsh/site-functions" ];
      }
    ];
  };

  test.stubs.zsh = { };

  test.asserts.warnings.expected = [
    "The option `programs.zsh.plugins.*.completions' defined in ${lib.showFiles options.programs.zsh.plugins.files} has been renamed to `programs.zsh.plugins.*.functions'."
  ];

  nmt.script = ''
    assertFileContains home-files/.zshrc 'mockPlugin/share/zsh/site-functions'
  '';
}
