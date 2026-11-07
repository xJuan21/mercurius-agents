# Mercurius Agents

Configurable AI agents that make decisions inside InterSystems IRIS Interoperability
productions, built on IRIS AI Hub.

Agents are stored records, not generated classes. One runtime runs them all. Each agent has
its own instructions, permitted tools, private knowledge and memory. Its decision then
routes a real message through a production.

## What it does

A document arrives at a Business Service. The **Scribe** agent searches its private
knowledge and decides whether the document relates to, or contradicts, what it already
knows. A contradiction is recorded as an open finding and routed to review. Alerts follow
the same production and code, but reach the **Sentinel** agent, which has different
instructions and tools.

```text
File inbox -> DocumentIngress / AlertIngress (BS)
                   |
             AgentWorkflow (BP) -> AgentRunner (BO) -> AI Hub agent + permitted tools
                   |
          validated decision routes the message
                   |
      +------------+------------+
      v                         v
 ResultHandler (BO)        ReviewQueue (BO)
```

| Deterministic code | AI judgment |
|---|---|
| Saving documents, checking tool permissions, enforcing ownership, validating the decision against allowed values, routing | Choosing search terms, comparing notes, proposing a decision |

An invalid or failed reply never gets accepted: it goes to review.

## Requirements

- Docker with Compose
- The **AI Hub Community** image, build `2027.1.0AI.109.0`, from the
  [EAP portal](https://evaluation.intersystems.com/Eval/early-access/AIHub).
  It can't be pulled from a registry, and this repo never publishes it.
- An **OpenAI** API key. Variable: `OPENAI_API_KEY`. The default model is `gpt-4.1-mini`.

## Install

Load the image and give it the short tag used by the Dockerfile:

```bash
docker image load -i iris-community-2027.1.0AI.109.0-docker.tar.gz
docker tag docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2027.1.0AI.109.0 iris-community:2027.1.0AI.109.0
```

Clone, add your key and start:

```bash
git clone https://github.com/xJuan21/mercurius-agents.git
cd mercurius-agents
cp .env.example .env      # then put your key in .env
docker compose up -d --build
```

The build compiles the code, seeds the sample agents and sets the production to start
with IRIS.

## Verify

```bash
docker compose ps                                        # shows (healthy)
curl -s http://localhost:52775/mercurius/api/agents      # lists Scribe and Sentinel
```

Backend checks, no LLM needed:

```bash
echo 'Do ##class(Mercurius.Test.Acceptance).Run() Halt' | docker compose exec -T iris iris session IRIS -U IRISAPP
```

This writes test records, and `demo/run.sh` resets them.

## Run the demo

```bash
./demo/run.sh
```

It sends three documents and an alert through the production and prints each decision.
LLM judgment varies between runs.

| Where | URL |
|---|---|
| Dashboard (read-only) | http://localhost:52775/mercurius/ |
| Production and message traces | http://localhost:52775/csp/sys/UtilHome.csp |

The portal uses `_SYSTEM` and the image default password. Open **Interoperability →
View → Messages** to see the trace, or use the session number shown by the demo.

## Add an agent

Add a row to `Mercurius.Model.AgentDefinition` with its prompt, `DecisionField`,
`AllowedDecisions` and `ReviewDecisions`, then grant tools in
`Mercurius.Model.AgentToolPermission`. See `Mercurius.Setup`. No new class is needed.
Point a Business Service at it with its `AgentName` setting.

## Security

- The runtime binds each tool to its agent, so the LLM never supplies the agent's identity.
- `Mercurius.Runtime.ToolPolicy` checks every tool against the agent's grants, and
  ungranted tools aren't shown to the LLM.
- `KnowledgeService` enforces ownership, so relationships can't cross agents.
- Every tool call is audited in `Mercurius.Model.AgentToolCall`.
- Agents get no SQL, filesystem or shell tools.
- The dashboard has no login and shows stored data. It's for local demos: don't expose it.

## Gotchas found on build 109

| Symptom | Cause | Fix |
|---|---|---|
| Container restarts with exit 134: `Unable to find/open file iris-main.log` | The repo is bind-mounted over the working directory, and the IRIS user can't write there | `working_dir: /home/irisowner` in `docker-compose.yml` |
| `<PRIVATE METHOD>` from `ToolManager.AddToolSetInstance()` | The method is private | Use `ToolManager.AddTool(instance)`, which keeps instance properties through `Chat()` |
| A tool hidden by `%CanList` isn't audited when called | The call fails as `ToolNotFound`, before `%CanExecute` and `%LogDenial` | Also check permissions in your own services |
| `No repositories are configured` from `zpm` in another namespace | `enable -community` alone doesn't map the repositories | Also run `zpm "enable -map -repos -globally"` in `%SYS` |
| Every `%CSP.REST` route returns the same output | A method named `Page` overrides `%CSP.Page` | Use another method name |
| An API call fails on a `Role` column | `Role` is reserved in SQL | Quote it |

## Known limitations

- Knowledge search is basic text matching, so related notes can be missed.
- A conflict is an AI finding, not a verified fact. There's no review screen yet.
- An LLM call that hangs has no timeout of its own.
- Agents are created in code or SQL. There's no create form yet.
- AI Hub is pre-release software.
