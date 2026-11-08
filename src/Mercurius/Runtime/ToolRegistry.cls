/// The tools an agent can be granted.
Class Mercurius.Runtime.ToolRegistry Extends %RegisteredObject
{

ClassMethod List() As %DynamicArray
{
    Return [
        {"key":"SearchKnowledge", "label":"Search knowledge", "description":"Search the agent's private knowledge"},
        {"key":"CreateRelationship", "label":"Create relationships", "description":"Link two of the agent's nodes"},
        {"key":"FlagConflict", "label":"Flag conflicts", "description":"Record a possible contradiction for review"},
        {"key":"SaveKnowledge", "label":"Save knowledge", "description":"Add an item to the agent's knowledge"},
        {"key":"GetAgentMemory", "label":"Read memory", "description":"Read the agent's private memory"},
        {"key":"SaveAgentMemory", "label":"Save memory", "description":"Add to the agent's private memory"},
        {"key":"ProposeNotification", "label":"Propose notification", "description":"Suggest a message for a person; it's sent only after approval"},
        {"key":"CheckSyntax", "label":"Check ObjectScript syntax", "description":"Compile code without running it and report syntax errors"},
        {"key":"DescribeSchema", "label":"Describe tables", "description":"List the tables and columns of an allowed schema"},
        {"key":"CheckSQL", "label":"Validate SQL", "description":"Prepare a SELECT without running it and report its columns or errors"},
        {"key":"ProposeKnowledgeUpdate", "label":"Propose knowledge update", "description":"Suggest new content for one of its notes; it changes only after approval"}
    ]
}

ClassMethod IsKnown(pToolKey As %String) As %Boolean
{
    Set Iterator = ..List().%GetIterator()
    While (Iterator.%GetNext(.Index, .Tool)) {
        Return:(Tool.key = pToolKey) 1
    }
    Return 0
}

}
