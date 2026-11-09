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
    // IPM holds the Interoperability lock while installing, so the production can't start
    // here. It starts with IRIS, or with Ens.Director.StartProduction after an IPM install.
    Return ##class(Ens.Director).SetAutoStart("Mercurius.Interop.Production")
}

/// Creates /mercurius for the web files, which hold no data, and /mercurius/api for the token-protected API.
ClassMethod CreateWebApps() As %Status
{
    Set Namespace = $NAMESPACE
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    // The roles need the resources of whichever namespace the package is installed into.
    Set SC = ..DatabaseResource(Namespace, "Routines", .CodeResource)
    Return:($$$ISERR(SC)) SC
    Set SC = ..DatabaseResource(Namespace, "Globals", .DataResource)
    Return:($$$ISERR(SC)) SC
    Set Resource = "MercuriusAccess"
    Set Role = "MercuriusUser"
    Set WebRole = "MercuriusWeb"
    If ('##class(Security.Resources).Exists(Resource)) {
        Set SC = ##class(Security.Resources).Create(Resource, "Sign in to Mercurius Agents", "", "")
        Return:($$$ISERR(SC)) SC
    }
    If ('##class(Security.Roles).Exists(Role)) {
        Set SC = ##class(Security.Roles).Create(Role, "Use Mercurius Agents", Resource_":U,"_DataResource_":RW"_$SELECT(CodeResource '= DataResource:","_CodeResource_":R", 1:""))
        Return:($$$ISERR(SC)) SC
    }

    If ('##class(Security.Roles).Exists(WebRole)) {
        Set SC = ##class(Security.Roles).Create(WebRole, "Serve the Mercurius web files", DataResource_":R"_$SELECT(CodeResource '= DataResource:","_CodeResource_":R", 1:""))
        Return:($$$ISERR(SC)) SC
    }

    Do:(##class(Security.Applications).Exists("/mercurius")) ##class(Security.Applications).Delete("/mercurius")
    Set Properties("NameSpace") = Namespace
    Set Properties("DispatchClass") = "Mercurius.API.Web"
    Set Properties("AutheEnabled") = 64
    Set Properties("MatchRoles") = ":"_WebRole
    Set Properties("Enabled") = 1
    Set SC = ##class(Security.Applications).Create("/mercurius", .Properties)
    Return:($$$ISERR(SC)) SC

    Do:(##class(Security.Applications).Exists("/mercurius/api")) ##class(Security.Applications).Delete("/mercurius/api")
    Kill Properties
    Set Properties("NameSpace") = Namespace
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

/// Returns the resource that protects the namespace's code or data database. Run in %SYS.
ClassMethod DatabaseResource(pNamespace As %String, pKind As %String, Output pResource As %String) As %Status
{
    Set pResource = ""
    Set SC = ##class(Config.Namespaces).Get(pNamespace, .Namespace)
    Return:($$$ISERR(SC)) SC
    Set SC = ##class(Config.Databases).Get(Namespace(pKind), .Database)
    Return:($$$ISERR(SC)) SC
    Set Handle = ##class(SYS.Database).%OpenId(Database("Directory"), , .SC)
    Return:($$$ISERR(SC)) SC
    Set pResource = Handle.ResourceName
    Return $$$OK
}

ClassMethod SeedAgents() As %Status
{
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/documents")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/alerts")
    Do ##class(%File).CreateDirectoryChain("/home/irisowner/inbox/code")

    Set Prompt = "You guard technical documentation. Each new note is already saved and its node id is given. Use SearchKnowledge with its key terms and ignore the new node itself in the results. Only use ids returned by SearchKnowledge. Choose exactly one decision. conflict: the new note and an existing node make incompatible claims about the same subject, so both cannot be true. A note saying something changed, was replaced, stopped or now works differently (now, instead of, no longer, only) conflicts with an older node that describes the old way, even if it sounds like an update. But when the old way still applies and something is added to it (in addition to, also, plus), that is related, not a conflict; use FlagConflict with the new node first. related: an existing node covers the same subject and the new note adds to it without contradicting it, for example an extra step or detail; use CreateRelationship with the new node first and RELATES_TO. none: no existing node covers the same subject, even if search returned results; a shared word is not enough; use no other tool. Your finding is a proposal for a person, not a fact. In your reason, refer to notes by their titles or subjects, never by node ids. When you find a conflict, also use ProposeKnowledgeUpdate on the older note with corrected content, so a person can approve the fix."
    Set SC = ..SaveAgent("Documenter", "Knowledge and documentation", "I connect the dots in your knowledge. I organize notes, surface relationships and flag contradictions so nothing gets lost.", Prompt, "Clear and thoughtful", "related,conflict,none", "conflict", "Document", "memory", ..Lines("instead of => conflict", "no longer => conflict", "replaced => conflict", "in addition to => related", "also => related"))
    Return:($$$ISERR(SC)) SC

    Set Prompt = "You assess operational events. Use SearchKnowledge for known issues first, then rate the severity. high: a service is down or data is at risk right now. medium: something is degraded, or a problem is expected soon but nothing is failing yet. low: routine or informational. When the severity is high, use ProposeNotification with one short sentence for the person on call."
    Set SC = ..SaveAgent("Sentinel", "Monitoring and diagnostics", "I help you understand operational alerts, assess their severity and identify what needs your attention.", Prompt, "Direct and concise", "low,medium,high", "high", "Event", "shield", ..Lines("failing => high", "failed => high", "down => high", "full => high", "expires => medium", "percent => medium", "finished => low", "completed => low", "succeeded => low"), "severity")
    Return:($$$ISERR(SC)) SC

    Set Prompt = "You review ObjectScript against the team's coding standards. Use CheckSyntax on the code first: a syntax error always means changes, unless the code is unsafe. Then use SearchKnowledge for the standards and the review checklist. ready: no standard is broken and nothing is unsafe; short or simple code is fine. changes: it breaks a specific standard, such as a lowercase or abbreviated command, a lowercase variable, or a postconditional without parentheses. blocked: it deletes or exposes data, runs arbitrary input or operating system commands, or stores a password or secret in plain text; this outranks changes. Name the specific problem in your reason."
    Set SC = ..SaveAgent("Forge", "Builder and code assistant", "I help you explore implementation ideas, review code and turn a technical plan into clear next steps.", Prompt, "Precise and technical", "ready,changes,blocked", "changes,blocked", "Event", "agents", ..Lines("kill ^ => blocked", "xecute => blocked", "$zf( => blocked", "set x= => changes", "$get( => changes"))
    Return:($$$ISERR(SC)) SC
    // gpt-4.1-mini misjudged valid code and missed conflicts in the measured runs, so these
    // two agents default to gpt-4.1. Users can change the model in the agent form.
    For Name = "Forge", "Documenter" {
        Set Agent = ##class(Mercurius.Model.AgentDefinition).NameIndexOpen(Name)
        Set Agent.ModelName = "gpt-4.1"
        Set SC = Agent.%Save()
        Return:($$$ISERR(SC)) SC
    }

    For Tool = "SearchKnowledge", "CreateRelationship", "FlagConflict", "GetAgentMemory", "SaveAgentMemory", "ProposeKnowledgeUpdate" {
        Set SC = ..Grant("Documenter", Tool)
        Return:($$$ISERR(SC)) SC
    }
    Set SC = ..Grant("Forge", "CheckSyntax")
    Return:($$$ISERR(SC)) SC

    Set Prompt = "You turn questions about the Mercurius data into one InterSystems IRIS SQL SELECT. Use SearchKnowledge for the data guide and DescribeSchema with Mercurius_Model first. Use the exact values the data guide lists; they are case-sensitive. Write the query, then use CheckSQL and fix it until it's valid. Never write statements that change data. ready: CheckSQL says the query is valid; put the SQL in output. clarify: the question is vague, or asks for something the data doesn't hold, such as revenue or sales; never guess a meaning; say what's missing. refused: it asks to change or delete data, or to read data outside that schema."
    Set SC = ..SaveAgent("Query", "SQL generator", "I turn your questions into SQL for the Mercurius data, and I check every query before you see it. I never run or change anything.", Prompt, "Precise and technical", "ready,clarify,refused", "clarify,refused", "Event", "graph", ..Lines("delete => refused", "update => refused", "drop => refused", "insert => refused"))
    Return:($$$ISERR(SC)) SC
    For Tool = "SearchKnowledge", "DescribeSchema", "CheckSQL" {
        Set SC = ..Grant("Query", Tool)
        Return:($$$ISERR(SC)) SC
    }

    For Agent = "Sentinel", "Forge" {
        Set SC = ..Grant(Agent, "SearchKnowledge")
        Return:($$$ISERR(SC)) SC
    }
    Set SC = ..Grant("Sentinel", "ProposeNotification")
    Return:($$$ISERR(SC)) SC
    Return ..ResetKnowledge()
}

ClassMethod SaveAgent(pName As %String, pRole As %String, pDescription As %String, pSystemPrompt As %String, pTone As %String, pAllowedDecisions As %String, pReviewDecisions As %String, pInputType As %String, pSymbol As %String, pFallbackRules As %String, pDecisionField As %String = "decision") As %Status
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
    Set Definition.ProviderName = "openai"
    Set Definition.ModelName = "gpt-4.1-mini"
    Set Definition.Enabled = 1
    Set Definition.FallbackRules = pFallbackRules
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

/// Restores a public demo to its starting state: removes agents and runs that visitors
/// created, and resets the sample agents, knowledge and memory.
ClassMethod ResetDemo() As %Status
{
    Set Seeded = $LISTBUILD("Documenter", "Sentinel", "Forge", "Query")
    Set Statement = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, Name FROM Mercurius_Model.AgentDefinition")
    While (Statement.%Next()) {
        Continue:($LISTFIND(Seeded, Statement.Name))
        Set Name = Statement.Name
        &sql(DELETE FROM Mercurius_Model.AgentToolPermission WHERE AgentName = :Name)
        Do ##class(Mercurius.Model.AgentDefinition).%DeleteId(Statement.ID)
    }
    Do ##class(Mercurius.Model.AgentExecution).%KillExtent()
    Do ##class(Mercurius.Model.AgentToolCall).%KillExtent()
    Return ..SeedAgents()
}

/// Restores the sample knowledge and memory used by the demo.
ClassMethod ResetKnowledge() As %Status
{
    Do ##class(Mercurius.Model.KnowledgeNode).%KillExtent()
    Do ##class(Mercurius.Model.KnowledgeEdge).%KillExtent()
    Do ##class(Mercurius.Model.KnowledgeConflict).%KillExtent()
    Do ##class(Mercurius.Model.AgentMemory).%KillExtent()
    Do ##class(Mercurius.Model.ActionProposal).%KillExtent()
    Do ##class(Mercurius.Model.Notification).%KillExtent()
    Set Service = "Mercurius.Runtime.KnowledgeService"
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "Partner orders runbook", "Partner orders arrive by SFTP every hour and are picked up by the file service.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "IRIS backup policy", "Journals and databases on the production server are backed up nightly.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "TLS certificate renewal", "TLS certificates on the web gateway are renewed manually every 90 days.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Documenter", "Restarting the production", "Restart the Mercurius production from the Management Portal. Never kill IRIS processes directly.", "Document", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Known issue: disk alerts", "Disk alerts on the production server usually mean journal growth.", "Issue", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Forge", "ObjectScript style", "Commands are full words in UpperCamelCase: Set, Do, Write, Quit, Return, Kill. Never lowercase and never abbreviated, so set, s, w, d and q are wrong. Variables use UpperCamelCase, so Total is right and total or x are wrong. A postconditional is always in parentheses: Set:(Count > 0) is right and Set:Count>0 is wrong. These lines follow every rule: Set Count = 0; Do ..Save(Record); Write Count, !; Quit:(Done = 1) Result.", "Concept", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Documenter", "The team prefers concise notes with explicit next steps.", "Preference")
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Sentinel", "Page a person for journal failures, even outside working hours.", "Preference")
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Forge", "ObjectScript review checklist", "From the objectscript-review skill in iris-agentic-dev (InterSystems, MIT License). No Quit with a value inside Try/Catch or loops. Intra-class calls use ..Method() syntax. Error handling uses $$$ThrowOnError, $$$ISERR and $$$ISOK. Never throw a %Status directly; use exception objects. Complex arithmetic has explicit parentheses. A method rolls back only its own transaction level. No New on a plain variable inside a procedure block. %TimeStamp values use YYYY-MM-DD HH:MM:SS. No temporary data in globals when locals suffice. Never edit Storage blocks by hand.", "Concept", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveNode", "Query", "Data guide", "Mercurius data, schema Mercurius_Model. AgentExecution is one agent run: AgentName, Decision, Status ('Completed' or 'Failed'), Route ('Accepted' or 'Review'; sent to review means Route = 'Review'), Engine ('AI' or 'Rules'), ModelName, PromptTokens, CompletionTokens, CostUSD (estimated AI cost of the run, not revenue), StartedAt. KnowledgeConflict is a possible contradiction: AgentName, Status ('Open', 'Reviewed', 'Dismissed' or 'Resolved'), Description, CreatedAt. AgentToolPermission says which agent may use which tool: AgentName, ToolKey, such as 'ProposeNotification'. AgentDefinition is an agent: Name, Role, ModelName, Enabled. ActionProposal is a proposed action: AgentName, ActionType ('Notify' or 'UpdateKnowledge'), Status ('Proposed', 'Rejected', 'Executed', 'Failed' or 'Expired'). The data holds no sales, revenue or customer information.", "Concept", .NodeId)
    Return:($$$ISERR(SC)) SC
    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Query", "People mostly ask about runs, decisions, conflicts and costs.", "Preference")
    Return:($$$ISERR(SC)) SC
    Return $CLASSMETHOD(Service, "SaveMemory", "Forge", "Reviews should name the exact rule that was broken.", "Preference")
}

/// Joins rules into the one-rule-per-line format.
ClassMethod Lines(pRules... As %String) As %String
{
    Set Text = ""
    For Index = 1:1:$GET(pRules) {
        Set Text = Text_$SELECT(Text = "":"", 1:$CHAR(10))_pRules(Index)
    }
    Return Text
}

}
