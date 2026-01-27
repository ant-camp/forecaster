# Weather Forecast Application

A Ruby on Rails application that provides weather forecasts for any location using the Open-Meteo API. Enter a full address, city name, or any location query and get current conditions plus a 7-day extended forecast.

## Table of Contents

- [Object Decomposition](#object-decomposition)
- [Getting Started](#getting-started)
- [Running the Application](#running-the-application)
- [Running Tests](#running-tests)
- [API Information](#api-information)

## Object Decomposition

### Controllers

#### `ForecastController`
**Location:** `app/controllers/forecast_controller.rb`

The main controller handling weather forecast requests. Follows the thin controller pattern by delegating business logic to the service layer.

| Method | Type | Description |
|--------|------|-------------|
| `index` | Action | Main entry point; fetches weather data and prepares view variables |
| `address_params` | Private | Extracts and returns the address parameter from the request |
| `set_weather_data` | Private | Unpacks weather data hash into instance variables for the view |

**Instance Variables Set:**
- `@address` - The queried location string
- `@location` - Hash with city name and country
- `@current` - Current weather conditions
- `@today` - Today's forecast summary
- `@extended_forecast` - Array of 7-day forecasts
- `@from_cache` - Boolean indicating cache hit

---

### Services

#### `ForecastService`
**Location:** `app/services/forecast_service.rb`

Core service object responsible for fetching, caching, and transforming weather data. Integrates with two external APIs and implements a caching layer.

| Method | Type | Description |
|--------|------|-------------|
| `initialize(address)` | Public | Creates service instance with target address |
| `get_weather_data` | Public | Main entry point; returns cached or fresh weather data |
| `read_from_cache` | Private | Retrieves data from Rails cache |
| `write_to_cache` | Private | Stores data in Rails cache with expiration |
| `cache_key` | Private | Generates normalized cache key from address |
| `fetch_weather_data` | Private | Orchestrates geocoding and forecast API calls |
| `fetch_json` | Private | Generic HTTP GET with JSON parsing and error handling |
| `fetch_geo_location` | Private | Calls Nominatim API to convert address to coordinates |
| `normalize_geo_result` | Private | Normalizes Nominatim response to consistent format |
| `extract_location_name` | Private | Extracts city/town name from address components |
| `extract_country_from_display` | Private | Fallback country extraction from display name |
| `fetch_forecast` | Private | Calls forecast API with latitude/longitude |
| `build_geocoding_url` | Private | Constructs Nominatim geocoding API URL |
| `build_forecast_url` | Private | Constructs forecast API URL with parameters |
| `build_response` | Private | Assembles final response hash from API data |
| `build_location` | Private | Extracts location info from geocoding response |
| `build_current_weather` | Private | Transforms current conditions data |
| `build_today_forecast` | Private | Extracts today's forecast summary |
| `build_extended_forecast` | Private | Builds array of daily forecasts |
| `build_daily_forecast` | Private | Creates single day forecast hash |

**Constants:**
- `GEOCODING_BASE_URL` - Nominatim (OpenStreetMap) geocoding endpoint
- `FORECAST_BASE_URL` - Open-Meteo forecast endpoint
- `CACHE_EXPIRATION` - 30 minutes

---

### Helpers

#### `ForecastHelper`
**Location:** `app/helpers/forecast_helper.rb`

View helper module providing weather display utilities. Translates WMO weather codes to human-readable descriptions and emoji icons.

| Method | Description |
|--------|-------------|
| `weather_description(code)` | Returns text description for WMO weather code |
| `weather_icon(code)` | Returns emoji icon for WMO weather code |
| `format_date(date_string)` | Formats ISO date to "Mon, Jan 15" format |
| `day_name(date_string, index)` | Returns "Today", "Tomorrow", or weekday name |

**Constants:**
- `WEATHER_CODES` - Hash mapping WMO codes to descriptions and icons

---

### Views

#### `forecast/index.html.erb`
**Location:** `app/views/forecast/index.html.erb`

Main forecast view template displaying:
- Search form for address input
- Flash messages for errors
- Cache indicator when showing cached data
- Current weather conditions card
- 7-day extended forecast grid

---

### Configuration

#### Routes (`config/routes.rb`)
| Route | Controller#Action | Description |
|-------|-------------------|-------------|
| `GET /` | `forecast#index` | Root path (redirects to forecast) |
| `GET /forecast` | `forecast#index` | Main forecast page |
| `GET /up` | `rails/health#show` | Health check endpoint |

## Getting Started

### Prerequisites

- **Ruby:** 3.2.0 or higher
- **Rails:** 7.2.x
- **PostgreSQL:** 12.0 or higher
- **Bundler:** 2.0 or higher

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd weather_forecast_app
   ```

2. **Install Ruby dependencies:**
   ```bash
   bundle install
   ```

3. **Set up the database:**
   ```bash
   # Create the databases
   bin/rails db:create

   # Run migrations (if any)
   bin/rails db:migrate
   ```

4. **Verify installation:**
   ```bash
   bin/rails --version
   ```

### Environment Configuration

No API keys are required. The application uses the free Open-Meteo API which does not require authentication.

The API base URLs are configured via environment variables. In development and test, these can be set in a `.env` file (loaded by `dotenv-rails`):

```bash
# Nominatim (OpenStreetMap) for geocoding - supports full addresses
GEOCODING_BASE_URL=https://nominatim.openstreetmap.org/search

# Open-Meteo for weather forecasts
FORECAST_BASE_URL=https://api.open-meteo.com/v1/forecast
```

For production deployments, consider configuring:
- `RAILS_ENV=production`
- `SECRET_KEY_BASE` - Run `bin/rails secret` to generate
- `DATABASE_URL` - PostgreSQL connection string

## Running the Application

### Development Mode

```bash
# Start the Rails server
bin/rails server

# Or with specific port
bin/rails server -p 3000
```

The application will be available at: **http://localhost:3000**

### Production Mode

```bash
# Precompile assets
RAILS_ENV=production bin/rails assets:precompile

# Start server
RAILS_ENV=production bin/rails server
```

### Using Docker

```bash
# Build the image
docker build -t weather_forecast_app .

# Run the container
docker run -p 3000:3000 weather_forecast_app
```

## Running Tests

### Run All Tests

```bash
bin/rails test
```

### Run Specific Test File

```bash
bin/rails test test/controllers/forecast_controller_test.rb
```

### Run with Verbose Output

```bash
bin/rails test -v
```

### Code Quality Tools

```bash
# Run RuboCop for style checking
bin/rubocop

# Run Brakeman for security analysis
bin/brakeman
```

## API Information

### Nominatim Geocoding API (OpenStreetMap)

**Endpoint:** `https://nominatim.openstreetmap.org/search`

Converts addresses, city names, or any location query to geographic coordinates. Supports full addresses like "123 Main St, Tampa, FL" as well as simple city names.

**Parameters:**
- `q` - Search query (full address, city name, or location)
- `format` - Response format (json)
- `limit` - Number of results (we use 1)
- `addressdetails` - Include address components in response (1)

**Example Queries:**
- `123 Main Street, Tampa, FL`
- `Tampa, FL`
- `Empire State Building, New York`
- `London, UK`

### Open-Meteo Forecast API

**Endpoint:** `https://api.open-meteo.com/v1/forecast`

Provides weather forecast data for given coordinates.

**Parameters:**
- `latitude` / `longitude` - Location coordinates
- `current` - Current conditions to include
- `daily` - Daily forecast fields to include
- `temperature_unit` - fahrenheit or celsius
- `timezone` - auto (detects from coordinates)

### WMO Weather Codes

The API returns standard WMO weather codes:

| Code Range | Condition Type |
|------------|----------------|
| 0-3 | Clear to cloudy |
| 45-48 | Fog |
| 51-55 | Drizzle |
| 61-65 | Rain |
| 66-67 | Freezing rain |
| 71-77 | Snow |
| 80-82 | Rain showers |
| 85-86 | Snow showers |
| 95-99 | Thunderstorms |
