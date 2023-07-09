{ pkgs, ... }:

let relToDotDirCustom = ".zshplugins";
in {
  programs.zsh = {
    enable = true;
    dotDir = relToDotDirCustom;
    antidote = {
      enable = true;
      useFriendlyNames = true;
      plugins = [ "zsh-users/zsh-autosuggestions" ];
    };
  };

  test.stubs = {
    antidote = { };
    zsh = { };
  };

  nmt.script = ''
    assertFileContains home-files/${relToDotDirCustom}/.zshrc \
      'source @antidote@/share/antidote/antidote.zsh'
    assertFileContains home-files/${relToDotDirCustom}/.zshrc \
      'antidote load'
    assertFileContains home-files/${relToDotDirCustom}/.zshrc \
      "zstyle ':antidote:bundle' use-friendly-names 'yes'"
  '';
}
