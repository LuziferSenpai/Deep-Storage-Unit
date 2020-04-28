if mods["Transport_Drones"] then
	data:extend
	{
		{
			type = "string-setting",
			name = "transport_drones_add_deep-storage-unit-fluid-big",
			setting_type = "startup",
			order = "01",
			default_value = "__Deep_Storage_Unit__/scripts/units/DSUFB",
			hidden = true
		},
		{
			type = "string-setting",
			name = "transport_drones_add_deep-storage-unit-item-big",
			setting_type = "startup",
			order = "02",
			default_value = "__Deep_Storage_Unit__/scripts/units/DSUIB",
			hidden = true
		}
	}
end