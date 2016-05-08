# continuations-demo
An internal demo of the Continuations feature for Trineo team members

## Example books by ISBN
* 9780321205681 - User Stories Applied by Mike Cohn
* 9780321125217 - Domain Driven Design by Eric Evans
* 9780321127426 - Patterns of Enterprise Application Architecture by Martin Fowler

## Continuations Flow
![alt text](https://developer.salesforce.com/docs/resources/img/en-us/200.0?doc_id=dev_guides%2Fapex%2Fimages%2Fapex_continuations_diagram.png&folder=apexcode "Continuation Flow")

## When to use:
* VF can be sped up by doing multiple callouts in parallel
* The callout is known to be long running
* Many users are expected to be thrashing the page simultaneously
* When multiple callouts must be performed in series
    
### Pros
* Up to 3 http request can be made simultaneously in a single continuation
* Up to 3 continuations can be changed
* Each continuation gets 120 seconds to complete
* Does not contribute to the org wide 10 long running callouts limit. (long running is > 5s)
    
### Cons 
* Controller view state is limited to 80kb, because the view state is serialised when the continuation is called, and deserialised when the callback is called. Use transient keyword to limit held view state.
* Max HTTP Post Size - 1MB
* Max HTTP Response Size - 1MB
