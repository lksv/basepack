# encoding: UTF-8
require 'parslet'

module Basepack
  class FilterQL
    class ParseError < StandardError; end

    class Parser < Parslet::Parser
      def stri(str)
        key_chars = str.split(//)
        key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.reduce(:>>)
      end

      rule(:spaces)         { match('\s').repeat(1) } # at least 1 space character (space, tab, new line, carriage return)
      rule(:spaces?)        { spaces.maybe } # a bunch of spaces or not

      rule(:quote)          { str("'") }
      rule(:nonquote)       { str("'").absnt? >> any }

      rule(:dbquote)          { str('"') }
      rule(:nondbquote)       { str('"').absnt? >> any }

      rule(:escape)         { str('\\') >> any }
      rule(:comma) { spaces? >> str(',') >> spaces? }

      rule(:and_op)         { stri('and') >> spaces? }
      rule(:or_op)          { stri('or') >> spaces? }
      rule(:lparen)         { str("(") >> spaces? }
      rule(:rparen)         { str(")") >> spaces? }
      rule(:not_op)         { spaces? >> stri('not').maybe.as(:not) >> spaces? }

      rule(:operator)       { str('=') | str('!=') | str('>=') | str('<=') | str('>') | str('<') }
      rule(:str_op)         { stri('like') | stri('cont') | stri('start') | stri('end') }
      rule(:switch_op)      { stri('null') | stri('blank') }
      rule(:identifier)     { (match('[a-z_]') >> match('[a-z0-9_]').repeat).as(:identifier) }
      rule(:string)         { (quote >> (escape | nonquote).repeat.as(:string) >> quote) | (dbquote >> (escape | nondbquote).repeat.as(:string) >> dbquote) }
      rule(:integer)        { (str('+') | str('-')).maybe >> match('[0-9]').repeat(1) }
      rule(:float)          { integer >> (str('.') >> match('[0-9]').repeat(1) | stri('e') >> match('[0-9]').repeat(1)) }
      rule(:literal)        { string | array | jshash | function.as(:function) | float.as(:float) | integer.as(:integer) | stri('true').as(:true) | stri('false').as(:false) }

      rule(:array)          { str('[') >> spaces? >> (literal >> (comma >> literal).repeat).maybe.as(:array) >> spaces? >> str(']') }
      rule(:hash_pair)      { ( identifier.as(:key) >> spaces? >> str(':') >> spaces? >> literal.as(:val) ).as(:hash_pair) }
      rule(:jshash)         { str('{') >> spaces? >> (hash_pair >> (comma >> hash_pair).repeat).maybe.as(:jshash) >> spaces? >> str('}') }

      rule(:function)       { (match('[a-z_]') >> match('[a-z0-9_]').repeat).as(:function_name) >> str('(') >> literal.maybe.as(:param) >> str(')') }

      rule(:expression)     { identifier.as(:id) >> spaces? >> operator.as(:op) >> spaces? >> literal.as(:value) >> spaces? }
      rule(:str_expression) { identifier.as(:id) >> spaces >> not_op.as(:not) >> str_op.as(:op) >> spaces? >> string.as(:str) >> spaces? }
      rule(:blank_expr)     { identifier.as(:id) >> spaces >> stri('is') >> not_op.as(:not) >> switch_op.as(:switch_op) >> spaces? }

      #rule(:condition)      { lparen >> or_cond >> rparen | expression | str_expression | blank_expr }
      #rule(:and_cond)       { (condition.as(:left) >> and_op >> and_cond.as(:right)).as(:and) | condition }
      #rule(:or_cond)        { (and_cond.as(:left) >> or_op >> or_cond.as(:right)).as(:or) | and_cond }
      rule(:condition)      { expression | str_expression | blank_expr }
      #rule(:query)          { spaces? >> or_cond >> spaces? }
      rule(:query)          { spaces? >> ( condition >> (and_op >> condition).repeat ).as(:query) >> spaces? }

      root :query
    end

    PREDICATE_MAP = {
      "="        => 'eq',
      "!="       => 'not_eq',
      ">="       => 'gteq',
      "<="       => 'lteq',
      ">"        => 'gt',
      "<"        => 'lt',
      "like"     => 'matches',
      "notlike"  => 'does_not_match',
      "cont"     => 'cont',
      "notcont"  => 'not_cont',
      "start"    => 'start',
      "notstart" => 'not_start',
      "end"      => 'end',
      "notend"   => 'not_end',
      "blank"    => 'blank',
      "notblank" => 'present',
      "null"     => 'null',
      "notnull"  => 'not_null',
    }.freeze

    PREDICATE_MAP_REVERSE = {
      'eq'             => "=",
      'not_eq'         => "!=",
      'gteq'           => ">=",
      'lteq'           => "<=",
      'gt'             => ">",
      'lt'             => "<",
      'matches'        => "like",
      'does_not_match' => "not like",
      'cont'           => "cont",
      'not_cont'       => "not cont",
      'start'          => "start",
      'not_start'      => "not start",
      'end'            => "end",
      'not_end'        => "not end",
      'blank'          => "is blank",
      'present'        => "is not blank",
      'null'           => "is null",
      'not_null'       => "is not null",
      'true'           => "= true",
      'false'          => "= false",
    }.freeze

    class Transformer < Parslet::Transform
      class HashPair < Struct.new(:key, :val); end

      rule(:string     => simple(:str))    { FilterQL.string_to_value(str.to_s) }
      rule(:integer    => simple(:int))    { Integer(int) }
      rule(:float      => simple(:float))  { Float(float) }
      rule(:identifier => simple(:id))     { id.to_sym }
      rule(:true       => simple(:true))   { true }
      rule(:false      => simple(:false))  { false }
      rule(:not        => simple(:n))      { n ? :not : nil }

      rule(:function => { :function_name => simple(:fce_name), :param => subtree(:param) }) do
        b = builder.new_for_slice(fce_name)
        if f = builder.functions[fce_name.to_sym]
          f.call(b, param)
        else
          b.raise_error(I18n.t("basepack.query.error_unknown_func") + " `#{fce_name}'")
        end
      end

      rule(:array => subtree(:ar)) { Array(ar) }
      rule(:jshash => subtree(:ob)) do
        (ob.is_a?(Array) ? ob : [ ob ]).inject({}) { |h, e| h[e.key] = e.val; h }
      end
      rule(:hash_pair => { :key => simple(:ke), :val => simple(:va) }) { HashPair.new(ke, va) }

      rule(id: simple(:id), op: simple(:op), value: subtree(:value)) do
        { "#{id}_#{PREDICATE_MAP[op.to_s]}" => value }
      end

      rule(id: simple(:id), not: simple(:n), op: simple(:op), str: simple(:value)) do
        predicate = PREDICATE_MAP["#{n}#{op}"]
        { "#{id}_#{predicate}" => value }
      end

      rule(id: simple(:id), not: simple(:n), switch_op: simple(:value)) do
        predicate = PREDICATE_MAP["#{n}#{value}"]
        { "#{id}_#{predicate}" => true }
      end

      rule(:query => subtree(:conditions)) do 
        Array.wrap(conditions).inject({}) {|result, cond| result.merge(cond)}
      end
    end

    class Builder
      attr_reader :query, :options, :slice

      def initialize(query, options, slice = nil)
        @query = query
        @options = options
        @slice = slice
      end

      def functions
        @options[:functions] || {}
      end

      def raise_error_for_pos(message, pos, line = '?', column = '?')
        normalized_pos = pos >= query.length ? query.length : pos
        query_error = query.dup.insert(normalized_pos, I18n.t("basepack.query.error"))
        raise ParseError, I18n.t('basepack.query.filter_ql_syntax_error', row: line, col: column, message: message, query_error: query_error)
      end

      def raise_error(message)
        if slice
          line, column = slice.line_and_column
          raise_error_for_pos(message, slice.offset + slice.size, line, column)
        else
          raise ParseError, message
        end
      end

      def new_for_slice(slice)
        Builder.new(query, options, slice)
      end
    end

    def initialize(options = nil)
      @parser = Parser.new
      @transformer = Transformer.new
      @options = (options || {}).freeze
    end

    def parse(query, options = nil)
      builder = Builder.new(query, @options)
      begin
        ast = @parser.parse(query, reporter: Parslet::ErrorReporter::Deepest.new)
        @transformer.apply(ast, builder: builder)
      rescue Parslet::ParseFailed => e
        #puts e.cause.ascii_tree
        deepest = deepest_cause(e.cause)
        line, column = deepest.source.line_and_column(deepest.pos)
        builder.raise_error_for_pos(I18n.t("basepack.query.error_query_input"), deepest.pos, line, column)
      end
    end

    #Basepack::FilterQL.test
    def self.test
      new(
        functions: {
          user: proc {|builder, arg| arg.inspect }
        }
      ).parse(
        "a0 = user() and a01 = user('I') and a02 = user({ x: 1}) and a03 = user([1,2,'3']) and " +
        "a1 = 3 and a2 like 'asd' and a3 not like 'asd' and a4 is null and a5 is not null and a6 != 'as\\'d' and a7 = \"str\\\"s\" and " +
        "a8 = { key:'value', key2:1 } and a9 = ['str', 4, 3.5] ",
      )
    end

    def self.conditions_to_ql(conditions)
      conditions.map do |name, predicate_name, value|
        if predicates[predicate_name][:type] == :boolean
          "#{name} #{PREDICATE_MAP_REVERSE[predicate_name]}"
        else
          case value
          when String then value = value_to_string(value)
          when Hash   then value = value_to_jshash(value)
          end
          "#{name} #{PREDICATE_MAP_REVERSE[predicate_name]} #{value}"
        end
      end.join(" and ")
    end

    def self.predicates
      @predicates ||= begin
        Hash[Ransack.predicates.map do |k, predicate|
          [k, {
            name:     k,
            label:    Ransack::Translate.predicate(k),
            type:     predicate.type,
            compound: predicate.compound,
            wants_array: predicate.wants_array,
          }]
        end.compact]
      end
    end

    def self.value_to_string(value)
      "'#{value.gsub(/(['\\])/, '\\\\\1')}'"
    end

    def self.value_to_jshash(value)
      res = value.inject([]) do |r,(k,v)|
        r << "#{k}: #{v.inspect}"
      end.join(", ")
      "{ #{res} }"
    end

    def self.string_to_value(string)
      string.gsub(/\\(.)/, '\1')
    end

    private

    def deepest_cause(cause)
      if cause.children.any?
        deepest_cause(cause.children.first)
      else
        cause
      end
    end
  end
end
