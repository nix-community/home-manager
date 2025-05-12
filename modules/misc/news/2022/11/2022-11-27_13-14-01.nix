{ config, ... }:

{
  time = "2022-11-27T13:14:01+00:00";
  condition = config.programs.ssh.enable;
  message = ''

    'programs.ssh.matchBlocks.*' now supports literal 'Match' blocks via
    'programs.ssh.matchBlocks.*.match' option as an alternative to plain
    'Host' blocks
  '';
}
