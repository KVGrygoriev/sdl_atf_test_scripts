--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

local function getRequestParams()
  return { 
    displayLayout = "ONSCREEN_PRESETS",
    dayColorScheme = {
      primaryColor = {
        red = 0,
        green = 255,
        blue = 100
      }
    }
  }
end

local function getRequestParams2()
  return { 
    displayLayout = "ONSCREEN_PRESETS",
    dayColorScheme = {
      primaryColor = {
        red = 0,
        green = 0,
        blue = 0
      }
    }
  }
end

local function setDisplayWithColorsSuccess(self)
  local responseParams = {}
  local cid = self.mobileSession1:SendRPC("SetDisplayLayout", getRequestParams())
  EXPECT_HMICALL("UI.SetDisplayLayout", getRequestParams())
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responseParams)
  end)
  self.mobileSession1:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS"
  })
end

local function setDisplayWithColorsRejected(self)
  local responseParams = {}
  local cid = self.mobileSession1:SendRPC("SetDisplayLayout", getRequestParams2())
  self.mobileSession1:ExpectResponse(cid, {
    success = false,
    resultCode = "REJECTED"
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("SetDisplay Positive Case 1", setDisplayWithColorsSuccess)
runner.Step("SetDisplay Rejected Case", setDisplayWithColorsRejected)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
