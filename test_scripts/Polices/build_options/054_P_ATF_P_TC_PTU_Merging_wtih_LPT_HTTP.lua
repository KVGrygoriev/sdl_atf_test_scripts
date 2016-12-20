--UNREADY:
-- In https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/247/ there are
--attached ptu_prop.json at ptu.json that need to be renamed and
--copied at: /tmp/fs/mp/images/ivsu_cache/, for lines containing "/tmp/fs/mp/images/ivsu_cache/ptu.json"
-- functions in Test section need to be updated

-- Requirement summary:
-- [PolicyTableUpdate] Merging PTU and LPT after getting Policy Table Update
--
-- Description:
--PolliciesManager must merge the Updated PT with the Local PT in the way not to get anything lost,
--including the appID added to Local PT during PT Exchange process.
--Information: When the PTU is received, it will not contain the appID of the newly registered app.

-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- App 1 is registered.
-- App 2 NOT yet registered on SDL and doesn't yet exist in LocalPT
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- App 2->SDL:RegisterAppInterface()
-- SDL->App 2: SUCCESS:RegsterAppInterface()
-- SDL adds application with App 2 data into LocalPT according to general rules
-- of adding app data into LocalPT
-- 2. Performed steps
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- Expected result:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU:
--module_config, functional_groupings and app_policies
--App 2 added to Local PT during PT Exchange process left after merge in LocalPT (not being lost on merge)
-------------------------------------------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local mobile_session = require('mobile_session')


--[[ Local Functions ]]
local registerAppInterfaceParams =
{
  syncMsgVersion =
  {
    majorVersion = 3,
    minorVersion = 0
  },
  appName = "Media Application",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
  appHMIType = {"NAVIGATION"},
  appID = "MyTestApp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Precondition_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

function Test:Precondition_CheckThatAppID_SecondApp_Present_In_DataBase()
  local app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select id from application")
  local app2_exist = false

  for _, value in pairs(app_id_table) do
    if ( value == registerAppInterfaceParams.appID) then
      app2_exist = true
    end
  end
  if(app2_exist == false) then
    self:FailTestCase("Application "..registerAppInterfaceParams.appID.." doesn't exist in Local PT.")
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_PoliciesManager_changes_UP_TO_DATE()
  assert(commonFunctions:File_exists("files/ptu.json"))
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = "PolicyTableUpdate" },"files/ptu.json")

  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, {"UPDATE_NEEDED"}):Times(2)
end

function Test:TestStep_CheckThatAppID_SecondApp_StillPresent_In_DataBase()
  local app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select id from application")
  local app2_exist = false

  for _, value in pairs(app_id_table) do
    if ( value == registerAppInterfaceParams.appID) then
      app2_exist = true
    end
  end
  if(app2_exist == false) then
    self:FailTestCase("Application "..registerAppInterfaceParams.appID.." doesn't exist in Local PT.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test