{ config, ... }:
{
  time = "2024-06-26T07:07:17+00:00";
  condition = config.programs.yazi.enable;
  message = ''
    Yazi's shell integration wrappers have been renamed from 'ya' to 'yy'.

    A new option `programs.yazi.shellWrapperName` is also available that
    allows you to override this name.
  '';
}
