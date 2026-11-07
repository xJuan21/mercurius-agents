#!/bin/bash
# Resets the sample knowledge, sends the demo events through the production, prints the results.
cd "$(dirname "$0")/.." || exit 1

irisrun() { docker compose exec -T iris iris session IRIS -U IRISAPP; }

irisrun <<'OS' >/dev/null
Do ##class(Mercurius.Setup).ResetKnowledge()
Halt
OS

for File in demo/documents/*; do
    docker compose exec -T iris sh -c "cat > /home/irisowner/inbox/documents/$(basename "$File")" < "$File"
done
for File in demo/alerts/*; do
    docker compose exec -T iris sh -c "cat > /home/irisowner/inbox/alerts/$(basename "$File")" < "$File"
done

for File in demo/code/*; do
    docker compose exec -T iris sh -c "cat > /home/irisowner/inbox/code/$(basename "$File")" < "$File"
done

echo "Events sent. Waiting for the agents..."
sleep 45

irisrun <<'OS' | grep -E '^(RUN|CONFLICT):'
Set R=##class(%SQL.Statement).%ExecDirect(,"SELECT TOP 5 AgentName,Status,Decision,Route,InteropSessionId FROM Mercurius_Model.AgentExecution ORDER BY ID DESC") While R.%Next() { Write "RUN: ",R.AgentName," | ",R.Status," | ",R.Decision," | ",R.Route," | session ",R.InteropSessionId,! }
Set R=##class(%SQL.Statement).%ExecDirect(,"SELECT Status,Description FROM Mercurius_Model.KnowledgeConflict") While R.%Next() { Write "CONFLICT: ",R.Status," | ",R.Description,! }
Halt
OS
