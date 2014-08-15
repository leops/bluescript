define ["nodes/base", "jquery"], (BaseNode, $)->
    class BuilderNode extends BaseNode
        constructor: (@viewport, @options) ->
            super viewport, options

            getIndex = (options) =>
                if @options.inputs?
                    return @options.inputs.push(options) - 1
                else
                    @options.inputs = [options]
                    return 0

            id = 1
            $('<span class="add">+</span>')
            .click((e) =>
                e.preventDefault()
                name = "key#{id++}"
                index = getIndex
                    type: 'object'
                    name: name

                @createInput
                    type: 'object'
                    name: name
                , index

            )
            .appendTo @element.find('.node-inputs')

        createInput: (input, i) ->
            elem = $("<div class=\"node-input pin-object\" data-index=\"#{i}\"></div>")
            @setupInput elem
            $("<span>#{@formatName input.name}</span>").attr('contenteditable', true)
            .mousedown((e) -> e.stopPropagation())
            .focus((e) =>
                $(e.target).text @options.inputs[i].name
            )
            .blur((e) =>
                val = $(e.target).text()
                @options.inputs[i].name = val
                $(e.target).text @formatName val
            )
            .appendTo elem

            $('<input type="text"/>')
            .mousedown((e) ->
                e.stopPropagation()
            )
            .appendTo elem

            elem.appendTo(@element.find('.node-inputs'))
            @inputs[i] = elem

        compile: (compiler) ->
            if @options.inputs?
                args = compiler.getFuncArguments @
                if @options.isObject
                    return "{" + (input.name + ': ' + args[id] for input, id in @options.inputs).join(', ') + "}"
                else
                    return "[" + (args[id] for input, id in @options.inputs).join(', ') + "]"
            else
                return 'null'

    return BuilderNode
