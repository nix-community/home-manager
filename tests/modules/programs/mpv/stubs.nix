{ lib, pkgs, ... }:

{
  test.stubs = {
    mpv-unwrapped = {
      name = "mpv-unwrapped";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications
        echo "Name=mpv" > $out/share/applications/mpv.desktop

        cp ${pkgs.writeShellScript "mpv" "exit 0"} $out/bin/mpv
        chmod +x $out/bin/mpv
      '';

      extraAttrs = {
        meta =
          let
            stub = "stub";
          in
          {
            description = stub;
            longDescription = stub;
            homepage = stub;
            mainProgram = stub;
            license = [ stub ];
            maintainers = [ stub ];
            teams = [ stub ];
            platforms = lib.platforms.all;
          };
      };
    };

    mpvScript = {
      extraAttrs = {
        scriptName = "mpvScript";
      };
    };
  };
}
