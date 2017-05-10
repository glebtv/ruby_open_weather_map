require 'net/http'
require 'json'

module OpenWeather
  class Base

    attr_reader :url, :options, :weather_info, :status, :message

    def initialize(url, options)
      @status       = false
      @url          = url
      @options      = extract_options!(options)
      @weather_info = { 'cod': nil, 'message': '' }
    end

    def retrieve(url=nil)
      response = send_request url unless @options.empty?
      parse_response(response)
    end

    def success?
      @status == 200
    end

    private

    def extract_options!(options)
      valid_options = [ :id, :lat, :lon, :cnt, :city, :lang, :units, :APPID,
        :country, :bbox, :q, :type]

      options.keys.each { |k| options.delete(k) unless valid_options.include?(k) }

      if options[:city] || options[:country]
        options[:q] = "#{options[:country]},#{options[:city]}"
        options.delete(:city)
        options.delete(:country)
      end

      options
    end

    def parse_response(response)
      return if response.nil?

      if response.is_a?(Net::HTTPSuccess)
        begin
          resp = JSON.parse(response.body)
          if resp.is_a?(Integer)
            @weather_info['cod']      = resp
            @weather_info['message']  = "Bad response"
          else
            @weather_info = resp
          end
        rescue JSON::ParserError
          @weather_info['cod']      = 500
          @weather_info['message']  = 'JSON parse error'
        end
      else
        @weather_info['cod']      = response.code
        @weather_info['message']  = response.message
      end

      @weather_info
    end

    def send_request(url=nil)
      url       = url || @url
      uri       = URI(url)
      uri.query = URI.encode_www_form(options)
      Net::HTTP.get_response(uri)
    end
  end
end
