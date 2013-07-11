# encoding: UTF-8

module ResourcesHelper

  def model_name_pluralize(model_class)
    model_class.model_name.human(
      :count => 'other',
      :default => model_class.model_name.human.pluralize
    )
  end

  def title(title_type = nil, title_subject = nil, options = {})
    title2 = title_subject
    title1 = Array.wrap(title_type).map do |type|
      case type
      when ActiveRecord::Base
        title2 = type.to_label if title_subject.nil?
        type.class.model_name.human
      when Class
        if type.respond_to? :model_name
          model_name_pluralize(type)
        else
          type.name
        end
      else
        type.to_s
      end
    end.join(' / ')

    content_for :page_title do
      haml_tag :small, html_escape(title1)
      haml_concat html_escape(title2) if title2
      if Lepidlo::Settings.help.title and options[:help] != false
        haml_tag "small.help" do
          haml_tag :a, href: help_path(options[:help] || title1.parameterize), title: "Nápověda" do
            haml_tag "i.icon-question-sign"
          end
        end
      end
    end
    content_for :title do
      html_escape("#{title1} #{title2} | #{t(:web_name)}")
    end
  end

  def model_config(resource_class)
    Lepidlo::Utils.model_config(resource_class)
  end

end
