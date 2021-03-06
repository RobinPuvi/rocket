# Description:
#   Get weather information using OpenWeatherMap for Hubot.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_OPEN_WEATHER_MAP_APIKEY = required API key from http://openweathermap.org/faq#error401
#   HUBOT_OPEN_WEATHER_MAP_URL (optional)
#   HUBOT_OPEN_WEATHER_MAP_FIND_COORDINATES (optional)
#   HUBOT_OPEN_WEATHER_MAP_FORECAST_URL (optional)
#   HUBOT_OPEN_WEATHER_MAP_DEFAULT_CITIES (optional)
#   HUBOT_OPEN_WEATHER_MAP_UNITS (optional) imperial, metric
#
# Commands:
#   hubot weather         provide weather information for the default cities
#   hubot weather <city>  provide weather information for a <city>
#   hubot forecast        provide weather forecast for the default cities
#   hubot forecast <city> provide weather forecast for a <city>
#   hubot weather help    explain OpenWeatherMap commands
#
# Author:
#   github.com/TrevorS
#   github.com/endodino
#   github.com/tan3

weatherURL = process.env.HUBOT_OPEN_WEATHER_MAP_URL or 'http://api.openweathermap.org/data/2.5/weather?q='
findWeatherCoordinatesURL = process.env.HUBOT_OPEN_WEATHER_MAP_FIND_COORDINATES or 'http://api.openweathermap.org/data/2.5/find?q='
forecastURL = process.env.HUBOT_OPEN_WEATHER_MAP_FORECAST_URL or 'http://api.openweathermap.org/data/2.5/onecall?'
cities     = process.env.HUBOT_OPEN_WEATHER_MAP_DEFAULT_CITIES
apiKey     = process.env.HUBOT_OPEN_WEATHER_MAP_APIKEY
units      = process.env.HUBOT_OPEN_WEATHER_MAP_UNITS or 'imperial'

module.exports = (robot) ->
  robot.respond /weather help$/i, (msg) ->
    msg.send 'Usage: hubot weather or hubot weather <city> or hubot forecast <city> for forecast'
    msg.finish()

  robot.respond /weather (.*)/i, (msg) ->
    weatherFor(msg, msg.match[1])

  robot.respond /weather$/i, (msg) ->
    if cities
      for city in cities.split(/\s*;\s*/)
        weatherFor(msg, city)

  weatherFor = (msg, input) ->
    robot.http(weatherURL + input + "&appid=" + apiKey + "&units=" + units)
      .get() (err, res, body) ->
        if err
          msg.send "Encountered an error :( #{err}"
          return
        json = JSON.parse body
        msg.send "It is currently #{json.main.temp} #{named_unit} in #{json.name}."

  robot.respond /forecast (.*)/i, (msg) ->
    forecastFindCoordinates(msg, msg.match[1])

  robot.respond /forecast$/i, (msg) ->
    if cities
      for city in cities.split(/\s*;\s*/)
        forecastFindCoordinates(msg, city)

  forecastFindCoordinates = (msg, input) ->
    robot.http(findWeatherCoordinatesURL + input + "&appid=" + apiKey )
      .get() (err, res, body) ->
        if err
          msg.send "Encountered an error :( #{err}"
          return
        json = JSON.parse body
        coordinates = "lat=#{json.list[0].coord.lat}&lon=#{json.list[0].coord.lon}"
        forecastFor(msg, coordinates)

  forecastFor = (msg, input) ->
    robot.http(forecastURL + input + "&appid=" + apiKey + "&units=" + units + "&exclude=hourly,minutely")
      .get() (err, res, body) ->
        if err
          msg.send "Encountered an error :( #{err}"
          return
        json = JSON.parse body
        msg.send "today we will have #{json.daily[0].temp.day} #{named_unit} with #{json.daily[0].weather[0].description} and feels like #{json.daily[0].feels_like.day} #{named_unit}.\n Tomorrow we will have #{json.daily[1].temp.day} #{named_unit} with #{json.daily[1].weather[0].description} and feels like #{json.daily[1].feels_like.day} #{named_unit}.\n The day after we will have #{json.daily[2].temp.day} #{named_unit} with #{json.daily[2].weather[0].description} and feels like #{json.daily[2].feels_like.day} #{named_unit}."

  named_unit = switch
    when units == "metric" then "??C"
    when units == "imperial" then "??F"
    else  "K"