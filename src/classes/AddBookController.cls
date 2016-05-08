/**
 * Contrived example to Demonstrate asynchronous callouts from Visualforce using Continuations. A feature introduced in Spring 15'
 * @author Logan Moore
 */
public with sharing class AddBookController {
    

    // A template for building a Google Books REST API endpoint
    private static final String GOOGLE_BOOKS_ENDPOINT = 'https://www.googleapis.com/books/v1/volumes?q={0}';
    

    // Will be explained later
    private String isbnRequestLabel;
    private String generalRequestLabel;
    

    // A term to search for, provided by the user
    public String searchText { get; set; }
    

    // Results of the search
    public transient GoogleBooksResult isbnSearchResult { get; private set; }
    public transient GoogleBooksResult generalSearchResult { get; private set; }


    public Integer syncSearchCounter { get; set; }
    public Integer asyncSearchCounter { get; set; }
    public Integer asyncCallbackCounter { get; set; }

    public Datetime startTime { get; set; }
    public Decimal duration { get; set; }


    public AddBookController() {
        syncSearchCounter = 0;
        asyncSearchCounter = 0;
        asyncCallbackCounter = 0;
    }


    /**
     * Synchronous http callout in visualforce. The way we're most familiar with.
     *
     * Problems: - Limit of 10 long running http callouts ORG WIDE!!!
     *           - http.send() method is blocking.
     *           - Chained callouts happen in the same thread. Overall time limit applies.
     */
    public void synchronousSearch() {

        // Lets increment a counter to see how many times this runs if I go street fighter on the search button.
        this.syncSearchCounter++;

        // Measure duration of request
        this.startTime = Datetime.now();

        Http http = new Http();
        
        // We read the response, update the controller state and either reload or rerender the page.
        HttpResponse isbnResponse = http.send(isbnSearchRequest()); // This is a blocking method call, which means we're spending time and resources waiting.
        if(isbnResponse.getStatusCode() == 200) {
            isbnSearchResult = parseResponse(isbnResponse.getBody());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'ISBN Synchronous Response Received ' + Datetime.now()));
        } else { // sumting wong, wi too lo, bang ding au
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ISBN Response: ' + isbnResponse.getStatusCode() + isbnResponse.getStatus()));
        }
        
        // We get to do it all over again.
        HttpResponse generalResponse = http.send(generalSearchRequest());
        if(generalResponse.getStatusCode() == 200) {
            generalSearchResult = parseResponse(generalResponse.getBody());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'General Synchronous Response Received ' + Datetime.now()));
        } else { // fire in the hole
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'General Response: ' + generalResponse.getStatusCode() + generalResponse.getStatus()));
        }

        // What's the duration?
        this.duration = Datetime.now().getTime() - this.startTime.getTime();
    }
    

    /** 
     * Generates a request to search for books using the searchText as an ISBN number.
     * This request will return 0 or 1 matches.
     */
    public HttpRequest isbnSearchRequest() {
        return buildHttpRequest(String.format(GOOGLE_BOOKS_ENDPOINT, new String[] {'isbn:' + EncodingUtil.urlEncode(searchText, 'UTF-8')}));

        // Want to see a strange error?
        // Remove the urlencoding of the endpoint, and search for a term with spaces in it
        // Google returns a 400 bad request
        // Salesforce blows up
    }
    

    /** 
     * Generates a request to search for books using the searchText as an general search term.
     * This request can return 0 to many matches.
     */
    public HttpRequest generalSearchRequest() {
        return buildHttpRequest(String.format(GOOGLE_BOOKS_ENDPOINT, new String[] {EncodingUtil.urlEncode(searchText, 'UTF-8')}));
    }
    

    /**
     * Wraps an enpoint URL in a HttpRequest with nature required to be sent to Google.
     * Nothing to see here, move along, move along.
     */
    public HttpRequest buildHttpRequest(String endpoint) {
        
        // Google requires an X-Forwarded-For header with the original clients IP (sneaky google, sneaky).
        // We can figure this about by looking at the current page headers for the True-Client-IP or X-Salesforce-SIP.
        String clientIp = ApexPages.currentPage().getHeaders().get('True-Client-IP');
        if (clientIp == null) {
            clientIp = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }
        
        // Build the http request to Googles API. Most of us are used to this by now.
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('X-Forwarded-For', clientIp);

        return request;
    }
    

    /**
     * Turns a JSON response body from Google into a data structure we can work with.
     */
    public GoogleBooksResult parseResponse(String googleBooksResultJSON) {
        JSONParser parser = JSON.createParser(googleBooksResultJSON);
        return (GoogleBooksResult)parser.readValueAs(GoogleBooksResult.class);
    }
    

    /**
     * Kicks off a Continuation which takes care of the callout for us. The method ends before the continuation completes.
     *
     * Advantages: - Unlimited callouts (doesn't incur the org wide 10 long running http callout limit)
     *             - up to 3 callouts can be requested in the same continuation
     *             - The 3 callouts happen in parallel, callback is called as soon as the longest callback is complete.
     *             - Can chain more continuations on the back of a callback
     *
     * Disadvantages: - Only works from VF context.
     *                - up to 3 callouts can be requested in the same continuation
     *                - 1MB response size limit.
     */
    public Object asynchronousSearch() {

        // Lets increment a counter to see how many times this runs if I go street fighter on the search button.
        this.asyncSearchCounter++;

        // Measure duration of request
        this.startTime = Datetime.now();
    
        // Creates a continuation with a 60 second timeout
        Continuation cont = new Continuation(60);
        
        // Tell the continuation to callback to us when the callout is finish on the handleCallback method
        cont.continuationMethod = 'handleCallback';
        
        // Add an http request to the continuation
        // Also, store the unique request label that gets generated. We'll need it later.
        this.isbnRequestLabel = cont.addHttpRequest(isbnSearchRequest());
        
        // you cand add two more callouts here and store their requestLabels in the controller state as well.
        this.generalRequestLabel = cont.addHttpRequest(generalSearchRequest());
        
        // Return the continuation to tell VF that its waiting for a continuation.
        return cont;
    }
    

    /**
     * Is called by the continuation server when the http callout is completed.
     *
     * The callback is considered a new apex transaction, so if you want to do 
     *
     * Can return: - A continuation to chain another continuation.
     *             - A PageReference to redirect to a new page (use page parameters to pass details of the continuation response)
     *             - null to rerender the page
     */
    public Object handleCallback() {

        // Lets increment a counter to see how many times this runs if I go street fighter on the search button.
        this.asyncCallbackCounter++;
        
        // Handle the response the same way as synchronous call
        // EXCEPT we have to get the HttpResponse object using the label that we stored earlier
        isbnSearchResult = parseResponse(Continuation.getResponse(this.isbnRequestLabel).getBody());
        
        // Handle a second response using its own requestLabel
        generalSearchResult = parseResponse(Continuation.getResponse(this.generalRequestLabel).getBody());
        
        // Inform us that the results were fetched asynchronously
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Asynchronous Response Received ' + Datetime.now()));

        // What's the duration?
        this.duration = Datetime.now().getTime() - this.startTime.getTime();
        
        // Return null to re-render the VF page
        return null;
    }


    public void timeForSync() {

        this.startTime = Datetime.now();

        Http http = new Http();

        HttpRequest request1 = new HttpRequest();
        request1.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request1.setMethod('GET');
        http.send(request1); 

        HttpRequest request2 = new HttpRequest();
        request2.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request2.setMethod('GET');
        http.send(request2); 

        HttpRequest request3 = new HttpRequest();
        request3.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request3.setMethod('GET');
        http.send(request3);

        this.duration = Datetime.now().getTime() - this.startTime.getTime();
    }

    public Object timeForAsyncStart() {
        
        this.startTime = Datetime.now();

        Continuation cont = new Continuation(60);
        cont.continuationMethod = 'timeForAsyncCallback';

        HttpRequest request1 = new HttpRequest();
        request1.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request1.setMethod('GET');
        cont.addHttpRequest(request1); 

        HttpRequest request2 = new HttpRequest();
        request2.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request2.setMethod('GET');
        cont.addHttpRequest(request2); 

        HttpRequest request3 = new HttpRequest();
        request3.setEndpoint('https://fathomless-bayou-16905.herokuapp.com');
        request3.setMethod('GET');
        cont.addHttpRequest(request3);

        return cont;
    }

    public Object timeForAsyncCallback() {
        this.duration = Datetime.now().getTime() - this.startTime.getTime();
        return null;
    }
}