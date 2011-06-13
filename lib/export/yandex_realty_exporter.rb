# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class YandexRealtyExporter
    include ActionController::UrlWriter
    attr_accessor :host, :currencies
    
#    DEFAULT_OFFER = "simple"

    def helper
      @helper ||= ApplicationController.helpers
    end
    
    def export
      
      Nokogiri::XML::Builder.new(:encoding =>"utf-8") do |xml|
        xml.realty-feed(:xmlns => "http://webmaster.yandex.ru/schemas/feed/realty/2010-06") {
          
        }
      end.to_xml
      
    end
    
    
    private
    # :type => "book"
    # :type => "audiobook"
    # :type => misic
    # :type => video
    # :type => tour
    # :type => event_ticket
    
    def path_to_url(path)
      "http://#{@host.sub(%r[^http://],'')}/#{path.sub(%r[^/],'')}"
    end
    
    def offer(xml,product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      wares_type_value = product_properties[@config.preferred_wares_type]
      if ["book", "audiobook", "music", "video", "tour", "event_ticket", "vendor_model"].include? wares_type_value
        send("offer_#{wares_type_value}".to_sym, xml, product, cat)
      else
        send("offer_#{DEFAULT_OFFER}".to_sym, xml, product, cat)      
      end
    end
    
    # общая часть для всех видов продукции
    def shared_xml(xml, product, cat)
      xml.url Spree::Config[:yandex_market_use_utm_labels] ? product_url(product, :host => @host, :utm_source => 'market.yandex.ru', :utm_medium => 'cpc', :utm_campaign => 'market') : product_url(product, :host => @host)
      xml.price product.price
      xml.currencyId @currencies.first.first
      xml.categoryId cat.id
      xml.picture path_to_url(CGI.escape(product.images.first.attachment.url(:product, false))) unless product.images.empty?
    end

    
    # Обычное описание
    def offer_vendor_model(xml,product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id, :type => "vendor.model", :available => (@config.preferred_only_backorder ? false : product.has_stock?) }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        # xml.delivery               !product.shipping_category.blank?
        # На самом деле наличие shipping_category не обязательно должно быть чтобы была возможна доставка
        # смотри http://spreecommerce.com/documentation/shipping.html#shipping-category
        xml.delivery               true
        xml.local_delivery_cost    @config.preferred_local_delivery_cost unless @config.preferred_local_delivery_cost.blank?
        xml.typePrefix             product_properties[@config.preferred_type_prefix] if product_properties[@config.preferred_type_prefix]
        xml.name                   product.name
        xml.vendor                 product_properties[@config.preferred_vendor] if product_properties[@config.preferred_vendor]
        xml.vendorCode             product_properties[@config.preferred_vendor_code] if product_properties[@config.preferred_vendor_code]
        xml.model                  product_properties[@config.preferred_model] if product_properties[@config.preferred_model]
        xml.description            product.description if product.description
        xml.sales_notes            @config.preferred_sales_notes unless @config.preferred_sales_notes.blank?
        xml.manufacturer_warranty  !product_properties[@config.preferred_manufacturer_warranty].blank? 
        xml.country_of_origin      product_properties[@config.preferred_country_of_manufacturer] if product_properties[@config.preferred_country_of_manufacturer]
        xml.downloadable           false
      }
    end

    # простое описание
    def offer_simple(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id,  :available => (@config.preferred_only_backorder ? false : product.has_stock?) }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        xml.delivery               true
        xml.local_delivery_cost @config.preferred_local_delivery_cost unless @config.preferred_local_delivery_cost.blank?
        xml.name                product.name
        xml.vendorCode          product_properties[@config.preferred_vendor_code]
        xml.description         product.description
        xml.sales_notes         @config.preferred_sales_notes unless @config.preferred_sales_notes.blank?
        xml.country_of_origin   product_properties[@config.preferred_country_of_manufacturer] if product_properties[@config.preferred_country_of_manufacturer]
        xml.downloadable false   
      }
    end
    
    # Книги
    def offer_book(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id, :type => "book", :available => product.has_stock? }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        
        xml.delivery true
        xml.local_delivery_cost @config.preferred_local_delivery_cost unless @config.preferred_local_delivery_cost.blank?
        
        xml.author product_properties[@config.preferred_author]
        xml.name product.name
        xml.publisher product_properties[@config.preferred_publisher]
        xml.series product_properties[@config.preferred_series]
        xml.year product_properties[@config.preferred_year]
        xml.ISBN product_properties[@config.preferred_isbn]
        xml.volume product_properties[@config.preferred_volume]
        xml.part product_properties[@config.preferred_part]
        xml.language product_properties[@config.preferred_language]
        
        xml.binding product_properties[@config.preferred_binding]
        xml.page_extent product_properties[@config.preferred_page_extent]
        
        xml.description product.description
        xml.sales_notes @config.preferred_sales_notes unless @config.preferred_sales_notes.blank?
        xml.downloadable false
      }
    end
    
    # Аудиокниги
    def offer_audiobook(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }      
      opt = { :id => product.id, :type => "audiobook", :available => product.has_stock?  }
      xml.offer(opt) {  
        shared_xml(xml, product, cat)
        
        xml.author product_properties[@config.preferred_author]
        xml.name product.name
        xml.publisher product_properties[@config.preferred_publisher]
        xml.series product_properties[@config.preferred_series]
        xml.year product_properties[@config.preferred_year]
        xml.ISBN product_properties[@config.preferred_isbn]
        xml.volume product_properties[@config.preferred_volume]
        xml.part product_properties[@config.preferred_part]
        xml.language product_properties[@config.preferred_language]
        
        xml.performed_by product_properties[@config.preferred_performed_by]
        xml.storage product_properties[@config.preferred_storage]
        xml.format product_properties[@config.preferred_format]
        xml.recording_length product_properties[@config.preferred_recording_length]
        xml.description product.description
        xml.downloadable true
        
      }
    end
    
    # Описание музыкальной продукции
    def offer_music(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id, :type => "artist.title", :available => product.has_stock?  }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        xml.delivery true        

        
        xml.artist product_properties[@config.preferred_artist]
        xml.title  product_properties[@config.preferred_title]
        xml.year   product_properties[@config.preferred_music_video_year]
        xml.media  product_properties[@config.preferred_media]
        
        xml.description product.description
        
      }
    end
    
    # Описание видео продукции:
    def offer_video(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id, :type => "artist.title", :available => product.has_stock?  }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        
        xml.delivery true        
        xml.title             product_properties[@config.preferred_title]
        xml.year              product_properties[@config.preferred_music_video_year]
        xml.media             product_properties[@config.preferred_media]
        xml.starring          product_properties[@config.preferred_starring]
        xml.director          product_properties[@config.preferred_director]
        xml.originalName      product_properties[@config.preferred_original_name]
        xml.country_of_origin product_properties[@config.preferred_video_country]
        xml.description product_url.description
      }
    end
    
    # Описание тура
    def offer_tour(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }
      opt = { :id => product.id, :type => "tour", :available => product.has_stock?  }
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        
        xml.delivery true        
        xml.local_delivery_cost @config.preferred_local_delivery_cost unless @config.preferred_local_delivery_cost.blank?
        xml.worldRegion ""
        xml.country ""
        xml.region ""
        xml.days ""
        xml.dataTour ""
        xml.dataTour ""
        xml.name ""
        xml.hotel_stars ""
        xml.room ""
        xml.meal ""
        xml.included ""
        xml.transport ""
        xml.description product.description
        xml.sales_notes @config.sales_notes unless @config.preferred_sales_notes.blank?
      }
    end
    
    # Описание билетов на мероприятия
    def offer_event_ticket(xml, product, cat)
      product_properties = { }
      product.product_properties.map {|x| product_properties[x.property_name] = x.value }      
      opt = { :id => product.id, :type => "event-ticket", :available => product.has_stock?  }    
      xml.offer(opt) {
        shared_xml(xml, product, cat)
        xml.delivery true                
        xml.local_delivery_cost @config.preferred_local_delivery_cost unless @config.preferred_local_delivery_cost.blank?
        xml.name product.name
        xml.place product_properties[@config.preferred_place]
        xml.hall(:plan => product_properties[@config.preferred_hall_url_plan]) { xml << product_properties[@config.preferred_hall] }
        xml.date product_properties[@config.preferred_event_date]
        xml.is_premiere !product_properties[@config.preferred_is_premiere].blank? 
        xml.is_kids !product_properties[@config.preferred_is_kids].blank? 
        xml.description product.description
        xml.sales_notes @config.preferred_sales_notes unless @config.preferred_sales_notes.blank?
      }
    end
    
  end
end
