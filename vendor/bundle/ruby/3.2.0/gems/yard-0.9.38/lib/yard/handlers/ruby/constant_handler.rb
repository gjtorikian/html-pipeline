# frozen_string_literal: true
# Handles any constant assignment
class YARD::Handlers::Ruby::ConstantHandler < YARD::Handlers::Ruby::Base
  include YARD::Handlers::Ruby::StructHandlerMethods
  handles :assign
  namespace_only

  process do
    if statement[1].call? && statement[1][0][0] == s(:const, "Struct") &&
       statement[1][2] == s(:ident, "new")
      process_structclass(statement)
    elsif statement[1].call? && statement[1][0][0] == s(:const, "Data") &&
       statement[1][2] == s(:ident, "define")
      process_dataclass(statement)
    elsif statement[0].type == :var_field && statement[0][0].type == :const
      process_constant(statement)
    elsif statement[0].type == :const_path_field
      process_constant(statement)
    end
  end

  private

  def process_constant(statement)
    name = statement[0].source
    value = statement[1].source
    obj = P(namespace, name)
    if obj.is_a?(NamespaceObject) && obj.namespace == namespace
      raise YARD::Parser::UndocumentableError, "constant for existing #{obj.type} #{obj}"
    else
      ensure_loaded! obj.parent
      register ConstantObject.new(namespace, name) {|o| o.source = statement; o.value = value.strip }
    end
  end

  def process_structclass(statement)
    lhs = statement[0]
    if (lhs.type == :var_field && lhs[0].type == :const) || lhs.type == :const_path_field
      klass = create_class(lhs.source, P(:Struct))
      create_attributes(klass, extract_parameters(statement[1]))
      parse_block(statement[1].block[1], :namespace => klass) unless statement[1].block.nil?
    else
      raise YARD::Parser::UndocumentableError, "Struct assignment to #{lhs.source}"
    end
  end

  def process_dataclass(statement)
    lhs = statement[0]
    if (lhs.type == :var_field && lhs[0].type == :const) || lhs.type == :const_path_field
      klass = create_class(lhs.source, P(:Data))
      extract_parameters(statement[1]).each do |member|
        klass.attributes[:instance][member] = SymbolHash[:read => nil, :write => nil]
        create_reader(klass, member)
      end
      parse_block(statement[1].block[1], :namespace => klass) unless statement[1].block.nil?
    else
      raise YARD::Parser::UndocumentableError, "Data assignment to #{lhs.source}"
    end
  end

  # Extract the parameters from the Struct.new or Data.define AST node, returning them as a list
  # of strings
  #
  # @param [MethodCallNode] superclass the AST node for the Struct.new or Data.define call
  # @return [Array<String>] the member names to generate methods for
  def extract_parameters(superclass)
    return [] unless superclass.parameters
    members = superclass.parameters.select {|x| x && x.type == :symbol_literal }
    members.map! {|x| x.source.strip[1..-1] }
    members
  end
end
