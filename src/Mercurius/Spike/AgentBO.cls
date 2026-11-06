Class Mercurius.Spike.AgentBO Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Parameter SETTINGS = "Model";

Property Model As %String [ InitialExpression = "gpt-4o-mini" ];

Method Decide(pRequest As Ens.StringRequest, Output pResponse As Ens.StringResponse) As %Status
{
    Set tSC = $$$OK
    Try {
        Set provider = ##class(%AI.Provider).Create("openai", {"api_key":($SYSTEM.Util.GetEnviron("OPENAI_API_KEY"))})
        Set agent = ##class(%AI.Agent).%New(provider)
        Set agent.Model = ..Model
        Set agent.SystemPrompt = "You review technical notes. Reply only with JSON: {""decision"":""related|conflict|none"",""reason"":""one sentence""}"
        $$$ThrowOnError(agent.%Init())
        Set session = agent.CreateSession()
        Set reply = agent.Chat(session, pRequest.StringValue)
        Set pResponse = ##class(Ens.StringResponse).%New()
        Set pResponse.StringValue = reply.Content
        $$$LOGINFO("Agent decision: "_reply.Content)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Ens.StringRequest">
    <Method>Decide</Method>
  </MapItem>
</MapItems>
}

}
