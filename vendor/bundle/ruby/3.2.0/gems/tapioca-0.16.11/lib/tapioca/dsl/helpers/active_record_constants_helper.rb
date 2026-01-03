# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ActiveRecordConstantsHelper
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveRecord::Reflection::ThroughReflection, ::ActiveRecord::Reflection::AssociationReflection)
        end

        AttributeMethodsModuleName = T.let("GeneratedAttributeMethods", String)
        AssociationMethodsModuleName = T.let("GeneratedAssociationMethods", String)
        DelegatedTypesModuleName = T.let("GeneratedDelegatedTypeMethods", String)
        SecureTokensModuleName = T.let("GeneratedSecureTokenMethods", String)
        StoredAttributesModuleName = T.let("GeneratedStoredAttributesMethods", String)

        RelationMethodsModuleName = T.let("GeneratedRelationMethods", String)
        AssociationRelationMethodsModuleName = T.let("GeneratedAssociationRelationMethods", String)
        CommonRelationMethodsModuleName = T.let("CommonRelationMethods", String)

        RelationClassName = T.let("PrivateRelation", String)
        RelationGroupChainClassName = T.let("PrivateRelationGroupChain", String)
        RelationWhereChainClassName = T.let("PrivateRelationWhereChain", String)
        AssociationRelationClassName = T.let("PrivateAssociationRelation", String)
        AssociationRelationGroupChainClassName = T.let("PrivateAssociationRelationGroupChain", String)
        AssociationRelationWhereChainClassName = T.let("PrivateAssociationRelationWhereChain", String)
        AssociationsCollectionProxyClassName = T.let("PrivateCollectionProxy", String)
      end
    end
  end
end
