/// JSON API for the web UI. The web application requires a JWT: IRIS provides
/// /login, /refresh and /logout, and every route here runs as the signed-in user.
Class Mercurius.API.REST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "utf-8";

Parameter UseSession As Integer = 0;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/agents" Method="GET" Call="ListAgents"/>
  <Route Url="/agents" Method="POST" Call="CreateAgent"/>
  <Route Url="/agents/:name" Method="PUT" Call="UpdateAgent"/>
  <Route Url="/agents/:name/messages" Method="POST" Call="SendMessage"/>
  <Route Url="/tools" Method="GET" Call="ListTools"/>
  <Route Url="/models" Method="GET" Call="ListModels"/>
  <Route Url="/summary" Method="GET" Call="GetSummary"/>
  <Route Url="/executions" Method="GET" Call="ListExecutions"/>
  <Route Url="/conflicts" Method="GET" Call="ListConflicts"/>
  <Route Url="/conflicts/:id" Method="PUT" Call="ReviewConflict"/>
  <Route Url="/proposals" Method="GET" Call="ListProposals"/>
  <Route Url="/proposals/:id" Method="PUT" Call="DecideProposal"/>
  <Route Url="/notifications" Method="GET" Call="ListNotifications"/>
  <Route Url="/knowledge" Method="GET" Call="ListKnowledge"/>
  <Route Url="/memory" Method="GET" Call="ListMemory"/>
</Routes>
}

ClassMethod ListAgents() As %Status
{
    Return ..WriteQuery("SELECT Name, ""Role"", Description, SystemPrompt, Tone, ProviderName, ModelName, DecisionField, AllowedDecisions, ReviewDecisions, InputType, Symbol, FallbackRules, Enabled, (SELECT LIST(ToolKey) FROM Mercurius_Model.AgentToolPermission P WHERE P.AgentName = A.Name) AS Tools FROM Mercurius_Model.AgentDefinition A ORDER BY ID")
}

