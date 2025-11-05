{
  imports = [ ./common-stubs.nix ];

  systemd.user.tmpfiles.settings = {
    cache."%C".d.age = "4 weeks";
    myTool."%h/.config/myTool.conf"."f+" = {
      mode = "0644";
      user = "alice";
      group = "users";
      argument = "my unescaped config";
    };
  };

  nmt.script = ''
    cacheRulesFile=home-files/.config/user-tmpfiles.d/home-manager-cache.conf
    assertFileExists $cacheRulesFile
    assertFileRegex $cacheRulesFile "^'d' '%C' '-' '-' '-' '4 weeks' $"

    myToolRulesFile=home-files/.config/user-tmpfiles.d/home-manager-myTool.conf
    assertFileExists $myToolRulesFile
    assertFileRegex $myToolRulesFile \
      "^'f+' '%h/.config/myTool.conf' '0644' 'alice' 'users' '-' my\\\\x20unescaped\\\\x20config$"
  '';
}
