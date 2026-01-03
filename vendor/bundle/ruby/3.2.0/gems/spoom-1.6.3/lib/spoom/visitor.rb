# typed: strict
# frozen_string_literal: true

require "prism"

module Spoom
  class Visitor < Prism::Visitor
    # @override
    #: (Prism::Node node) -> void
    def visit_child_nodes(node)
      node.child_nodes.compact.each { |node| visit(node) }
    end

    # @override
    #: (Prism::AliasGlobalVariableNode node) -> void
    def visit_alias_global_variable_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::AliasMethodNode node) -> void
    def visit_alias_method_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::AlternationPatternNode node) -> void
    def visit_alternation_pattern_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::AndNode node) -> void
    def visit_and_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ArgumentsNode node) -> void
    def visit_arguments_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ArrayNode node) -> void
    def visit_array_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ArrayPatternNode node) -> void
    def visit_array_pattern_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::AssocNode node) -> void
    def visit_assoc_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::AssocSplatNode node) -> void
    def visit_assoc_splat_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BackReferenceReadNode node) -> void
    def visit_back_reference_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BeginNode node) -> void
    def visit_begin_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BlockArgumentNode node) -> void
    def visit_block_argument_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BlockLocalVariableNode node) -> void
    def visit_block_local_variable_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BlockNode node) -> void
    def visit_block_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BlockParameterNode node) -> void
    def visit_block_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BlockParametersNode node) -> void
    def visit_block_parameters_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::BreakNode node) -> void
    def visit_break_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CallAndWriteNode node) -> void
    def visit_call_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CallNode node) -> void
    def visit_call_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CallOperatorWriteNode node) -> void
    def visit_call_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CallOrWriteNode node) -> void
    def visit_call_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CallTargetNode node) -> void
    def visit_call_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CapturePatternNode node) -> void
    def visit_capture_pattern_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CaseMatchNode node) -> void
    def visit_case_match_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::CaseNode node) -> void
    def visit_case_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassNode node) -> void
    def visit_class_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableAndWriteNode node) -> void
    def visit_class_variable_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableOperatorWriteNode node) -> void
    def visit_class_variable_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableOrWriteNode node) -> void
    def visit_class_variable_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableReadNode node) -> void
    def visit_class_variable_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableTargetNode node) -> void
    def visit_class_variable_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ClassVariableWriteNode node) -> void
    def visit_class_variable_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantAndWriteNode node) -> void
    def visit_constant_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantOperatorWriteNode node) -> void
    def visit_constant_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantOrWriteNode node) -> void
    def visit_constant_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathAndWriteNode node) -> void
    def visit_constant_path_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathNode node) -> void
    def visit_constant_path_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathOperatorWriteNode node) -> void
    def visit_constant_path_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathOrWriteNode node) -> void
    def visit_constant_path_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathTargetNode node) -> void
    def visit_constant_path_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantPathWriteNode node) -> void
    def visit_constant_path_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantReadNode node) -> void
    def visit_constant_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantTargetNode node) -> void
    def visit_constant_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ConstantWriteNode node) -> void
    def visit_constant_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::DefNode node) -> void
    def visit_def_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::DefinedNode node) -> void
    def visit_defined_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ElseNode node) -> void
    def visit_else_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::EmbeddedStatementsNode node) -> void
    def visit_embedded_statements_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::EmbeddedVariableNode node) -> void
    def visit_embedded_variable_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::EnsureNode node) -> void
    def visit_ensure_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::FalseNode node) -> void
    def visit_false_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::FindPatternNode node) -> void
    def visit_find_pattern_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::FlipFlopNode node) -> void
    def visit_flip_flop_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::FloatNode node) -> void
    def visit_float_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ForNode node) -> void
    def visit_for_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ForwardingArgumentsNode node) -> void
    def visit_forwarding_arguments_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ForwardingParameterNode node) -> void
    def visit_forwarding_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ForwardingSuperNode node) -> void
    def visit_forwarding_super_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableAndWriteNode node) -> void
    def visit_global_variable_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableOperatorWriteNode node) -> void
    def visit_global_variable_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableOrWriteNode node) -> void
    def visit_global_variable_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableReadNode node) -> void
    def visit_global_variable_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableTargetNode node) -> void
    def visit_global_variable_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::GlobalVariableWriteNode node) -> void
    def visit_global_variable_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::HashNode node) -> void
    def visit_hash_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::HashPatternNode node) -> void
    def visit_hash_pattern_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IfNode node) -> void
    def visit_if_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ImaginaryNode node) -> void
    def visit_imaginary_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ImplicitNode node) -> void
    def visit_implicit_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ImplicitRestNode node) -> void
    def visit_implicit_rest_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InNode node) -> void
    def visit_in_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IndexAndWriteNode node) -> void
    def visit_index_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IndexOperatorWriteNode node) -> void
    def visit_index_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IndexOrWriteNode node) -> void
    def visit_index_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IndexTargetNode node) -> void
    def visit_index_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableAndWriteNode node) -> void
    def visit_instance_variable_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableOperatorWriteNode node) -> void
    def visit_instance_variable_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableOrWriteNode node) -> void
    def visit_instance_variable_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableReadNode node) -> void
    def visit_instance_variable_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableTargetNode node) -> void
    def visit_instance_variable_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InstanceVariableWriteNode node) -> void
    def visit_instance_variable_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::IntegerNode node) -> void
    def visit_integer_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InterpolatedMatchLastLineNode node) -> void
    def visit_interpolated_match_last_line_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InterpolatedRegularExpressionNode node) -> void
    def visit_interpolated_regular_expression_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InterpolatedStringNode node) -> void
    def visit_interpolated_string_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InterpolatedSymbolNode node) -> void
    def visit_interpolated_symbol_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::InterpolatedXStringNode node) -> void
    def visit_interpolated_x_string_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::KeywordHashNode node) -> void
    def visit_keyword_hash_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::KeywordRestParameterNode node) -> void
    def visit_keyword_rest_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LambdaNode node) -> void
    def visit_lambda_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableAndWriteNode node) -> void
    def visit_local_variable_and_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableOperatorWriteNode node) -> void
    def visit_local_variable_operator_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableOrWriteNode node) -> void
    def visit_local_variable_or_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableReadNode node) -> void
    def visit_local_variable_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableTargetNode node) -> void
    def visit_local_variable_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::LocalVariableWriteNode node) -> void
    def visit_local_variable_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MatchLastLineNode node) -> void
    def visit_match_last_line_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MatchPredicateNode node) -> void
    def visit_match_predicate_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MatchRequiredNode node) -> void
    def visit_match_required_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MatchWriteNode node) -> void
    def visit_match_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MissingNode node) -> void
    def visit_missing_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ModuleNode node) -> void
    def visit_module_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MultiTargetNode node) -> void
    def visit_multi_target_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::MultiWriteNode node) -> void
    def visit_multi_write_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::NextNode node) -> void
    def visit_next_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::NilNode node) -> void
    def visit_nil_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::NoKeywordsParameterNode node) -> void
    def visit_no_keywords_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::NumberedParametersNode node) -> void
    def visit_numbered_parameters_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::NumberedReferenceReadNode node) -> void
    def visit_numbered_reference_read_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::OptionalKeywordParameterNode node) -> void
    def visit_optional_keyword_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::OptionalParameterNode node) -> void
    def visit_optional_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::OrNode node) -> void
    def visit_or_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ParametersNode node) -> void
    def visit_parameters_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ParenthesesNode node) -> void
    def visit_parentheses_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::PinnedExpressionNode node) -> void
    def visit_pinned_expression_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::PinnedVariableNode node) -> void
    def visit_pinned_variable_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::PostExecutionNode node) -> void
    def visit_post_execution_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::PreExecutionNode node) -> void
    def visit_pre_execution_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ProgramNode node) -> void
    def visit_program_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RangeNode node) -> void
    def visit_range_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RationalNode node) -> void
    def visit_rational_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RedoNode node) -> void
    def visit_redo_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RegularExpressionNode node) -> void
    def visit_regular_expression_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RequiredKeywordParameterNode node) -> void
    def visit_required_keyword_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RequiredParameterNode node) -> void
    def visit_required_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RescueModifierNode node) -> void
    def visit_rescue_modifier_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RescueNode node) -> void
    def visit_rescue_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RestParameterNode node) -> void
    def visit_rest_parameter_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::RetryNode node) -> void
    def visit_retry_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::ReturnNode node) -> void
    def visit_return_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SelfNode node) -> void
    def visit_self_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SingletonClassNode node) -> void
    def visit_singleton_class_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SourceEncodingNode node) -> void
    def visit_source_encoding_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SourceFileNode node) -> void
    def visit_source_file_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SourceLineNode node) -> void
    def visit_source_line_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SplatNode node) -> void
    def visit_splat_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::StatementsNode node) -> void
    def visit_statements_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::StringNode node) -> void
    def visit_string_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SuperNode node) -> void
    def visit_super_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::SymbolNode node) -> void
    def visit_symbol_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::TrueNode node) -> void
    def visit_true_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::UndefNode node) -> void
    def visit_undef_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::UnlessNode node) -> void
    def visit_unless_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::UntilNode node) -> void
    def visit_until_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::WhenNode node) -> void
    def visit_when_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::WhileNode node) -> void
    def visit_while_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::XStringNode node) -> void
    def visit_x_string_node(node)
      visit_child_nodes(node)
    end

    # @override
    #: (Prism::YieldNode node) -> void
    def visit_yield_node(node)
      visit_child_nodes(node)
    end
  end
end
