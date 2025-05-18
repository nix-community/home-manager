{ pkgs, ... }:

{
  time = "2022-11-13T09:05:51+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    A new module is available: 'programs.thunderbird'.

    Please note that the Thunderbird packages provided by Nix are
    currently not working on macOS. The module can still be used to manage
    configuration files by installing Thunderbird manually and setting the
    'programs.thunderbird.package' option to a dummy package, for example
    using 'pkgs.runCommand'.

    This module requires you to set the following environment variables
    when using an installation of Thunderbird that is not provided by Nix:

      export MOZ_LEGACY_PROFILES=1
      export MOZ_ALLOW_DOWNGRADE=1
  '';
}
