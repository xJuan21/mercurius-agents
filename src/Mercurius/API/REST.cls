/// Read-only dashboard and JSON API. There are no write routes.
Class Mercurius.API.REST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "utf-8";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/" Method="GET" Call="Page"/>
  <Route Url="/api/agents" Method="GET" Call="Agents"/>
  <Route Url="/api/executions" Method="GET" Call="Executions"/>
  <Route Url="/api/conflicts" Method="GET" Call="Conflicts"/>
  <Route Url="/api/knowledge" Method="GET" Call="Knowledge"/>
</Routes>
}

ClassMethod Page() As %Status
{
    Set %response.ContentType = "text/html"
    Set XData = ##class(%Dictionary.CompiledXData).%OpenId("Mercurius.API.REST||Dashboard")
    Return XData.Data.OutputToDevice()
}

ClassMethod Agents() As %Status
{
    Return ..WriteQuery("SELECT Name, Role, ModelName, DecisionField, AllowedDecisions, ReviewDecisions, Enabled, (SELECT LIST(ToolKey) FROM Mercurius_Model.AgentToolPermission P WHERE P.AgentName = A.Name) AS Tools FROM Mercurius_Model.AgentDefinition A ORDER BY Name")
}

ClassMethod Executions() As %Status
{
    Return ..WriteQuery("SELECT TOP 50 ExecutionId, AgentName, SourceType, Status, Decision, Route, StartedAt, InputSummary, OutputSummary, ErrorDetails, InteropSessionId, (SELECT LIST(ToolKey) FROM Mercurius_Model.AgentToolCall T WHERE T.ExecutionId = E.ExecutionId) AS Tools FROM Mercurius_Model.AgentExecution E ORDER BY ID DESC")
}

ClassMethod Conflicts() As %Status
{
    Return ..WriteQuery("SELECT TOP 50 C.AgentName, C.Status, C.Description, C.CreatedAt, S.Title AS SourceTitle, T.Title AS TargetTitle FROM Mercurius_Model.KnowledgeConflict C LEFT JOIN Mercurius_Model.KnowledgeNode S ON S.ID = C.SourceNodeId LEFT JOIN Mercurius_Model.KnowledgeNode T ON T.ID = C.TargetNodeId ORDER BY C.ID DESC")
}

ClassMethod Knowledge() As %Status
{
    Return ..WriteQuery("SELECT TOP 100 AgentName, Title, NodeType, Content FROM Mercurius_Model.KnowledgeNode ORDER BY AgentName, ID")
}

/// Runs a fixed query and writes the rows as a JSON array.
ClassMethod WriteQuery(pQuery As %String) As %Status
{
    Set Statement = ##class(%SQL.Statement).%New()
    Set Statement.%SelectMode = 1
    Set SC = Statement.%Prepare(pQuery)
    Return:($$$ISERR(SC)) SC
    Set Result = Statement.%Execute()
    Return:(Result.%SQLCODE < 0) $$$ERROR($$$SQLError, Result.%SQLCODE, Result.%Message)
    Set Metadata = Result.%GetMetadata()
    Set Rows = []
    While (Result.%Next()) {
        Set Row = {}
        For Index = 1:1:Metadata.columnCount {
            Do Row.%Set(Metadata.columns.GetAt(Index).colName, Result.%GetData(Index))
        }
        Do Rows.%Push(Row)
    }
    Write Rows.%ToJSON()
    Return $$$OK
}

XData Dashboard [ MimeType = text/html ]
{
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mercurius Agents</title>
<style>
:root { --bg:#0f1724; --panel:#172233; --line:#2a3a50; --text:#e6ebf2; --muted:#9fb0c3; --teal:#2fb6a8; --gold:#d9b45b; --red:#e2777a; }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--text); font:15px/1.5 system-ui,sans-serif; }
header { padding:20px 16px 8px; max-width:1100px; margin:auto; }
h1 { margin:0; font-size:24px; } header p { margin:2px 0 0; color:var(--muted); }
nav { display:flex; gap:6px; flex-wrap:wrap; max-width:1100px; margin:12px auto; padding:0 16px; }
button { background:var(--panel); color:var(--text); border:1px solid var(--line); border-radius:6px; padding:7px 12px; font:inherit; cursor:pointer; }
button.on { border-color:var(--teal); color:var(--teal); }
main { max-width:1100px; margin:auto; padding:0 16px 32px; }
.card { background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:12px 14px; margin-bottom:10px; overflow-wrap:anywhere; }
.top { display:flex; gap:8px; flex-wrap:wrap; align-items:center; }
.badge { font-size:12px; padding:1px 8px; border-radius:10px; border:1px solid var(--line); color:var(--muted); }
.Review,.Open { color:var(--gold); border-color:var(--gold); } .Accepted,.Completed { color:var(--teal); border-color:var(--teal); } .Failed { color:var(--red); border-color:var(--red); }
.muted { color:var(--muted); font-size:13px; } pre { white-space:pre-wrap; margin:6px 0 0; font:13px/1.45 ui-monospace,monospace; }
</style>
</head>
<body>
<header><h1>Mercurius Agents</h1><p>Agent decisions inside an IRIS production. Read-only. AI findings need human review.</p></header>
<nav id="tabs"></nav>
<main id="view"></main>
<script>
const views = {
  "Execution history": ["api/executions", r => card(r.AgentName, [r.Status, r.Decision, r.Route], [
    ["Input", r.InputSummary], ["Agent reply", r.OutputSummary], ["Error", r.ErrorDetails],
    ["Tools called", r.Tools], ["Trace", "Session " + r.InteropSessionId + " · " + r.StartedAt]])],
  "Conflicts": ["api/conflicts", r => card(r.AgentName, [r.Status], [
    ["Finding", r.Description], ["Between", r.SourceTitle + " and " + r.TargetTitle], ["Found", r.CreatedAt]])],
  "Agents": ["api/agents", r => card(r.Name, [r.Enabled == 1 ? "Enabled" : "Disabled"], [
    ["Role", r.Role], ["Model", r.ModelName], ["Allowed decisions", r.AllowedDecisions],
    ["Needs review", r.ReviewDecisions], ["Permitted tools", r.Tools]])],
  "Knowledge": ["api/knowledge", r => card(r.Title, [r.AgentName, r.NodeType], [["Content", r.Content]])]
};
let current = "Execution history";
function el(tag, cls, text) { const e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
function card(title, badges, rows) {
  const c = el("div", "card"), top = el("div", "top");
  top.append(el("strong", "", title));
  badges.filter(Boolean).forEach(b => top.append(el("span", "badge " + b, b)));
  c.append(top);
  rows.filter(r => r[1]).forEach(r => { c.append(el("div", "muted", r[0])); c.append(el("pre", "", r[1])); });
  return c;
}
async function load() {
  const view = document.getElementById("view"), [url, render] = views[current];
  try {
    const rows = await (await fetch(url)).json();
    view.replaceChildren(...(rows.length ? rows.map(render) : [el("p", "muted", "Nothing yet. Run demo/run.sh to send events through the production.")]));
  } catch (e) { view.replaceChildren(el("p", "muted", "Could not load data: " + e.message)); }
}
function tabs() {
  const nav = document.getElementById("tabs");
  nav.replaceChildren(...Object.keys(views).map(n => { const b = el("button", n === current ? "on" : "", n); b.onclick = () => { current = n; tabs(); load(); }; return b; }));
}
tabs(); load(); setInterval(load, 5000);
</script>
</body>
</html>
}

}
