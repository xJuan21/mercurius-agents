/// Runs the agent, then routes on its validated decision.
Class Mercurius.Interop.BP.AgentWorkflow Extends Ens.BusinessProcess [ ClassType = persistent ]
{

Method OnRequest(pRequest As Mercurius.Interop.Msg.AgentRequest, Output pResponse As Ens.Response) As %Status
{
    Return ..SendRequestAsync("AgentRunner", pRequest, 1, "agent")
}

Method OnResponse(pRequest As Ens.Request, ByRef pResponse As Ens.Response, pCallRequest As Ens.Request, pCallResponse As Ens.Response, pCompletionKey As %String) As %Status
{
    Return:(pCompletionKey '= "agent") $$$OK
    Set pResponse = pCallResponse

    Set Result = ##class(Mercurius.Interop.Msg.AgentResult).%New()
    Set Result.ExecutionId = pCallResponse.ExecutionId
    Set Result.AgentName = pCallResponse.AgentName
    Set Result.Decision = pCallResponse.Decision
    Set Result.Result = pCallResponse.Result
    Set Result.Route = $SELECT(pCallResponse.NeedsReview:"Review", 1:"Accepted")
    Set Target = $SELECT(pCallResponse.NeedsReview:"ReviewQueue", 1:"ResultHandler")
    Return ..SendRequestAsync(Target, Result, 0)
}

}
