require "spec_helper"

describe "Basepack Basic Export", type: :request do
  let(:employee) { FactoryGirl.create(:employee) }
  let(:export_template) { FactoryGirl.create(:export_template,
  	class_type: "Employee",
  	schema_template: ["name", "not_existing", {"projects"=>["name"]}])
	}

  describe "export template" do
    it "saves export template" do
  	  visit export_employees_path
			find("#export_template_name").set("Employee with names")
			check 'schema_name'

      expect {
        click_on "Export to csv"
      }.to change(ExportTemplate, :count).by(1)
      expect(page.driver.status_code).to eq 200
      et = ExportTemplate.last
      expect(et.name).to eq "Employee with names"
      expect(et.schema_template).to eq ["name"]
    end

    it "pre fills name" do
    	export_template
  	  visit export_employees_path(export_template_id: export_template.id)

			expect(find('#schema_name')).to be_checked
			expect(find('#schema_projects_name')).to be_checked
    end
  end

end
