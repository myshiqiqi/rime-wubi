--[[
组件名称：时间转换器
描述：输入 date/week/time/moth
作者：空山明月
时间：2024-6-5
--]]

--------------------------------------------------------------------------------------

-- 分割字符串
-- str: 需要被分割的字符串
-- reps: 分割字符串的符号
-- return: 返回被一个字符集
local function split(str,reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

-- 将数字转换成纯大写文本
local function num_to_cnstr(num)
    local hzNum = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "〇"}
	local result = ""

    for i=1, string.len(tostring(num)) do
        local strNum = string.sub(num,i,i)
        if strNum == "0" then strNum = "10" end
        local index = tonumber(strNum)
        local strValue = hzNum[index]
        result = result..strValue
    end
    
    return result
end

-- 将数字转换成纯大写数字
local function num_to_cnnum(num)
    local hzNum = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "〇"}
    local hzWei = {"十", "百", "千", "万"}
	local result = ""
    local num_len = string.len(tostring(num))

    for i=1, num_len do
        local strNum = string.sub(num,i,i)
        if i == num_len then
            result = result..(hzNum[tonumber(strNum)] or "")
        elseif i == 1 then
            if strNum ~= "0" then
                local _num = hzNum[tonumber(strNum)]..hzWei[num_len -i]
                if  _num == "一十" then _num = "十" end
                result = result.._num
            end
        else
            if strNum == "0" then strNum = "10" end
            local _num = hzNum[tonumber(strNum)]..hzWei[num_len -i]
            if  _num == "一十" then _num = "十" end
            result = result.._num
        end
    end

    return result
end

-- 将时间字符串转换成中文时间格式
-- strDate: 格式 2024.05.12
-- return: 返回中文描述的时间字符串，格式 二〇二四年五月十二日
local function date_to_cnstr(strDate)
    local strYear, strMoth, strDay = "", "", ""
    -- 将日期以.分割
	local dtArray = split(strDate, '.')
    -- 转换年
    strYear = num_to_cnstr(dtArray[1])
    -- 转换月
    strMoth = num_to_cnnum(dtArray[2])
    -- 转换日
    strDay = num_to_cnnum(dtArray[3])

    return strYear.."年"..strMoth.."月"..strDay.."日"
end

-- 返回年月日纯数字部分
-- 如 2024年06月06日 返回 {2024, 6, 6}
local function get_date_nums(date)
    local dt = date or os.date("%Y.%m.%d")
    local nums = split(tostring(dt), ".")
    local y = tostring(tonumber(nums[1]))
    local m = tostring(tonumber(nums[2]))
    local d = tostring(tonumber(nums[3]))

    return {y, m, d}
end

-- 获取当天日期
local function get_date(input, seg)
    local dt_nums = get_date_nums()
    local dt_str = dt_nums[1].."年"..dt_nums[2].."月"..dt_nums[3].."日"
    yield(Candidate(input, seg.start, seg._end, dt_str, "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%Y-%m-%d"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%Y%m%d"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%Y年%m月%d日"), "〈日期〉"))
    yield(Candidate(input, seg.start, seg._end, date_to_cnstr(os.date("%Y.%m.%d")), "〈日期〉"))
end

-- 获取星期
local function get_week(input, seg)
    local week_strs = {"日","一","二","三","四","五","六"}
    local week_num = os.date("%w") + 1

	yield(Candidate(input, seg.start, seg._end, "周"..week_strs[week_num], "〈星期〉"))
    yield(Candidate(input, seg.start, seg._end, "星期"..week_strs[week_num], "〈星期〉"))
    yield(Candidate(input, seg.start, seg._end, "礼拜"..week_strs[week_num], "〈星期〉"))
end

-- 获取时间戳
local function get_time(input, seg)
    local dt_nums = get_date_nums()
    local dt_str = dt_nums[1].."年"..dt_nums[2].."月"..dt_nums[3].."日"
    yield(Candidate(input, seg.start, seg._end, dt_str.." "..os.date("%H:%M:%S"), "〈时间〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%Y-%m-%d").." "..os.date("%H:%M:%S"), "〈时间〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%H:%M:%S"), "〈时间〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%H").."时"..os.date("%M").."分"..os.date("%S").."秒", "〈时间〉"))
    yield(Candidate(input, seg.start, seg._end, os.date("%Y年%m月%d日").." "..os.date("%H:%M:%S"), "〈时间〉"))
    yield(Candidate(input, seg.start, seg._end, num_to_cnnum(tostring(os.date("%H"))).."时"..num_to_cnnum(tostring(os.date("%M"))).."分"..num_to_cnnum(tostring(os.date("%S"))).."秒", "〈时间〉"))
end

-- 公用函数，供外部调用
function GetDate(input, seg)
    get_date(input, seg)
end

-- 公用函数，供外部调用
function GetWeek(input, seg)
    get_week(input, seg)
end

-- 公用函数，供外部调用
function GetTime(input, seg)
    get_time(input, seg)
end

-- 公用函数，供外部调用
function DateToCnStr(strDate)
    return date_to_cnstr(strDate)
end

-- 公用函数，供外部调用
function GetDateNums(date)
    return get_date_nums(date)
end

-- 转换器入口
local function translator(input, seg)
    if input == "date" then
        get_date(input, seg)
    elseif input == "week" then
        get_week(input, seg)
    elseif input == "time" then
        get_time(input, seg)
    end
 end
 
 return translator