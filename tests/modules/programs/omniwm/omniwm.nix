{ config, pkgs, ... }:
let
  hmPkgs = pkgs.extend (
    _self: _super: {
      omniwm = config.lib.test.mkStubPackage {
        name = "omniwm";
        buildScript = ''
          mkdir -p $out/Applications/OmniWM.app/Contents/MacOS
          touch $out/Applications/OmniWM.app/Contents/MacOS/OmniWM
          chmod 755 $out/Applications/OmniWM.app/Contents/MacOS/OmniWM
        '';
      };
    }
  );
in
{
  programs.omniwm = {
    enable = true;
    package = hmPkgs.omniwm;
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/omniwm/settings.toml"

    serviceFile=$(normalizeStorePaths LaunchAgents/org.nix-community.home.omniwm.plist)
    assertFileExists $serviceFile
    assertFileContent "$serviceFile" ${./omniwm-service-expected.plist}
  '';
}
