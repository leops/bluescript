requirejs.config
    baseUrl: 'js/lib',
    paths:
        jquery: '../bower/jquery.min'
        coffee: '../bower/coffee-script'
        nodes: '../nodes'

requirejs ['main']
