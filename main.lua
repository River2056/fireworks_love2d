PARTICLE_RADIUS = 1.7

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
		local mult = { x = love.math.random(-3, 3), y = love.math.random(-3, 3) }
		vel = { x = love.math.random(-3, 3), y = love.math.random(-3, 3) }

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
				local randomX = love.math.random(0.9)
				local randomY = love.math.random(0.9)
				local mult = { x = randomX, y = randomY }
				print(mult.x)
				print(mult.y)
				self.vel.x = self.vel.x * mult.x
				self.vel.y = self.vel.y * mult.y
				self.lifespan = self.lifespan - 0.01
			end

			self.vel.x = self.vel.x + self.acc.x
			self.vel.y = self.vel.y + self.acc.y

			self.pos.x = self.pos.x + vel.x
			self.pos.y = self.pos.y + vel.y

			self.acc.x = self.acc.x * 0
			self.acc.y = self.acc.y * 0
		end,

		done = function(self)
			return self.lifespan <= 0
		end,

		show = function(self)
			if not firework then
				love.graphics.setColor(HSL(hu.r, hu.g, hu.b, self.lifespan))
			else
				love.graphics.setColor(HSL(hu.r, hu.g, hu.b))
			end
			love.graphics.ellipse("fill", self.pos.x, self.pos.y, self.r, self.r)
		end,
	}
end

function Firework()
	local hu = {
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
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
				self.particles[i]:applyForce(GRAVITY)
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
	love.window.setMode(430, 932, {
		resizable = true,
	})
	WIDTH = love.graphics.getWidth()
	HEIGHT = love.graphics.getHeight()
	GRAVITY = { x = 0, y = 0.1 }

	fireworks = {}
end

function love.update(dt)
	local chance = love.math.random(0, 100)

	if chance >= 99 then
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
	love.graphics.setBackgroundColor(0.15, 0.15, 0.15)
	for _, p in ipairs(fireworks) do
		p:show()
	end
end
