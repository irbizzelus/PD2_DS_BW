Hooks:OverrideFunction(TimerGui, "start", function (self, timer)
	timer = self._override_timer or timer
	
	if Network and Network:is_server() and DS_BW and DS_BW.DS_difficultycheck and not managers.groupai:state():whisper_mode() then
		timer = timer * 1.5
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