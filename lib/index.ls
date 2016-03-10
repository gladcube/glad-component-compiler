require! <[fs async jade browserify browserify-livescript]>

module.exports = ({src}:options)->
  (req, res, next)->
    [_, dir, name] = req.base-url.match /([^/]+)\/([^/.]+)\.[^/.]+$/
    err, [html, script] <- async.parallel [
      (next)->
        err, content <- fs.read-file "#src/#dir/#name.jade"
        if err? then next err; return
        content |> jade.render |> next null, _
      , (next)->
        err, content <- browserify "#src/#dir/#name.ls", transform: [browserify-livescript] .bundle
        if err? then next err; return
        content |> ( .to-string!) |> next null, _
    ]
    html + "<script>#script</script>"
    |> res.end


