' Sunroom: a wall display for the Flex Room Roku. The same scene runs as the
' channel and as the Roku's screensaver, so it stays up when nobody's
' touching the remote.

sub Main(args as Dynamic)
    showScene(false)
end sub

sub RunScreenSaver()
    showScene(true)
end sub

sub showScene(isScreensaver as Boolean)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
    scene = screen.CreateScene("SunroomScene")
    scene.screensaver = isScreensaver
    screen.show()
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then return
    end while
end sub
