# frozen_string_literal: true

# ForecastController
#
# This controller handles weather forecast requests for the application.
# It serves as the main entry point for users to retrieve weather data
# based on a given address.
#
# == Responsibilities
# - Accept address input from users via query parameters
# - Delegate weather data fetching to the ForecastService
# - Handle successful responses by setting instance variables for the view
# - Handle error cases by displaying appropriate flash messages
#
# == Dependencies
# - ForecastService: Service object that handles geocoding and weather API calls
# - ForecastHelper: View helper for weather code translations and date formatting
#
# == Routes
# - GET /forecast (forecast_index_path) - Main forecast page
# - GET / (root_path) - Redirects to forecast index
#
# == Example Usage
# GET /forecast?address=Tampa,%20FL
# GET /forecast?address=New%20York,%20NY
#
class ForecastController < ApplicationController
  # GET /forecast
  #
  # Main action that displays weather forecast data for a given address.
  # If no address is provided, defaults to 'Tampa, FL'.
  #
  # == Request Parameters
  # - address [String] (optional): The location to fetch weather for.
  #   Accepts formats like "City, State", "City, Country", or just "City"
  #
  # == Instance Variables Set
  # - @address [String]: The address being queried (for form persistence)
  # - @location [Hash]: Location details (name, country) from geocoding
  # - @current [Hash]: Current weather conditions (temperature, humidity, etc.)
  # - @today [Hash]: Today's forecast summary (high, low, precipitation)
  # - @extended_forecast [Array<Hash>]: 7-day forecast data
  # - @from_cache [Boolean]: Whether data was served from cache
  #
  # == Response Scenarios
  # 1. Success: Weather data is fetched and displayed
  # 2. Cache Hit: Cached data is returned with cache indicator
  # 3. Failure: Flash alert is shown when weather data cannot be fetched
  #
  def index
    @address = address_params.presence || 'Tampa, FL'
    weather_data = ForecastService.new(@address).get_weather_data

    if weather_data.present?
      set_weather_data(weather_data)
    else
      flash.now[:alert] = 'Unable to fetch weather data for the given address.'
    end
  end

  private

  # Extracts the address parameter from the request.
  #
  # @return [String, nil] The address parameter value or nil if not present
  #
  def address_params
    params[:address]
  end

  # Sets instance variables from the weather data hash for use in the view.
  #
  # This method unpacks the weather data response from ForecastService
  # into individual instance variables that the view template expects.
  #
  # @param weather_data [Hash] The weather data hash from ForecastService containing:
  #   - 'location' [Hash]: Location information with 'name' and 'country'
  #   - 'current' [Hash]: Current conditions with temperature, humidity, wind, etc.
  #   - 'today' [Hash]: Today's forecast with high, low, and precipitation chance
  #   - 'extended_forecast' [Array]: Array of daily forecast hashes
  #   - 'from_cache' [Boolean]: Cache status indicator
  #
  # @return [void]
  #
  def set_weather_data(weather_data)
    @location = weather_data['location']
    @current = weather_data['current']
    @today = weather_data['today']
    @extended_forecast = weather_data['extended_forecast']
    @from_cache = weather_data['from_cache']
  end
end
