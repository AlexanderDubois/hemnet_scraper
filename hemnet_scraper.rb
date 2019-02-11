require 'rest-client'
require 'pry'
require 'nokogiri'
require 'json'

@data = []
@values = {starting_price: "kr", price_per_square_meters: "kr/m²", number_of_rooms: "rum", living_are_square_meters: "m²", cost_per_month: "kr/mån"}

def parse_sold_property_data(link)

  proprety_details_css = "div.sold-property__details dl dd.sold-property__attribute-value"
  sold_price_css = "span.sold-property__price-value"
  title_css = "h1.sold-property__address"
  sold_date_css = "p.sold-property__metadata time"

  details_data = data_from_link(link, proprety_details_css)
  sold_price_data = data_from_link(link, sold_price_css)
  title_data = data_from_link(link, title_css)
  sold_date = data_from_link(link, sold_date_css)

  titel = title_data[0].text.split("\n").last
  sold_price = sold_price_data[0].text.split(" kr")[0]
  sold_date = sold_date[0].values[0]

  organize_and_store_data(details_data, titel, sold_price, sold_date)

end

def organize_and_store_data(data, title, sold_price, sold_date)

  current_hash = {title => {}}
  current_hash[title][:sold_price] = sold_price
  current_hash[title][:sold_date] = sold_date

  data.each do |row|
    @values.each do |key, unit|
      if !row.text.include?("%")
        if row.text.split(" ").include?(unit)
          current_hash[title][key] = row.text
        elsif (1700..2019).include?(row.text.to_i)
          current_hash[title][:construction_year] = row.text
        end
      end
    end
  end

  @data << current_hash

end

def scrape_page(link)

  css = "li.sold-results__normal-hit div.sold-property-listing a.item-link-container"
  webpage_data = data_from_link(link, css)
  webpage_data.each do |data|

    sold_propety_link = data.attr("href").split("/maklare/salda/")[0]
    parse_sold_property_data(sold_propety_link)

  end
end

def scrape_hemnet
  number_of_pages = (1..12239)
  number_of_pages.each do |index|
    link = "https://www.hemnet.se/salda/bostader?page=#{index}&sold_age=all"
    scrape_page(link)
  end

  save_json_to_file(@data)
end

def data_from_link(link, css_input)
  response_string = RestClient.get(link)
  webpage = Nokogiri::HTML(response_string)
  webpage_data = webpage.css(css_input)
end

def save_json_to_file(data)
  json_file = File.new('hemnet_json.json', 'w')
  json_file.write(data.to_json)
  json_file.close
end


#binding.pry
#0
