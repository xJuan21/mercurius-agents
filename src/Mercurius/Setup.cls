/// Creates the sample agents.
Class Mercurius.Setup Extends %RegisteredObject
{

ClassMethod SeedAgents() As %Status
{
    Set SC = ..AddAgent("Scribe", "Documentation review", "You review technical notes. Reply only with JSON: {""decision"":""related|conflict|none"",""reason"":""one sentence""}")
    Return:($$$ISERR(SC)) SC
    Return ..AddAgent("Sentinel", "Operational alerts", "You assess operational events. Reply only with JSON: {""severity"":""low|medium|high"",""action"":""one sentence""}")
}

ClassMethod AddAgent(pName As %String, pRole As %String, pSystemPrompt As %String) As %Status
{
    Return:(##class(Mercurius.Model.AgentDefinition).NameIndexExists(pName)) $$$OK
    Set Definition = ##class(Mercurius.Model.AgentDefinition).%New()
    Set Definition.Name = pName
    Set Definition.Role = pRole
    Set Definition.SystemPrompt = pSystemPrompt
    Return Definition.%Save()
}

}
