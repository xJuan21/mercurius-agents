/// A message a person approved. The Notifier operation records it; another operation can deliver it.
Class Mercurius.Model.Notification Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property Message As %String(MAXLEN = 500) [ Required ];

Property Channel As %String(MAXLEN = 30) [ InitialExpression = "Inbox" ];

Property ProposalId As %Integer;

Property ApprovedBy As %String(MAXLEN = 128);

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

}
