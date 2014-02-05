if defined? Ransack
  Ransack.configure do |config|
    # Changes default search parameter key name
    # default is :q, this can be however overridden on
    # ransack search creation.
    config.search_key = :f

    config.add_predicate 'one_of',
      :arel_predicate => 'in',
      :compounds => false,
      :type => :string,
      :formatter => proc {|v| v.split(/\s*[,;]\s*/) }
  end

  #temporary solution for https://github.com/ernie/ransack/issues/61
  #coppied from https://gist.github.com/cawel/5448691

  # Patch for ransack (https://github.com/ernie/ransack) to use scopes
  # Helps migrating from Searchlogic or MetaSearch
  # Place this file into config/initializer/ransack.rb of your Rails 3.2 project
  #
  # Usage:
  # class Debt < ActiveRecord::Base
  # scope_ransackable :overdue
  # scope :overdue, lambda { where(["status = 'open' AND due_date < ?", Date.today]) }
  # end
  #
  # Ransack out of the box ignores scopes. Example:
  # Debt.search(:overdue => true, :amount_gteq => 10).result.to_sql
  # => "SELECT `debts`.* FROM `debts` AND (`debts`.`amount` >= 10.0)"
  #
  # This is changed by the patch. Example:
  # Debt.search(:overdue => true).result.to_sql
  # => "SELECT `debts`.* FROM `debts` WHERE `debts`.`status` = 'open' AND (due_date < '2012-11-23') AND (`debts`.`amount` >= 10.0)"
  #
  # Only scopes that return ActiveRecord::Relation are supported.
  # Any other scope or method that is called via Ransack will throw an exception
  # and cause a database transaction rollback.
  #
  module Ransack
    class ScopeNotWhitelistedError < StandardError; end

    module Adapters
      module ActiveRecord
        module Base
          def scope_ransackable(*args)
            @ransackable_scopes ||= []
            @ransackable_scopes += args.map(&:to_sym).reject { |scope| scope == :scope_ransackable }
            # make the custom scopes available in view, so that we can use view helpers
            # e.g. f.select :my_field instead of select_tag 'q[my_field]'
            # note: that means we need to override with :selected => value
            args.each do |method|
              Ransack::Search.send(:define_method, method) do
                nil
              end
            end
          end

          def scope_is_ransackable?(scope)
            @ransackable_scopes ||= []
            @ransackable_scopes.include? scope.to_sym
          end

          def search_with_scopes(params = {}, options = {})
            ransack_scope = self
            ransack_params = {}

            # Extract params which refer to a scope
            transaction do
              (params||{}).each_pair do |k,v|
                if ransack_scope.respond_to?(k)
                  Rails.logger.debug(k.inspect)
                  Rails.logger.debug(v.inspect)
                  Rails.logger.debug(ransack.class)
                  if (v == true or !v.blank?)
                    if !scope_is_ransackable? k
                      raise ScopeNotWhitelistedError.new
                    elsif (v == true)
                      ransack_scope = ransack_scope.send(k)
                    else
                      ransack_scope = ransack_scope.send(k, v)
                    end
                    raise ArgumentError.new "#{k} is not a scope that returns an ActiveRecord::Relation" unless ransack_scope.is_a? ::ActiveRecord::Relation
                  end
                else
                  ransack_params.merge!(k => v)
                end
              end
            end

            ransack_scope.search_without_scopes(ransack_params, options)
          end

          alias_method_chain :search, :scopes
          # refresh already existing ransack alias
          alias_method :ransack, :search
        end
      end
    end
  end
end
