/// Runs any stored agent through AI Hub.
Class Mercurius.Runtime.AgentExecutor Extends %RegisteredObject
{

/// Loads the named agent, sends it the input and returns the reply text.
ClassMethod Execute(pAgentName As %String, pInput As %String, Output pReply As %String, pExecutionId As %String = "", Output pUsage As %DynamicObject) As %Status
{
    Set SC = $$$OK
    Set pReply = ""
    Set pUsage = {}
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
        Set Agent.SystemPrompt = Agent.SystemPrompt_" "_..DecisionContract(Definition)
        $$$ThrowOnError(Agent.%Init())

        $$$ThrowOnError(..AttachTools(Agent, pAgentName, pExecutionId))

        Set Session = Agent.CreateSession({"max_iterations":8})
        Set Response = Agent.Chat(Session, pInput)
        Set pReply = Response.Content
        Set:($ISOBJECT(Response.Usage)) pUsage = Response.Usage
    } Catch Ex {
        Set SC = Ex.AsStatus()
    }
    Return SC
}

/// The reply format, built from the agent's stored decision values.
ClassMethod DecisionContract(pDefinition As Mercurius.Model.AgentDefinition) As %String
{
    Set Values = $TRANSLATE(pDefinition.AllowedDecisions, ",", "|")
    Return "Finish by replying only with JSON: {"""_pDefinition.DecisionField_""":"""_Values_""",""reason"":""one sentence""}"
}

/// Binds the tools and policies to this agent. The LLM never supplies the agent's identity.
ClassMethod AttachTools(pAgent As %AI.Agent, pAgentName As %String, pExecutionId As %String) As %Status
{
    Set Tools = ##class(Mercurius.Tools.Knowledge).%New()
    Set Tools.AgentName = pAgentName
    Set Tools.ExecutionId = pExecutionId
    Set SC = pAgent.ToolManager.AddTool(Tools)
    Return:($$$ISERR(SC)) SC

    Set Policy = ##class(Mercurius.Runtime.ToolPolicy).%New()
    Set Policy.AgentName = pAgentName
    Set SC = pAgent.ToolManager.SetAuthPolicy(Policy)
    Return:($$$ISERR(SC)) SC

    Set Audit = ##class(Mercurius.Runtime.ToolAudit).%New()
    Set Audit.AgentName = pAgentName
    Set Audit.ExecutionId = pExecutionId
    Return pAgent.ToolManager.SetAuditPolicy(Audit)
}

/// Removes API keys from text before it's logged or stored. Providers can echo them in errors.
ClassMethod Redact(pText As %String) As %String
{
    Set Text = pText
    For KeyName = "OPENAI_API_KEY", "ANTHROPIC_API_KEY" {
        Set Key = $SYSTEM.Util.GetEnviron(KeyName)
        Set:(Key '= "") Text = $REPLACE(Text, Key, "[REDACTED]")
    }
    Set Matcher = ##class(%Regex.Matcher).%New("sk-[A-Za-z0-9_\-]{8,}", Text)
    Return Matcher.ReplaceAll("[REDACTED]")
}

}
