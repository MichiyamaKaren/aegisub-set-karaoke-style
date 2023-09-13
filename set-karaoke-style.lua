script_name = "Set Karaoke Style"
script_description = "Set styles and rearrange time for karaoke subtitles, to generate two-line karaoke effect"
script_author = "Michiyama Karen"
script_version = "1.1.0"


function check_subtitle_line(line, handle_style)
    -- same as aegisub Karaoke templater, see https://aegi.vmoe.info/docs/3.2/Automation/Karaoke_Templater/Template_execution_rules_and_order/#iterate-throughok
    return line.class == "dialogue" and line.style == handle_style and
        ((not line.comment and (line.effect=="" or line.effect=="karaoke")) or
         (line.comment and line.effect=="karaoke"))
end


function set_style(subtitles, handle_style, advance_time, sep_threshold)
    -- 处理歌词时间重叠的情况，将重叠的歌词分为数层，每层中的歌词不互相重叠
    -- layers存储每层歌词的信息，属性为`last_end`(该层上一条歌词的结束时间)和`counter`(已处理的该层歌词数)
    local layers = {}

    for i = 1, subtitles.n do
        local line = subtitles[i]
        if check_subtitle_line(line, handle_style) then
            local layer_i = 0
            local last_start, style_i
            while (true) do
                local cur_layer, cur_layer_next
                local start_time = line.start_time  -- value of `last_start` in `cur_layer_next`
                cur_layer = layers[layer_i]
                if not cur_layer then
                    start_time = line.start_time - advance_time
                    cur_layer = { last_start = start_time, last_end = line.start_time, counter = 0 }
                end
                if line.start_time >= cur_layer.last_end then
                    style_i = cur_layer.counter % 2 + 1 + 2 * layer_i

                    last_start = cur_layer.last_start
                    cur_layer_next = { last_start = start_time, last_end = line.end_time, counter = cur_layer.counter + 1 }
                    if line.start_time - cur_layer.last_end > sep_threshold then
                        last_start = line.start_time - advance_time
                        cur_layer_next.last_start = last_start  -- align the start time of the next subtitle 
                    end
                    layers[layer_i] = cur_layer_next
                    break
                end
                layer_i = layer_i + 1
            end

            line.text = string.format("{\\k%d}%s", math.floor((line.start_time - last_start)/10), line.text)
            line.start_time = last_start

            line.style = string.format("K%d", style_i)
            subtitles[i] = line -- replace origin subtitles
        end
    end
end

function macro_set_style(subtitles, selected_lines, active_line)
    config = {
        {class="label", label="Karaoke line style:", x=0, y=0},
        {class="edit", name="style", value="Default", x=1, y=0},
        {class="label", label="Advance time (ms):", x=0, y=1},
        {class="floatedit", name="advance_time", value="100", x=1, y=1},
        {class="label", label="Seperation threshold (ms):", x=0, y=2},
        {class="floatedit", name="sep_threshold", value="2000", x=1, y=2}
    }
    btn, result = aegisub.dialog.display(config)
    if btn then
        set_style(subtitles, result.style, math.floor(result.advance_time), math.floor(result.sep_threshold))
    end
end

aegisub.register_macro(script_name, script_description, macro_set_style)
