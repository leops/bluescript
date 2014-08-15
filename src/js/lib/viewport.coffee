define ["require", "jquery", "menu", "nodes/base", "nodes/builder", "nodes/function", "nodes/loop", "nodes/variable"], (require, $, Menu) ->
    class Viewport
        constructor: (@element) ->
            @init()

            if localStorage.layoutWidth?
                $('#sidebar').css 'flex-basis', localStorage.layoutWidth
            else
                localStorage.layoutWidth = 250

            if localStorage.layoutHeight?
                $('#bottombar').css 'flex-basis', localStorage.layoutHeight
            else
                localStorage.layoutHeight = 220

            $('#resizeHandleH').mousedown((e) ->
                e.preventDefault()
                e.stopPropagation()

                mousemove = (e) ->
                    $('#sidebar').css 'flex-basis', e.pageX
                    localStorage.layoutWidth = e.pageX

                $(document).mousemove(mousemove)
                .mouseup (e) ->
                    $(document).off 'mousemove', mousemove
            )

            $('#resizeHandleV').mousedown((e) ->
                e.preventDefault()
                e.stopPropagation()

                mousemove = (e) ->
                    $('#bottombar').css 'flex-basis', $(document).height() - e.clientY
                    localStorage.layoutHeight = $(document).height() - e.clientY

                $(document).mousemove(mousemove)
                .mouseup (e) ->
                    $(document).off 'mousemove', mousemove
            )

        reset: ->
            @nodes = {}
            @index = 0
            @connections = []
            @element.html ''
            @canvas = $('<svg height="100%" width="100%" class="canvas" version="1.1" xmlns="http://www.w3.org/2000/svg"></svg>').appendTo @element

        init: ->
            @reset()
            @menu = new Menu @

            ###
            $(window).keydown((e) =>
                #e.preventDefault()
                switch e.which
                    when 46, 8 then @removeSelection()
                    when 67
                        if e.ctrlKey
                            viewport.copy()
                    when 88
                        if e.ctrlKey
                            viewport.cut()
                    when 86
                        if e.ctrlKey
                            viewport.paste()
                    #else console.log e.which
            )
            ###

            $(@element).on('contextmenu', (e) =>
                e.preventDefault()
                offset = @element.offset()
                @menu.open {x: e.clientX - offset.left, y: e.clientY - offset.top}
            ).mousedown((e) ->
                $('.menu.show').removeClass 'show'
                $('.selected').removeClass 'selected'

                offset = $(@).offset()
                start = {x: e.pageX - offset.left, y: e.pageY - offset.top}
                element = $("<div class=\"selectBox\" style=\"left: #{start.x}; top: #{start.y};\"></div>").appendTo @

                selectBox = (x1, y1, x2, y2) ->
                    $('.node').each ->
                        offs = $(@).offset()
                        x = offs.left
                        y = offs.top
                        w = $(@).width()
                        h = $(@).height()

                        if x >= x1 and y >= y1 and x + w <= x2 and y + h <= y2
                            $(@).addClass 'selected'
                        else
                            $(@).removeClass 'selected'

                mousemove = (e) ->
                    e.preventDefault()
                    x = e.pageX - start.x - offset.left
                    y = e.pageY - start.y - offset.top

                    if e.pageX > start.x + offset.left
                        element.css('left', start.x).css('width', x)
                    else
                        element.css('left', e.pageX - offset.left).css('width', start.x - e.pageX + offset.left)

                    if e.pageY > start.y + offset.top
                        element.css('top', start.y).css('height', y)
                    else
                        element.css('top', e.pageY - offset.top).css('height', start.y - e.pageY + offset.top)

                    offs = element.offset()
                    selectBox offs.left, offs.top, offs.left + element.width(), offs.top + element.height()

                $(document).mousemove mousemove
                $(document).mouseup (e) ->
                    e.preventDefault()

                    offset = element.offset()
                    selectBox offset.left, offset.top, offset.left + element.width(), offset.top + element.height()

                    element.remove()
                    $(@).off 'mousemove', mousemove
            )

            @createNode
                title: 'Start'
                type: 'special'
                special: 'start'
                outputs: [
                    {
                        type: 'exec'
                        name: 'then'
                    }
                ]

            return ''

        createNode: (options) ->
            if not options.id? or (options.id? and @nodes[options.id]?)
                id = 'node-' + @index++
            else
                id = options.id

            NodeClass = (switch options.type
                when 'function' then require 'nodes/function'
                when 'variable' then require 'nodes/variable'
                when 'loop' then require 'nodes/loop'
                when 'builder' then require 'nodes/builder'
                else require 'nodes/base')

            node = new NodeClass $.extend({id: id}, options), @
            @element.append node.element
            @nodes[id] = node

        pathD: (a, b) ->
            cp1 = a.x + Math.max(Math.abs((b.x - a.x) / 2), 30)
            cp2 = b.x - Math.max(Math.abs((b.x - a.x) / 2), 30)
            return "M#{a.x},#{a.y}C#{cp1},#{a.y},#{cp2},#{b.y},#{b.x},#{b.y}"

        connect: (a, b) ->
            return $(document.createElementNS('http://www.w3.org/2000/svg', 'path'))
            .attr('d', @pathD(a, b))
            .attr('fill', "none")
            .attr('stroke', "white")
            .attr('stroke-width', "4")
            .attr('stroke-linecap', "round")
            .appendTo(@canvas)

        openMenu: (pos, out, origin, pin) ->
            @menu.open pos, out, origin, pin

        createConnection: (type, start, end) ->
            container = @element.offset()
            $(end).addClass 'active'
            $(start).addClass 'active'
            path = @connect {
                x: ($(start).offset().left + $(start).width()) - container.left
                y: ($(start).offset().top + ($(start).height() / 2)) - container.top
            }, {
                x: ($(end).offset().left) - container.left
                y: ($(end).offset().top + ($(end).height() / 2)) - container.top
            }
            @connections.push `{
                start: $(start).data('index'),
                end: $(end).data('index'),
                origin: $(start).closest('.node').attr('id'),
                target: $(end).closest('.node').attr('id'),
                type: type,
                get path () {
                    return path;
                },
                set path (val) {
                    this.path.remove();
                    this.path = val;
                }
            }`

        findConnectionsFor: (obj) -> e for e in @connections when e.origin is obj.options.id or e.target is obj.options.id

        serialize: ->
            val = {nodes: {}, connections: []}

            for con in @connections
                copy = con
                delete copy.path
                val.connections.push copy

            for i, node of @nodes
                opt = node.options
                if opt.inputs?
                    for input, idx in opt.inputs
                        do (input, idx) =>
                            link = lnk for lnk in @connections when lnk.target is opt.id and lnk.end is idx
                            if not link?
                                elem = node.element.find(".node-inputs [data-index=#{idx}] input")
                                opt.inputs[idx].value = elem.val()
                if opt.outputs?
                    opt.outputs = opt.outputs.filter (e) -> e.type isnt 'function'
                if opt.pos?
                    opt.pos.x = opt.pos.x - @element.offset().left
                    opt.pos.y = opt.pos.y - @element.offset().top
                val.nodes[i] = opt

            return JSON.stringify val

        parse: (save) ->
            @reset()
            data = JSON.parse save

            for i, node of data.nodes
                if node.pos?
                    node.pos.x = node.pos.x + @element.offset().left
                    node.pos.y = node.pos.y + @element.offset().top
                @createNode node

            for link, i in data.connections
                do (link, i) =>
                    container = @element.offset()
                    $('#' + link.target + ' .node-input[data-index=' + link.start + '], #' + link.origin + ' .node-output[data-index=' + link.end + ']').addClass 'active'
                    path = @connect {
                        x: ($('#' + link.origin).offset().left + $('#' + link.origin).width()) - container.left
                        y: ($('#' + link.origin).offset().top + ($('#' + link.origin).height() / 2)) - container.top
                    }, {
                        x: ($('#' + link.target).offset().left) - container.left
                        y: ($('#' + link.target).offset().top + ($('#' + link.target).height() / 2)) - container.top
                    }
                    @connections.push `{
                        start: link.start,
                        end: link.end,
                        origin: link.origin,
                        target: link.target,
                        type: link.type,
                        get path () {
                            return path;
                        },
                        set path (val) {
                            this.path.remove();
                            this.path = val;
                        }
                    }`

            return data
        removeSelection: ->
            $('.node.selected:not(.node-special)').each (e) =>
                id = $(e).attr('id')
                delete @nodes[id]
                for link, i in @connections when link.origin is id or link.target is id
                    link.path.remove()
                    @connections.splice i, 1
                $(e).remove()

        copy: ->
            clipboard = remote.require('clipboard')
            data = JSON.stringify jQuery.makeArray $('.node.selected:not(.node-special)').map (i, e) =>
                opt = @nodes[$(e).attr('id')].options
                if opt.pos?
                    opt.pos.x = opt.pos.x - @element.offset().left
                    opt.pos.y = opt.pos.y - @element.offset().top
                return opt
            clipboard.writeText data, 'text'

        cut: ->
            clipboard = remote.require('clipboard')
            data = JSON.stringify jQuery.makeArray $('.node.selected:not(.node-special)').map (i, e) =>
                opt = @nodes[$(e).attr('id')].options
                if opt.pos?
                    opt.pos.x = opt.pos.x - @element.offset().left
                    opt.pos.y = opt.pos.y - @element.offset().top
                return opt
            clipboard.writeText data, 'text'
            @removeSelection()

        paste: ->
            clipboard = remote.require('clipboard')
            data = JSON.parse clipboard.readText 'text'
            for i, node of data
                if node.pos?
                    node.pos.x = node.pos.x + @element.offset().left
                    node.pos.y = node.pos.y + @element.offset().top
                @createNode node

        selectAll: -> $('.node').addClass 'selected'

    return Viewport
