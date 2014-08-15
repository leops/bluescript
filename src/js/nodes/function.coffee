define ["jquery", "nodes/base"], ($, BaseNode)->
    class FunctionNode extends BaseNode
        constructor: (@viewport, @options) ->
            super viewport, options

            @element.find('h1').attr('contenteditable', true).mousedown((e) -> e.stopPropagation()).focus((e) ->
                $(@).text options.title
            ).blur((e) =>
                val = $(e.target).text()

                for i, node of @viewport.nodes when node.options.title is @options.title and node.options.type is 'call'
                    node.options.title = val
                    node.element.find('h1').text node.formatName val

                @options.title = val
                $(e.target).text @formatName val
            )

            getIndex = (options) =>
                if @options.outputs?
                    return @options.outputs.push(options) - 1
                else
                    @options.outputs = [options]
                    return 0

            index = getIndex
                type: 'function'
                name: options.title
            elem = $("<div class=\"node-output pin-object\" data-index=\"#{index}\"></div>")
            @setupOutput elem
            elem.appendTo @element.find('header')
            @outputs[index] = elem

            id = 0
            $('<span class="add">+</span>')
            .click((e) =>
                e.preventDefault()
                name = "argument#{id++}"
                index = getIndex
                    type: 'object'
                    name: name
                elem = $("<div class=\"node-output pin-object\" data-index=\"#{index}\">#{@formatName name}</div>")
                @setupOutput elem
                elem.appendTo @element.find('.node-outputs')
                @outputs[index] = elem

                for i, node of @viewport.nodes when node.options.title is @options.title and node.options.type is 'call'
                    index = (if node.options.inputs?
                        node.options.inputs.push(
                            type: 'object'
                            name: name
                        ) - 1
                    else
                        node.options.inputs = [
                            {
                                type: 'object'
                                name: name
                            }
                        ]
                        0)

                    elem = $("<div class=\"node-input pin-object\" data-index=\"#{index}\">#{name}</div>")
                    node.setupInput elem

                    $('<input type="text"/>')
                    .mousedown((e) ->
                        e.stopPropagation()
                    )
                    .appendTo elem

                    elem.appendTo(node.element.find('.node-inputs'))
                    node.inputs[i] = elem
            )
            .appendTo @element.find('.node-outputs')

        compile: (compiler) ->
            down = compiler.getNext(@).filter (e) -> e.type is 'exec'
            body = '    ' + (while down.length > 0
                lfunc = @viewport.nodes[down[0].target]
                down = compiler.getNext lfunc
                lfunc.compile compiler).join '\n    '

            args = (arg.name for arg, idx in @options.outputs when arg.type is 'object')
            if args?.length > 0
                args = "(#{args.join ', '}) "
            else
                args = ''

            return "#{@options.title} = #{args}->\n#{body}"

    return FunctionNode
