/// Entry point for messages from the web UI. Called directly, so it has no adapter.
Class Mercurius.Interop.BS.ChatIngress Extends Ens.BusinessService
{

Parameter ADAPTER;

Method OnProcessInput(pInput As Mercurius.Interop.Msg.AgentRequest, Output pOutput As Mercurius.Interop.Msg.AgentResponse) As %Status
{
    Return ..SendRequestSync("AgentWorkflow", pInput, .pOutput, 120)
}

}
