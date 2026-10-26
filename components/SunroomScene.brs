' Three screens fed by latitude-sunroom's /api/feed: clock + weather, homelab
' status, chess. They rotate on their own every 30 seconds; left/right flips
' by hand and pauses the rotation for five minutes.

function server() as String
    return "http://192.168.1.158:8473"
end function

sub init()
    m.pages = [m.top.findNode("clockPage"), m.top.findNode("statusPage"), m.top.findNode("chessPage")]
    m.index = 0
    m.pausedUntil = 0
    m.feed = invalid
    m.clock = CreateObject("roDateTime")

    m.dots = []
    dotRow = m.top.findNode("dots")
    for i = 0 to 2
        d = CreateObject("roSGNode", "Rectangle")
        d.width = 18
        d.height = 18
        d.translation = [i * 34, 0]
        dotRow.appendChild(d)
        m.dots.push(d)
    end for

    m.top.findNode("clockTimer").observeField("fire", "onClock")
    m.top.findNode("feedTimer").observeField("fire", "refresh")
    m.top.findNode("rotateTimer").observeField("fire", "onRotate")
    m.top.findNode("clockTimer").control = "start"
    m.top.findNode("feedTimer").control = "start"
    m.top.findNode("rotateTimer").control = "start"

    m.top.setFocus(true)
    showPage(0)
    onClock()
    refresh()
end sub

' ---- navigation ----------------------------------------------------------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "right" or key = "fastforward"
        showPage((m.index + 1) mod 3)
    else if key = "left" or key = "rewind"
        showPage((m.index + 2) mod 3)
    else
        return false
    end if
    m.pausedUntil = nowSecs() + 300
    return true
end function

sub onRotate()
    if m.top.screensaver or nowSecs() >= m.pausedUntil then showPage((m.index + 1) mod 3)
end sub

sub showPage(i as Integer)
    m.index = i
    for p = 0 to 2
        m.pages[p].visible = (p = i)
        if p = i then m.dots[p].color = "0xAA5CC3FF" else m.dots[p].color = "0x3A3E4AFF"
    end for
    m.top.findNode("cornerTime").visible = (i <> 0)
end sub

function nowSecs() as Integer
    m.clock.Mark()
    return m.clock.AsSeconds()
end function

' ---- clock ---------------------------------------------------------------

sub onClock()
    t = CreateObject("roDateTime")
    t.ToLocalTime()
    h = t.GetHours()
    mins = t.GetMinutes()
    hh = h mod 12
    if hh = 0 then hh = 12
    mm = mins.ToStr()
    if mins < 10 then mm = "0" + mm
    clock = hh.ToStr() + ":" + mm
    m.top.findNode("bigTime").text = clock
    m.top.findNode("cornerTime").text = clock
    months = ["January", "February", "March", "April", "May", "June", "July", "August",
              "September", "October", "November", "December"]
    m.top.findNode("bigDate").text = t.GetWeekday() + ", " + months[t.GetMonth() - 1] + " " + t.GetDayOfMonth().ToStr()
end sub

' ---- feed ----------------------------------------------------------------

sub refresh()
    task = CreateObject("roSGNode", "FeedTask")
    task.url = server() + "/api/feed"
    task.observeField("result", "onFeed")
    task.control = "RUN"
    m.task = task  ' keep a reference until it reports back
end sub

sub onFeed(event as Object)
    data = event.getData()
    if data = invalid or data.error <> invalid then return  ' keep showing the last good feed
    m.feed = data
    showWeather(data.weather, data.air)
    showIss(data.iss)
    showAlerts(data.alerts)
    showStatus(data)
    showChess(data.chess)
    showPuzzle(data.puzzle)
end sub

function hour12(hhmm as String) as String
    h = Int(Val(Left(hhmm, 2)))
    suffix = "AM"
    if h >= 12 then suffix = "PM"
    hh = h mod 12
    if hh = 0 then hh = 12
    return hh.ToStr() + " " + suffix
end function

function time12(hhmm as String) as String
    h = Int(Val(Left(hhmm, 2)))
    suffix = " AM"
    if h >= 12 then suffix = " PM"
    hh = h mod 12
    if hh = 0 then hh = 12
    return hh.ToStr() + ":" + Mid(hhmm, 4, 2) + suffix
end function

sub showWeather(w as Object, air as Object)
    if w = invalid then return
    m.top.findNode("temp").text = w.temp.ToStr() + "°"
    m.top.findNode("summary").text = w.summary
    lines = "High " + w.high.ToStr() + "°  ·  Low " + w.low.ToStr() + "°" + Chr(10)
    lines = lines + "Feels like " + w.feels.ToStr() + "°  ·  Humidity " + w.humidity.ToStr() + "%" + Chr(10)
    lines = lines + "Wind " + w.wind.ToStr() + " mph  ·  Rain " + w.rain.ToStr() + "%" + Chr(10)
    lines = lines + "Sunrise " + time12(w.sunrise) + "  ·  Sunset " + time12(w.sunset)
    if air <> invalid
        lines = lines + Chr(10) + "Air " + air.aqi.ToStr() + " (" + air.aqiLabel + ")  ·  UV " + air.uv.ToStr() + " " + air.uvLabel + ", max " + w.uvMax.ToStr()
    end if
    m.top.findNode("details").text = lines

    row = m.top.findNode("hours")
    row.removeChildrenIndex(row.getChildCount(), 0)
    x = 0
    for each h in w.hours
        addLabel(row, hour12(h.time), [x, 0], 34, "0x9A9CABFF", false, 260)
        addLabel(row, h.temp.ToStr() + "°", [x, 50], 64, "0xFFFFFFFF", true, 260)
        addLabel(row, h.summary, [x, 140], 30, "0x9A9CABFF", false, 260)
        x = x + 280
    end for
