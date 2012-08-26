path = require "path"

require("fs").readdirSync(__dirname).forEach (file) ->
  require(path.join __dirname, file)
