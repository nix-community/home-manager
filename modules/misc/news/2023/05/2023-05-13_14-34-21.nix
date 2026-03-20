{ config, ... }:

{
  time = "2023-05-13T14:34:21+00:00";
  condition = config.programs.ssh.enable;
  message = ''

    The module 'programs.ssh' can now install an SSH client. The installed
    client is controlled by the 'programs.ssh.package` option, which
    defaults to 'null'.
  '';
}
