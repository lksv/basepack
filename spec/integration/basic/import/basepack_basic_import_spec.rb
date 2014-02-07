require 'spec_helper'

describe "Basepack basic list" do
  # subject { page }

  describe "import" do
    it "imports an file" do
      sleep 10
      visit employees_path
      click_link "Import"
      path = File.join(::Rails.root, "../../spec/fixtures/employees.csv")
      attach_file('import_file', File.expand_path(path))
      click_button('Add')
      click_button('Start')
      expect(page).to have_selector("td.num_errors_field", text:'0')
      expect(page).to have_selector("td.num_imported_field", text:'2')

      find("td.num_imported_field", text:'2').click
    end

  end

end
