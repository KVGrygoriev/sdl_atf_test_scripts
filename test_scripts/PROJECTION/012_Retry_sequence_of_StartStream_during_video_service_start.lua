---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Application is registered with PROJECTION appHMIType
-- 2) and starts video services
-- 3) HMI does not respond on first StartStream
-- SDL must:
-- 1) start retry sequence for StartStream
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/PROJECTION/common')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "PROJECTION"

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }
config.defaultProtocolVersion = 3

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.getAppID()].AppHMIType = { appHMIType }
end

local function BackUpIniFileAndSetStreamRetryValue()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("StartStreamRetry", "5,50")
end

local function RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function startService()
	test.mobileSession1:StartService(11)
    EXPECT_HMICALL("Navigation.StartStream")
    :Do(function(exp,data)
    	if 4 == exp.occurences then
      		test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      	end
    end)
    :Times(4)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("BackUp ini file and set StartStreamRetry value to 5,50", BackUpIniFileAndSetStreamRetryValue)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start video service with retry sequence for StartStream", startService)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore ini file", RestoreIniFile)