ClassMethod CreateAgent() As %Status
{
    Set Body = ..ReadBody()
    Return:('$ISOBJECT(Body)) ..Fail(..#HTTP400BADREQUEST, "The request body isn't valid JSON.")
    Set Problem = ##class(Mercurius.Runtime.AgentService).Validate(Body, 1)
    Return:(Problem '= "") ..Fail(..#HTTP400BADREQUEST, Problem)
    If (##class(Mercurius.Model.AgentDefinition).NameIndexExists(Body.name)) {
        Return ..Fail(..#HTTP409CONFLICT, "An agent with that name already exists.")
    }
    Return ..SaveResult(##class(Mercurius.Runtime.AgentService).Save(Body))
}

ClassMethod UpdateAgent(pName As %String) As %Status
{
    Set Body = ..ReadBody()
    Return:('$ISOBJECT(Body)) ..Fail(..#HTTP400BADREQUEST, "The request body isn't valid JSON.")
    If ('##class(Mercurius.Model.AgentDefinition).NameIndexExists(pName)) {
        Return ..Fail(..#HTTP404NOTFOUND, "Agent not found.")
    }
    Set Problem = ##class(Mercurius.Runtime.AgentService).Validate(Body, 0)
    Return:(Problem '= "") ..Fail(..#HTTP400BADREQUEST, Problem)
    Return ..SaveResult(##class(Mercurius.Runtime.AgentService).Save(Body, pName))
}

/// Sends the text through the production and returns the agent's decision.
ClassMethod SendMessage(pName As %String) As %Status
{
    Set Body = ..ReadBody()
    Return:('$ISOBJECT(Body)) ..Fail(..#HTTP400BADREQUEST, "The request body isn't valid JSON.")
    Set Text = $ZSTRIP(Body.text, "<>W")
    Return:(Text = "") ..Fail(..#HTTP400BADREQUEST, "Message text is required.")
    Return:($LENGTH(Text) > 8000) ..Fail(..#HTTP400BADREQUEST, "Messages are limited to 8000 characters.")
    Set Definition = ##class(Mercurius.Model.AgentDefinition).NameIndexOpen(pName, , .SC)
    Return:($$$ISERR(SC)) ..Fail(..#HTTP404NOTFOUND, "Agent not found.")

    Set Request = ##class(Mercurius.Interop.Msg.AgentRequest).%New()
    Set Request.AgentName = pName
    Set Request.EventType = Definition.InputType
    Set Request.Payload = Text
    Set Request.CorrelationId = $EXTRACT(Text, 1, 60)

    Set SC = ##class(Ens.Director).CreateBusinessService("ChatIngress", .Service)
    Return:($$$ISERR(SC)) ..Fail("503 Service Unavailable", "The production isn't running.")
    Set SC = Service.ProcessInput(Request, .Response)
    Return:($$$ISERR(SC)) ..Fail(..#HTTP500INTERNALSERVERERROR, "The agent run failed.")

    Write {
        "executionId":(Response.ExecutionId),
        "agentName":(Response.AgentName),
        "status":(Response.Status),
        "decision":(Response.Decision),
        "needsReview":(Response.NeedsReview = 1),
        "result":(Response.Result),
        "error":(Response.ErrorMessage),
        "engine":(Response.Engine),
        "sessionId":(Response.SessionId)
    }.%ToJSON()
    Return $$$OK
}

ClassMethod ListTools() As %Status
{
    Write ##class(Mercurius.Runtime.ToolRegistry).List().%ToJSON()
    Return $$$OK
}

/// Models per configured provider. ?refresh=1 asks the providers again.
ClassMethod ListModels() As %Status
{
    Write ##class(Mercurius.Runtime.ModelCatalog).Catalog(%request.Get("refresh") = 1).%ToJSON()
    Return $$$OK
}

ClassMethod GetSummary() As %Status
{
    Return ..WriteQuery("SELECT COUNT(*) AS Runs, SUM(CASE WHEN Route = 'Review' THEN 1 ELSE 0 END) AS Review, SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) AS Failed, (SELECT COUNT(*) FROM Mercurius_Model.KnowledgeConflict WHERE Status = 'Open') AS OpenConflicts, (SELECT COUNT(*) FROM Mercurius_Model.AgentToolCall) AS ToolCalls, (SELECT COUNT(*) FROM Mercurius_Model.ActionProposal WHERE Status = 'Proposed') AS PendingActions, SUM(CASE WHEN Engine = 'Rules' THEN 1 ELSE 0 END) AS RuleRuns, SUM(PromptTokens + CompletionTokens) AS Tokens, SUM(CostUSD) AS CostUSD FROM Mercurius_Model.AgentExecution")
}

ClassMethod ListExecutions() As %Status
{
    Return ..WriteAgentQuery("SELECT TOP 100 ExecutionId, AgentName, SourceType, Status, Decision, Route, StartedAt, CompletedAt, InputSummary, OutputSummary, ErrorDetails, InteropSessionId, Engine, ModelName, PromptTokens, CompletionTokens, CostUSD, (SELECT LIST(ToolKey) FROM Mercurius_Model.AgentToolCall T WHERE T.ExecutionId = E.ExecutionId) AS Tools, (SELECT LIST(ActionType || ' ' || Status) FROM Mercurius_Model.ActionProposal A WHERE A.ExecutionId = E.ExecutionId) AS Actions FROM Mercurius_Model.AgentExecution E", "ID DESC")
}

ClassMethod ListConflicts() As %Status
{
    Return ..WriteQuery("SELECT TOP 100 C.ID AS Id, C.AgentName, C.Status, C.Description, C.CreatedAt, C.ReviewedBy, C.ReviewedAt, S.Title AS SourceTitle, S.Content AS SourceContent, T.Title AS TargetTitle, T.Content AS TargetContent FROM Mercurius_Model.KnowledgeConflict C LEFT JOIN Mercurius_Model.KnowledgeNode S ON S.ID = C.SourceNodeId LEFT JOIN Mercurius_Model.KnowledgeNode T ON T.ID = C.TargetNodeId ORDER BY C.ID DESC")
}

ClassMethod ReviewConflict(pId As %String) As %Status
{
    Set Body = ..ReadBody()
    Return:('$ISOBJECT(Body)) ..Fail(..#HTTP400BADREQUEST, "The request body isn't valid JSON.")
    If ('$LISTFIND($LISTBUILD("Reviewed", "Dismissed", "Resolved"), Body.status)) {
        Return ..Fail(..#HTTP400BADREQUEST, "Status must be Reviewed, Dismissed or Resolved.")
    }
    Set Conflict = ##class(Mercurius.Model.KnowledgeConflict).%OpenId(pId)
    Return:('$ISOBJECT(Conflict)) ..Fail(..#HTTP404NOTFOUND, "Conflict not found.")
    Set Conflict.Status = Body.status
    Set Conflict.ReviewedBy = $USERNAME
    Set Conflict.ReviewedAt = $ZDATETIME($HOROLOG, 3)
    Return ..SaveResult(Conflict.%Save())
}

ClassMethod ListProposals() As %Status
{
    Do ##class(Mercurius.Runtime.ActionService).ExpireOld()
    Return ..WriteQuery("SELECT TOP 100 ID AS Id, AgentName, ExecutionId, ActionType, Summary, Payload, Status, CreatedAt, ExpiresAt, DecidedBy, DecidedAt, Result FROM Mercurius_Model.ActionProposal ORDER BY ID DESC")
}

/// Approves or rejects a proposed action. Approval re-checks it, then runs it through the production.
ClassMethod DecideProposal(pId As %String) As %Status
{
    Set Body = ..ReadBody()
    Return:('$ISOBJECT(Body)) ..Fail(..#HTTP400BADREQUEST, "The request body isn't valid JSON.")
    Return:('$LISTFIND($LISTBUILD("Approved", "Rejected"), Body.status)) ..Fail(..#HTTP400BADREQUEST, "Status must be Approved or Rejected.")
    Set Problem = ##class(Mercurius.Runtime.ActionService).Decide(pId, Body.status, $USERNAME)
    Return:(Problem '= "") ..Fail(..#HTTP409CONFLICT, Problem)
    Write {"saved":true}.%ToJSON()
    Return $$$OK
}

ClassMethod ListNotifications() As %Status
{
    Return ..WriteQuery("SELECT TOP 100 AgentName, Message, Channel, ApprovedBy, CreatedAt FROM Mercurius_Model.Notification ORDER BY ID DESC")
}

ClassMethod ListKnowledge() As %Status
{
    Set Agent = %request.Get("agent")
    Write "{""nodes"":"
    Set SC = ..WriteAgentQuery("SELECT TOP 200 ID AS Id, AgentName, Title, NodeType, Content, CreatedAt FROM Mercurius_Model.KnowledgeNode", "ID")
    Return:($$$ISERR(SC)) SC
    Write ",""edges"":"
    Set SC = ..WriteAgentQuery("SELECT TOP 200 AgentName, SourceNodeId, TargetNodeId, RelationshipType FROM Mercurius_Model.KnowledgeEdge", "ID")
    Return:($$$ISERR(SC)) SC
    Write "}"
    Return $$$OK
}

ClassMethod ListMemory() As %Status
{
    Return ..WriteAgentQuery("SELECT TOP 100 AgentName, MemoryType, Content, CreatedAt FROM Mercurius_Model.AgentMemory", "ID DESC")
}

/// Adds the optional agent filter from the query string to a fixed query.
ClassMethod WriteAgentQuery(pQuery As %String, pOrder As %String) As %Status
{
    Set Agent = %request.Get("agent")
    Return:(Agent = "") ..WriteQuery(pQuery_" ORDER BY "_pOrder)
    Return ..WriteQuery(pQuery_" WHERE AgentName = ? ORDER BY "_pOrder, Agent)
}

/// Runs a fixed query and writes the rows as a JSON array. Callers pass constants, and user
/// input only as parameters. Access is controlled by the web application, so the SQL
/// privilege check is skipped.
ClassMethod WriteQuery(pQuery As %String, pArgs...) As %Status
{
    Set Statement = ##class(%SQL.Statement).%New()
    Set Statement.%SelectMode = 1
    Set SC = Statement.%Prepare(pQuery, 0)
    Return:($$$ISERR(SC)) SC
    Set Result = Statement.%Execute(pArgs...)
    Return:(Result.%SQLCODE < 0) $$$ERROR($$$SQLError, Result.%SQLCODE, Result.%Message)
    Set Metadata = Result.%GetMetadata()
    Set Rows = []
    While (Result.%Next()) {
        Set Row = {}
        For Index = 1:1:Metadata.columnCount {
            Do Row.%Set(Metadata.columns.GetAt(Index).colName, Result.%GetData(Index))
        }
        Do Rows.%Push(Row)
    }
    Write Rows.%ToJSON()
    Return $$$OK
}

ClassMethod ReadBody() As %DynamicObject
{
    Try {
        Return ##class(%DynamicObject).%FromJSON(%request.Content)
    } Catch {
        Return ""
    }
}

ClassMethod SaveResult(pStatus As %Status) As %Status
{
    Return:($$$ISERR(pStatus)) ..Fail(..#HTTP400BADREQUEST, "The change couldn't be saved.")
    Write {"saved":true}.%ToJSON()
    Return $$$OK
}

ClassMethod Fail(pHttpStatus As %String, pMessage As %String) As %Status
{
    Set %response.Status = pHttpStatus
    Write {"error":(pMessage)}.%ToJSON()
    Return $$$OK
}

}
