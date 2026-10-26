' Network calls have to run off the render thread, so the scene starts one of
' these per refresh.

sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    port = CreateObject("roMessagePort")
    t = CreateObject("roUrlTransfer")
    t.SetMessagePort(port)
    t.SetUrl(m.top.url)
    data = invalid
    if t.AsyncGetToString()
        msg = wait(20000, port)
        if type(msg) = "roUrlEvent" and msg.GetResponseCode() = 200
            data = ParseJson(msg.GetString())
        else
            t.AsyncCancel()
        end if
    end if
    if data = invalid then data = { error: true }
    m.top.result = data
end sub
