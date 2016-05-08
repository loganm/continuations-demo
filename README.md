# continuations-demo
An internal demo of the Continuations feature for Trineo team members

![Happy Matt Damon](https://s-media-cache-ak0.pinimg.com/236x/6f/2d/e1/6f2de1f09fd4c32f91b9f6d50f51437f.jpg)

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
* Can be used in JS Remoting
    
### Cons 
* Controller view state is limited to 80kb, because the view state is serialised when the continuation is called, and deserialised when the callback is called. Use transient keyword to limit held view state.
* Max HTTP Post Size - 1MB
* Max HTTP Response Size - 1MB
* Does not get around uncommitted work pending error
* Mixing synchronous and asynchronous could be a world of hurt
* Requires rerender on commandButton, will not rerender the whole page

## Documentation
* https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_continuation_overview.htm
* https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_continuation_process.htm
* https://developer.salesforce.com/blogs/developer-relations/2015/02/apex-continuations-asynchronous-callouts-visualforce-pages.html
