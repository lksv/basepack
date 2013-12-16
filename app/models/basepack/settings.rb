module Basepack
  class Settings < Settingslogic
    SETTINGS_FILE     = File.join(Basepack::Engine.root, "config", "basepack-settings.yml")
    SETTINGS_FILE_APP = File.join(Rails.root, "config", "basepack-settings.yml")

    source SETTINGS_FILE
    namespace Rails.env

    class App < Settingslogic
      source File.exist?(SETTINGS_FILE_APP) ? SETTINGS_FILE_APP : SETTINGS_FILE
      namespace Rails.env
      Basepack::Settings.deep_merge!(to_hash)
    end
  end
end
