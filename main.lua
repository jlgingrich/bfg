function init()
	--Register tool and enable it
	RegisterTool("bfg", "B.F.G", "MOD/vox/bfg.vox")
	SetBool("game.tool.bfg.enabled", true)

	--BFG has 10 shots. 
	--If played in sandbox mode, the sandbox script will make it infinite automatically
	SetInt("game.tool.bfg.ammo", 10)
	
	ready = 0
	fireTime = 0
	
	chargeLoop = LoadLoop("MOD/snd/laser.ogg")
	plasmaSnd = LoadSound("MOD/snd/plasma.ogg")
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function tick(dt)
	--Check if laser blaster is selected
	if GetString("game.player.tool") == "bfg" then
	
		--Check if tool is firing
		if GetBool("game.player.canusetool") and InputDown("lmb") and GetInt("game.tool.bfg.ammo") > 0 then
			ready = math.min(1.0, ready + 0.5 * dt)
			if ready == 1.0 then
				local t = GetCameraTransform()
				local fwd = TransformToParentVec(t, Vec(0, 0, -1))
				local maxDist = 100
				local hit, dist, normal, shape = QueryRaycast(t.pos, fwd, maxDist)
				if not hit then
					dist = maxDist
				end

				
				--Laser line start and end points
				local s = VecAdd(VecAdd(t.pos, Vec(0, -0.5, 0)),VecScale(fwd, 1.5))
				local e = VecAdd(t.pos, VecScale(fwd, dist))

				PlaySound(plasmaSnd, t.pos)

				--Draw laser line in ten segments with random offset
				local last = s
				for l=1, 3 do
					for i=1, 10 do
						local t = i/10
						local p = VecLerp(s, e, t)
						p = VecAdd(p, rndVec(0.5*t))
						DrawLine(last, p, 0, 1, 0)
						last = p
					end
				end
				--Make damage and spawn particles
				if hit then
					MakeHole(e, 2.5, 2.5, 2.5, false)
					Explosion(e, 2.0)
					SpawnParticle("smoke", e, rndVec(0.5), 1.0, 1.0)
					for i=1, 10 do
						p = VecAdd(e, rndVec(3.0))
						DrawLine(e, p, 0, 1, 0)
					end
				end
				
				ready = 0
				fireTime = fireTime + dt
				SetInt("game.tool.bfg.ammo", math.max(0, GetInt("game.tool.bfg.ammo")-1))
			else
				local t = GetCameraTransform()
				PlayLoop(chargeLoop, t.pos, ready)
			end
		else
			fireTime = 0
			if ready == 1 then
		end
			ready = math.max(0.0, ready - 0.5 * dt)
		end
	
		local b = GetToolBody()
		if b ~= 0 then
			local shapes = GetBodyShapes(b)

			--Control emissiveness
			for i=1, #shapes do
				SetShapeEmissiveScale(shapes[i], ready)
			end
	
			--Add some light
			if ready > 0 then
				local p = TransformToParentPoint(GetBodyTransform(body), Vec(0, 0, 0))
				PointLight(p, 0, 1, 1, ready * math.random(10, 15) / 10)
			end
			
			--Move tool
			local offset = VecScale(rndVec(0.01), ready*math.min(fireTime/5, 1.0))
			SetToolTransform(Transform(offset))
			
			--Animate 
			local t	= ready
			t = t*t
			local offset = t*0.1
			
			if b ~= body then
				body = b
				--Get default transforms
				t0 = GetShapeLocalTransform(shapes[2])
			end

			t = TransformCopy(t0)
			t.pos = VecAdd(t.pos, Vec(0, 0, offset))
			SetShapeLocalTransform(shapes[2], t)
		end
	end
end

