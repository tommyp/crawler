require 'open-uri'
require 'nokogiri'

class Crawler
  def initialize(domain)
    return unless domain.start_with?("http")

    @domain = URI.parse(domain).merge("/")
    @pages = {}
  end

  def crawl
    return unless @domain.to_s.start_with?("http")
    puts "Crawling..."
    crawl_page(@domain)

    formatted_results
  end

private

  def crawl_page(url)
    begin
      response = open(url)
      return if response.content_type != "text/html"

      body = Nokogiri::HTML(response)
    rescue OpenURI::HTTPError
      return
    end

    js = find_js(body)
    css = find_css(body)

    @pages[url.to_s] = {
      js: js,
      css: css,
    }

    hrefs = find_hrefs(body)

    hrefs
      .select(&method(:crawlable_href?))
      .map(&method(:clean_url))
      .reject(&method(:already_crawled?))
      .map(&method(:crawl_page))
  end

  def find_js(body)
    body.css("script").map { |j|
      j.attr("src")
    }.compact
  end

  def find_css(body)
    body.css("link[rel='stylesheet']").map { |c|
      c.attr("href")
    }.compact
  end

  def find_hrefs(body)
    body.css("a").map { |c|
      c.attr("href")
    }.compact.uniq
  end

  def crawlable_href?(url)
    return true if url.to_s.start_with?(@domain.to_s)
    return true if url.to_s.start_with?("/")

    false
  end

  def clean_url(url)
    @domain.merge(url)
  end

  def already_crawled?(url)
    @pages.key?(url.to_s)
  end

  def formatted_results
    "Assets for #{@domain.host}:
    #{@pages.map { |u, a| formatted_result(u, a) }.join}"
  end

  def formatted_result(url, assets)
    "#{url}:
      js: #{assets[:js].join(', ')}
      css: #{assets[:css].join(', ')}
    "
  end
end

raise "You must supply a domain" unless ARGV[0]

puts Crawler.new(ARGV[0]).crawl
