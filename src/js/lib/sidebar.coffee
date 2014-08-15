define ['jquery', 'logger'], ($, Logger) ->
    class Sidebar
        constructor: (@element, @viewport) ->
            observer = new MutationObserver (mutations) =>
                selection = $('#viewport .selected')
                val = selection.map (i, e) =>
                    return ("#{key} = #{Logger::format value}" for key, value of @viewport.nodes[e.id].options).join '\n'
                @element.html val.get().join('\n\n')

            observer.observe document.getElementById('viewport'),
                attributes: true
                subtree: true
                attributeFilter: ['class']

    return Sidebar
