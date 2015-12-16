APP_CONFIG = YAML.load(ERB.new(IO.read(Rails.root.join('config', 'appcfg.yml'))).result)[Rails.env]

#Type.load_config_data
#Resource.load_config_data

#HTTPI.log = false
