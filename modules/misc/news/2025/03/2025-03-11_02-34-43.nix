{ config, ... }:

{
  time = "2025-03-11T02:34:43+00:00";
  condition = config.programs.zsh.enable;
  message = ''
    A new module is available: 'programs.zsh.initContent'.

    initContent option allows you to set the content of the zshrc file,
    you can use `lib.mkOrder` to specify the order of the content you want to insert.
  '';
}
