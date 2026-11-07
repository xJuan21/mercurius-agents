/// Creates the sample agents.
Class Mercurius.Setup Extends %RegisteredObject
{

/// Called by IPM on install: seeds the agents and starts the production with the instance.
ClassMethod Install() As %Status
{
    Set SC = ..SeedAgents()
    Return:($$$ISERR(SC)) SC
    Set SC = ..CreateWebApp()
    Return:($$$ISERR(SC)) SC
    Return ##class(Ens.Director).SetAutoStart("Mercurius.Interop.Production")
}

/// Creates the read-only dashboard at /mercurius/.
ClassMethod CreateWebApp() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    Set Role = "MercuriusReader"
    If ('##class(Security.Roles).Exists(Role)) {
        Set SC = ##class(Security.Roles).Create(Role, "Read-only Mercurius dashboard", "%DB_IRISAPP_DATA:R,%DB_IRISAPP_CODE:R")
        Return:($$$ISERR(SC)) SC
    }
    Return:(##class(Security.Applications).Exists("/mercurius")) $$$OK
    Set Properties("NameSpace") = "IRISAPP"
    Set Properties("DispatchClass") = "Mercurius.API.REST"
    Set Properties("AutheEnabled") = 64
    Set Properties("MatchRoles") = ":"_Role
    Set Properties("Enabled") = 1
    Return ##class(Security.Applications).Create("/mercurius", .Properties)
}

ClassMethod SeedAgents() As %Status
{
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/documents")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/alerts")
    Set SC = ..SaveAgent("Documenter", "Documentation review", "You guard technical documentation. Each new note is already saved and its node id is given. Use SearchKnowledge with its key terms and ignore the new node itself in the results. Only use ids returned by SearchKnowledge. Choose exactly one decision. conflict: the new note and an existing node make incompatible claims about the same subject, so both cannot be true; use FlagConflict with the new node first. related: an existing node covers the same subject and the new note adds to it without contradicting it, for example an extra step or detail; use CreateRelationship with the new node first and RELATES_TO. none: no existing node covers the same subject, even if search returned results; a shared word is not enough; use no other tool. Your finding is a proposal for a person, not a fact. Finish by replying only with JSON: {""decision"":""related|conflict|none"",""reason"":""one sentence""}", "decision", "related,conflict,none", "conflict")
    Return:($$$ISERR(SC)) SC
    Set SC = ..SaveAgent("Sentinel", "Operational alerts", "You assess operational events. Use SearchKnowledge for known issues first. Then reply only with JSON: {""severity"":""low|medium|high"",""action"":""one sentence""}", "severity", "low,medium,high", "high")
    Return:($$$ISERR(SC)) SC
    For Tool = "SearchKnowledge", "CreateRelationship", "FlagConflict", "GetAgentMemory", "SaveAgentMemory" {
        Set SC = ..Grant("Documenter", Tool)
        Return:($$$ISERR(SC)) SC
    }
    Set SC = ..Grant("Sentinel", "SearchKnowledge")
    Return:($$$ISERR(SC)) SC
    Return ..ResetKnowledge()
}

ClassMethod Grant(pAgentName As %String, pToolKey As %String) As %Status
{
    Return:(##class(Mercurius.Model.AgentToolPermission).AgentToolIndexExists(pAgentName, pToolKey)) $$$OK
    Set Permission = ##class(Mercurius.Model.AgentToolPermission).%New()
    Set Permission.AgentName = pAgentName
    Set Permission.ToolKey = pToolKey
    Return Permission.%Save()
}

/// Restores the sample knowledge used by the demo.
ClassMethod ResetKnowledge() As %Status
{
    Do ##class(Mercurius.Model.KnowledgeNode).%KillExtent()
    Do ##class(Mercurius.Model.KnowledgeEdge).%KillExtent()
    Do ##class(Mercurius.Model.KnowledgeConflict).%KillExtent()
    Do ##class(Mercurius.Model.AgentMemory).%KillExtent()
    Set Service = "Mercurius.Runtime.KnowledgeService"
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "WhatsApp webhook runbook", "The WhatsApp webhook is exposed publicly through Tailscale Funnel.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "IRIS backup policy", "Journals and databases on iris01 are backed up nightly.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Return $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Known issue: disk alerts", "Disk alerts on iris-dev usually mean journal growth.", "Issue", .NodeId)
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
