{ pkgs, ... }:

{
  time = "2024-06-22T05:49:48+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.blanket'.

    Blanket is a program you can use to improve your focus and increase
    your productivity by listening to different sounds. See
    https://github.com/rafaelmardojai/blanket for more.
  '';
}
