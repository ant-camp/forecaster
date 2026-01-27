# frozen_string_literal: true

module ForecastHelper
  # Weather Code Mapping
  #
  # Maps World Meteorological Organization (WMO) standard weather codes
  # to human-readable descriptions and emoji icons.
  #
  # Code ranges:
  # - 0-3: Clear to cloudy conditions
  # - 45-48: Fog conditions
  # - 51-55: Drizzle (light to dense)
  # - 61-65: Rain (slight to heavy)
  # - 66-67: Freezing rain
  # - 71-77: Snow conditions
  # - 80-82: Rain showers
  # - 85-86: Snow showers
  # - 95-99: Thunderstorms
  #
  # @see https://open-meteo.com/en/docs for complete WMO code documentation
  #
  WEATHER_CODES = {
    0 => { description: 'Clear sky', icon: '☀️' },
    1 => { description: 'Mainly clear', icon: '🌤️' },
    2 => { description: 'Partly cloudy', icon: '⛅' },
    3 => { description: 'Overcast', icon: '☁️' },
    45 => { description: 'Foggy', icon: '🌫️' },
    48 => { description: 'Depositing rime fog', icon: '🌫️' },
    51 => { description: 'Light drizzle', icon: '🌧️' },
    53 => { description: 'Moderate drizzle', icon: '🌧️' },
    55 => { description: 'Dense drizzle', icon: '🌧️' },
    61 => { description: 'Slight rain', icon: '🌧️' },
    63 => { description: 'Moderate rain', icon: '🌧️' },
    65 => { description: 'Heavy rain', icon: '🌧️' },
    66 => { description: 'Light freezing rain', icon: '🌨️' },
    67 => { description: 'Heavy freezing rain', icon: '🌨️' },
    71 => { description: 'Slight snow', icon: '❄️' },
    73 => { description: 'Moderate snow', icon: '❄️' },
    75 => { description: 'Heavy snow', icon: '❄️' },
    77 => { description: 'Snow grains', icon: '❄️' },
    80 => { description: 'Slight rain showers', icon: '🌦️' },
    81 => { description: 'Moderate rain showers', icon: '🌦️' },
    82 => { description: 'Violent rain showers', icon: '🌦️' },
    85 => { description: 'Slight snow showers', icon: '🌨️' },
    86 => { description: 'Heavy snow showers', icon: '🌨️' },
    95 => { description: 'Thunderstorm', icon: '⛈️' },
    96 => { description: 'Thunderstorm with slight hail', icon: '⛈️' },
    99 => { description: 'Thunderstorm with heavy hail', icon: '⛈️' }
  }.freeze

  # Returns a human-readable weather description for a WMO weather code.
  #
  # @param code [Integer] WMO weather code from the forecast API
  # @return [String] Weather description (e.g., "Clear sky", "Moderate rain")
  #   Returns "Unknown" for unrecognized codes
  #
  # @example
  #   weather_description(0)  # => "Clear sky"
  #   weather_description(63) # => "Moderate rain"
  #   weather_description(999) # => "Unknown"
  #
  def weather_description(code)
    WEATHER_CODES.dig(code, :description) || 'Unknown'
  end

  # Returns an emoji icon representing the weather condition.
  #
  # @param code [Integer] WMO weather code from the forecast API
  # @return [String] Weather emoji icon (e.g., "☀️", "🌧️", "❄️")
  #   Returns "🌡️" (thermometer) for unrecognized codes
  #
  # @example
  #   weather_icon(0)  # => "☀️"
  #   weather_icon(71) # => "❄️"
  #   weather_icon(95) # => "⛈️"
  #
  def weather_icon(code)
    WEATHER_CODES.dig(code, :icon) || '🌡️'
  end

  # Formats a date string for display.
  #
  # Converts an ISO date string (YYYY-MM-DD) to a more readable format.
  #
  # @param date_string [String] Date in YYYY-MM-DD format
  # @return [String] Formatted date (e.g., "Mon, Jan 15")
  #
  # @example
  #   format_date("2024-01-15") # => "Mon, Jan 15"
  #   format_date("2024-12-25") # => "Wed, Dec 25"
  #
  def format_date(date_string)
    Date.parse(date_string).strftime('%a, %b %d')
  end

  # Returns a user-friendly day name based on position in forecast.
  #
  # The first day is always "Today", the second is "Tomorrow",
  # and subsequent days show the full weekday name.
  #
  # @param date_string [String] Date in YYYY-MM-DD format
  # @param index [Integer] Zero-based index in the forecast array
  # @return [String] Day name ("Today", "Tomorrow", or weekday like "Wednesday")
  #
  # @example
  #   day_name("2024-01-15", 0) # => "Today"
  #   day_name("2024-01-16", 1) # => "Tomorrow"
  #   day_name("2024-01-17", 2) # => "Wednesday"
  #
  def day_name(date_string, index)
    return 'Today' if index == 0
    return 'Tomorrow' if index == 1

    Date.parse(date_string).strftime('%A')
  end
end
