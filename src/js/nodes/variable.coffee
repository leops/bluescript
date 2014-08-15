define ["jquery", "nodes/base"], ($, BaseNode)->
    class VariableNode extends BaseNode
        constructor: (@viewport, @options) ->
            super viewport, options

            @element.find('h1').attr('contenteditable', true).mousedown((e) -> e.stopPropagation()).focus((e) ->
                $(@).text options.title
            ).blur((e) =>
                val = $(e.target).text()
                @options.title = val
                $(e.target).text @formatName val
            )

        setupElement: (options) ->
            if not options.pos?
                options.pos =
                    x: 0
                    y: 0

            return $("<div id=\"#{options.id}\" class=\"node node-variable\" style=\"left: #{options.pos.x}; top: #{options.pos.y};\">
                <header>
                    <h1>#{@formatName options.title}</h1>
                </header>
                <div class=\"node-body\">
                    <div class=\"node-inputs\"></div>
                    <div class=\"node-outputs\"></div>
                </div>
            </div>")

        compile: (compiler) ->
            if @options.pure
                return @options.title
            else
                return "#{@options.title} = #{compiler.getArgs @}"

    return VariableNode
