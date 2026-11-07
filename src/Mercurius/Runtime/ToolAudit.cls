/// Writes each tool call to AgentToolCall, linked to the execution.
Class Mercurius.Runtime.ToolAudit Extends %AI.Policy.Audit
{

Property AgentName As %String(MAXLEN = 100);

Property ExecutionId As %String(MAXLEN = 50);

Method %LogExecution(call As %DynamicObject, metadata As %DynamicObject, result As %DynamicObject, duration As %Integer, status As %Status) As %Status
{
    Return ..Record(call, $SELECT($$$ISOK(status):"Completed", 1:"Failed"), result)
}

Method %LogDenial(call As %DynamicObject, metadata As %DynamicObject, status As %Status) As %Status
{
    Return ..Record(call, "Denied")
}

Method Record(pCall As %DynamicObject, pOutcome As %String, pResult As %DynamicObject = "") As %Status
{
    Set Entry = ##class(Mercurius.Model.AgentToolCall).%New()
    Set Entry.ExecutionId = ..ExecutionId
    Set Entry.AgentName = ..AgentName
    Set Entry.ToolKey = pCall.name
    Set Entry.Arguments = $EXTRACT(pCall.%ToJSON(), 1, 2000)
    Set Entry.Outcome = pOutcome
    Set:($ISOBJECT(pResult)) Entry.ResultPreview = $EXTRACT(pResult.%ToJSON(), 1, 500)
    Return Entry.%Save()
}

}
