{ config, ... }:
{
  time = "2026-07-31T09:10:14+00:00";
  condition = config.programs.prismlauncher.enable;
  message = ''
    The option `programs.prismlauncher.extraPackages` has been renamed to
    `programs.prismlauncher.themePackages`.

    Please migrate to the new option to suppress the generated warning.
  '';
}
