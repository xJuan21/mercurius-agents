/// Picks up files and sends each one to the configured stored agent.
Class Mercurius.Interop.BS.DocumentIngress Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

Parameter SETTINGS = "AgentName:Basic,EventType:Basic,TargetConfigName:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Property AgentName As %String(MAXLEN = 100);

Property EventType As %String(MAXLEN = 50) [ InitialExpression = "Document" ];

Property TargetConfigName As %String(MAXLEN = 100) [ InitialExpression = "AgentWorkflow" ];

Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %RegisteredObject) As %Status
{
    Set Payload = pInput.Read(3000000)
    If ($ZSTRIP(Payload, "<>WC") = "") {
        Return $$$ERROR($$$GeneralError, "Empty file ignored: "_pInput.Attributes("Filename"))
    }
    Set Request = ##class(Mercurius.Interop.Msg.AgentRequest).%New()
    Set Request.AgentName = ..AgentName
    Set Request.EventType = ..EventType
    Set Request.Payload = Payload
    Set Request.CorrelationId = ##class(%File).GetFilename(pInput.Attributes("Filename"))
    Return ..SendRequestAsync(..TargetConfigName, Request)
}

}
