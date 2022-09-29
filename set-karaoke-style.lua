script_name = "Set Karaoke Style"
script_description = "Set Karaoke Style"
script_author = "Michiyama Karen"
script_version = "1.0.0"


function check_subtitle_line(line, handle_style)
    -- same as aegisub Karaoke templater, see https://aegi.vmoe.info/docs/3.2/Automation/Karaoke_Templater/Template_execution_rules_and_order/#iterate-throughok
    return line.class == "dialogue" and line.style == handle_style and
        ((not line.comment and (line.effect=="" or line.effect=="karaoke")) or
         (line.comment and line.effect=="karaoke"))
end


function set_style(subtitles, handle_style)
    -- 处理歌词时间重叠的情况，将重叠的歌词分为数层，每层中的歌词不互相重叠
    -- layers存储每层歌词的信息，属性为`last_end`(该层上一条歌词的结束时间)和`counter`(已处理的该层歌词数)
    local layers = {}

    for i = 1, subtitles.n do
        local line = subtitles[i]
        if check_subtitle_line(line, handle_style) then
            local style_i

            local layer_i = 0
            while (true) do
                local cur_layer = layers[layer_i]
                if not cur_layer then
                    cur_layer = { last_end = 0, counter = 0 }
                end
                if line.start_time >= cur_layer.last_end then
                    style_i = cur_layer.counter % 2 + 1 + 2 * layer_i
                    layers[layer_i] = { last_end = line.end_time, counter = cur_layer.counter + 1 }
                    break
                end
                layer_i = layer_i + 1
            end

            line.style = string.format("K%d", style_i)
            subtitles[i] = line -- replace origin subtitles
        end
    end
end

function macro_set_style(subtitles, selected_lines, active_line)
    config = {
        {class="label", label="Karaoke line style:", x=0, y=0},
        {class="edit", name="style", value="Default", x=1, y=0}
    }
    btn, result = aegisub.dialog.display(config)
    if btn then
        set_style(subtitles, result.style)
    end
end

aegisub.register_macro(script_name, script_description, macro_set_style)
