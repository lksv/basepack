module Basepack
  module Forms
    module Groups
      class Diff < Groups::Base
        def visible_fields2
          field_names.map {|f| form.visible_field2(f)}.compact
        end

        def changes
          fields2_hash = form.form2.fields_hash
          visible_fields.map {|f| [f, fields2_hash[f.name]]}.reject do |f1, f2|
            (form.compare(f1.name) || form.compare("*")).call(f1, f2)
          end
        end
      end
    end
  end
end
