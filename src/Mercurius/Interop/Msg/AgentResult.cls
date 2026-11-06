/// A routed agent result for a handler operation.
Class Mercurius.Interop.Msg.AgentResult Extends Ens.Request
{

Property ExecutionId As %String(MAXLEN = 50);

Property AgentName As %String(MAXLEN = 100);

Property Decision As %String(MAXLEN = 100);

Property Route As %String(MAXLEN = 20);

Property Result As %String(MAXLEN = "");

}
