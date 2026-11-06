/// Creates the sample agents.
Class Mercurius.Setup Extends %RegisteredObject
{

ClassMethod SeedAgents() As %Status
{
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/documents")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/alerts")
    Set SC = ..SaveAgent("Scribe", "Documentation review", "You review technical notes. Reply only with JSON: {""decision"":""related|conflict|none"",""reason"":""one sentence""}", "decision", "related,conflict,none", "conflict")
    Return:($$$ISERR(SC)) SC
    Return ..SaveAgent("Sentinel", "Operational alerts", "You assess operational events. Reply only with JSON: {""severity"":""low|medium|high"",""action"":""one sentence""}", "severity", "low,medium,high", "high")
}

ClassMethod SaveAgent(pName As %String, pRole As %String, pSystemPrompt As %String, pDecisionField As %String, pAllowedDecisions As %String, pReviewDecisions As %String) As %Status
{
    Set Class = "Mercurius.Model.AgentDefinition"
    If ($CLASSMETHOD(Class, "NameIndexExists", pName)) {
        Set Definition = $CLASSMETHOD(Class, "NameIndexOpen", pName)
    } Else {
        Set Definition = $CLASSMETHOD(Class, "%New")
    }
    Set Definition.Name = pName
    Set Definition.Role = pRole
    Set Definition.SystemPrompt = pSystemPrompt
    Set Definition.DecisionField = pDecisionField
    Set Definition.AllowedDecisions = pAllowedDecisions
    Set Definition.ReviewDecisions = pReviewDecisions
    Return Definition.%Save()
}

}