end sub

sub showIss(iss as Object)
    label = m.top.findNode("issText")
    if iss = invalid
        label.text = ""
    else
        label.text = "Space station overhead " + iss.when + "  ·  " + iss.maxElevation.ToStr() + "° up  ·  " + iss.minutes.ToStr() + " min"
    end if
end sub

' Most severe alert first; red for Extreme/Severe, amber for Moderate, grey otherwise.
sub showAlerts(alerts as Object)
    bar = m.top.findNode("alertBar")
    if alerts = invalid or alerts.Count() = 0
        bar.visible = false
        return
    end if
    a = alerts[0]
    text = "WEATHER ALERT  ·  " + a.event
    if a.until <> invalid then text = text + " until " + a.until
    if alerts.Count() > 1 then text = text + "  ·  +" + (alerts.Count() - 1).ToStr() + " more"
    m.top.findNode("alertText").text = text
    if a.severity = "Extreme" or a.severity = "Severe"
        bar.color = "0xB91C1CFF"
    else if a.severity = "Moderate"
        bar.color = "0xB45309FF"
    else
        bar.color = "0x3A3E4AFF"
    end if
    bar.visible = true
end sub

sub showPuzzle(p as Object)
    board = m.top.findNode("puzzleBoard")
    label = m.top.findNode("puzzleText")
    if p = invalid
        board.visible = false
        label.text = ""
        return
    end if
    board.uri = server() + p.board
    board.visible = true
    if p.color = "white" then side = "White" else side = "Black"
    label.text = side + " to move" + Chr(10) + "Rated " + p.rating.ToStr()
end sub

sub showStatus(data as Object)
    grid = m.top.findNode("serviceGrid")
    grid.removeChildrenIndex(grid.getChildCount(), 0)
    down = []
    if data.services <> invalid
        i = 0
        for each s in data.services
            col = Int(i / 8)
            rowY = (i mod 8) * 82
            dot = CreateObject("roSGNode", "Rectangle")
            dot.width = 26
            dot.height = 26
            dot.translation = [col * 600, rowY + 12]
            if s.ok then dot.color = "0x22C55EFF" else dot.color = "0xEF4444FF"
            grid.appendChild(dot)
            addLabel(grid, s.name, [col * 600 + 50, rowY], 44, "0xFFFFFFFF", false, 520)
            if not s.ok then down.push(s.name)
            i = i + 1
        end for
        if down.Count() = 0
            m.top.findNode("statusSummary").text = "Everything's running"
        else
            m.top.findNode("statusSummary").text = down.Count().ToStr() + " down: " + down.Join(", ")
        end if
    end if

    b = data.backup
    if b <> invalid
        if b.ok then prefix = "OK" else prefix = "Overdue"
        m.top.findNode("backupText").text = prefix + Chr(10) + "Last: " + b.last
    end if

    r = data.ripper
    bar = m.top.findNode("ripperBar")
    barBg = m.top.findNode("ripperBarBg")
    bar.visible = false
    barBg.visible = false
    if r <> invalid
        if r.state = "idle"
            text = "Idle"
            if r.last <> invalid
                if r.lastOk then text = text + Chr(10) + "Last: " + r.last else text = text + Chr(10) + "Last failed: " + r.last
            end if
        else
            if r.state = "copying" then verb = "Copying" else verb = "Compressing"
            text = verb + Chr(10) + r.title
            if r.progress <> invalid
                text = text + Chr(10) + Int(r.progress).ToStr() + "%"
                barBg.visible = true
                bar.visible = true
                bar.width = Int(460 * r.progress / 100)
            end if
        end if
        m.top.findNode("ripperText").text = text
    end if
end sub

sub showChess(c as Object)
    if c = invalid then return
    summary = c.me + "  ·  Correspondence " + c.rating.ToStr()
    if c.puzzleSolved = true then summary = summary + "  ·  Daily puzzle done" else summary = summary + "  ·  Daily puzzle waiting"
    if c.challenges > 0 then summary = summary + "  ·  " + c.challenges.ToStr() + " challenge(s)"
    m.top.findNode("chessSummary").text = summary

    games = c.games
    m.top.findNode("noGames").visible = (games.Count() = 0)
    for i = 1 to 2
        board = m.top.findNode("board" + i.ToStr())
        label = m.top.findNode("game" + i.ToStr())
        if games.Count() >= i
            g = games[i - 1]
            board.uri = server() + g.board
            board.visible = true
            if g.myTurn then turn = "Your move" else turn = "Their move"
            label.text = turn + " vs " + g.opponent
            label.visible = true
        else
            board.visible = false
            label.visible = false
        end if
    end for
    more = ""
    if games.Count() > 2 then more = "+ " + (games.Count() - 2).ToStr() + " more game(s)"
    m.top.findNode("moreGames").text = more
end sub

sub addLabel(parent as Object, text as String, pos as Object, size as Integer, color as String, bold as Boolean, width as Integer)
    l = CreateObject("roSGNode", "Label")
    l.text = text
    l.translation = pos
    l.color = color
    l.width = width
    f = CreateObject("roSGNode", "Font")
    if bold then f.uri = "font:BoldSystemFontFile" else f.uri = "font:SystemFontFile"
    f.size = size
    l.font = f
    parent.appendChild(l)
end sub
