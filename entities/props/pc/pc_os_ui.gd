extends Control

signal boot_complete
signal app_closed

@onready var boot_screen: Control = $BootScreen
@onready var desktop_screen: Control = $Desktop
@onready var boot_log: Label = $BootScreen/LogLabel
@onready var loading_bar: ProgressBar = $BootScreen/ProgressBar
@onready var time_label: Label = $Desktop/TaskBar/TimeLabel

var boot_step: int = 0
var boot_timer: float = 0.0
var is_booted: bool = false
    
func _ready() -> void:
    if not boot_screen:
        push_error("PCOSUI: BootScreen node missing!")
        return
        
    boot_screen.visible = true
    if desktop_screen: desktop_screen.visible = false
    if loading_bar: loading_bar.value = 0
    _add_log("> System Power On...")

func _process(delta: float) -> void:
	if not is_booted:
		_process_boot(delta)
	else:
		_update_clock()

func _process_boot(delta: float) -> void:
	boot_timer += delta
	if boot_timer > 0.5:
		boot_timer = 0.0
		boot_step += 1
		_advance_boot()

func _advance_boot() -> void:
	match boot_step:
		1:
			_add_log("> Checking RAM... OK")
			loading_bar.value = 10
		2:
			_add_log("> Initializing CPU Cores... [OK]")
			loading_bar.value = 25
		3:
			_add_log("> Loading Kernel... [OK]")
			loading_bar.value = 40
		4:
			_add_log("> Mounting Filesystems... /dev/sda1")
			loading_bar.value = 60
		5:
			_add_log("> Starting Network Services... [OK]")
			loading_bar.value = 80
		6:
			_add_log("> Starting Graphical Interface...")
			loading_bar.value = 95
		7:
			loading_bar.value = 100
			display_desktop()

func _add_log(text: String) -> void:
    if boot_log:
        boot_log.text += "\n" + text

func display_desktop() -> void:
	is_booted = true
	boot_screen.visible = false
	desktop_screen.visible = true
	emit_signal("boot_complete")

func _update_clock() -> void:
    if not time_label: return
    var time = Time.get_time_dict_from_system()
    time_label.text = "%02d:%02d" % [time.hour, time.minute]

func _on_shutdown_pressed() -> void:
	# Simulate shutdown or exit interaction
	emit_signal("app_closed")
