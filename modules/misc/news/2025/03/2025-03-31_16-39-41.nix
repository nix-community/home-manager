{ config, ... }:

{
  time = "2025-03-31T16:39:41+00:00";
  condition = config.programs.jq.enable;
  message = ''
    Jq module now supports color for object keys

    Your configuration will break if you have defined the "programs.jq.colors" option.
    To resolve this, please add `objectKeys` to your assignment of `programs.jq.colors`.
  '';
}
