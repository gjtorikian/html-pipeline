## Available cops

In the following section you find all available cops:

<!-- START_COP_LIST -->
#### Department [Sorbet](cops_sorbet.md)

* [Sorbet/AllowIncompatibleOverride](cops_sorbet.md#sorbetallowincompatibleoverride)
* [Sorbet/BindingConstantWithoutTypeAlias](cops_sorbet.md#sorbetbindingconstantwithouttypealias)
* [Sorbet/BlockMethodDefinition](cops_sorbet.md#sorbetblockmethoddefinition)
* [Sorbet/BuggyObsoleteStrictMemoization](cops_sorbet.md#sorbetbuggyobsoletestrictmemoization)
* [Sorbet/CallbackConditionalsBinding](cops_sorbet.md#sorbetcallbackconditionalsbinding)
* [Sorbet/CapitalizedTypeParameters](cops_sorbet.md#sorbetcapitalizedtypeparameters)
* [Sorbet/CheckedTrueInSignature](cops_sorbet.md#sorbetcheckedtrueinsignature)
* [Sorbet/ConstantsFromStrings](cops_sorbet.md#sorbetconstantsfromstrings)
* [Sorbet/EmptyLineAfterSig](cops_sorbet.md#sorbetemptylineaftersig)
* [Sorbet/EnforceSigilOrder](cops_sorbet.md#sorbetenforcesigilorder)
* [Sorbet/EnforceSignatures](cops_sorbet.md#sorbetenforcesignatures)
* [Sorbet/EnforceSingleSigil](cops_sorbet.md#sorbetenforcesinglesigil)
* [Sorbet/FalseSigil](cops_sorbet.md#sorbetfalsesigil)
* [Sorbet/ForbidComparableTEnum](cops_sorbet.md#sorbetforbidcomparabletenum)
* [Sorbet/ForbidExtendTSigHelpersInShims](cops_sorbet.md#sorbetforbidextendtsighelpersinshims)
* [Sorbet/ForbidIncludeConstLiteral](cops_sorbet.md#sorbetforbidincludeconstliteral)
* [Sorbet/ForbidMixesInClassMethods](cops_sorbet.md#sorbetforbidmixesinclassmethods)
* [Sorbet/ForbidRBIOutsideOfAllowedPaths](cops_sorbet.md#sorbetforbidrbioutsideofallowedpaths)
* [Sorbet/ForbidSig](cops_sorbet.md#sorbetforbidsig)
* [Sorbet/ForbidSigWithRuntime](cops_sorbet.md#sorbetforbidsigwithruntime)
* [Sorbet/ForbidSigWithoutRuntime](cops_sorbet.md#sorbetforbidsigwithoutruntime)
* [Sorbet/ForbidSuperclassConstLiteral](cops_sorbet.md#sorbetforbidsuperclassconstliteral)
* [Sorbet/ForbidTAbsurd](cops_sorbet.md#sorbetforbidtabsurd)
* [Sorbet/ForbidTAnyWithNil](cops_sorbet.md#sorbetforbidtanywithnil)
* [Sorbet/ForbidTBind](cops_sorbet.md#sorbetforbidtbind)
* [Sorbet/ForbidTCast](cops_sorbet.md#sorbetforbidtcast)
* [Sorbet/ForbidTEnum](cops_sorbet.md#sorbetforbidtenum)
* [Sorbet/ForbidTHelpers](cops_sorbet.md#sorbetforbidthelpers)
* [Sorbet/ForbidTLet](cops_sorbet.md#sorbetforbidtlet)
* [Sorbet/ForbidTMust](cops_sorbet.md#sorbetforbidtmust)
* [Sorbet/ForbidTSig](cops_sorbet.md#sorbetforbidtsig)
* [Sorbet/ForbidTStruct](cops_sorbet.md#sorbetforbidtstruct)
* [Sorbet/ForbidTTypeAlias](cops_sorbet.md#sorbetforbidttypealias)
* [Sorbet/ForbidTUnsafe](cops_sorbet.md#sorbetforbidtunsafe)
* [Sorbet/ForbidTUntyped](cops_sorbet.md#sorbetforbidtuntyped)
* [Sorbet/ForbidTypeAliasedShapes](cops_sorbet.md#sorbetforbidtypealiasedshapes)
* [Sorbet/ForbidUntypedStructProps](cops_sorbet.md#sorbetforbiduntypedstructprops)
* [Sorbet/HasSigil](cops_sorbet.md#sorbethassigil)
* [Sorbet/IgnoreSigil](cops_sorbet.md#sorbetignoresigil)
* [Sorbet/ImplicitConversionMethod](cops_sorbet.md#sorbetimplicitconversionmethod)
* [Sorbet/KeywordArgumentOrdering](cops_sorbet.md#sorbetkeywordargumentordering)
* [Sorbet/MultipleTEnumValues](cops_sorbet.md#sorbetmultipletenumvalues)
* [Sorbet/ObsoleteStrictMemoization](cops_sorbet.md#sorbetobsoletestrictmemoization)
* [Sorbet/RedundantExtendTSig](cops_sorbet.md#sorbetredundantextendtsig)
* [Sorbet/Refinement](cops_sorbet.md#sorbetrefinement)
* [Sorbet/SelectByIsA](cops_sorbet.md#sorbetselectbyisa)
* [Sorbet/SignatureBuildOrder](cops_sorbet.md#sorbetsignaturebuildorder)
* [Sorbet/SingleLineRbiClassModuleDefinitions](cops_sorbet.md#sorbetsinglelinerbiclassmoduledefinitions)
* [Sorbet/StrictSigil](cops_sorbet.md#sorbetstrictsigil)
* [Sorbet/StrongSigil](cops_sorbet.md#sorbetstrongsigil)
* [Sorbet/TrueSigil](cops_sorbet.md#sorbettruesigil)
* [Sorbet/TypeAliasName](cops_sorbet.md#sorbettypealiasname)
* [Sorbet/ValidGemVersionAnnotations](cops_sorbet.md#sorbetvalidgemversionannotations)
* [Sorbet/ValidSigil](cops_sorbet.md#sorbetvalidsigil)
* [Sorbet/VoidCheckedTests](cops_sorbet.md#sorbetvoidcheckedtests)

<!-- END_COP_LIST -->

In addition to the cops defined in this gem, it also modifies the behaviour of some other cops
defined in other RuboCop gems:

* [Style/MutableConstant](https://docs.rubocop.org/rubocop/cops_style.html#stylemutableconstant): In addition to the default behaviour, RuboCop Sorbet makes this cop `T.let` aware, so that `CONST = T.let([1, 2, 3], T::Array[Integer])` is also treated as a mutable literal constant value.
