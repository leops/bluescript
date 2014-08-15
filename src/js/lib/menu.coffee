define ["jquery"], ($)->
    class Menu
        constructor: (@viewport) ->
            @element = $('<div class="menu"></div>').appendTo(viewport.element)
            @index = 0

        open: (@pos, @origin, @pin) ->
            @refresh()
            @element.addClass('show').css('left', @pos.x).css('top', @pos.y).css('max-height', "calc(100vh - #{@pos.y}px - 10px)")
            $(window).one 'click', (e) =>
                    e.preventDefault()
                    @element.removeClass 'show'

        refresh: ->
            @element.html ''
            block = (e) -> e.stopPropagation()

            win = $('<details><summary>Window</summary></details>').mousedown(block).click(block).appendTo @element

            list = Object.keys window
            for fname in list
                do (fname) =>
                    id = 0
                    if typeof window[fname] is 'function'
                        win.append $("<a href=\"#\">Call #{fname}</a>").mousedown((e) =>
                            @element.removeClass 'show'
                            node = @viewport.createNode(
                                title: 'window.' + fname
                                subtitle: 'Function of window'
                                type: 'call'
                                pos: @pos
                                outputs: [
                                    {
                                        type: 'exec'
                                        name: 'then'
                                    },
                                    {
                                        type: 'object'
                                        name: "return"
                                        displayName: 'Return'
                                    }
                                ]
                                inputs: [
                                    {
                                        type: 'exec'
                                        name: 'do'
                                    }
                                ].concat({type: 'object', name: "Argument #{i}"} for i in [0..window[fname].length])
                            )

                            if @out is true
                                pos = node.inputs[0].offset()
                                @viewport.releaseOutput {x: pos.left - 100, y: pos.top}, @origin, @pin
                            else if @out is false
                                pos = node.outputs[0].offset()
                                @viewport.releaseInput {x: pos.left - 100, y: pos.top}, @origin, @pin
                        )

            functions = $('<details><summary>Functions</summary></details>').mousedown(block).click(block)

            for i, func of @viewport.nodes when func.options.type is 'function'
                do (i, func) =>
                    id = 0
                    functions.append $("<a href=\"#\">Call function #{func.options.title}</a>").mousedown((e) =>
                        @element.removeClass 'show'
                        node = @viewport.createNode(
                            title: func.options.title
                            type: 'call'
                            pos: @pos
                            outputs: [
                                {
                                    type: 'exec'
                                    name: 'then'
                                },
                                {
                                    type: 'object'
                                    name: "return"
                                    displayName: 'Return'
                                }
                            ]
                            inputs: [
                                {
                                    type: 'exec'
                                    name: 'do'
                                }
                            ].concat((func.options.outputs || []).filter (e) -> e.type isnt 'exec' and e.type isnt 'function')
                        )

                        if @out is true
                            pos = node.inputs[0].offset()
                            @viewport.releaseOutput {x: pos.left - 100, y: pos.top}, @origin, @pin
                        else if @out is false
                            pos = node.outputs[0].offset()
                            @viewport.releaseInput {x: pos.left - 100, y: pos.top}, @origin, @pin
                    )

            if functions.find(':not(summary)').length > 0
                functions.appendTo @element

            @element.append $("<a href=\"#\">New function</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "function#{@index++}"
                    subtitle: "Function"
                    type: 'function'
                    pos: @pos
                    outputs: [
                        {
                            type: 'exec'
                            name: 'then'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New return node</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "return"
                    type: 'special'
                    pos: @pos
                    inputs: [
                        {
                            type: 'exec'
                            name: 'do'
                        },
                        {
                            type: 'object'
                            name: 'value'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New set variable</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "variable#{@index++}"
                    type: 'variable'
                    pos: @pos
                    inputs: [
                        {
                            type: 'exec'
                            name: 'do'
                        }, {
                            type: 'object'
                            name: 'value'
                        }
                    ]
                    outputs: [
                        {
                            type: 'exec'
                            name: 'then'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New get variable</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "variable#{@index++}"
                    type: 'variable'
                    pos: @pos
                    pure: true
                    outputs: [
                        {
                            type: 'object'
                            name: 'value'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New loop</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "forEach"
                    type: 'loop'
                    pos: @pos
                    inputs: [
                        {
                            type: 'exec'
                            name: 'do'
                        }
                        {
                            type: 'object'
                            name: 'object'
                        }
                    ]
                    outputs: [
                        {
                            type: 'exec'
                            name: 'body'
                        }
                        {
                            type: 'object'
                            name: 'target'
                        }
                        {
                            type: 'object'
                            name: 'index'
                        }
                        {
                            type: 'exec'
                            name: 'then'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New object</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "Make object"
                    type: 'builder'
                    pure: true
                    isObject: true
                    pos: @pos
                    inputs: [
                        {
                            type: 'object'
                            name: 'key'
                            displayName: 'Key'
                        }
                    ]
                    outputs: [
                        {
                            type: 'object'
                            name: 'val'
                            displayName: 'Value'
                        }
                    ]
                )
            )

            @element.append $("<a href=\"#\">New array</a>").mousedown((e) =>
                @viewport.createNode(
                    title: "Make array"
                    type: 'builder'
                    pure: true
                    isObject: false
                    pos: @pos
                    inputs: [
                        {
                            type: 'object'
                            name: 'key'
                            displayName: 'Key'
                        }
                    ]
                    outputs: [
                        {
                            type: 'object'
                            name: 'val'
                            displayName: 'Value'
                        }
                    ]
                )
            )

    return Menu
