local config = {}

function config.file_exists(file)
    local f = io.open(file, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

  function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter.."(.-)") do
        table.insert(result, match);
    end
    return result;
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function config.loadConfig(file)
    if not config.file_exists(file) then
        return nil, "File ".. file .." doesn't exist"
    end
    local conf = {}
    local valid_params = {'ENABLED','API_URL', 'API_KEY', 'BOUNCING_ON_TYPE', 'MODE', 'SECRET_KEY', 'SITE_KEY', 'BAN_TEMPLATE_PATH' ,'CAPTCHA_TEMPLATE_PATH', 'REDIRECT_LOCATION', 'RET_CODE', 'EXCLUDE_LOCATION', 'FALLBACK_REMEDIATION', 'CAPTCHA_PROVIDER'}
    local valid_int_params = {'CACHE_EXPIRATION', 'CACHE_SIZE', 'REQUEST_TIMEOUT', 'UPDATE_FREQUENCY', 'CAPTCHA_EXPIRATION', 'SSL_VERIFY'}
    local valid_bouncing_on_type_values = {'ban', 'captcha', 'all'}
    local valid_truefalse_values = {'false', 'true'}
    local default_values = {
        ['ENABLED'] = "true",
        ['REQUEST_TIMEOUT'] = 0.2,
        ['BOUNCING_ON_TYPE'] = "ban",
        ['MODE'] = "stream",
        ['UPDATE_FREQUENCY'] = 10,
        ['CAPTCHA_EXPIRATION'] = 3600,
        ['REDIRECT_LOCATION'] = "",
        ['EXCLUDE_LOCATION'] = {},
        ['RET_CODE'] = 0,
        ['SSL_VERIFY'] = "true",
	    ['CAPTCHA_PROVIDER'] = "recaptcha"
    }
    for line in io.lines(file) do
        local isOk = false
        if starts_with(line, "#") then
            isOk = true
        end
        if trim(line) == "" then
            isOk = true
        end
        if not isOk then
	    local sep_pos = line:find("=")
	    if not sep_pos then
	       ngx.log(ngx.ERR, "invalid configuration line: " .. line)
	       break
	    end
            local key = trim(line:sub(1, sep_pos - 1))
	    local value = trim(line:sub(sep_pos + 1))
	    if has_value(valid_params, key) then
		if key == "ENABLED" then
		    if not has_value(valid_truefalse_values, value) then
			ngx.log(ngx.ERR, "unsupported value '" .. value .. "' for variable '" .. key .. "'. Using default value 'true' instead")
			conf[key] = "true"
		    end
		elseif key == "BOUNCING_ON_TYPE" then
		    if not has_value(valid_bouncing_on_type_values, value) then
			ngx.log(ngx.ERR, "unsupported value '" .. value .. "' for variable '" .. key .. "'. Using default value 'ban' instead")
			conf[key] = "ban"
		    end
		elseif key == "MODE" then
		    if not has_value({'stream', 'live'}, value) then
			ngx.log(ngx.ERR, "unsupported value '" .. value .. "' for variable '" .. key .. "'. Using default value 'stream' instead")
			conf[key] = "stream"
		    end
		elseif key == "EXCLUDE_LOCATION" then
		    exclude_location = {}
		    if value ~= "" then
			for match in (value..","):gmatch("(.-)"..",") do
			    table.insert(exclude_location, match)
			end
		    end
		    conf[key] = exclude_location
		elseif key == "FALLBACK_REMEDIATION" then
		    if not has_value({'captcha', 'ban'}, value) then
			ngx.log(ngx.ERR, "unsupported value '" .. value .. "' for variable '" .. key .. "'. Using default value 'ban' instead")
			conf[key] = "ban"
		    end
		else
		    conf[key] = value
		end
	    elseif has_value(valid_int_params, key) then
		conf[key] = tonumber(value)
	    else
		ngx.log(ngx.ERR, "unsupported configuration '" .. key .. "'")
	    end
	end
    end
    for k, v in pairs(default_values) do
        if conf[k] == nil then
            conf[k] = v
        end
    end
    return conf, nil
end
return config