public class GoogleBooksItem {
    public String kind { get; set; }
    public String id { get; set; }
    public String etag { get; set; }
    public String selfLink { get; set; }
    public GoogleBooksVolumeInfo volumeInfo { get; set; }
    public GoogleBooksSaleInfo saleInfo { get; set; }
    public GoogleBooksAccessInfo accessInfo { get; set; }
    public GoogleBooksSearchInfo searchInfo { get; set; }
}