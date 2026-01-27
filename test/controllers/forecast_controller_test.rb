require "test_helper"

class ForecastControllerTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
  end

  test "should get index with default address" do
    mock_weather_data = {
      'location' => { 'name' => 'Tampa', 'country' => 'United States' },
      'current' => {
        'temperature' => 75.0,
        'apparent_temperature' => 77.0,
        'humidity' => 65,
        'wind_speed' => 10.0,
        'weather_code' => 1
      },
      'today' => { 'high' => 82.0, 'low' => 68.0, 'precipitation_probability' => 20 },
      'extended_forecast' => [],
      'from_cache' => false
    }

    ForecastService.any_instance.stubs(:get_weather_data).returns(mock_weather_data)

    get forecast_index_url
    assert_response :success
    assert_select "h2", /Tampa/
  end

  test "should get index with custom address" do
    mock_weather_data = {
      'location' => { 'name' => 'New York', 'country' => 'United States' },
      'current' => {
        'temperature' => 45.0,
        'apparent_temperature' => 40.0,
        'humidity' => 55,
        'wind_speed' => 15.0,
        'weather_code' => 3
      },
      'today' => { 'high' => 50.0, 'low' => 35.0, 'precipitation_probability' => 40 },
      'extended_forecast' => [],
      'from_cache' => false
    }

    ForecastService.any_instance.stubs(:get_weather_data).returns(mock_weather_data)

    get forecast_index_url, params: { address: "New York, NY" }
    assert_response :success
    assert_select "h2", /New York/
  end

  test "should show alert when weather data unavailable" do
    ForecastService.any_instance.stubs(:get_weather_data).returns(nil)

    get forecast_index_url, params: { address: "Invalid Address 12345" }
    assert_response :success
    assert_select ".alert-danger", /Unable to fetch weather data/
  end

  test "should show cache notice when data is from cache" do
    mock_weather_data = {
      'location' => { 'name' => 'Tampa', 'country' => 'United States' },
      'current' => {
        'temperature' => 75.0,
        'apparent_temperature' => 77.0,
        'humidity' => 65,
        'wind_speed' => 10.0,
        'weather_code' => 1
      },
      'today' => { 'high' => 82.0, 'low' => 68.0, 'precipitation_probability' => 20 },
      'extended_forecast' => [],
      'from_cache' => true
    }

    ForecastService.any_instance.stubs(:get_weather_data).returns(mock_weather_data)

    get forecast_index_url
    assert_response :success
    assert_select ".cache-notice", /cached data/
  end
end
