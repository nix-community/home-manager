{ lib, pkgs, ... }:

{
  programs.radio-active = {
    enable = true;
    package =
      (builtins.derivation {
        name = "radio-active-raw";
        system = pkgs.stdenv.hostPlatform.system;
        builder = "${pkgs.runtimeShell}";
        args = [
          "-c"
          ''
            ${pkgs.coreutils}/bin/mkdir -p "$out/bin"
            ${pkgs.coreutils}/bin/touch "$out/bin/radio-active-raw"
            ${pkgs.coreutils}/bin/chmod +x "$out/bin/radio-active-raw"
          ''
        ];
      })
      // {
        meta.mainProgram = "radio-active-raw";
      };
    settings.AppConfig.player = "mpv";
  };

  nmt.script = ''
    assertFileExists home-path/bin/radio-active-raw
    assertFileContains home-path/bin/radio-active-raw \
      ${lib.escapeShellArg (lib.makeBinPath [ pkgs.mpv ])}
  '';
}
