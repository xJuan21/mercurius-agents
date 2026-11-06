/// Runs any stored agent through AI Hub.
Class Mercurius.Runtime.AgentExecutor Extends %RegisteredObject
{

/// Loads the named agent, sends it the input and returns the reply text.
ClassMethod Execute(pAgentName As %String, pInput As %String, Output pReply As %String) As %Status
{
    Set SC = $$$OK
    Set pReply = ""
    Try {
        Set Definition = ##class(Mercurius.Model.AgentDefinition).NameIndexOpen(pAgentName, , .SC)
        $$$ThrowOnError(SC)
        If ('Definition.Enabled) {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Agent is disabled: "_pAgentName))
        }

        Set KeyName = $ZCONVERT(Definition.ProviderName, "U")_"_API_KEY"
        Set Key = $SYSTEM.Util.GetEnviron(KeyName)
        If (Key = "") {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Missing environment variable: "_KeyName))
        }

        Set Provider = ##class(%AI.Provider).Create(Definition.ProviderName, {"api_key":(Key)})
        Set Agent = ##class(%AI.Agent).%New(Provider)
        Set Agent.Model = Definition.ModelName
        Set Agent.SystemPrompt = Definition.SystemPrompt
        Set:(Definition.Tone '= "") Agent.SystemPrompt = Agent.SystemPrompt_" Tone: "_Definition.Tone
        $$$ThrowOnError(Agent.%Init())

        Set Session = Agent.CreateSession()
        Set Response = Agent.Chat(Session, pInput)
        Set pReply = Response.Content
    } Catch Ex {
        Set SC = Ex.AsStatus()
    }
    Return SC
}

}
