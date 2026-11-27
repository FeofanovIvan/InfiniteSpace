class_name ComicPdfExporter
extends RefCounted

signal progress_changed(done: int, total: int)

const CATALOG_PATH := "res://mika_motion_comic/data/comic_catalog.json"
const PDF_WIDTH := 595.0
const PDF_HEIGHT := 842.0
const EXPORT_WIDTH := 1240
const EXPORT_HEIGHT := 1754

var last_error: String = ""

func export_pdf(language: String, drawing: Image, tree: SceneTree) -> String:
	last_error = ""
	var catalog := _load_catalog()
	if catalog.is_empty():
		return ""
	var languages: Array = catalog.get("languages", [])
	if not languages.has(language):
		last_error = "Unsupported comic language: " + language
		return ""
	var pages: Array = catalog.get("pages", [])
	if pages.is_empty():
		last_error = "Comic catalog contains no pages."
		return ""
	var output_path := "user://MIKA_Infinite_Space_%s.pdf" % language
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not create the PDF file."
		return ""
	var object_count: int = 2 + pages.size() * 3
	var offsets: Array[int] = []
	offsets.resize(object_count + 1)
	file.store_buffer(PackedByteArray([37, 80, 68, 70, 45, 49, 46, 52, 10, 37, 226, 227, 207, 211, 10]))
	_write_object(file, offsets, 1, "<< /Type /Catalog /Pages 2 0 R >>")
	var kids := PackedStringArray()
	for index in range(pages.size()):
		kids.append("%d 0 R" % (3 + index * 3))
	_write_object(file, offsets, 2, "<< /Type /Pages /Count %d /Kids [%s] >>" % [pages.size(), " ".join(kids)])
	for index in range(pages.size()):
		var page: Dictionary = pages[index]
		var image := _load_page_image(catalog, page, language, drawing)
		if image == null or image.is_empty():
			file.close()
			DirAccess.remove_absolute(ProjectSettings.globalize_path(output_path))
			if last_error.is_empty():
				last_error = "Could not render page " + str(page.get("id", index))
			return ""
		image.resize(EXPORT_WIDTH, EXPORT_HEIGHT, Image.INTERPOLATE_LANCZOS)
		image.convert(Image.FORMAT_RGB8)
		var jpg := image.save_jpg_to_buffer(0.86)
		var page_object: int = 3 + index * 3
		var content_object: int = page_object + 1
		var image_object: int = page_object + 2
		_write_object(file, offsets, page_object, "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.0f %.0f] /Resources << /XObject << /Im0 %d 0 R >> >> /Contents %d 0 R >>" % [PDF_WIDTH, PDF_HEIGHT, image_object, content_object])
		var drawing_commands := "q\n%.0f 0 0 %.0f 0 0 cm\n/Im0 Do\nQ\n" % [PDF_WIDTH, PDF_HEIGHT]
		_write_stream_object(file, offsets, content_object, drawing_commands.to_utf8_buffer(), "")
		var image_dictionary := "/Type /XObject /Subtype /Image /Width %d /Height %d /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode" % [EXPORT_WIDTH, EXPORT_HEIGHT]
		_write_stream_object(file, offsets, image_object, jpg, image_dictionary)
		progress_changed.emit(index + 1, pages.size())
		await tree.process_frame
	var xref_position: int = file.get_position()
	_write_ascii(file, "xref\n0 %d\n" % (object_count + 1))
	_write_ascii(file, "0000000000 65535 f \n")
	for object_id in range(1, object_count + 1):
		_write_ascii(file, "%010d 00000 n \n" % offsets[object_id])
	_write_ascii(file, "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % [object_count + 1, xref_position])
	file.close()
	return output_path

func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	var catalog := _load_catalog()
	if catalog.is_empty():
		errors.append(last_error)
		return errors
	var languages: Array = catalog.get("languages", [])
	var seen := {}
	for raw_page in catalog.get("pages", []):
		var page: Dictionary = raw_page
		var page_id := str(page.get("id", ""))
		if page_id.is_empty() or seen.has(page_id):
			errors.append("Invalid or duplicate page id: " + page_id)
		continue
		seen[page_id] = true
		if page.has("overlay_template"):
			if not bool(page.get("blank_base", false)) and not FileAccess.file_exists(str(page.get("base_path", ""))):
				errors.append("Missing base page: " + str(page.get("base_path", "")))
			for language in languages:
				var overlay := str(page.overlay_template).replace("{language}", str(language))
				if not FileAccess.file_exists(overlay):
					errors.append("Missing overlay: " + overlay)
		elif page.has("neutral_path"):
			if not FileAccess.file_exists(str(page.neutral_path)):
				errors.append("Missing page: " + str(page.neutral_path))
		else:
			for language in languages:
				var path := _page_path(catalog, page, str(language))
				if not FileAccess.file_exists(path):
					errors.append("Missing page: " + path)
	return errors

func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		last_error = "Comic catalog is missing."
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		last_error = "Comic catalog is not valid JSON."
		return {}
	return parsed as Dictionary

func _page_path(catalog: Dictionary, page: Dictionary, language: String) -> String:
	if page.has("neutral_path"):
		return str(page.neutral_path)
	var template := str(page.get("localized_template", catalog.get("default_localized_template", "")))
	return template.replace("{id}", str(page.get("id", ""))).replace("{language}", language)

func _load_page_image(catalog: Dictionary, page: Dictionary, language: String, drawing: Image) -> Image:
	var image: Image
	if page.has("overlay_template"):
		if bool(page.get("blank_base", false)):
			image = Image.create(2480, 3508, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
		else:
			image = _load_image(str(page.get("base_path", "")))
			if image == null:
				return null
		var overlay_path := str(page.overlay_template).replace("{language}", language)
		var overlay := _load_image(overlay_path)
		if overlay == null:
			return null
		if overlay.get_size() != image.get_size():
			overlay.resize(image.get_width(), image.get_height(), Image.INTERPOLATE_LANCZOS)
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		if overlay.get_format() != Image.FORMAT_RGBA8:
			overlay.convert(Image.FORMAT_RGBA8)
		image.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)
	else:
		image = _load_image(_page_path(catalog, page, language))
		if image == null:
			return null
	if str(page.get("section", "")) == "child_art" and drawing != null and not drawing.is_empty():
		_composite_drawing(image, drawing, page.get("drawing_rect", []))
	return image

func _load_image(path: String) -> Image:
	if not FileAccess.file_exists(path):
		last_error = "Missing comic resource: " + path
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	var extension := path.get_extension().to_lower()
	var error := ERR_FILE_UNRECOGNIZED
	match extension:
		"webp":
			error = image.load_webp_from_buffer(bytes)
		"png":
			error = image.load_png_from_buffer(bytes)
		"jpg", "jpeg":
			error = image.load_jpg_from_buffer(bytes)
		"svg":
			error = image.load_svg_from_buffer(bytes, 1.0)
	if error != OK:
		last_error = "Could not decode comic resource: " + path
		return null
	return image

func _composite_drawing(page: Image, drawing: Image, raw_rect: Variant) -> void:
	if not raw_rect is Array or raw_rect.size() != 4:
		return
	if page.get_format() != Image.FORMAT_RGBA8:
		page.convert(Image.FORMAT_RGBA8)
	var target := Rect2i(int(raw_rect[0]), int(raw_rect[1]), int(raw_rect[2]), int(raw_rect[3]))
	var artwork := drawing.duplicate()
	if artwork.get_format() != Image.FORMAT_RGBA8:
		artwork.convert(Image.FORMAT_RGBA8)
	var scale := minf(float(target.size.x) / artwork.get_width(), float(target.size.y) / artwork.get_height())
	var fitted := Vector2i(maxi(1, roundi(artwork.get_width() * scale)), maxi(1, roundi(artwork.get_height() * scale)))
	artwork.resize(fitted.x, fitted.y, Image.INTERPOLATE_LANCZOS)
	var position := target.position + (target.size - fitted) / 2
	page.blend_rect(artwork, Rect2i(Vector2i.ZERO, fitted), position)

func _write_object(file: FileAccess, offsets: Array[int], object_id: int, body: String) -> void:
	offsets[object_id] = file.get_position()
	_write_ascii(file, "%d 0 obj\n%s\nendobj\n" % [object_id, body])

func _write_stream_object(file: FileAccess, offsets: Array[int], object_id: int, bytes: PackedByteArray, dictionary: String) -> void:
	offsets[object_id] = file.get_position()
	var prefix := "%d 0 obj\n<< %s /Length %d >>\nstream\n" % [object_id, dictionary, bytes.size()]
	_write_ascii(file, prefix)
	file.store_buffer(bytes)
	_write_ascii(file, "\nendstream\nendobj\n")

func _write_ascii(file: FileAccess, value: String) -> void:
	file.store_buffer(value.to_utf8_buffer())
