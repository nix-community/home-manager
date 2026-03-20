{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.airlift;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.airlift = {
    enable = mkEnableOption "airlift";
    package = mkPackageOption pkgs "airlift" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        dag_path = "/path/to/dags";
        plugin_path = "/path/to/plugins";
        requirements_file = "/path/to/requirements.txt";
        helm_values_file = "/path/to/values.yaml";
        extra_volume_mounts = [
          "hostPath=/my/cool/path,containerPath=/my/mounted/path,name=a_unique_name"
        ];
        cluster_config_file = "/path/to/cluster/config.yaml";
        image = "apache/airflow:2.6.0";
        helm_chart_version = "1.0.0";
        port = 8080;
        post_start_dag_id = "example_dag_id";
      };
      description = ''
        Configuration settings for airlift. All the available options can be found here:
        <https://artifacthub.io/packages/helm/apache-airflow/airflow?modal=values>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".config/airlift/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "airlift-config.yaml" cfg.settings;
    };
  };
}
