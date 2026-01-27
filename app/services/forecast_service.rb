# frozen_string_literal: true

require 'json'
require 'open-uri'

class ForecastService
  # Base URL for the Nominatim (OpenStreetMap) Geocoding API
  # Used to convert addresses (street, city, or full address) to latitude/longitude coordinates
  # Nominatim supports full addresses unlike Open-Meteo's city-only geocoding
  GEOCODING_BASE_URL = ENV.fetch('GEOCODING_BASE_URL')

  # Base URL for the Open-Meteo Weather Forecast API
  # Used to fetch current conditions and extended forecasts
  FORECAST_BASE_URL = ENV.fetch('FORECAST_BASE_URL')

  # Duration for which weather data is cached
  # Balances freshness of data with API rate limiting considerations
  CACHE_EXPIRATION = 30.minutes

  # Initializes a new ForecastService instance.
  #
  # @param address [String] The location to fetch weather for.
  #   Accepts formats like "Tampa, FL", "New York", "London, UK"
  #
  def initialize(address)
    @address = address
  end

  # Main method to retrieve weather data.
  #
  # This method orchestrates the entire weather data retrieval process:
  # 1. First checks the cache for existing data
  # 2. If cache miss, fetches fresh data from APIs
  # 3. Caches the fresh data for future requests
  # 4. Returns the data with a 'from_cache' indicator
  #
  # @return [Hash, nil] Weather data hash with 'from_cache' key, or nil on failure
  #
  def get_weather_data
    cached = read_from_cache
    return cached.merge('from_cache' => true) if cached.present?

    weather_data = fetch_weather_data
    return nil unless weather_data.present?

    write_to_cache(weather_data)
    weather_data.merge('from_cache' => false)
  end

  private

  # Reads weather data from the cache.
  #
  # @return [Hash, nil] Parsed JSON data from cache, or nil if not found
  #
  def read_from_cache
    cached_data = Rails.cache.read(cache_key)
    JSON.parse(cached_data) if cached_data.present?
  end

  # Writes weather data to the cache.
  #
  # @param data [Hash] The weather data to cache
  # @return [Boolean] True if write was successful
  #
  def write_to_cache(data)
    Rails.cache.write(cache_key, data.to_json, expires_in: CACHE_EXPIRATION)
  end

  # Generates a unique cache key for the address.
  #
  # The key is normalized to ensure consistent caching:
  # - Converted to lowercase
  # - Spaces replaced with underscores
  #
  # @return [String] The cache key (e.g., "weather_data_tampa,_fl")
  #
  def cache_key
    "weather_data_#{@address.downcase.gsub(/\s+/, '_')}"
  end

  # Orchestrates the complete weather data fetch process.
  #
  # This method coordinates:
  # 1. Geocoding the address to get coordinates
  # 2. Fetching forecast data using those coordinates
  # 3. Building the standardized response
  #
  # @return [Hash, nil] Complete weather data hash, or nil on any failure
  #
  def fetch_weather_data
    geo_data = fetch_geo_location
    return nil unless geo_data.present?

    forecast = fetch_forecast(geo_data['latitude'], geo_data['longitude'])
    return nil unless forecast.present?

    build_response(forecast, geo_data)
  end

  
  # Generic JSON fetching method with error handling.
  #
  # Provides a reusable pattern for API calls with:
  # - HTTP request execution with appropriate headers
  # - JSON parsing
  # - Error logging for HTTP and parsing failures
  #
  # @param url [String] The URL to fetch
  # @param error_context [String] Description for error logging
  # @param headers [Hash] Optional HTTP headers (default includes User-Agent for Nominatim compliance)
  # @return [Hash, Array, nil] Parsed JSON response, or nil on error
  #
  def fetch_json(url, error_context, headers = {})
    default_headers = { 'User-Agent' => 'WeatherForecastApp/1.0' }
    response = URI.open(url, default_headers.merge(headers)).read
    JSON.parse(response)
  rescue OpenURI::HTTPError, JSON::ParserError => e
    Rails.logger.error("#{error_context}: #{e.message}")
    nil
  end

  # Fetches geographic coordinates for the address using Nominatim Geocoding API.
  #
  # Nominatim returns an array of results; we take the first (most relevant) match
  # and normalize the response to a consistent format with 'latitude', 'longitude',
  # 'name', and 'country' keys.
  #
  # @return [Hash, nil] Geocoding result with 'latitude', 'longitude', 'name',
  #   'country', etc., or nil if location not found
  #
  def fetch_geo_location
    url = build_geocoding_url
    data = fetch_json(url, 'Geocoding error')
    return nil unless data.is_a?(Array) && data.first.present?

    result = data.first
    normalize_geo_result(result)
  end

  # Normalizes Nominatim response to a consistent format.
  #
  # Nominatim uses 'lat'/'lon' while we use 'latitude'/'longitude' internally.
  # Also extracts location name and country from the address components.
  #
  # @param result [Hash] Raw Nominatim result
  # @return [Hash] Normalized result with consistent keys
  #
  def normalize_geo_result(result)
    address = result['address'] || {}
    {
      'latitude' => result['lat'].to_f,
      'longitude' => result['lon'].to_f,
      'name' => extract_location_name(result, address),
      'country' => address['country'] || extract_country_from_display(result['display_name'])
    }
  end

  # Extracts the most appropriate location name from geocoding result.
  #
  # Tries city, town, village, municipality, county in order of preference.
  # Falls back to the first part of display_name if no address components found.
  #
  # @param result [Hash] Nominatim result
  # @param address [Hash] Address components from Nominatim
  # @return [String] Location name
  #
  def extract_location_name(result, address)
    address['city'] || address['town'] || address['village'] ||
      address['municipality'] || address['county'] ||
      result['display_name']&.split(',')&.first&.strip || 'Unknown'
  end

  # Extracts country from display_name as fallback.
  #
  # @param display_name [String] Full display name from Nominatim
  # @return [String] Country name or 'Unknown'
  #
  def extract_country_from_display(display_name)
    display_name&.split(',')&.last&.strip || 'Unknown'
  end

  # Fetches weather forecast data for given coordinates.
  #
  # @param lat [Float] Latitude coordinate
  # @param lon [Float] Longitude coordinate
  # @return [Hash, nil] Raw forecast data from API, or nil on error
  #
  def fetch_forecast(lat, lon)
    url = build_forecast_url(lat, lon)
    fetch_json(url, 'Weather fetch error')
  end

  # Builds the URL for the geocoding API request.
  #
  # Uses Nominatim's search API which accepts full addresses, city names,
  # or any location query. The addressdetails parameter ensures we get
  # structured address components in the response.
  #
  # @return [String] Complete geocoding API URL with encoded parameters
  #
  def build_geocoding_url
    params = {
      q: @address,
      format: 'json',
      limit: 1,
      addressdetails: 1
    }
    "#{GEOCODING_BASE_URL}?#{URI.encode_www_form(params)}"
  end

  # Builds the URL for the forecast API request.
  #
  # Requests the following data points:
  # - Current: temperature, humidity, apparent temp, weather code, wind speed
  # - Daily: high/low temps, weather codes, precipitation probability
  # - Settings: Fahrenheit units, automatic timezone detection
  #
  # @param lat [Float] Latitude coordinate
  # @param lon [Float] Longitude coordinate
  # @return [String] Complete forecast API URL with encoded parameters
  #
  def build_forecast_url(lat, lon)
    params = {
      latitude: lat,
      longitude: lon,
      current: 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      daily: 'temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max',
      temperature_unit: 'fahrenheit',
      timezone: 'auto'
    }
    "#{FORECAST_BASE_URL}?#{URI.encode_www_form(params)}"
  end

  # Builds the complete response hash from API data.
  #
  # @param forecast [Hash] Raw forecast data from weather API
  # @param geo_data [Hash] Geocoding data with location details
  # @return [Hash] Standardized weather data response
  #
  def build_response(forecast, geo_data)
    {
      'location' => build_location(geo_data),
      'current' => build_current_weather(forecast),
      'today' => build_today_forecast(forecast),
      'extended_forecast' => build_extended_forecast(forecast),
      'units' => forecast['daily_units']
    }
  end

  # Extracts location information from geocoding data.
  #
  # @param geo_data [Hash] Geocoding response data
  # @return [Hash] Location hash with 'name' and 'country' keys
  #
  def build_location(geo_data)
    {
      'name' => geo_data['name'],
      'country' => geo_data['country']
    }
  end

  # Extracts current weather conditions from forecast data.
  #
  # @param forecast [Hash] Forecast API response
  # @return [Hash] Current conditions including:
  #   - temperature: Current temperature in Fahrenheit
  #   - apparent_temperature: "Feels like" temperature
  #   - humidity: Relative humidity percentage
  #   - wind_speed: Wind speed in mph
  #   - weather_code: WMO weather code for icon/description lookup
  #
  def build_current_weather(forecast)
    current = forecast['current'] || {}
    {
      'temperature' => current['temperature_2m'],
      'apparent_temperature' => current['apparent_temperature'],
      'humidity' => current['relative_humidity_2m'],
      'wind_speed' => current['wind_speed_10m'],
      'weather_code' => current['weather_code']
    }
  end

  # Extracts today's forecast summary from daily data.
  #
  # @param forecast [Hash] Forecast API response
  # @return [Hash] Today's forecast with:
  #   - high: Expected high temperature
  #   - low: Expected low temperature
  #   - precipitation_probability: Chance of precipitation (0-100)
  #
  def build_today_forecast(forecast)
    daily = forecast['daily'] || {}
    {
      'high' => daily.dig('temperature_2m_max', 0),
      'low' => daily.dig('temperature_2m_min', 0),
      'precipitation_probability' => daily.dig('precipitation_probability_max', 0)
    }
  end

  # Builds the extended (7-day) forecast array.
  #
  # @param forecast [Hash] Forecast API response
  # @return [Array<Hash>] Array of daily forecast hashes, empty array if no data
  #
  def build_extended_forecast(forecast)
    daily = forecast['daily']
    return [] unless daily.present?

    daily['time'].each_with_index.map do |date, index|
      build_daily_forecast(daily, date, index)
    end
  end

  # Builds a single day's forecast hash.
  #
  # @param daily [Hash] Daily forecast data from API
  # @param date [String] Date string in YYYY-MM-DD format
  # @param index [Integer] Index into the daily arrays
  # @return [Hash] Daily forecast with date, high, low, weather_code,
  #   and precipitation_probability
  #
  def build_daily_forecast(daily, date, index)
    {
      'date' => date,
      'high' => daily['temperature_2m_max'][index],
      'low' => daily['temperature_2m_min'][index],
      'weather_code' => daily['weather_code'][index],
      'precipitation_probability' => daily['precipitation_probability_max'][index]
    }
  end
end
