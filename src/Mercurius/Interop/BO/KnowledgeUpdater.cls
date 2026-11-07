/// Applies an approved knowledge update, unless the note changed after the proposal.
Class Mercurius.Interop.BO.KnowledgeUpdater Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method Apply(pRequest As Mercurius.Interop.Msg.ActionRequest, Output pResponse As Mercurius.Interop.Msg.ActionResponse) As %Status
{
    Set pResponse = ##class(Mercurius.Interop.Msg.ActionResponse).%New()
    Set Payload = ##class(%DynamicObject).%FromJSON(pRequest.Payload)
    Set Node = ##class(Mercurius.Model.KnowledgeNode).%OpenId(Payload.nodeId, 4)
    If ('$ISOBJECT(Node) || (Node.AgentName '= pRequest.AgentName)) {
        Set pResponse.Result = "The note no longer exists or belongs to another agent."
        Return $$$OK
    }
    If (Node.Content '= Payload.before) {
        Set pResponse.Result = "The note changed after the proposal, so it wasn't updated."
        Return $$$OK
    }
    Set Node.Content = Payload.after
    Set SC = Node.%Save()
    Return:($$$ISERR(SC)) SC
    Set pResponse.Done = 1
    Set pResponse.Result = "Note updated"
    Return $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Mercurius.Interop.Msg.ActionRequest">
    <Method>Apply</Method>
  </MapItem>
</MapItems>
}

}
