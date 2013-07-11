class Lepidlo::Settings < Settingslogic
  source "#{Rails.root}/config/lepidlo-settings.yml"
  namespace Rails.env
end
