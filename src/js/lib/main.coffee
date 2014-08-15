define ["viewport", "compiler", "sidebar", "rpc", "jquery"], (Viewport, Compiler, Sidebar, RPC, $) ->
    viewport = new Viewport($('#viewport'))
    sidebar = new Sidebar($('#sidebar'), viewport)
    compiler = new Compiler(viewport)

    rpc = RPC viewport, compiler
    if rpc? and typeof rpc is 'function'
        module.require('ipc').on 'rpc', rpc
    else
        console.error rpc
