/// Lists the chat models each configured provider offers. The provider's list is cached for a
/// day, and agents may only use a model from it.
Class Mercurius.Runtime.ModelCatalog Extends %RegisteredObject
{

Parameter LIFETIME = 86400;

/// Providers the runtime supports. A provider is offered only when its key is set.
Parameter PROVIDERS = "openai,anthropic";

ClassMethod Providers() As %List
{
    Set Result = ""
    Set Names = $LISTFROMSTRING(..#PROVIDERS)
    For Index = 1:1:$LISTLENGTH(Names) {
        Set Name = $LIST(Names, Index)
        Set:($SYSTEM.Util.GetEnviron($ZCONVERT(Name, "U")_"_API_KEY") '= "") Result = Result_$LISTBUILD(Name)
    }
    Return Result
}

/// Returns [{provider, models: [{id, name, priced}]}] for every configured provider.
ClassMethod Catalog(pRefresh As %Boolean = 0) As %DynamicArray
{
    Set Result = []
    Set Names = ..Providers()
    For Index = 1:1:$LISTLENGTH(Names) {
        Set Name = $LIST(Names, Index)
        Do Result.%Push({"provider":(Name), "models":(..Models(Name, pRefresh))})
    }
    Return Result
}

ClassMethod Models(pProvider As %String, pRefresh As %Boolean = 0) As %DynamicArray
{
    Set Cached = $GET(^Mercurius.ModelCache(pProvider))
    If ('pRefresh && (Cached '= "") && (($ZHOROLOG - $LIST(Cached, 1)) < ..#LIFETIME) && ($PIECE($HOROLOG, ",", 1) = $LIST(Cached, 3))) {
        Return ##class(%DynamicArray).%FromJSON($LIST(Cached, 2))
    }
    Set Models = []
    Try {
        Set Key = $SYSTEM.Util.GetEnviron($ZCONVERT(pProvider, "U")_"_API_KEY")
        Set Provider = ##class(%AI.Provider).Create(pProvider, {"api_key":(Key)})
        Set Iterator = Provider.ListModels().%GetIterator()
        While (Iterator.%GetNext(.Index, .Model)) {
            Continue:('$ISOBJECT(Model) || '..IsChatModel(Model))
            Set Priced = (##class(Mercurius.Runtime.Pricing).Estimate(Model.id, 1000000, 0) '= "")
            Do Models.%Push({"id":(Model.id), "name":($SELECT(Model.name '= "":Model.name, 1:Model.id)), "priced":(Priced)})
        }
        Set ^Mercurius.ModelCache(pProvider) = $LISTBUILD($ZHOROLOG, Models.%ToJSON(), $PIECE($HOROLOG, ",", 1))
    } Catch Ex {
        // An unreachable provider keeps its last list, if there is one.
        Return:(Cached '= "") ##class(%DynamicArray).%FromJSON($LIST(Cached, 2))
    }
    Return Models
}

/// Keeps text chat models only: the providers also list audio, image, embedding and search models.
ClassMethod IsChatModel(pModel As %DynamicObject) As %Boolean
{
    Set Id = $ZCONVERT(pModel.id, "L")
    Return:($MATCH(Id, ".*(realtime|audio|tts|transcribe|search|image|embedding|moderation|dall-e|whisper|codex|computer-use|instruct).*")) 0
    Set Capabilities = pModel.capabilities
    Return:('$ISOBJECT(Capabilities)) 1
    Set Iterator = Capabilities.%GetIterator()
    While (Iterator.%GetNext(.Index, .Capability)) {
        Return:(Capability = "ChatCompletion") 1
    }
    Return 0
}

ClassMethod IsAllowed(pProvider As %String, pModel As %String) As %Boolean
{
    Return:('$LISTFIND(..Providers(), pProvider)) 0
    Set Iterator = ..Models(pProvider).%GetIterator()
    While (Iterator.%GetNext(.Index, .Model)) {
        Return:(Model.id = pModel) 1
    }
    Return 0
}

}
