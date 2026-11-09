/// Sample class for the Tester agent. Checks an order before it enters fulfilment.
Class Mercurius.Demo.OrderValidator Extends %RegisteredObject
{

/// Orders above this total need a manual check.
Parameter LIMIT = 10000;

/// Returns an empty string when the order is valid, or the first problem found.
ClassMethod Validate(pOrder As %DynamicObject) As %String
{
    Return:('$ISOBJECT(pOrder)) "No order."
    Return:(pOrder.id = "") "Missing id."
    Return:('$ISOBJECT(pOrder.items) || (pOrder.items.%Size() = 0)) "No items."
    Set Iterator = pOrder.items.%GetIterator()
    While (Iterator.%GetNext(.Index, .Item)) {
        Return:(Item.quantity < 1) "Item "_(Index + 1)_": quantity must be at least 1."
        Return:(Item.price < 0) "Item "_(Index + 1)_": price can't be negative."
    }
    Return:(..Total(pOrder) > ..#LIMIT) "Total is over the limit."
    Return ""
}

/// Sums quantity times price over the items.
ClassMethod Total(pOrder As %DynamicObject) As %Numeric
{
    Set Total = 0
    Set Iterator = pOrder.items.%GetIterator()
    While (Iterator.%GetNext(.Index, .Item)) {
        Set Total = Total + (Item.quantity * Item.price)
    }
    Return Total
}

/// Takes 10% off totals of 1000 or more.
ClassMethod Discount(pTotal As %Numeric) As %Numeric
{
    Return $SELECT(pTotal >= 1000:pTotal * 0.9, 1:pTotal)
}

}
