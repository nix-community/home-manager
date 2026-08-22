{ lib, pkgs, ... }:
{
  config = {
    targets.darwin.defaults."com.apple.dock" = {
      persistent-apps = [
        {
          app = "${lib.getExe pkgs.discord}";
        }
      ];
      persistent-others = [
        {
          folder.path = "Desktop";
        }
      ];
    };

    nmt.script = ''
      assertFileRegex activate \
        "/usr/bin/defaults  import com.apple.dock /nix/store/[a-z0-9]\\{32\\}-com\\.apple\\.dock\\.plist"
    '';
  };
}
