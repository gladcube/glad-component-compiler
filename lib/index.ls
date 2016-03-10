require! <[fs async jade browserify browserify-livescript]>

module.exports =
  express: ({src}:options)->
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
  compile: ({src, dest, flatten}:options, cb)->
    err, results <- async.parallel (
      fs.readdir-sync src
      |> map (dir)->
        fs.readdir-sync "#src/#dir"
        |> map ( .match /([^.]+)\.\w+/ .1)
        |> unique
        |> map (name)->
          (next)->
            html = fs.read-file-sync "#src/#dir/#name.jade" |> jade.render
            err, content <- browserify "#src/#dir/#name.ls", transform: [browserify-livescript] .bundle
            js = content |> ( .to-string!) |> ("<script>" + ) |> ( + "</script>")
            switch
            | flatten => fs.write-file-sync "#dest/#name.html", (html + js)
            | _ =>
              if not (fs.exists-sync (path = "#dest/#dir")) then fs.mkdir-sync path
              fs.write-file-sync "#dest/#dir/#name.html", (html + js)
            next!
      |> concat
    )
    cb!



