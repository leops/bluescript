define ["jquery"], ($) ->
    class BaseNode
        constructor: (@options, @viewport) ->
            self = @
            @inputs = @outputs = {}

            @element = @setupElement(options).click((e) ->
                e.stopPropagation()
                $(@).addClass 'selected'
            ).on('copy', (e) ->
                e.preventDefault()
                console.log 'copy'
                clipboard = require 'clipboard'
            ).mousedown((e) ->
                e.preventDefault()
                e.stopPropagation()

                $(@).addClass 'selected'

                $('.selected').each (i, elem) ->
                    elem = $(elem)
                    offset = elem.offset()
                    mouse = {x: e.clientX - offset.left, y: e.clientY - offset.top}
                    id = elem.attr('id')
                    mousemove = (e) ->
                        e.preventDefault()
                        elem.offset {left: e.clientX - mouse.x, top: e.clientY - mouse.y}
                        viewport.nodes[id].options.pos.x = e.clientX - mouse.x
                        viewport.nodes[id].options.pos.y = e.clientY - mouse.y
                        for c in viewport.connections when c.origin is id or c.target is id
                            container = viewport.element.offset()
                            start = $('#' + c.origin + ' .node-output[data-index=' + c.start + ']')
                            end = $('#' + c.target + ' .node-input[data-index=' + c.end + ']')
                            if c.path?
                                c.path.attr('d', viewport.pathD({
                                    x: (start.offset().left + start.width()) - container.left
                                    y: (start.offset().top + (start.height() / 2)) - container.top
                                }, {
                                    x: (end.offset().left) - container.left
                                    y: (end.offset().top + (end.height() / 2)) - container.top
                                }))
                            else
                                c.path = viewport.connect({
                                    x: (start.offset().left + start.width()) - container.left
                                    y: (start.offset().top + (start.height() / 2)) - container.top
                                }, {
                                    x: (end.offset().left) - container.left
                                    y: (end.offset().top + (end.height() / 2)) - container.top
                                })

                    $(document).mousemove mousemove
                    $(document).mouseup (e) ->
                        e.preventDefault()
                        e.stopPropagation()
                        $(document).off 'mousemove', mousemove
            )

            @setupPins()

        setupPins: ->
            if @options.inputs?
                for input, i in @options.inputs
                    do (input, i) =>
                        @createInput input, i

            if @options.outputs?
                for output, j in @options.outputs
                    do (output, j) =>
                        @createOutput output, j

        createInput: (input, i) ->
            elem = $("<div class=\"node-input pin-#{input.type}\" data-index=\"#{i}\">#{input.displayName || @formatName input.name}</div>")
            @setupInput elem

            if input.type isnt 'exec'
                val = input.value || ''
                $('<input type="text" value="' + val + '"/>')
                .mousedown((e) ->
                    e.stopPropagation()
                )
                .appendTo elem

            elem.appendTo(@element.find('.node-inputs'))
            @inputs[i] = elem

        createOutput: (output, j) ->
            if output.name is 'return'
                output.name = 'returnVal["' + @options.id + '"]'
            elem = $("<div class=\"node-output pin-#{output.type}\" data-index=\"#{j}\">#{output.displayName || @formatName output.name}</div>")
            @setupOutput elem
            elem.appendTo @element.find('.node-outputs')
            @outputs[j] = elem

        formatName: (name) -> name[0].toUpperCase() + name.slice(1).replace /[A-Z0-9]/g, (char) -> ' ' + char.toUpperCase()

        setupElement: (options) ->
            if not options.pos?
                options.pos =
                    x: 0
                    y: 0

            return $("<div id=\"#{options.id}\" class=\"node node-#{options.type}\" style=\"left: #{options.pos.x}px; top: #{options.pos.y}px;\">
                <header>
                    <h1>#{@formatName options.title}</h1>
                    <h2>#{options.subtitle || ''}</h2>
                </header>
                <div class=\"node-body\">
                    <div class=\"node-inputs\"></div>
                    <div class=\"node-outputs\"></div>
                </div>
            </div>")

        setupOutput: (elem) =>
            elem.mousedown((e) =>
                e.preventDefault()
                e.stopPropagation()

                offset = $(e.target).offset()
                container = @viewport.element.offset()
                path = @viewport.connect {x: offset.left + container.left, y: offset.top + container.top}, {x: e.pageX - container.left, y: e.pageY - container.top}
                index = $(e.target).data('index')

                mousemove = (e) =>
                    e.preventDefault()
                    path.attr('d', @viewport.pathD({x: offset.left - container.left, y: offset.top - container.top}, {x: e.pageX - container.left, y: e.pageY - container.top}))

                $(document).mousemove(mousemove)
                .one 'mouseup', (e) =>
                    e.preventDefault()
                    $(document).off 'mousemove', mousemove
                    if $(e.target).hasClass 'node-input'
                        if elem.hasClass 'active'
                            for link, i in @viewport.connections when link? and link.origin is @options.id and link.start is index and link.type is 'exec'
                                link.path.remove()
                                @viewport.connections.splice i, 1
                        if $(e.target).hasClass 'active'
                            for link, i in @viewport.connections when link? and link.target is $(e.target).closest('.node').attr('id') and link.end is $(e.target).data('index') and link.type isnt 'exec'
                                link.path.remove()
                                @viewport.connections.splice i, 1
                        @viewport.createConnection @options.outputs[elem.data('index')].type, elem, e.target
                        $(e.target).addClass 'active'
                        elem.addClass 'active'
                    else
                        @viewport.openMenu {x: e.clientX - container.left, y: e.clientY - container.top}, true, @, elem.data('id')
                    #@viewport.releaseOutput {x: e.clientX - container.left, y: e.clientY - container.top}, @, index
                    path.remove()
            )

        setupInput: (elem) =>
            elem.mousedown((e) =>
                e.preventDefault()
                e.stopPropagation()

                offset = $(e.target).offset()
                container = @viewport.element.offset()
                path = @viewport.connect {x: e.clientX - container.left, y: e.clientY - container.top}, {x: offset.left - container.left, y: offset.top - container.top}
                index = $(e.target).data('index')

                mousemove = (e) =>
                    e.preventDefault()
                    path.attr('d', @viewport.pathD({x: e.clientX - container.left, y: e.clientY - container.top}, {x: offset.left - container.left, y: offset.top - container.top}))

                $(document).mousemove(mousemove)
                .one 'mouseup', (e) =>
                    e.preventDefault()
                    $(document).off 'mousemove', mousemove
                    if $(e.target).hasClass 'node-output'
                        if elem.hasClass 'active'
                            for link, i in @viewport.connections when link? and link.target is @options.id and link.end is index and link.type is 'exec'
                                link.path.remove()
                                @viewport.connections.splice i, 1
                        if $(e.target).hasClass 'active'
                            for link, i in @viewport.connections when link? and link.origin is $(e.target).closest('.node').attr('id') and link.start is $(e.target).data('index') and link.type isnt 'exec'
                                link.path.remove()
                                @viewport.connections.splice i, 1
                        @viewport.createConnection @options.inputs[elem.data('index')].type, e.target, elem
                        $(e.target).addClass 'active'
                        elem.addClass 'active'
                    else
                        @viewport.openMenu {x: e.clientX - container.left, y: e.clientY - container.top}, false, @, elem.data('id')
                    #@viewport.releaseInput {x: e.clientX - container.left, y: e.clientY - container.top}, @, index
                    path.remove()
            )

        compile: (compiler) ->
            name = @options.title
            args = compiler.getArgs @
            rval = (if @options.outputs? and @options.outputs[1]? and @outputs[1].hasClass 'active'
                        @options.outputs[1].name + ' = '
                    else '')
            return "#{rval}#{name}#{args}"


    return BaseNode
