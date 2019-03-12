require_relative 'crawler'
require 'open-uri'

RSpec.describe Crawler do
  subject { Crawler.new("http://example.com") }

  let(:root) {
    "
    <html>
      <head>
        <meta charset='utf-8' />
        <link href='/css/reset.css' media='screen' rel='stylesheet' type='text/css'>
        <link href='/css/style.css' media='screen' rel='stylesheet' type='text/css'>
        <script src='/js/script.js' type='text/javascript'></script>
        <script src='/js/main.js' type='text/javascript'></script>
      </head>
      <body>
        <h1>Some example copy</h1>
        <a href='/'>Home</a>
        <a href='/another-page'>Another page</a>
      </body
    </html>
    "
  }

  let(:another_page) {
    "
    <html>
      <head>
        <meta charset='utf-8' />
        <link href='/css/reset.css' media='screen' rel='stylesheet' type='text/css'>
        <link href='/css/other.css' media='screen' rel='stylesheet' type='text/css'>
        <script src='/js/other.js' type='text/javascript'></script>
        <script src='/js/some-other.js' type='text/javascript'></script>
      </head>
      <body>
        <h1>Other example copy</h1>
        <a href='/'>Home</a>
        <a href='/another-page'>Another page</a>
        <a href='http://twitter.com/example'>Twitter</a>
      </body
    </html>
    "
  }

  before do
    allow(subject).to receive(:open).with(URI.parse("http://example.com")).and_return(root)
    allow(subject).to receive(:open).with(URI.parse("http://example.com/another-page")).and_return(another_page)
    allow(root).to receive(:content_type).and_return("text/html")
    allow(another_page).to receive(:content_type).and_return("text/html")
    allow_any_instance_of(Nokogiri::HTML::Document).to receive(:content_type).and_return("text/html")
  end

  context "when crawling a page" do
    it "returns the assets" do
      result = subject.crawl

      expect(result).to include("http://example.com/")
      expect(result).to include("js: /js/script.js, /js/main.js")
      expect(result).to include("css: /css/reset.css, /css/style.css")
      expect(result).to include("http://example.com/another-page")
      expect(result).to include("js: /js/other.js, /js/some-other.js")
      expect(result).to include("css: /css/reset.css, /css/other.css")

      expect(result).not_to include("http://twitter.com/example")
    end
  end
end
