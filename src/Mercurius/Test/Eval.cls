/// Measures decisions against labelled inputs. Each case runs through the production with
/// fresh sample knowledge. Run with Do ##class(Mercurius.Test.Eval).Run()
Class Mercurius.Test.Eval Extends %RegisteredObject
{

/// target: a word the right note contains, used to check whether search found it.
XData Cases [ MimeType = application/json ]
{
[
  {"agent":"Documenter","expected":"conflict","target":"funnel","input":"Decision: the WhatsApp webhook now uses Cloudflare Tunnel instead of Tailscale Funnel."},
  {"agent":"Documenter","expected":"conflict","target":"nightly","input":"Backups on iris01 now run weekly only. The nightly backup was stopped."},
  {"agent":"Documenter","expected":"conflict","target":"manually","input":"TLS certificates on the web gateway are now renewed automatically by certbot. Manual renewal is no longer needed."},
  {"agent":"Documenter","expected":"conflict","target":"portal","input":"To restart the production, kill the IRIS processes directly."},
  {"agent":"Documenter","expected":"conflict","target":"funnel","input":"The WhatsApp webhook is no longer exposed publicly. It is only reachable inside the tailnet."},
  {"agent":"Documenter","expected":"related","target":"nightly","input":"IRIS backup update: a weekly offsite copy now runs in addition to the nightly backup."},
  {"agent":"Documenter","expected":"related","target":"manually","input":"Certificate renewal checklist: after renewing the TLS certificate, restart the web gateway."},
  {"agent":"Documenter","expected":"related","target":"funnel","input":"The WhatsApp webhook verifies the X-Hub-Signature-256 header on every request."},
  {"agent":"Documenter","expected":"related","target":"nightly","input":"Backup restores from iris01 are tested once a month on iris-test."},
  {"agent":"Documenter","expected":"related","target":"portal","input":"Before restarting the production from the Management Portal, check the queue counts."},
  {"agent":"Documenter","expected":"none","input":"Team lunch on Friday: sandwiches and fruit."},
  {"agent":"Documenter","expected":"none","input":"The office printer is out of toner."},
  {"agent":"Documenter","expected":"none","input":"New hire onboarding starts on Monday."},
  {"agent":"Documenter","expected":"none","input":"Reminder: update your laptop's operating system."},
  {"agent":"Documenter","expected":"none","input":"The rugby team travels on Saturday."},
  {"agent":"Sentinel","expected":"high","input":"iris-dev disk is 97 percent full and journal writes are failing."},
  {"agent":"Sentinel","expected":"high","input":"The production stopped and messages are queuing in AgentRunner."},
  {"agent":"Sentinel","expected":"high","input":"The journal file system is read-only. IRIS cannot write journals."},
  {"agent":"Sentinel","expected":"high","input":"The license server is unreachable and users cannot sign in."},
  {"agent":"Sentinel","expected":"high","input":"The mirror failed over and the backup member is down."},
  {"agent":"Sentinel","expected":"medium","input":"Disk usage on iris-dev reached 80 percent."},
  {"agent":"Sentinel","expected":"medium","input":"Average message processing time doubled in the last hour."},
  {"agent":"Sentinel","expected":"medium","input":"The web gateway TLS certificate expires in 10 days."},
  {"agent":"Sentinel","expected":"medium","input":"One business operation retried a message 3 times before it succeeded."},
  {"agent":"Sentinel","expected":"medium","input":"Memory usage on iris01 has been above 85 percent for an hour."},
  {"agent":"Sentinel","expected":"low","input":"Nightly backup finished in 12 minutes."},
  {"agent":"Sentinel","expected":"low","input":"A user changed their password."},
  {"agent":"Sentinel","expected":"low","input":"CPU usage is 15 percent."},
  {"agent":"Sentinel","expected":"low","input":"An administrator started the production."},
  {"agent":"Sentinel","expected":"low","input":"A scheduled task completed successfully."},
  {"agent":"Forge","expected":"changes","input":"set x=$get(^Config(\"key\")) w x"},
  {"agent":"Forge","expected":"changes","input":"s Total=Total+1"},
  {"agent":"Forge","expected":"changes","input":"Set:Count>0 Average = Sum / Count"},
  {"agent":"Forge","expected":"changes","input":"Set total = 0"},
  {"agent":"Forge","expected":"changes","input":"d ..Log(Message) q"},
  {"agent":"Forge","expected":"ready","input":"Set Total = Total + 1"},
  {"agent":"Forge","expected":"ready","input":"Set:(Count > 0) Average = Sum / Count"},
  {"agent":"Forge","expected":"ready","input":"Do ..Log(Message)"},
  {"agent":"Forge","expected":"ready","input":"Write Name, !"},
  {"agent":"Forge","expected":"ready","input":"Return:(Value = \"\") $$$OK"},
  {"agent":"Forge","expected":"blocked","input":"Kill ^Patients  // clean up test data on the live server"},
  {"agent":"Forge","expected":"blocked","input":"Do $ZF(-100, \"\", \"rm\", \"-rf\", \"/\")"},
  {"agent":"Forge","expected":"blocked","input":"Set ^Config(\"password\") = \"admin123\"  // store the admin password in plain text"},
  {"agent":"Forge","expected":"blocked","input":"Xecute UserInput  // run whatever the web form sends"},
  {"agent":"Forge","expected":"blocked","input":"Do ##class(Security.Users).Delete(\"_SYSTEM\")"}
]
}

/// pAgent limits the run to one agent.
ClassMethod Run(pAgent As %String = "") As %Status
{
    Set XData = ##class(%Dictionary.CompiledXData).%OpenId("Mercurius.Test.Eval||Cases")
    Set Cases = ##class(%DynamicArray).%FromJSON(XData.Data)
    Set Iterator = Cases.%GetIterator()
    Write "| Agent | Input | Expected | Got | Engine | Search found note |", !, "|---|---|---|---|---|---|", !
    While (Iterator.%GetNext(.Index, .Case)) {
        Continue:((pAgent '= "") && (Case.agent '= pAgent))
        Do ##class(Mercurius.Setup).ResetKnowledge()
        Set SC = ..RunCase(Case, .Response)
        Set Got = $SELECT($$$ISOK(SC):Response.Decision, 1:"error")
        Set Agent = Case.agent
        Set Total(Agent) = $GET(Total(Agent)) + 1
        Set:(Got = Case.expected) Right(Agent) = $GET(Right(Agent)) + 1
        Set Found = ""
        If (Case.target '= "") {
            Set Found = $SELECT(..SearchFound(Response.ExecutionId, Case.target):"yes", 1:"no")
            Set Searched(Agent) = $GET(Searched(Agent)) + 1
            Set:(Found = "yes") Hits(Agent) = $GET(Hits(Agent)) + 1
        }
        Set Tokens(Agent) = $GET(Tokens(Agent)) + Response.PromptTokens + Response.CompletionTokens
        Set Cost(Agent) = $GET(Cost(Agent)) + Response.CostUSD
        Write "| ", Agent, " | ", $EXTRACT(Case.input, 1, 60), " | ", Case.expected, " | ", Got, " | ", Response.Engine, " | ", Found, " |", !
    }
    Write !, "| Agent | Correct | Search found the right note | Tokens, final calls | Estimated cost |", !, "|---|---|---|---|---|", !
    Set Agent = ""
    For {
        Set Agent = $ORDER(Total(Agent))
        Quit:(Agent = "")
        Write "| ", Agent, " | ", +$GET(Right(Agent)), " of ", Total(Agent), " | ", $SELECT($DATA(Searched(Agent)):+$GET(Hits(Agent))_" of "_Searched(Agent), 1:"n/a"), " | ", Tokens(Agent), " | $", $FNUMBER(Cost(Agent), "", 4), " |", !
    }
    Do ##class(Mercurius.Setup).ResetKnowledge()
    Return $$$OK
}

ClassMethod RunCase(pCase As %DynamicObject, Output pResponse As Mercurius.Interop.Msg.AgentResponse) As %Status
{
    Set Definition = ##class(Mercurius.Model.AgentDefinition).NameIndexOpen(pCase.agent, , .SC)
    Return:($$$ISERR(SC)) SC
    Set Request = ##class(Mercurius.Interop.Msg.AgentRequest).%New()
    Set Request.AgentName = pCase.agent
    Set Request.EventType = Definition.InputType
    Set Request.Payload = pCase.input
    Set Request.CorrelationId = "eval: "_$EXTRACT(pCase.input, 1, 50)
    Set SC = ##class(Ens.Director).CreateBusinessService("ChatIngress", .Service)
    Return:($$$ISERR(SC)) SC
    Return Service.ProcessInput(Request, .pResponse)
}

ClassMethod SearchFound(pExecutionId As %String, pTarget As %String) As %Boolean
{
    Set Query = "SELECT COUNT(*) AS Total FROM Mercurius_Model.AgentToolCall WHERE ExecutionId = ? AND ToolKey = 'SearchKnowledge' AND LOWER(ResultPreview) [ ?"
    Set Statement = ##class(%SQL.Statement).%ExecDirect(, Query, pExecutionId, $ZCONVERT(pTarget, "L"))
    Do Statement.%Next()
    Return (Statement.Total > 0)
}

}
