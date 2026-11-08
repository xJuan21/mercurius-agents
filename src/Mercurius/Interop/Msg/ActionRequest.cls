/// An approved action to run.
Class Mercurius.Interop.Msg.ActionRequest Extends Ens.Request
{

Property ProposalId As %Integer;

Property ActionType As %String(MAXLEN = 30);

Property AgentName As %String(MAXLEN = 100);

Property Payload As %String(MAXLEN = "");

Property ApprovedBy As %String(MAXLEN = 128);

}
