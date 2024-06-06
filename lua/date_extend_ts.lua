--[[
组件名称：时间转换器-扩展
描述：输入 今天/明天/后天/前天等
作者：空山明月
时间：2024-6-6
--]]

--------------------------------------------------------------------------------------

require("date_ts")

-- 时间向前或向后计算
local function addDaysToDate(days, format)
    return os.date(format, os.time() + days * 86400)
end

-- 从当前日期向前或向后计算
local function somedate_translator(input, seg, days) 
    local dt_nums = GetDateNums(addDaysToDate(days, "%Y.%m.%d"))
    local dt_str = dt_nums[1].."年"..dt_nums[2].."月"..dt_nums[3].."日"
    yield(Candidate(input, seg.start, seg._end, dt_str, "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, addDaysToDate(days, "%Y-%m-%d"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, addDaysToDate(days, "%Y%m%d"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, addDaysToDate(days, "%Y年%m月%d日"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, DateToCnStr(addDaysToDate(days, "%Y.%m.%d")), "〈日期〉"))
end

-- 获取本月相邻月份同一天时的日期
-- 比如今天是 2024-05-13，则可获取 2024-04/6-13 的日期
-- today: 当天日期
-- is_next: true 表示获取下个月，fase 表示获取上个月
-- retrun: 返回结果表示与当天相差的天数
local function get_month_sameday(is_next)
	local offset_days = 0
	local this_year, this_month = os.date("%Y", os.time()), os.date("%m", os.time())
	local now_days = os.date("%d", os.time())  -- 本月第几天
	
	local last_month, next_month = 0, 0
    local this_day_amount = 0
	local last_day_amount = 0
	local next_day_amount = 0

	if is_next then
		-- 如果现在是12月份，需要向后推一年
		if this_month == 12 then
			last_month, next_month = this_month - 1, 1
		else
			last_month, next_month = this_month - 1, this_month + 1
		end

        this_day_amount = os.date("%d", os.time({year=this_year, month=this_month+1, day=0}))
	    next_day_amount = os.date("%d", os.time({year=this_year, month=next_month+1, day=0}))	

        -- 如果时间间隔超出了下个月的最后一天，则按最后一天算
        local temp_offset_max = this_day_amount
        local temp_offset_min = this_day_amount - now_days + next_day_amount
        if now_days >= next_day_amount then
            offset_days = temp_offset_min
        else
            offset_days = temp_offset_max
        end
	else
		-- 如果当前是1月份，需要向前推一年
		if this_month == 1 then
			last_month, next_month = 12, this_month + 1
		else
			last_month, next_month = this_month - 1, this_month + 1
		end

        this_day_amount = os.date("%d", os.time({year=this_year, month=this_month+1, day=0}))
	    last_day_amount = os.date("%d", os.time({year=this_year, month=last_month+1, day=0}))	

        -- 如果时间间隔超出了下个月的最后一天，则按最后一天算
        if now_days <= last_day_amount then
            offset_days = last_day_amount
        else
            offset_days = now_days
        end
	end
    
	return offset_days
end

-- 时期类字符串集
local str_date_time={ 
	today="wygd",
	next_day="jegd",
	after_next_day = "rggd",
	lastday = "jtgd",
	before_lastday = "uegd",
	time = "jfuj",
	this_week = "sgmf",
	last_week = "hhmf",
	next_week = "ghmf",
	this_month = "sgee",
	last_month = "hhee",
	next_month = "ghee",}

-- 时间字符串转译成时间
local function str_to_datetime(input, seg)

	-- 输出今天的日期
	if (input == str_date_time["today"]) then
		GetDate("date", seg)
	end

	-- 输出明天的日期
	if (input == str_date_time["next_day"]) then
		somedate_translator("date", seg, 1)
	end

	-- 输出后天的日期
	if (input == str_date_time["after_next_day"]) then
		somedate_translator("date", seg, 2)
	end

	-- 输出昨天的日期
	if (input == str_date_time["lastday"]) then
		somedate_translator("date", seg, -1)
	end

	-- 输出前天的日期
	if (input == str_date_time["before_lastday"]) then
		somedate_translator("date", seg, -2)
	end

	-- 输出当前时间
	if (input == str_date_time["time"]) then
		GetTime("time", seg)
	end

	-- 输出本周时间：表示本周的当天时间
	if (input == str_date_time["this_week"]) then
		GetDate("date", seg)
	end

	-- 输出上周时间：表示上周对应星期时间
	-- 比如今天是周三，则此函数返回上周周三对应的日期
	if (input == str_date_time["last_week"]) then
		somedate_translator("date", seg, -7)
	end

	-- 输出下周时间：表示上周对应星期时间
	-- 比如今天是周三，则此函数返回下周周三对应的日期
	if (input == str_date_time["next_week"]) then
		somedate_translator("date", seg, 7)
	end

	-- 输出本月日期，默认是本月当天日期
	if (input == str_date_time["this_month"]) then
		GetDate("date", seg)
	end

	-- 输出上月与当天天数相同的日期，有末则按最后一天计算
	if (input == str_date_time["last_month"]) then
		local days_offset = get_month_sameday(false)
		somedate_translator("date", seg, -days_offset)
	end

	-- 输出下月与当天天数相同的日期，有末则按最后一天计算
	if (input == str_date_time["next_month"]) then
		local days_offset = get_month_sameday(true)
		somedate_translator("date", seg, days_offset)
	end
end

-- 转换器入口
local function translator(input, seg)
    str_to_datetime(input, seg)
end
 
 return translator