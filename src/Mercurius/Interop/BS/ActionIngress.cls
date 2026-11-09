/// Runs approved actions. Each action type goes to its own operation, so a deployment can
/// point NotifyTarget at another channel without changing code.
Class Mercurius.Interop.BS.ActionIngress Extends Ens.BusinessService
{

Parameter ADAPTER;

Parameter SETTINGS = "NotifyTarget:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Property NotifyTarget As %String(MAXLEN = 100) [ InitialExpression = "Notifier" ];

Method OnProcessInput(pInput As Mercurius.Interop.Msg.ActionRequest, Output pOutput As Mercurius.Interop.Msg.ActionResponse) As %Status
{
    Set Target = $CASE(pInput.ActionType, "Notify":..NotifyTarget, "UpdateKnowledge":"KnowledgeUpdater", "RunTests":"TestRunner", :"")
    Return:(Target = "") $$$ERROR($$$GeneralError, "Unknown action type: "_pInput.ActionType)
    Return ..SendRequestSync(Target, pInput, .pOutput, 60)
}

}
