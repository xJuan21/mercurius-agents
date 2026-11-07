/// The outcome of one agent run.
Class Mercurius.Interop.Msg.AgentResponse Extends Ens.Response
{

Property AgentName As %String(MAXLEN = 100);

Property ExecutionId As %String(MAXLEN = 50);

Property Status As %String(MAXLEN = 20);

Property Decision As %String(MAXLEN = 100);

Property NeedsReview As %Boolean;

Property Result As %String(MAXLEN = "");

Property SessionId As %Integer;

Property ErrorMessage As %String(MAXLEN = 2000);

}
