{ pkgs, lib, ... }:
let
  fakeSecret = pkgs.writeText "fake-npm-token" "supersecret";
  wrapper = lib.hm.mcp.mkEnvFilesWrapper {
    inherit pkgs;
    name = "test-server";
    server = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything"
      ];
      envFiles.NPM_TOKEN = "${fakeSecret}";
    };
  };
in
{
  home.file."mcp-wrapper-under-test" = {
    source = wrapper;
  };

  nmt.script = ''
    assertFileContains home-files/mcp-wrapper-under-test \
      'if NPM_TOKEN=$(cat ${fakeSecret}); then'
    assertFileContains home-files/mcp-wrapper-under-test \
      'export NPM_TOKEN'
    assertFileContains home-files/mcp-wrapper-under-test \
      'exec npx -y @modelcontextprotocol/server-everything'
  '';
}
