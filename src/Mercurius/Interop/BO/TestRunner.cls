/// Runs approved unit tests in a throwaway namespace and posts the result to the inbox.
Class Mercurius.Interop.BO.TestRunner Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method Run(pRequest As Mercurius.Interop.Msg.ActionRequest, Output pResponse As Mercurius.Interop.Msg.ActionResponse) As %Status
{
    Set pResponse = ##class(Mercurius.Interop.Msg.ActionResponse).%New()
    Set Payload = ##class(%DynamicObject).%FromJSON(pRequest.Payload)
    // Run checks the code again, so a class that changed since the proposal is caught here.
    Set SC = ##class(Mercurius.Runtime.TestSandbox).Run(Payload.className, Payload.code, 1, .Summary)
    Return:($$$ISERR(SC)) SC
    If (Summary.problem '= "") {
        Set pResponse.Result = Summary.problem
        Return $$$OK
    }
    Set Text = Payload.className_": "_Summary.passed_" passed, "_Summary.failed_" failed."
    Set Iterator = Summary.failures.%GetIterator()
    While (Iterator.%GetNext(.Index, .Failure)) {
        Set Text = Text_" "_Failure_"."
    }
    Set Entry = ##class(Mercurius.Model.Notification).%New()
    Set Entry.AgentName = pRequest.AgentName
    Set Entry.Message = $EXTRACT(Text, 1, 500)
    Set Entry.ProposalId = pRequest.ProposalId
    Set Entry.ApprovedBy = pRequest.ApprovedBy
    Set SC = Entry.%Save()
    Return:($$$ISERR(SC)) SC
    Set pResponse.Done = 1
    Set pResponse.Result = $EXTRACT(Text, 1, 2000)
    Return $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Mercurius.Interop.Msg.ActionRequest">
    <Method>Run</Method>
  </MapItem>
</MapItems>
}

}
