require "lib.luafft"

local player = {}

local abs = math.abs
local new = complex.new

function f_map(x,  in_min,  in_max,  out_min,  out_max)
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function spectro_up_mic(obj, sdata, size, mic)
	if mic:getSampleCount() > size then
		local List = {}
		local data = mic:getData()
		for i= 0, size-1 do
			List[#List+1] = new(data:getSample(i), 0)
		end
		return fft(List, false)
	end
end

function spectro_up(obj, sdata, size)
	local MusicPos = obj:tell("samples")
	local MusicSize = sdata:getSampleCount()
	local List = {}

	for i= MusicPos, MusicPos + (size-1) do
		CopyPos = i
		if i + 2048 > MusicSize then i = MusicSize/2 end

		if sdata:getChannelCount()==1 then
			List[#List+1] = new(sdata:getSample(i), 0)
		else
			List[#List+1] = new(sdata:getSample(i*2), 0)
		end
	end
	return fft(List, false)
end

function player:load(loveframes, lx, ly)
	local frame = loveframes.Create("frame")
	frame:SetName("Player")
	frame:SetSize(411, 300)
	frame:SetPos(0,330)
	frame:SetAlwaysUpdate(true)
	frame:SetScreenLocked(true)

	frame:SetResizable(true)
	frame:SetMaxWidth(1000)
	frame:SetMaxHeight(1000)
	frame:SetMinWidth(200)
	frame:SetMinHeight(200)

	frame:SetDockable(true)

	local tabs = loveframes.Create("tabs", frame)
	tabs:SetPos(4, 30)
	tabs:SetSize(frame:GetWidth()-8, frame:GetHeight()-26-4)

	local panel_video = loveframes.Create("panel")
	local panel_shader = loveframes.Create("panel")
	local panel_music = loveframes.Create("panel")
	local panel_script = loveframes.Create("panel")

	local video = love.graphics.newVideo("ressource/video/bebop.ogv", {audio=true})
	local video_source = video:getSource()


---------------------------- Shader --------------------------------------------

	tabs:AddTab("Shader", panel_shader, nil)
	local choice_shader = loveframes.Create("multichoice", panel_shader)
	choice_shader:SetPos(8, 8)
	choice_shader:SetSize(panel_shader:GetWidth()-16, 25)

	local slider_speed = loveframes.Create("slider", panel_shader)
	slider_speed:SetPos(100, 40)
	slider_speed:SetWidth(panel_shader:GetWidth()-100-8)
	slider_speed:SetMinMax(0.0, 10)
	slider_speed:SetValue(1)

	local slider_speed_text = loveframes.Create("text", panel_shader)
	slider_speed_text:SetPos(8, 40)
	slider_speed_text:SetText("Speed: "..slider_speed:GetValue())

	slider_speed.OnValueChanged = function(object)
		slider_speed_text:SetText("Speed: "..math.floor(slider_speed:GetValue()*100)/100)
		shaders_param.speed = slider_speed:GetValue()
	end

	local slider_density = loveframes.Create("slider", panel_shader)
	slider_density:SetPos(100, 70)
	slider_density:SetWidth(panel_shader:GetWidth()-100-8)
	slider_density:SetMinMax(0.0, 4)
	slider_density:SetValue(1)

	local text1 = loveframes.Create("text", panel_shader)
	text1:SetPos(8, 70)
	text1:SetText("Density: "..slider_density:GetValue())

	slider_density.OnValueChanged = function(object)
		text1:SetText("Density: "..math.floor(slider_density:GetValue()*100)/100)
		shaders_param.density = slider_density:GetValue()
	end

	for k,v in ipairs(shaders) do
		choice_shader:AddChoice(v.name)
	end

	panel_shader.Update = function(object, dt)
		love.graphics.setCanvas(canvas)
			love.graphics.setColor(1,1,1,1)
			-- love.graphics.setColor(0.2, 0.2, 0.2)
			love.graphics.setShader(shaders[shader_nb].shader)
				love.graphics.draw(canvas_test,0,0)
			love.graphics.setShader()
		love.graphics.setCanvas()
	end

	choice_shader.OnChoiceSelected = function(object, choice)
		for k,v in ipairs(shaders) do
			if v.name == choice then
				shader_nb = k
			end
		end
	end
	choice_shader:SelectChoice("distord.glsl")

---------------------------- Music ---------------------------------------------

	-- local soundData = love.sound.newSoundData("ressource/music/8bit.mp3")

	local record_list = love.audio.getRecordingDevices()

	local mic = record_list[1]
	mic:start(735, 44100, 16, 1)


	local slider_lerp = loveframes.Create("slider", panel_music)
	tabs:AddTab("Music", panel_music, nil, nil, function() if sound then sound:play() end end, function() if sound then sound:pause() end end)
	slider_lerp:SetPos(100, 70)
	slider_lerp:SetWidth(panel_music:GetWidth()-100-8)
	slider_lerp:SetMinMax(0.05, 1)
	slider_lerp:SetValue(0.3)

	local text1 = loveframes.Create("text", panel_music)
	text1:SetPos(8, 70)
	text1:SetText("Lerp: "..slider_lerp:GetValue())

	slider_lerp.OnValueChanged = function(object)
		text1:SetText("Lerp: "..slider_lerp:GetValue())
	end

	local slider_amp = loveframes.Create("slider", panel_music)

	slider_amp:SetPos(100, 100)
	slider_amp:SetWidth(panel_music:GetWidth()-100-8)
	slider_amp:SetMinMax(0.01, 100)
	slider_amp:SetValue(40)

	local text2 = loveframes.Create("text", panel_music)
	text2:SetPos(8, 100)
	text2:SetText("Amp: "..slider_amp:GetValue())

	slider_amp.OnValueChanged = function(object)
		text2:SetText("Amp: "..math.floor(slider_amp:GetValue()*100)/100)
	end

	local progressbar = loveframes.Create("slider", panel_music)
	progressbar:SetPos(100, 40)
	progressbar:SetWidth(panel_music:GetWidth()-100-8)

	progressbar.OnValueChanged = function(object)
		-- progressbar:SetValue(math.floor(sound:tell("seconds")))
		-- self.value = math.floor(sound:tell("seconds"))
		sound:seek(progressbar:GetValue(), "seconds")
	end

	local checkbox = loveframes.Create("checkbox", panel_music)
	checkbox:SetText("Use audio in")
	checkbox:SetPos(8, 130)

	local t = {}
	local timer = 0
	local spectre = {}

	local choice_music = loveframes.Create("multichoice", panel_music)
	choice_music:SetPos(8, 8)
	choice_music:SetSize(panel_music:GetWidth()-16, 25)

	local list = love.filesystem.getDirectoryItems("ressource/music/")
	local musics = {}

	choice_music.OnChoiceSelected = function(object, choice)
		sound:stop()

		soundData = musics[choice].soundData
		sound = musics[choice].sound
		sound:play()
		progressbar:SetMinMax(0, math.floor(sound:getDuration()))
	end

	print("Load music:")
	for k,v in ipairs(list) do
		print("    "..v)
		musics[v] = {}
		musics[v].soundData = love.sound.newSoundData("ressource/music/"..v)
		musics[v].sound = love.audio.newSource(musics[v].soundData)
		-- scripts[v] = require("ressource/mu/"..v:gsub(".lua",""))
		musics[v].name = v
		soundData = musics[v].soundData
		sound = musics[v].sound
		choice_music:AddChoice(v)
		if #musics == 1 then
			choice_music:SelectChoice(v)
		end
	end

	local choice_mic = loveframes.Create("multichoice", panel_music)
	choice_mic:SetPos(130, 125)
	choice_mic:SetSize(panel_music:GetWidth()-130-8, 25)

	print("Load audio in:")
	for k,v in ipairs(record_list) do
		print("    "..v:getName())
		choice_mic:AddChoice(v:getName())
		choice_mic:SelectChoice(v:getName())
	end

	choice_mic.OnChoiceSelected = function(object, choice)
		mic:stop()
		for k,v in ipairs(record_list) do
			if v:getName() == choice then
				mic = v
				mic:start(735, 44100, 16, 1)
				break
			end
		end
	end



	local music_button = loveframes.Create("button", panel_music)
	music_button:SetPos(8, 40)
	music_button:SetSize(50, 25)
	music_button:SetText("Pause")
	music_button.OnClick = function(object, x, y)
		if sound:isPlaying() then
			sound:pause()
			object:SetText("Play")
		else
			sound:play()
			object:SetText("Pause")
		end
	end



	panel_music.Update = function(object, dt)
		timer = timer + dt
		local l = 1
		local div = 4
		--object:SetSize(frame:GetWidth()-8, frame:GetHeight()-28-4)
		local size = canvas:getWidth()
		if checkbox:GetChecked() then
			s = spectro_up_mic(sound, soundData, size*div/l, mic)
			spectre = s or spectre
		else
			spectre = spectro_up(sound, soundData, size*div/l)
		end

		love.graphics.setCanvas(canvas)
			love.graphics.clear(0,0,0,1)
			local lx = (canvas:getWidth() / size) * l
			-- local ly = (canvas:getHeight() / 20)
			love.graphics.setColor(0, 0, 0)
			-- love.graphics.rectangle("fill", object:GetX(), object:GetY(), object:GetWidth(), object:GetHeight())

			for i = 0, #spectre/div-1 do
				local v = 100*(spectre[i+1]:abs())
				-- v = math.min(v,200)
				local m = v/slider_amp:GetValue()--f_map(v, 0, 200, 0, 20)
				t[i+1] = lerp(t[i+1] or 0, m, slider_lerp:GetValue())

				local x = i*lx --(i*lx + canvas:getWidth()/2)%canvas:getWidth()

				local r,g,b = hslToRgb((timer+(x/canvas:getWidth()))%1,1,0.5)
				love.graphics.setColor(r,g,b)

				-- local color = math.min(t[i+1],canvas:getHeight())/canvas:getHeight()
				-- love.graphics.setColor(1,1-color,0)


				love.graphics.rectangle("fill", x, canvas:getHeight(), lx, -math.floor(t[i+1]))
				-- love.graphics.rectangle("fill", (x+canvas:getWidth()/2)%canvas:getWidth(), canvas:getHeight(), lx, -math.floor(t[i+1]*ly))
				-- love.graphics.rectangle("fill", canvas:getWidth()-(i+1)*lx, canvas:getHeight(), lx, -math.floor(t[i+1]*ly))
			end
			-- progressbar:SetValue(math.floor(sound:tell("seconds")))
			-- self.value = math.floor(sound:tell("seconds"))
		love.graphics.setCanvas()
	end

---------------------------- Video ---------------------------------------------

	tabs:AddTab("Video", panel_video, nil, nil, function() video:play() end, function() video:pause() end)
	local video_progressbar = loveframes.Create("progressbar", panel_video)
	video_progressbar:SetPos(68, 8)
	video_progressbar:SetWidth(210)
	video_progressbar:SetMinMax(0, math.floor(video_source:getDuration()))

	local video_button = loveframes.Create("button", panel_video)
	video_button:SetPos(8, 8)
	video_button:SetSize(50, 25)
	video_button:SetText("Pause")
	video_button.OnClick = function(object, x, y)
		if video:isPlaying() then
			video:pause()
			object:SetText("Play")
		else
			video:play()
			object:SetText("Pause")
		end
	end

	panel_video.Update = function(object, dt)
		love.graphics.setCanvas(canvas)
			love.graphics.draw(video, 0, 0, 0, canvas:getWidth()/video:getWidth(), canvas:getHeight()/video:getHeight())
			video_progressbar:SetValue(math.floor(video_source:tell("seconds")))
		love.graphics.setCanvas()
	end

---------------------------- Script --------------------------------------------

	tabs:AddTab("Script", panel_script)
	local choice_script = loveframes.Create("multichoice", panel_script)
	choice_script:SetPos(8, 8)
	choice_script:SetSize(panel_script:GetWidth()-16, 25)

	local list = love.filesystem.getDirectoryItems("ressource/script/")
	local scripts = {}
	print("Load scripts:")
	for k,v in ipairs(list) do
		print("    "..v)
		scripts[v] = require("ressource/script/"..v:gsub(".lua",""))
		scripts[v].name = v
	end

	for k,v in pairs(scripts) do
		choice_script:AddChoice(v.name)
	end
	choice_script:SelectChoice("42.lua")


	panel_script.Update = function(object, dt)
		love.graphics.setCanvas(canvas)
		scripts[choice_script:GetChoice()]:update(dt, canvas:getWidth(), canvas:getHeight())
		love.graphics.setCanvas()
	end

-------------------------------------------------------------------------------

end

return player
