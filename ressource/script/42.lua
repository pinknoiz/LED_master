local forty_two = {}

local img = love.graphics.newImage("ressource/image/42_2.png")

function forty_two:update(dt, lx, ly)
	local k = ly / img:getHeight()
	-- love.graphics.clear(0,0,0,1)
	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.setShader(shaders[shader_nb].shader)
		love.graphics.draw(canvas_test,0,0)
	love.graphics.setShader()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(img, math.floor(lx/2 - (img:getWidth()*k)/2), 0, 0, k, k)
end

return forty_two
