module Lepidlo
  module Import
    module Importable
      extend ActiveSupport::Concern

      included do
        attr_reader :current_import, :current_ability
      end

      def importing(import, current_ability)
        @current_import = @import
        @current_ability = current_ability
        self.import_id = import.id if respond_to? :import_id= # TODO - move into Import, should be also in associations
      end
      alias :importing! :importing
    end
  end
end
