module BasepackHelper

  # Test that select2 identifed by label *locator* has selected (also) value
  # passed in *options*[:selected]
  #
  # TODO: extend to pass all the params as Capybara::Node::Matchers#has_select 
  # see http://rubydoc.info/github/jnicklas/capybara/master/Capybara/Node/Matchers#has_no_select%3F-instance_method
  def have_select2(locator, options = {})
    select2_container = first("label", text: locator).
      find(:xpath, '..').
      find(".select2-container")

    within(select2_container) do
      if select2_container.has_selector?('.select2-choices')
        have_selector(".select2-search-choice", text: options[:selected])
      else
        have_selector(".select2-chosen", text: options[:selected])
      end
    end
  end

  def have_selector2(locator, options)
    select2_container = first("label", text: locator).
      find(:xpath, '..').
      find(".select2-container")

    select2_container.find(".select2-choice").click
    find(:css, "div[style*=block].select2-drop-active input[type=text].select2-input").set(options[:selected])

    within(select2_container) do
      have_selector(".select2-drop li", text: options[:selected])
    end
  end

  def get_select2_container(options = {})
    #TODO: maybe inspire by: https://gist.github.com/onyxrev/6970632 which is more clear solution

    raise "Must pass a hash containing 'from' or 'xpath'" unless options.is_a?(Hash) and [:from, :xpath].any? { |k| options.has_key? k }

    if options.has_key? :xpath
      select2_container = first(:xpath, options[:xpath])
    else
      # find by label
      select_name = options[:from]
      select2_container = first("label", text: select_name).find(:xpath, '..').find(".select2-container")
    end

    # return signe or multiple value
    if select2_container.has_selector?('.select2-choice')
      select2_container.find(".select2-choice")
    else 
      select2_container.find(".select2-choices")
    end
  end

  def select2(value, options = {})
    #TODO: maybe inspire by: https://gist.github.com/onyxrev/6970632 which is more clear solution
    select2_container = get_select2_container(options)
    select2_container.click
    
    #find(:css, "div[style*=block].select2-drop-active input[type=text].select2-input").set(value)
    select2_container.find(:css, "input[type=text].select2-input").set(value)
    find(:xpath, "//body").find(".select2-drop li", text: value).click
  end

  def add_select2(label, options)
    raise "Must pass a hash containing 'with'" if options[:with].nil?
    select2(options[:with], {from: label})
  end

  def remove_select2(label, options)
    raise "Must pass a hash containing 'with'" if options[:with].nil?
    within(get_select2_container(from: label)) do
      # there is no identifier in options must find by name
      all('.select2-search-choice').each do |item|
        item.first('.select2-search-choice-close').click if item.has_content?(options[:with])
      end
    end
    sleep 0.2
  end

  def remove_all_select2(label)
    within(get_select2_container(from: label)) do
      # find all crosses links and click on each one
      all('.select2-search-choice-close').each do |cross_link|
        cross_link.click       
      end
    end
    # sleep to assure that all options are removed before next instructions
    sleep 0.2
  end

  def fill_in_datepicker(id, options)
    raise "Must pass a hash containing 'with'" if options[:with].nil?
    find(:css, "input##{id} + input").set(options[:with])
  end
end
