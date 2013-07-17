class Lepidlo::Settings < Settingslogic
  SETTINGS_FILE     = File.join(Lepidlo::Engine.root, "config", "lepidlo-settings.yml")
  SETTINGS_FILE_APP = File.join(Rails.root, "config", "lepidlo-settings.yml")

  source SETTINGS_FILE
  namespace Rails.env

  class App < Settingslogic
    source File.exist?(SETTINGS_FILE_APP) ? SETTINGS_FILE_APP : SETTINGS_FILE
    namespace Rails.env
    Lepidlo::Settings.deep_merge!(to_hash)
  end
end
