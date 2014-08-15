define ["jquery"], ($) ->
    class Logger
        constructor: (@element) ->
            #

        format: ->
            return (for i, obj of arguments
                switch typeof obj
                    when "string" or "number" or "boolean" then obj
                    when "object" then JSON.stringify obj
                    when "function" then obj.toString()
                    when "undefined" then "undefined"
            ).join(' ').replace('\n', '\n   ')

        print: ->
            console.info.apply console, arguments
            @element.append " > #{@format.apply @, arguments}\n"

    return Logger
