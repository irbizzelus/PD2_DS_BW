local function update_EnemyManager()
	DelayedCalls:Add("DS_BW_add_faster_enemy_ai_for_DS", 3, function()
		if Network:is_server() and DS_BW and DS_BW.DS_difficultycheck and tweak_data then
			
			function EnemyManager:reindex_tasks()
				local new_tasks_tbl = {}
				for i=1,#self._queued_tasks do
					local v = self._queued_tasks[i]
					if not v.was_executed then
						table.insert(new_tasks_tbl, v)
					end
				end
				self._queued_tasks = new_tasks_tbl
			end

			function EnemyManager:_update_queued_tasks(t, dt)
				local tasks_executed = 0

				local max_tasks_this_frame = math.ceil(60 * dt)
				
				if not managers.groupai:state():whisper_mode() then -- stelf
					if DS_BW._low_spawns_manager and DS_BW._low_spawns_manager.level then
						local tasks_per_lvl = {
							[0] = 60,
							[1] = 80,
							[2] = 100,
							[3] = 150,
							[4] = 210,
							[5] = 300,
							[6] = 300, -- crashproofing in case i fucked something up elsewhere
						}
						local options_mul = DS_BW.settings.tasks_per_min_mul or 1
						max_tasks_this_frame = math.ceil(tasks_per_lvl[DS_BW._low_spawns_manager.level] * options_mul * dt)
					end
				end

				for i=1, #self._queued_tasks do
					local task_data = self._queued_tasks[i]

					if not task_data.t or task_data.t < t then
						self:_execute_queued_task(i)
						tasks_executed = tasks_executed + 1
					elseif task_data.asap then
						self:_execute_queued_task(i)
						tasks_executed = tasks_executed + 1
					end

					if tasks_executed > max_tasks_this_frame then
						break
					end

					i = i + 1
				end

				local all_clbks = self._delayed_clbks

				if all_clbks[1] and all_clbks[1][2] < t then
					local clbk = table.remove(all_clbks, 1)[3]

					clbk()
				end
				
				self:reindex_tasks()
			end

			function EnemyManager:_execute_queued_task(i)
				local task = self._queued_tasks[i]
				if task.was_executed then
					return
				end

				task.was_executed = true
				
				self._queued_task_executed = true

				if task.v_cb then
					task.v_cb(task.id)
				end

				task.clbk(task.data)
			end

			function EnemyManager:unqueue_task(id)
				local tasks = self._queued_tasks
				local i = #tasks

				while i > 0 do
					if tasks[i].id == id then
						tasks[i].was_executed = true
						return
					end

					i = i - 1
				end
			end
			
		elseif not tweak_data then
			update_EnemyManager()
		end
	end)
end
update_EnemyManager()