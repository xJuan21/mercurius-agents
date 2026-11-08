/// Creates and updates stored agents, with the rules enforced on the backend.
Class Mercurius.Runtime.AgentService Extends %RegisteredObject
{

/// Returns an error message, or an empty string when the body is valid.
ClassMethod Validate(pBody As %DynamicObject, pIsNew As %Boolean) As %String
{
    If (pIsNew && '$MATCH(pBody.name, "[A-Za-z][A-Za-z0-9-]{0,29}")) {
        Return "Name must start with a letter and use only letters, digits and hyphens, up to 30 characters."
    }
    Return:($ZSTRIP(pBody.role, "<>W") = "") "Role is required."
    Return:($ZSTRIP(pBody.instructions, "<>W") = "") "Instructions are required."
    Return:($LENGTH(pBody.instructions) > 4000) "Instructions are limited to 4000 characters."

    Set Allowed = ..CleanList(pBody.allowedDecisions)
    Return:(Allowed = "") "At least one decision value is required."
    Return:('$MATCH(Allowed, "[a-z0-9-]+(,[a-z0-9-]+)*")) "Decision values must be lowercase words separated by commas."
    Set Review = ..CleanList(pBody.reviewDecisions)
    For Index = 1:1:$LENGTH(Review, ",") {
        Set Value = $PIECE(Review, ",", Index)
        If ((Value '= "") && '##class(Mercurius.Runtime.DecisionPolicy).InList(Value, Allowed)) {
            Return "Review value is not an allowed decision: "_Value
        }
    }

    If ((pBody.provider '= "") || (pBody.model '= "")) {
        If ('##class(Mercurius.Runtime.ModelCatalog).IsAllowed(pBody.provider, pBody.model)) {
            Return "That model isn't available for the provider. Refresh the model list and choose again."
        }
    }

    Set Problem = ##class(Mercurius.Runtime.RulesEngine).Validate(pBody.fallbackRules, Allowed)
    Return:(Problem '= "") Problem

    If ($ISOBJECT(pBody.tools)) {
        Set Iterator = pBody.tools.%GetIterator()
        While (Iterator.%GetNext(.Key, .ToolKey)) {
            Return:('##class(Mercurius.Runtime.ToolRegistry).IsKnown(ToolKey)) "Unknown tool: "_ToolKey
        }
    }
    Return ""
}

/// Saves the agent and replaces its tool grants.
ClassMethod Save(pBody As %DynamicObject, pName As %String = "") As %Status
{
    Set Class = "Mercurius.Model.AgentDefinition"
    If (pName = "") {
        Set Definition = $CLASSMETHOD(Class, "%New")
        Set Definition.Name = pBody.name
    } Else {
        Set Definition = $CLASSMETHOD(Class, "NameIndexOpen", pName, , .SC)
        Return:($$$ISERR(SC)) SC
    }
    Set Definition.Role = pBody.role
    Set Definition.Description = pBody.description
    Set Definition.SystemPrompt = pBody.instructions
    Set Definition.Tone = pBody.tone
    Set Definition.AllowedDecisions = ..CleanList(pBody.allowedDecisions)
    Set Definition.ReviewDecisions = ..CleanList(pBody.reviewDecisions)
    Set Definition.FallbackRules = pBody.fallbackRules
    Set:(pBody.provider '= "") Definition.ProviderName = pBody.provider
    Set:(pBody.model '= "") Definition.ModelName = pBody.model
    Set:(pBody.%IsDefined("enabled")) Definition.Enabled = +pBody.enabled
    Set SC = Definition.%Save()
    Return:($$$ISERR(SC)) SC
    Return:('$ISOBJECT(pBody.tools)) $$$OK

    Set Name = Definition.Name
    &sql(DELETE FROM Mercurius_Model.AgentToolPermission WHERE AgentName = :Name)
    Set Iterator = pBody.tools.%GetIterator()
    While (Iterator.%GetNext(.Key, .ToolKey)) {
        Set SC = ##class(Mercurius.Setup).Grant(Name, ToolKey)
        Return:($$$ISERR(SC)) SC
    }
    Return $$$OK
}

ClassMethod CleanList(pList As %String) As %String
{
    Return $ZCONVERT($TRANSLATE(pList, " ", ""), "L")
}

}
