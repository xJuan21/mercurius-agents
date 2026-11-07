/// An event for a stored agent.
Class Mercurius.Interop.Msg.AgentRequest Extends Ens.Request
{

Property AgentName As %String(MAXLEN = 100);

Property EventType As %String(MAXLEN = 50);

Property Payload As %String(MAXLEN = "");

Property CorrelationId As %String(MAXLEN = 255);

}
