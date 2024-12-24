FREQ = 0.09
PARTICLE_RADIUS = 1.5

function HSL(h, s, l, a)
	if s <= 0 then
		return l, l, l, a
	end
	h, s, l = h * 6, s, l
	local c = (1 - math.abs(2 * l - 1)) * s
	local x = (1 - math.abs(h % 2 - 1)) * c
	local m, r, g, b = (l - 0.5 * c), 0, 0, 0
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return r + m, g + m, b + m, a
end

function Particle(x, y, hu, firework)
	local vel
	if firework then
		vel = { x = 0, y = love.math.random(-12, -8) }
	else
		local mult = { x = love.math.random(5, 20), y = love.math.random(5, 20) }
		local randomX = love.math.random()
		if love.math.random() >= 0.5 then
			randomX = randomX * -1
		end

		local randomY = love.math.random()
		if love.math.random() >= 0.5 then
			randomY = randomY * -1
		end
		vel = { x = randomX, y = randomY }

		vel.x = vel.x * mult.x
		vel.y = vel.y * mult.y
	end

	return {
		pos = { x = x, y = y },
		vel = vel,
		acc = { x = 0, y = 0 },
		lifespan = 1,
		r = PARTICLE_RADIUS,

		applyForce = function(self, force)
			self.acc.x = self.acc.x + force.x
			self.acc.y = self.acc.y + force.y
		end,

		update = function(self)
			if not firework then
				self.vel.x = self.vel.x * 0.9
				self.vel.y = self.vel.y * 0.9
				self.lifespan = self.lifespan - 0.029
			end

			self.vel.x = self.vel.x + self.acc.x
			self.vel.y = self.vel.y + self.acc.y

			self.pos.x = self.pos.x + self.vel.x
			self.pos.y = self.pos.y + self.vel.y

			self.acc.x = self.acc.x * 0
			self.acc.y = self.acc.y * 0
		end,

		done = function(self)
			return self.lifespan < 0 and true or false
		end,

		show = function(self)
			love.graphics.setBlendMode("alpha", "alphamultiply")
			if not firework then
				love.graphics.setColor(hu.r, hu.g, hu.b, self.lifespan)
				local points = {}
				for i = 1, 20 do
					table.insert(points, { self.pos.x, self.pos.y + i, hu.r, hu.g, hu.b, self.lifespan - (0.029 * i) })
				end
				love.graphics.points(points)
			else
				love.graphics.setColor(hu.r, hu.g, hu.b)

				local points = {}
				for i = 1, 3 do
					table.insert(points, { self.pos.x, self.pos.y - i, hu.r, hu.g, hu.b, self.lifespan - (0.029 * i) })
				end
				love.graphics.points(points)
			end
		end,
	}
end

function Firework()
	local hu = {
		r = love.math.random() + 0.1,
		g = love.math.random() + 0.1,
		b = love.math.random() + 0.1,
	}

	return {
		firework = Particle(love.math.random(0, WIDTH), HEIGHT, hu, true),
		exploded = false,
		particles = {},

		done = function(self)
			return self.exploded and #self.particles == 0
		end,

		update = function(self)
			if not self.exploded then
				self.firework:applyForce(GRAVITY)
				self.firework:update()
				if self.firework.vel.y >= 0 then
					self.exploded = true
					self:explode()
				end
			end
			for i = #self.particles, 1, -1 do
				self.particles[i]:applyForce({ x = 0, y = 0.4 })
				self.particles[i]:update()
				if self.particles[i]:done() then
					table.remove(self.particles, i)
				end
			end
		end,

		explode = function(self)
			for _ = 1, 200 do
				table.insert(self.particles, Particle(self.firework.pos.x, self.firework.pos.y, hu, false))
			end
		end,

		show = function(self)
			if not self.exploded then
				self.firework:show()
			end
			for _, p in ipairs(self.particles) do
				p:show()
			end
		end,
	}
end

function love.load()
	WIDTH = love.graphics.getWidth()
	HEIGHT = love.graphics.getHeight()

	love.graphics.setBlendMode("add", "alphamultiply")
	love.window.setMode(WIDTH, HEIGHT, { borderless = true })
	GRAVITY = { x = 0, y = 0.2 }

	dtCount = 0
	fireworks = {}
end

function love.update(dt)
	if love.math.random() * 1 < FREQ then
		table.insert(fireworks, Firework())
	end

	for idx, p in ipairs(fireworks) do
		p:update()
		if p:done() then
			table.remove(fireworks, idx)
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.draw()
	love.graphics.setBackgroundColor(0.15, 0.15, 0.15, 0.25)
	love.graphics.setBlendMode("add", "alphamultiply")
	for _, p in ipairs(fireworks) do
		p:show()
	end
end

function love.run()
	if love.load then
		love.load(love.arg.parseGameArguments(arg), arg)
	end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then
		love.timer.step()
	end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a, b, c, d, e, f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a, b, c, d, e, f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			dt = love.timer.step()
		end

		-- Call update and draw
		if love.update then
			love.update(dt)
		end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then
				love.draw()
			end

			love.graphics.present()
		end

		if love.timer then
			love.timer.sleep(0.015) -- default 0.001
		end
	end
end
