{ config, lib, pkgs, ... }:

{
  config = {
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        custom = "plz-fail";
        customPkgs = [ pkgs.zshPlugin ];
      };
    };

    test.stubs.zshPlugin = { };

    test.asserts.assertions.expected = [
      "The options `programs.zsh.oh-my-zsh.custom' and `programs.zsh.oh-my-zsh.customPkgs' are mutually exclusive."
    ];
  };
}
