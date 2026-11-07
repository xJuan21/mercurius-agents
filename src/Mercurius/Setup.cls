/// Creates the sample agents, the sample knowledge and the web applications.
Class Mercurius.Setup Extends %RegisteredObject
{

/// Called by IPM on install: seeds the agents and starts the production with the instance.
ClassMethod Install() As %Status
{
    Set SC = ..SeedAgents()
    Return:($$$ISERR(SC)) SC
    Set SC = ..CreateWebApps()
    Return:($$$ISERR(SC)) SC
    Return ##class(Ens.Director).SetAutoStart("Mercurius.Interop.Production")
}

/// Creates /mercurius for the web files, which hold no data, and /mercurius/api for the token-protected API.
ClassMethod CreateWebApps() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    Set Resource = "MercuriusAccess"
    Set Role = "MercuriusUser"
    Set WebRole = "MercuriusWeb"
    If ('##class(Security.Resources).Exists(Resource)) {
        Set SC = ##class(Security.Resources).Create(Resource, "Sign in to Mercurius Agents", "", "")
        Return:($$$ISERR(SC)) SC
    }
    If ('##class(Security.Roles).Exists(Role)) {
        Set SC = ##class(Security.Roles).Create(Role, "Use Mercurius Agents", Resource_":U,%DB_IRISAPP_DATA:RW,%DB_IRISAPP_CODE:R")
        Return:($$$ISERR(SC)) SC
    }

    If ('##class(Security.Roles).Exists(WebRole)) {
        Set SC = ##class(Security.Roles).Create(WebRole, "Serve the Mercurius web files", "%DB_IRISAPP_CODE:R,%DB_IRISAPP_DATA:R")
        Return:($$$ISERR(SC)) SC
    }

    Do:(##class(Security.Applications).Exists("/mercurius")) ##class(Security.Applications).Delete("/mercurius")
    Set Properties("NameSpace") = "IRISAPP"
    Set Properties("DispatchClass") = "Mercurius.API.Web"
    Set Properties("AutheEnabled") = 64
    Set Properties("MatchRoles") = ":"_WebRole
    Set Properties("Enabled") = 1
    Set SC = ##class(Security.Applications).Create("/mercurius", .Properties)
    Return:($$$ISERR(SC)) SC

    Do:(##class(Security.Applications).Exists("/mercurius/api")) ##class(Security.Applications).Delete("/mercurius/api")
    Kill Properties
    Set Properties("NameSpace") = "IRISAPP"
    Set Properties("DispatchClass") = "Mercurius.API.REST"
    Set Properties("AutheEnabled") = 32
    Set Properties("Resource") = Resource
    Set Properties("MatchRoles") = ":"_Role
    Set Properties("Enabled") = 1
    Set Properties("JWTAuthEnabled") = 1
    Set Properties("JWTAccessTokenTimeout") = 900
    Set Properties("JWTRefreshTokenTimeout") = 28800
    Return ##class(Security.Applications).Create("/mercurius/api", .Properties)
}

ClassMethod SeedAgents() As %Status
{
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/documents")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/alerts")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/code")

    Set Prompt = "You guard technical documentation. Each new note is already saved and its node id is given. Use SearchKnowledge with its key terms and ignore the new node itself in the results. Only use ids returned by SearchKnowledge. Choose exactly one decision. conflict: the new note and an existing node make incompatible claims about the same subject, so both cannot be true; use FlagConflict with the new node first. related: an existing node covers the same subject and the new note adds to it without contradicting it, for example an extra step or detail; use CreateRelationship with the new node first and RELATES_TO. none: no existing node covers the same subject, even if search returned results; a shared word is not enough; use no other tool. Your finding is a proposal for a person, not a fact. In your reason, refer to notes by their titles or subjects, never by node ids."
    Set SC = ..SaveAgent("Documenter", "Knowledge and documentation", "I connect the dots in your knowledge. I organize notes, surface relationships and flag contradictions so nothing gets lost.", Prompt, "Clear and thoughtful", "related,conflict,none", "conflict", "Document", "memory")
    Return:($$$ISERR(SC)) SC

    Set Prompt = "You assess operational events. Use SearchKnowledge for known issues first, then rate the severity."
    Set SC = ..SaveAgent("Sentinel", "Monitoring and diagnostics", "I help you understand operational alerts, assess their severity and identify what needs your attention.", Prompt, "Direct and concise", "low,medium,high", "high", "Event", "shield", "severity")
    Return:($$$ISERR(SC)) SC

    Set Prompt = "You review code and implementation plans. Use SearchKnowledge for the team's coding standards first. ready: it follows the standards. changes: it breaks a standard or has a defect you can name. blocked: it is unsafe or can't work as written. Name the specific problem in your reason."
    Set SC = ..SaveAgent("Forge", "Builder and code assistant", "I help you explore implementation ideas, review code and turn a technical plan into clear next steps.", Prompt, "Precise and technical", "ready,changes,blocked", "changes,blocked", "Event", "agents")
    Return:($$$ISERR(SC)) SC

    For Tool = "SearchKnowledge", "CreateRelationship", "FlagConflict", "GetAgentMemory", "SaveAgentMemory" {
        Set SC = ..Grant("Documenter", Tool)
        Return:($$$ISERR(SC)) SC
    }
    For Agent = "Sentinel", "Forge" {
        Set SC = ..Grant(Agent, "SearchKnowledge")
        Return:($$$ISERR(SC)) SC
    }
    Return ..ResetKnowledge()
}

ClassMethod SaveAgent(pName As %String, pRole As %String, pDescription As %String, pSystemPrompt As %String, pTone As %String, pAllowedDecisions As %String, pReviewDecisions As %String, pInputType As %String, pSymbol As %String, pDecisionField As %String = "decision") As %Status
{
    Set Class = "Mercurius.Model.AgentDefinition"
    If ($CLASSMETHOD(Class, "NameIndexExists", pName)) {
        Set Definition = $CLASSMETHOD(Class, "NameIndexOpen", pName)
    } Else {
        Set Definition = $CLASSMETHOD(Class, "%New")
    }
    Set Definition.Name = pName
    Set Definition.Role = pRole
    Set Definition.Description = pDescription
    Set Definition.SystemPrompt = pSystemPrompt
    Set Definition.Tone = pTone
    Set Definition.DecisionField = pDecisionField
    Set Definition.AllowedDecisions = pAllowedDecisions
    Set Definition.ReviewDecisions = pReviewDecisions
    Set Definition.InputType = pInputType
    Set Definition.Symbol = pSymbol
    Return Definition.%Save()
}

ClassMethod Grant(pAgentName As %String, pToolKey As %String) As %Status
{
    Return:(##class(Mercurius.Model.AgentToolPermission).AgentToolIndexExists(pAgentName, pToolKey)) $$$OK
    Set Permission = ##class(Mercurius.Model.AgentToolPermission).%New()
    Set Permission.AgentName = pAgentName
    Set Permission.ToolKey = pToolKey
    Return Permission.%Save()
}

/// Restores the sample knowledge and memory used by the demo.
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
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Known issue: disk alerts", "Disk alerts on iris-dev usually mean journal growth.", "Issue", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Forge", "ObjectScript style", "Commands use UpperCamelCase, such as Set and Write, never abbreviations. Variables use UpperCamelCase. Postconditionals are always in parentheses.", "Concept", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Documenter", "The team prefers concise notes with explicit next steps.", "Preference")
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Sentinel", "Page a person for journal failures, even outside working hours.", "Preference")
    Return:($$$ISERR(SC)) SC
    Return $CLASSMETHOD(Service, "SaveMemory", "Forge", "Reviews should name the exact rule that was broken.", "Preference")
}

}
