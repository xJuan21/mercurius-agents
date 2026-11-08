/// Delivers an approved notification to the in-app inbox.
Class Mercurius.Interop.BO.Notifier Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method Notify(pRequest As Mercurius.Interop.Msg.ActionRequest, Output pResponse As Mercurius.Interop.Msg.ActionResponse) As %Status
{
    Set pResponse = ##class(Mercurius.Interop.Msg.ActionResponse).%New()
    Set Payload = ##class(%DynamicObject).%FromJSON(pRequest.Payload)
    Set Entry = ##class(Mercurius.Model.Notification).%New()
    Set Entry.AgentName = pRequest.AgentName
    Set Entry.Message = Payload.message
    Set Entry.ProposalId = pRequest.ProposalId
    Set Entry.ApprovedBy = pRequest.ApprovedBy
    Set SC = Entry.%Save()
    Return:($$$ISERR(SC)) SC
    Set pResponse.Done = 1
    Set pResponse.Result = "Delivered to the inbox"
    Return $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Mercurius.Interop.Msg.ActionRequest">
    <Method>Notify</Method>
  </MapItem>
</MapItems>
}

}
