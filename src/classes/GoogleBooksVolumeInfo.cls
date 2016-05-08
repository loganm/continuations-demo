public class GoogleBooksVolumeInfo {
    public String title { get; set; }
    public String subtitle { get; set; }
    public List<String> authors { get; set; }
    public String publisher { get; set; }
    public String publishedDate { get; set; }
    public String description { get; set; }
    public List<GoogleBooksIndustryIdentifier> industryIdentifiers { get; set; }
    public Integer pageCount { get; set; }
    public String printType { get; set; }
    public List<String> categories { get; set; }
    public double averageRating { get; set; }
    public Integer ratingsCount { get; set; }
    public String contentVersion { get; set; }
    public GoogleBooksImageLinks imageLinks { get; set; }
    public String language { get; set; }
    public String previewLink { get; set; }
    public String infoLink { get; set; }
    public String canonicalVolumeLink { get; set; }
}