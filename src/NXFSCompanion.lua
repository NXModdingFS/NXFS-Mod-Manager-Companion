-- NXFS Mod Manager Companion
--
-- Plays a video over the map loading screen, using the engine's own video overlay
-- functions. Installed by NXFS Mod Manager; it writes nothing and reads nothing but the
-- video sitting beside this file.

NXFSCompanion = {}

local directory = g_currentModDirectory
local VIDEO = "loadingVideo.ogv"

-- The loading screen does not last forever, and neither should this. If every other way
-- of noticing the game has started fails, this stops it anyway.
local GIVE_UP_AFTER_MS = 10 * 60 * 1000

NXFSCompanion.overlay = nil
NXFSCompanion.started = false
NXFSCompanion.done = false
NXFSCompanion.age = 0
NXFSCompanion.wrapped = false

local function log(message)
    print("[NXFS Companion] " .. tostring(message))
end

--- Stops and releases the video. Safe to call repeatedly and from anywhere.
function NXFSCompanion.stop()
    NXFSCompanion.done = true

    local overlay = NXFSCompanion.overlay
    if overlay == nil then
        return
    end

    NXFSCompanion.overlay = nil

    if isVideoOverlayPlaying ~= nil and isVideoOverlayPlaying(overlay) then
        stopVideoOverlay(overlay)
    end

    delete(overlay)
    log("video stopped")
end

--- Draws a frame of the video, creating it the first time round.
function NXFSCompanion.drawVideo()
    if NXFSCompanion.done then
        return
    end

    if NXFSCompanion.overlay == nil then
        local path = directory .. VIDEO

        if not fileExists(path) then
            log("no video beside the script, nothing to play")
            NXFSCompanion.done = true
            return
        end

        -- Looping, because a loading screen is as long as it is and a video that stops
        -- halfway through leaves a frozen frame.
        NXFSCompanion.overlay = createVideoOverlay(path, true, 1.0)

        if NXFSCompanion.overlay == nil then
            log("the engine would not open the video")
            NXFSCompanion.done = true
            return
        end
    end

    -- Opening is asynchronous; drawing before it is ready shows nothing at best.
    if not isVideoOverlayReadyToPlay(NXFSCompanion.overlay) then
        return
    end

    if not NXFSCompanion.started then
        playVideoOverlay(NXFSCompanion.overlay)
        NXFSCompanion.started = true
        log("video playing")
    end

    renderVideoOverlay(NXFSCompanion.overlay, 0, 0, 1, 1)
end

--- Wraps the current screen so the video is drawn after whatever it draws itself.
function NXFSCompanion.attach()
    if NXFSCompanion.wrapped or g_gui == nil then
        return
    end

    local gui = g_gui.currentGui
    if gui == nil or gui.target == nil then
        return
    end

    local screen = gui.target
    NXFSCompanion.wrapped = true

    local originalDraw = screen.draw
    screen.draw = function(self, ...)
        if originalDraw ~= nil then
            originalDraw(self, ...)
        end

        NXFSCompanion.drawVideo()
    end

    -- Pressing Start is the clearest signal the player is done looking at this.
    for _, name in pairs({ "onButtonStart", "onClickOk", "onClickBack" }) do
        local original = screen[name]

        if original ~= nil then
            screen[name] = function(self, ...)
                NXFSCompanion.stop()
                return original(self, ...)
            end
        end
    end

    log("attached to " .. tostring(gui.name))
end

function NXFSCompanion:update(dt)
    if self.done then
        return
    end

    self.age = self.age + (dt or 0)

    if not self.wrapped then
        NXFSCompanion.attach()
    end

    -- The map is up, or the screen has gone: either way nobody is looking at a loading
    -- screen any more.
    local playing = g_currentMission ~= nil and g_currentMission.isRunning
    local noScreen = g_gui == nil or g_gui.currentGui == nil

    if playing or noScreen or self.age > GIVE_UP_AFTER_MS then
        NXFSCompanion.stop()
    end
end

function NXFSCompanion:loadMap(name)
    NXFSCompanion.attach()
end

function NXFSCompanion:deleteMap()
    NXFSCompanion.stop()
end

addModEventListener(NXFSCompanion)
NXFSCompanion.attach()
