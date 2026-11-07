/// Records where a result was routed. Used for both accepted results and the review queue.
Class Mercurius.Interop.BO.ResultHandler Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method Handle(pRequest As Mercurius.Interop.Msg.AgentResult, Output pResponse As Ens.Response) As %Status
{
    Set Execution = ##class(Mercurius.Model.AgentExecution).ExecutionIdIndexOpen(pRequest.ExecutionId, , .SC)
    Return:($$$ISERR(SC)) SC
    Set Execution.Route = pRequest.Route
    $$$LOGINFO(pRequest.AgentName_" -> "_pRequest.Route_" ("_pRequest.Decision_")")
    Return Execution.%Save()
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Mercurius.Interop.Msg.AgentResult">
    <Method>Handle</Method>
  </MapItem>
</MapItems>
}

}
