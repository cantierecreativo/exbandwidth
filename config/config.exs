use Mix.Config

environment_secrets = "#{Mix.env}.secrets.exs"
if File.exists?(Path.join("config", environment_secrets)) do
  import_config environment_secrets
end

config :snmp, :manager,
  config: [dir: './config/snmp', db_dir: './config/snmp_db']
