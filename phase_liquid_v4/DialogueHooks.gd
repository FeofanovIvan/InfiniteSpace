extends RefCounted
## OPTIONAL examples to be manually adapted to the actual tablet/dialog scripts.
## Do not attach blindly to the main scene: dialogue UI evolves by version.

# var phase = preload("res://phase_liquid_v4/PhaseLiquid3D.tscn").instantiate()
# character_portrait_slot.add_child(phase)
# phase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
#
# When the alien starts a spoken line:
# phase.speak_for(maxf(1.2, voice_duration_seconds), 0.70)
#
# While an audio player is speaking, if measured energy is available:
# phase.set_voice_energy(clampf(normalized_amplitude, 0.0, 1.0))
#
# When speech ends:
# phase.stop_talking()
#
# To avoid multiple live viewports on mobile, instantiate only for the
# currently visible representative; leave atlas thumbnail as a PNG.
