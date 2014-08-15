var app = require('app'),
    BrowserWindow = require('browser-window'),
    Menu = require('menu'),
    mainWindow = null,
    menu = null,
    isDev = process.argv.indexOf('--dev') > -1;

console.log('isDev', isDev);

app.on('window-all-closed', function() {
    if (process.platform != 'darwin')
        app.quit();
});

app.on('will-finish-launching', function() {
    require('crash-reporter').start();
});

app.on('ready', function() {
    mainWindow = new BrowserWindow({
        width: 800,
        height: 600,
        title: app.getName(),
        icon: __dirname + '/img/logo.png',
    });
    if(isDev)
        mainWindow.openDevTools();
    mainWindow.loadUrl('file://' + __dirname + '/index.html');

    var template = [
        {
        label: 'File',
            submenu: [
                {
                    label: 'New',
                },
                {
                    label: 'Open',
                    click: function() { mainWindow.webContents.send('rpc', 'open'); }
                },
                {
                    type: 'separator'
                },
                {
                    label: 'Save',
                    accelerator: 'CmdOrCtrl+S',
                    click: function() { mainWindow.webContents.send('rpc', 'save'); }
                },
                {
                    label: 'Save as',
                    accelerator: 'CmdOrCtrl+Shift+S',
                    click: function() { mainWindow.webContents.send('rpc', 'saveAs'); }
                },
                {
                    label: 'Export',
                    click: function() { mainWindow.webContents.send('rpc', 'export'); }
                },
                {
                    type: 'separator'
                },
                {
                    label: 'Quit',
                    accelerator: 'CmdOrCtrl+Q',
                    click: function() { app.quit(); }
                },
            ]
        },
        {
            label: 'Edit',
            submenu: [
                {
                    label: 'Undo',
                    accelerator: 'CmdOrCtrl+Z',
                    click: function() { mainWindow.webContents.send('rpc', 'undo'); }
                },
                {
                    label: 'Redo',
                    accelerator: 'CmdOrCtrl+Y',
                    click: function() { mainWindow.webContents.send('rpc', 'redo'); }
                },
                {
                    type: 'separator'
                },
                {
                    label: 'Cut',
                    accelerator: 'CmdOrCtrl+X',
                    click: function() { mainWindow.webContents.send('rpc', 'cut'); }
                },
                {
                    label: 'Copy',
                    accelerator: 'CmdOrCtrl+C',
                    click: function() { mainWindow.webContents.send('rpc', 'copy'); }
                },
                {
                    label: 'Paste',
                    accelerator: 'CmdOrCtrl+V',
                    click: function() { mainWindow.webContents.send('rpc', 'paste'); }
                },
                {
                    label: 'Select All',
                    accelerator: 'CmdOrCtrl+A',
                    click: function() { mainWindow.webContents.send('rpc', 'selectAll'); }
                },
            ]
        },
        {
            label: 'Build',
            submenu: [
                {
                    label: 'Run',
                    accelerator: 'CmdOrCtrl+R',
                    click: function() { mainWindow.webContents.send('rpc', 'run'); }
                },
                {
                    type: 'separator'
                },
                {
                    label: 'Clear logs',
                    click: function() { mainWindow.webContents.send('rpc', 'clear'); }
                },
            ]
        },
        {
            label: 'View',
            submenu: [
                {
                    label: 'Set theme',
                    submenu: [
                        {
                            label: 'Grey',
                            type: 'checkbox',
                            click: function() {
                                mainWindow.webContents.send('rpc', 'setTheme', 'grey');
                                menu.items[3].submenu.items[0].submenu.items[0].checked = true;
                                menu.items[3].submenu.items[0].submenu.items[1].checked = false;
                                menu.items[3].submenu.items[0].submenu.items[2].checked = false;
                            },
                            checked: true
                        },
                        {
                            label: 'Blueprint',
                            type: 'checkbox',
                            click: function() {
                                mainWindow.webContents.send('rpc', 'setTheme', 'blueprint');
                                menu.items[3].submenu.items[0].submenu.items[0].checked = false;
                                menu.items[3].submenu.items[0].submenu.items[1].checked = true;
                                menu.items[3].submenu.items[0].submenu.items[2].checked = false;
                            }
                        },
                        {
                            label: 'Carbon',
                            type: 'checkbox',
                            click: function() {
                                mainWindow.webContents.send('rpc', 'setTheme', 'carbon');
                                menu.items[3].submenu.items[0].submenu.items[0].checked = false;
                                menu.items[3].submenu.items[0].submenu.items[1].checked = false;
                                menu.items[3].submenu.items[0].submenu.items[2].checked = true;
                            }
                        },
                    ]
                },
                {
                    label: 'Reload',
                    accelerator: 'CmdOrCtrl+Alt+R',
                    click: function() { mainWindow.reloadIgnoringCache(); }
                },
                {
                    label: 'Toggle DevTools',
                    accelerator: 'Alt+CmdOrCtrl+I',
                    click: function() { mainWindow.toggleDevTools(); }
                },
            ]
        },
    ];

    menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);

    mainWindow.webContents.on('did-start-loading', function() {
        console.log('did-start-loading');
    }).on('did-stop-loading', function() {
        console.log('did-stop-loading');
    }).on('did-finish-load', function() {
        console.log('did-finish-load');
    }).on('crashed', function(e) {
        console.error('Page crashed');
        mainWindow.reloadIgnoringCache();
    });

    mainWindow.on('closed', function() {
        mainWindow = null;
    });
});
