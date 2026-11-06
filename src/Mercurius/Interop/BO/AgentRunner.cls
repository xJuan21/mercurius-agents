/// Calls the agent runtime. A failed run is a result to record, not a message to retry.
Class Mercurius.Interop.BO.AgentRunner Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method Run(pRequest As Mercurius.Interop.Msg.AgentRequest, Output pResponse As Mercurius.Interop.Msg.AgentResponse) As %Status
{
    Set pResponse = ##class(Mercurius.Interop.Msg.AgentResponse).%New()
    Set pResponse.AgentName = pRequest.AgentName
    Set pResponse.ExecutionId = $SYSTEM.Util.CreateGUID()
    Set pResponse.NeedsReview = 1

    Set Execution = ##class(Mercurius.Model.AgentExecution).%New()
    Set Execution.ExecutionId = pResponse.ExecutionId
    Set Execution.AgentName = pRequest.AgentName
    Set Execution.SourceType = pRequest.EventType
    Set Execution.Status = "Running"
    Set Execution.StartedAt = $ZDATETIME($HOROLOG, 3)
    Set Execution.InputSummary = $EXTRACT(pRequest.Payload, 1, 500)
    Set Execution.InteropSessionId = ..%SessionId
    Set SC = Execution.%Save()
    Return:($$$ISERR(SC)) SC

    Set Input = pRequest.Payload
    If (pRequest.EventType = "Document") {
        Set SC = ##class(Mercurius.Runtime.KnowledgeService).SaveNode(pRequest.AgentName, pRequest.CorrelationId, pRequest.Payload, "Document", .NodeId)
        Set:($$$ISOK(SC)) Input = "New note, already saved as node "_NodeId_":"_$CHAR(10)_pRequest.Payload
    }
    Set:($$$ISOK(SC)) SC = ##class(Mercurius.Runtime.AgentExecutor).Execute(pRequest.AgentName, Input, .Reply, pResponse.ExecutionId)
    If ($$$ISOK(SC)) {
        Set SC = ##class(Mercurius.Runtime.DecisionPolicy).Evaluate(pRequest.AgentName, Reply, .Decision, .NeedsReview)
    }
    If ($$$ISOK(SC)) {
        Set pResponse.Status = "Completed"
        Set pResponse.Result = Reply
        Set pResponse.Decision = Decision
        Set pResponse.NeedsReview = NeedsReview
    } Else {
        Set pResponse.Status = "Failed"
        Set pResponse.ErrorMessage = $SYSTEM.Status.GetErrorText(SC)
        $$$LOGWARNING("Agent run failed: "_pResponse.ErrorMessage)
    }

    Set Execution.Status = pResponse.Status
    Set Execution.Decision = pResponse.Decision
    Set Execution.OutputSummary = pResponse.Result
    Set Execution.ErrorDetails = pResponse.ErrorMessage
    Set Execution.CompletedAt = $ZDATETIME($HOROLOG, 3)
    Return Execution.%Save()
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Mercurius.Interop.Msg.AgentRequest">
    <Method>Run</Method>
  </MapItem>
</MapItems>
}

}
