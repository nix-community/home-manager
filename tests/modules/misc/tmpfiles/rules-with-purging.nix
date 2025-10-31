{
  imports = [ ./common-stubs.nix ];

  systemd.user.tmpfiles.settings = {
    cache.rules."%C".d.age = "4 weeks";
    myTool = {
      rules = {
        "%h/.config/myTool.conf"."f+".argument = "my_config";
        "%h/.config/myToolPurged.conf"."f+$".argument = "my_config_purged";
      };
      purgeOnChange = true;
    };
  };

  nmt.script = ''
    cacheRulesFile=home-files/.config/user-tmpfiles.d/home-manager-cache.conf
    assertFileExists $cacheRulesFile
    assertFileRegex $cacheRulesFile "^'d' '%C' '-' '-' '-' '4 weeks' $"

    assertPathNotExists home-files/.config/user-tmpfiles.d/home-manager-myTool.conf
    myToolRulesFile=home-files/.config/user-tmpfiles.d/home-manager-purge-on-change.conf
    assertFileExists $myToolRulesFile
    assertFileRegex $myToolRulesFile \
      "^'f+' '%h/.config/myTool.conf' '-' '-' '-' '-' my_config$"
    assertFileRegex $myToolRulesFile \
      "^'f+$' '%h/.config/myToolPurged.conf' '-' '-' '-' '-' my_config_purged$"
  '';
}
