define ["nodes/base"], (BaseNode)->
    class LoopNode extends BaseNode
        constructor: (@viewport, @options) ->
            super viewport, options

        compile: (compiler) ->
            down = compiler.getNext @
            link = compiler.getPrev @, 1
            obj = @viewport.nodes[link[0].origin].options.outputs[link[0].start].name
            body = '        ' + (while down.length > 0
                func = @viewport.nodes[down[0].target]
                down = compiler.getNext func
                func.compile compiler).join '\n        '
            return "for target, index in #{obj}\n    do (target, index) ->\n#{body}"

    return LoopNode
