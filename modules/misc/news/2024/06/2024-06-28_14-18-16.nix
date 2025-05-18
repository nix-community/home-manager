{ pkgs, ... }:

{
  time = "2024-06-28T14:18:16+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.glance'.

    Glance is a self-hosted dashboard that puts all your feeds in
    one place. See https://github.com/glanceapp/glance for more.
  '';
}
