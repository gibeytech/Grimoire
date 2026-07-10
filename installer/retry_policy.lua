local RetryPolicy = {}

local MAX_ATTEMPTS = 5

local function is_integer(value)
   return type(value) == "number"
      and value == math.floor(value)
end

local function normalize_exit_codes(values)
   if values == nil then
      return {}, {}, nil
   end

   if type(values) ~= "table" then
      return nil, nil,
         "La liste des codes de retry doit être une table"
   end

   local highest_index = 0

   for key in pairs(values) do
      if not is_integer(key) or key < 1 then
         return nil, nil,
            "La liste des codes de retry doit être séquentielle"
      end

      if key > highest_index then
         highest_index = key
      end
   end

   local list = {}
   local lookup = {}

   for index = 1, highest_index do
      local value = values[index]

      if value == nil then
         return nil, nil,
            "La liste des codes de retry doit être séquentielle"
      end

      if not is_integer(value)
         or value < 1
         or value > 255
      then
         return nil, nil,
            "Code de sortie de retry invalide: "
               .. tostring(value)
      end

      if lookup[value] then
         return nil, nil,
            "Code de sortie de retry dupliqué: "
               .. tostring(value)
      end

      table.insert(list, value)
      lookup[value] = true
   end

   return list, lookup, nil
end

local function disabled_policy()
   return {
      enabled = false,
      max_attempts = 1,
      retry_on_timeout = false,
      exit_codes = {},
      exit_code_lookup = {},
   }
end

function RetryPolicy.resolve(action)
   action = action or {}

   local configuration = action.retry

   if configuration == nil
      or configuration == false
   then
      return disabled_policy(), nil
   end

   if type(configuration) ~= "table" then
      return nil,
         "La politique de retry doit être une table"
   end

   if action.type ~= "command" then
      return nil,
         "Le retry est réservé aux actions command explicitement rejouables"
   end

   if configuration.replay_safe ~= true then
      return nil,
         "replay_safe doit être true pour autoriser le retry"
   end

   local max_attempts = configuration.max_attempts

   if not is_integer(max_attempts)
      or max_attempts < 2
      or max_attempts > MAX_ATTEMPTS
   then
      return nil,
         "max_attempts doit être un entier compris entre 2 et "
            .. tostring(MAX_ATTEMPTS)
   end

   if configuration.retry_on_timeout ~= nil
      and type(configuration.retry_on_timeout)
         ~= "boolean"
   then
      return nil,
         "retry_on_timeout doit être un booléen"
   end

   local exit_codes, exit_code_lookup,
      exit_codes_error = normalize_exit_codes(
         configuration.exit_codes
      )

   if exit_codes_error then
      return nil, exit_codes_error
   end

   local retry_on_timeout =
      configuration.retry_on_timeout == true

   if #exit_codes == 0
      and not retry_on_timeout
   then
      return nil,
         "La politique de retry doit autoriser au moins "
            .. "un code de sortie ou le timeout"
   end

   return {
      enabled = true,
      replay_safe = true,
      max_attempts = max_attempts,
      retry_on_timeout = retry_on_timeout,
      exit_codes = exit_codes,
      exit_code_lookup = exit_code_lookup,
   }, nil
end

function RetryPolicy.should_retry(
   policy,
   result,
   attempt
)
   policy = policy or disabled_policy()
   result = result or {}
   attempt = attempt or 1

   if result.ok == true then
      return false, "success"
   end

   if not policy.enabled then
      return false, "disabled"
   end

   if result.interrupted == true then
      return false, "interrupted"
   end

   local eligible = false
   local eligible_reason = "not-eligible"

   if result.timed_out == true then
      if policy.retry_on_timeout then
         eligible = true
         eligible_reason = "timeout"
      else
         return false, "timeout-not-enabled"
      end
   elseif result.exit_code ~= nil
      and policy.exit_code_lookup[
         result.exit_code
      ] == true
   then
      eligible = true
      eligible_reason = "exit-code"
   end

   if not eligible then
      return false, eligible_reason
   end

   if attempt >= policy.max_attempts then
      return false, "exhausted"
   end

   return true, eligible_reason
end

return RetryPolicy
