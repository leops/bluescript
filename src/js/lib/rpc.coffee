define ['jquery', 'logger'], ($, Logger) ->
        return (viewport, compiler) ->
            logger = new Logger $('#logs')
            remote = module.require 'remote'
            dialog = remote.require 'dialog'
            fs = remote.require 'fs'

            savePath = null
            saveDialog = ->
                dialog.showSaveDialog remote.getCurrentWindow(), {
                    filters: [
                        { name: 'BlueScript', extensions: ['bs'] }
                    ]
                }, (path) ->
                    if path?
                        savePath = path
                        fs.writeFile path, viewport.serialize(), (err) ->
                            console.log err

            loadDialog = ->
                dialog.showOpenDialog remote.getCurrentWindow(), {
                    filters: [
                        { name: 'BlueScript', extensions: ['bs'] }
                    ]
                    properties: ['openFile']
                }, (paths) ->
                    if paths?
                        for path in paths
                            savePath = path
                            fs.readFile path, (err, data) ->
                                console.log err
                                viewport.parse data

            exportDialog = ->
                dialog.showSaveDialog remote.getCurrentWindow(), {
                    filters: [
                        { name: 'CoffeeScript', extensions: ['coffee'] }
                        { name: 'JavaScript', extensions: ['js'] }
                    ]
                }, (path) ->
                    if path?
                        content = compiler.compile()
                        if path.match /\.js$/
                            content = CoffeeScript.compile content
                        fs.writeFile path, content, (err) ->
                            console.log err

            return (message) ->
                switch message
                    when 'run' then logger.print 'Program result: "' + compiler.run() + '"'
                    when 'clear' then $('#output').html('')
                    when 'new'
                        savePath = null
                        viewport.init()
                    when 'open' then loadDialog()
                    when 'saveAs' then saveDialog()
                    when 'export' then exportDialog()
                    when 'save'
                        if savePath?
                            fs.writeFile savePath, viewport.serialize(), (err) ->
                                console.log err
                        else
                            saveDialog()
                    when 'copy' then viewport.copy()
                    when 'cut' then viewport.cut()
                    when 'paste' then viewport.paste()
                    when 'delete' then viewport.removeSelection()
                    when 'selectAll' then viewport.selectAll()
                    when 'setTheme' then $('body').attr('data-theme', arguments[1])
                    else
                        console.warn 'Unknown message', arguments
