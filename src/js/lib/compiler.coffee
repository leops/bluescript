define ["jquery", "coffee"], ($, CoffeeScript) ->
    class Compiler
        constructor: (@viewport) ->
            @functions = []

            $('#output').html @compile()
            observer = new MutationObserver (mutations) =>
                $('#output').html @compile()
            observer.observe document.getElementById('viewport'),
                childList: true
                attributes: true
                characterData: true
                subtree: true

        getNext: (node, id = 0, type = 'exec') => link for link in @viewport.connections when link.origin is node.options.id and link.start is id and link.type is type

        getPrev: (node, id) => link for link in @viewport.connections when link.target is node.options.id and link.end is id

        getFuncArguments: (func) ->
            return (for arg, idx in func.options.inputs
                do (arg, idx) =>
                    link = lnk for lnk in @viewport.connections when lnk.target is func.options.id and lnk.end is idx
                    if link?
                        if link.type is 'exec'
                            return null
                        else if link.type is 'function'
                            return @viewport.nodes[link.origin].options.title
                        else if @viewport.nodes[link.origin].options.pure
                            return @viewport.nodes[link.origin].compile @
                        else
                            return @viewport.nodes[link.origin].options.outputs[link.start]?.name
                    else
                        elem = func.element.find(".node-inputs [data-index=#{idx}] input")
                        val = elem.val()
                        match = val.match /^true|false|[0-9]+$/
                        if match?
                            return val
                        else
                            return "'" + val.replace(/'/g, '\'') + "'")

        getArgs: (func) ->
            if func.options.inputs?.length > 1
                return ' ' + @getFuncArguments(func).filter((e) -> e?).join ', '
            else
                return '()'

        compileFunctions: ->
            functions = for i, func of @viewport.nodes when func.options.type is 'function'
                func.compile @

            functions.join '\n'

        compileMainFlow: ->
            down = @getNext node for i, node of @viewport.nodes when node.options.special is 'start'

            onload = while down.length > 0
                func = @viewport.nodes[down[0].target]
                pin = 0
                func.options.outputs?.forEach (e, i) ->
                    if e.type is 'exec' and e.name is 'then'
                        pin = i
                down = @getNext func, pin
                func.compile @

            onload.join '\n'

        compile: -> "returnVal = {}\n#{@compileFunctions()}\n#{@compileMainFlow()}"

        run: (context) ->
            if not context?
                context = window
            func = (window, code) -> eval code
            code = CoffeeScript.compile @compile()
            console.log code
            func.apply context, [context, code]

    return Compiler
