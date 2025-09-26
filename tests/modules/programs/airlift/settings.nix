{
  programs.airlift = {
    enable = true;
    settings = {
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
  };

  nmt.script = ''
    assertFileExists home-files/.config/airlift/config.yaml
    assertFileContent home-files/.config/airlift/config.yaml \
      ${./config.yaml}
  '';
}
