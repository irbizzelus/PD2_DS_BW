Hooks:OverrideFunction(TimerGui, "start", function (self, timer)
	timer = self._override_timer or timer
	
	if Network and Network:is_server() and DS_BW and DS_BW.DS_difficultycheck and not managers.groupai:state():whisper_mode() then
		local mul = 1
		local event_muls = {
			drill = 1.5,
			thermal_lance_on = 1.5,
			buzz_saw = 1.5,
		}
		if event_muls[self._start_event] then
			mul = event_muls[self._start_event]
		else
			log("[DSBW] Increased_timer_by_1x_for: "..tostring(self._start_event))
			log("[DSBW] Increased_timer_by_1x_for: "..tostring(self._start_event))
			log("[DSBW] Increased_timer_by_1x_for: "..tostring(self._start_event))
		end
		timer = timer * mul
	end
	
	if not self._started then
		self:_start(timer)

		if managers.network:session() then
			managers.network:session():send_to_peers_synched("start_timer_gui", self._unit, timer)
		end
	end

	if not self._powered then
		self:set_powered(true)
	end

	if self._jammed then
		self:set_jammed(false)
	end
end)